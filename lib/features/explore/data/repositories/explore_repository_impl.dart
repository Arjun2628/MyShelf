import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:epub_audio/features/epub/data/repositories/epub_repository_impl.dart';
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/epub/domain/usecases/open_epub_usecase.dart';
import 'package:epub_audio/features/explore/domain/entities/book_shelf.dart';
import 'package:epub_audio/features/explore/domain/entities/category.dart';
import 'package:epub_audio/features/explore/domain/entities/category_experience_config.dart';
import 'package:epub_audio/features/explore/domain/entities/explore_section.dart';
import 'package:epub_audio/features/explore/domain/repositories/explore_repository.dart';
import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:epub_audio/features/library/data/sample_books_provider.dart';

/// Concrete implementation of ExploreRepository that resolves books using existing
/// Book entities (SampleBooksProvider, HiveStorageService, and local synthesized EPUBs).
class ExploreRepositoryImpl implements ExploreRepository {
  final OpenEpubUseCase _openEpubUseCase;
  final SampleBooksProvider _sampleBooksProvider;
  final HiveStorageService _hiveStorageService;

  final Map<String, Book> _bookCache = {};
  bool _initialized = false;

  ExploreRepositoryImpl({
    OpenEpubUseCase? openEpubUseCase,
    SampleBooksProvider? sampleBooksProvider,
    HiveStorageService? hiveStorageService,
  })  : _openEpubUseCase = openEpubUseCase ??
            const OpenEpubUseCase(
              EpubRepositoryImpl(),
            ),
        _sampleBooksProvider = sampleBooksProvider ??
            SampleBooksProvider(
              openEpubUseCase ??
                  const OpenEpubUseCase(
                    EpubRepositoryImpl(),
                  ),
            ),
        _hiveStorageService = hiveStorageService ?? HiveStorageService();

  Future<void> _ensureCatalogLoaded() async {
    if (_initialized) return;

    // 1. Load foundational sample books
    try {
      final chemmeen = await _sampleBooksProvider.getMalayalamSampleBook();
      _bookCache[chemmeen.id] = chemmeen;
    } catch (_) {}

    try {
      final alice = await _sampleBooksProvider.getEnglishSampleBook();
      _bookCache[alice.id] = alice;
    } catch (_) {}

    // 2. Synthesize rich catalog books with real valid EPUB structure
    final extraBooks = await _buildExploreCatalogBooks();
    for (final b in extraBooks) {
      _bookCache[b.id] = b;
    }

    // 3. Load user-imported books from HiveStorage
    try {
      final storedBooks = await _hiveStorageService.loadAllImportedBooks(_openEpubUseCase);
      for (final sb in storedBooks) {
        if (!_bookCache.containsKey(sb.id)) {
          _bookCache[sb.id] = sb;
        }
      }
    } catch (_) {}

    _initialized = true;
  }

  @override
  Future<List<ExploreSection>> getExploreSections() async {
    await _ensureCatalogLoaded();

    return [
      const ExploreSection(
        id: 'sec_greeting',
        title: 'Explore & Discover',
        subtitle: 'Curated stories, ambient audiobooks, and rich worlds',
        type: ExploreSectionType.greeting,
      ),
      const ExploreSection(
        id: 'sec_hero_featured',
        title: 'Featured Today',
        subtitle: 'Editor\'s handpicked immersive experiences',
        type: ExploreSectionType.featured,
        bookIds: ['book_sherlock', 'sample_chemmeen', 'book_starlight'],
        displayStyle: ShelfDisplayStyle.largeFeatured,
      ),
      const ExploreSection(
        id: 'sec_continue_reading',
        title: 'Continue Reading',
        subtitle: 'Pick up right where you left off',
        type: ExploreSectionType.continueReading,
        bookIds: ['sample_chemmeen', 'sample_alice'],
        displayStyle: ShelfDisplayStyle.horizontalCarousel,
      ),
      const ExploreSection(
        id: 'sec_continue_listening',
        title: 'Continue Listening',
        subtitle: 'Audiobooks in progress',
        type: ExploreSectionType.continueListening,
        bookIds: ['book_sherlock'],
        displayStyle: ShelfDisplayStyle.horizontalCarousel,
      ),
      const ExploreSection(
        id: 'sec_categories',
        title: 'Browse by Mood & Category',
        subtitle: 'Every category crafted with a unique visual and audio aesthetic',
        type: ExploreSectionType.categories,
        displayStyle: ShelfDisplayStyle.grid,
      ),
      const ExploreSection(
        id: 'sec_story_cards',
        title: 'Immersive Story Spotlight',
        subtitle: 'Deep atmospheric journeys',
        type: ExploreSectionType.recommended,
        bookIds: ['book_dracula', 'book_timemachine', 'book_littleprince'],
        displayStyle: ShelfDisplayStyle.storyCards,
      ),
      const ExploreSection(
        id: 'sec_popular',
        title: 'Popular Classics & Hits',
        subtitle: 'Most read this week',
        type: ExploreSectionType.popular,
        bookIds: ['sample_alice', 'book_sherlock', 'book_artofwar', 'sample_chemmeen'],
        displayStyle: ShelfDisplayStyle.horizontalCarousel,
      ),
      const ExploreSection(
        id: 'sec_malayalam_shelf',
        title: 'Malayalam Classics',
        subtitle: 'Great works of Malayalam literature',
        type: ExploreSectionType.curated,
        categoryId: 'cat_malayalam',
        bookIds: ['sample_chemmeen', 'book_indulekha', 'book_balyakalasakhi'],
        displayStyle: ShelfDisplayStyle.horizontalShelf,
      ),
      const ExploreSection(
        id: 'sec_new_releases',
        title: 'Freshly Added',
        subtitle: 'New arrivals in the universe',
        type: ExploreSectionType.newReleases,
        bookIds: ['book_starlight', 'book_history_kerala', 'book_dracula'],
        displayStyle: ShelfDisplayStyle.coverCarousel,
      ),
      const ExploreSection(
        id: 'sec_curated_picks',
        title: 'Essential Masterpieces',
        subtitle: 'Hand-picked literature for your collection',
        type: ExploreSectionType.curated,
        bookIds: ['book_sherlock', 'book_timemachine', 'book_artofwar', 'sample_alice'],
        displayStyle: ShelfDisplayStyle.verticalList,
      ),
    ];
  }

  @override
  Future<List<Category>> getCategories() async {
    return [
      const Category(
        id: 'cat_history',
        name: 'History & Lore',
        tagline: 'Ancient chronicles & timeless narratives',
        iconName: 'history_edu_rounded',
        experienceId: 'exp_history',
        bookIds: ['book_history_kerala', 'book_artofwar'],
        tags: ['History', 'Chronicles', 'Parchment', 'World'],
      ),
      const Category(
        id: 'cat_mystery',
        name: 'Mystery & Crime',
        tagline: 'Dark intrigue, riddles & shadows',
        iconName: 'psychology_alt_rounded',
        experienceId: 'exp_mystery',
        bookIds: ['book_sherlock', 'book_dracula'],
        tags: ['Mystery', 'Suspense', 'Detective', 'Thriller'],
      ),
      const Category(
        id: 'cat_malayalam',
        name: 'Malayalam Classics',
        tagline: 'മലയാള സാഹിത്യത്തിലെ അനശ്വര സൃഷ്ടികൾ',
        iconName: 'menu_book_rounded',
        experienceId: 'exp_malayalam',
        bookIds: ['sample_chemmeen', 'book_indulekha', 'book_balyakalasakhi'],
        tags: ['Malayalam', 'Kerala', 'Literature', 'Classics'],
      ),
      const Category(
        id: 'cat_scifi',
        name: 'Sci-Fi & Time Travel',
        tagline: 'Visions of tomorrow & distant cosmos',
        iconName: 'rocket_launch_rounded',
        experienceId: 'exp_scifi',
        bookIds: ['book_timemachine'],
        tags: ['Sci-Fi', 'Future', 'Space', 'Time'],
      ),
      const Category(
        id: 'cat_sleep',
        name: 'Sleep & Ambient Tales',
        tagline: 'Calm rhythms for deep relaxation',
        iconName: 'bedtime_rounded',
        experienceId: 'exp_sleep',
        bookIds: ['book_starlight'],
        tags: ['Sleep', 'Meditation', 'Relax', 'Night'],
      ),
      const Category(
        id: 'cat_fantasy',
        name: 'Fantasy & Wonder',
        tagline: 'Magical realms & mythical beasts',
        iconName: 'auto_fix_high_rounded',
        experienceId: 'exp_fantasy',
        bookIds: ['sample_alice', 'book_littleprince'],
        tags: ['Fantasy', 'Magic', 'Adventure', 'Wonder'],
      ),
      const Category(
        id: 'cat_children',
        name: 'Children & Fables',
        tagline: 'Whimsical adventures for young minds',
        iconName: 'child_care_rounded',
        experienceId: 'exp_children',
        bookIds: ['sample_alice', 'book_littleprince'],
        tags: ['Kids', 'Illustrated', 'Fables', 'Bedtime'],
      ),
      const Category(
        id: 'cat_philosophy',
        name: 'Philosophy & Wisdom',
        tagline: 'Strategic thoughts & timeless principles',
        iconName: 'lightbulb_rounded',
        experienceId: 'exp_history',
        bookIds: ['book_artofwar'],
        tags: ['Wisdom', 'Philosophy', 'Strategy'],
      ),
    ];
  }

  @override
  Future<Category?> getCategoryById(String categoryId) async {
    final categories = await getCategories();
    try {
      return categories.firstWhere((c) => c.id == categoryId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<CategoryExperienceConfig> getCategoryExperienceConfig(String experienceId) async {
    final configs = _getExperienceConfigs();
    return configs[experienceId] ?? CategoryExperienceConfig.defaultConfig;
  }

  @override
  Future<List<Book>> getCategoryBooks(String categoryId) async {
    await _ensureCatalogLoaded();
    final category = await getCategoryById(categoryId);
    if (category == null) return [];
    return getBooksByIds(category.bookIds);
  }

  @override
  Future<List<Book>> getBooksByIds(List<String> bookIds) async {
    await _ensureCatalogLoaded();
    final List<Book> results = [];
    for (final id in bookIds) {
      final book = _bookCache[id];
      if (book != null) {
        results.add(book);
      }
    }
    return results;
  }

  @override
  Future<Book?> getBookById(String bookId) async {
    await _ensureCatalogLoaded();
    return _bookCache[bookId];
  }

  @override
  Future<List<BookShelf>> getCuratedShelves() async {
    await _ensureCatalogLoaded();

    try {
      final customJson = _hiveStorageService.getCustomSetting<String>('curated_shelves_custom_v1');
      if (customJson != null && customJson.isNotEmpty) {
        final List<dynamic> list = jsonDecode(customJson);
        return list.map((item) {
          final map = item as Map<String, dynamic>;
          final styleName = map['displayStyle'] as String?;
          final style = ShelfDisplayStyle.values.firstWhere(
            (s) => s.name == styleName,
            orElse: () => ShelfDisplayStyle.horizontalShelf,
          );
          return BookShelf(
            id: map['id'] as String? ?? 'shelf_custom',
            title: map['title'] as String? ?? 'Curated Shelf',
            subtitle: map['subtitle'] as String?,
            bookIds: (map['bookIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
            displayStyle: style,
            categoryId: map['categoryId'] as String?,
          );
        }).toList();
      }
    } catch (_) {}

    return [
      const BookShelf(
        id: 'shelf_malayalam',
        title: 'Malayalam Gems',
        subtitle: 'Timeless storytelling from God\'s own country',
        bookIds: ['sample_chemmeen', 'book_indulekha', 'book_balyakalasakhi'],
        displayStyle: ShelfDisplayStyle.horizontalShelf,
        categoryId: 'cat_malayalam',
      ),
      const BookShelf(
        id: 'shelf_mystery_thrillers',
        title: 'Midnight Thrillers',
        subtitle: 'Suspense stories best read with the lights off',
        bookIds: ['book_sherlock', 'book_dracula'],
        displayStyle: ShelfDisplayStyle.storyCards,
        categoryId: 'cat_mystery',
      ),
      const BookShelf(
        id: 'shelf_sleep_stories',
        title: 'Sleep & Night Ambience',
        subtitle: 'Drift into slumber with soothing narrations',
        bookIds: ['book_starlight'],
        displayStyle: ShelfDisplayStyle.horizontalCarousel,
        categoryId: 'cat_sleep',
      ),
      const BookShelf(
        id: 'shelf_classics',
        title: 'World Literature Classics',
        subtitle: 'Foundational stories of human imagination',
        bookIds: ['sample_alice', 'book_timemachine', 'book_artofwar'],
        displayStyle: ShelfDisplayStyle.coverCarousel,
      ),
    ];
  }

  Map<String, CategoryExperienceConfig> _getExperienceConfigs() {
    return {
      'exp_history': const CategoryExperienceConfig(
        id: 'exp_history',
        themeId: 'parchment',
        gradientHexColors: ['0xFF2B2217', '0xFF161009'],
        typographyId: 'classical',
        accentColorHex: '0xFFD4A373',
        atmosphereEffectId: 'ink_dust',
        ambientAudioId: 'historical_ambience',
        transitionType: 'page_unfold',
      ),
      'exp_mystery': const CategoryExperienceConfig(
        id: 'exp_mystery',
        themeId: 'dark_mystery',
        gradientHexColors: ['0xFF141724', '0xFF0A0C14'],
        typographyId: 'suspense',
        accentColorHex: '0xFF8B5CF6',
        atmosphereEffectId: 'shadow_mist',
        ambientAudioId: 'suspense_ambience',
        transitionType: 'shadow_fade',
      ),
      'exp_malayalam': const CategoryExperienceConfig(
        id: 'exp_malayalam',
        themeId: 'kerala_heritage',
        gradientHexColors: ['0xFF24180C', '0xFF140C06'],
        typographyId: 'classical',
        accentColorHex: '0xFFF59E0B',
        atmosphereEffectId: 'golden_glow',
        ambientAudioId: 'temple_rain',
        transitionType: 'fade_scale',
      ),
      'exp_scifi': const CategoryExperienceConfig(
        id: 'exp_scifi',
        themeId: 'cosmic_scifi',
        gradientHexColors: ['0xFF0B192C', '0xFF040C17'],
        typographyId: 'modern',
        accentColorHex: '0xFF06B6D4',
        atmosphereEffectId: 'cosmic_pulse',
        ambientAudioId: 'deep_space',
        transitionType: 'warp_slide',
      ),
      'exp_sleep': const CategoryExperienceConfig(
        id: 'exp_sleep',
        themeId: 'night_sky',
        gradientHexColors: ['0xFF0A192F', '0xFF030A14'],
        typographyId: 'soft',
        accentColorHex: '0xFF60A5FA',
        atmosphereEffectId: 'starfield',
        ambientAudioId: 'calm_ambience',
        transitionType: 'gentle_float',
      ),
      'exp_fantasy': const CategoryExperienceConfig(
        id: 'exp_fantasy',
        themeId: 'magical_realm',
        gradientHexColors: ['0xFF241026', '0xFF120514'],
        typographyId: 'fantasy',
        accentColorHex: '0xFFEC4899',
        atmosphereEffectId: 'magical_sparkles',
        ambientAudioId: 'enchanted_forest',
        transitionType: 'portal_zoom',
      ),
      'exp_children': const CategoryExperienceConfig(
        id: 'exp_children',
        themeId: 'illustrated_world',
        gradientHexColors: ['0xFF1E293B', '0xFF0F172A'],
        typographyId: 'playful',
        accentColorHex: '0xFF10B981',
        atmosphereEffectId: 'floating_bubbles',
        ambientAudioId: 'gentle_lullaby',
        transitionType: 'bounce_pop',
      ),
    };
  }

  Future<List<Book>> _buildExploreCatalogBooks() async {
    final List<Book> books = [];

    // 1. Sherlock Holmes (Mystery)
    try {
      final sherlock = await _createSynthesizedBook(
        bookId: 'book_sherlock',
        title: 'The Adventures of Sherlock Holmes',
        creator: 'Arthur Conan Doyle',
        language: 'en',
        description: 'Iconic detective mysteries solved by the legendary Sherlock Holmes and Dr. Watson.',
        chapters: [
          _ChapterData(
            title: 'A Scandal in Bohemia',
            contentHtml: '<h1>A Scandal in Bohemia</h1><p>To Sherlock Holmes she is always <i>the</i> woman. I have seldom heard him mention her under any other name.</p><p>In his eyes she eclipses and predominates the whole of her sex. It was not that he felt any emotion akin to love for Irene Adler.</p><blockquote><p>"You see, Watson, but you do not observe. The distinction is clear."</p></blockquote><p>We sat in the consulting room at Baker Street as footsteps ascended the wooden stairs.</p>',
          ),
          _ChapterData(
            title: 'The Red-Headed League',
            contentHtml: '<h1>The Red-Headed League</h1><p>I had called upon my friend, Mr. Sherlock Holmes, one day in the autumn of last year and found him in deep conversation with a very stout, florid-faced, elderly gentleman with fiery red hair.</p><p>Holmes smiled and waved me into an armchair. "You could not have come at a better time, my dear Watson," he said cordially.</p>',
          ),
        ],
      );
      books.add(sherlock);
    } catch (_) {}

    // 2. Dracula (Gothic Horror/Mystery)
    try {
      final dracula = await _createSynthesizedBook(
        bookId: 'book_dracula',
        title: 'Dracula: The Shadow in the Mist',
        creator: 'Bram Stoker',
        language: 'en',
        description: 'Gothic masterpiece of mystery, ancient castles, and the dark prince of the night.',
        chapters: [
          _ChapterData(
            title: 'Jonathan Harker\'s Journal',
            contentHtml: '<h1>Jonathan Harker\'s Journal</h1><p>3 May. Bistritz.—Left Munich at 8:35 P. M., arriving at Vienna early next morning; should have arrived at 6:46, but train was an hour late.</p><p>The shadows grew longer as the carriage climbed higher into the Carpathians. The wolves howled in the mountain gorges.</p><blockquote><p>"Welcome to my house! Enter freely and of your own will!"</p></blockquote>',
          ),
        ],
      );
      books.add(dracula);
    } catch (_) {}

    // 3. Starlight Sleep Tales (Sleep / Ambient)
    try {
      final sleepBook = await _createSynthesizedBook(
        bookId: 'book_starlight',
        title: 'Starlight Sanctuary: Tales for Deep Sleep',
        creator: 'Luna Whisper',
        language: 'en',
        description: 'Gentle ambient prose designed to ease your mind and guide you into restful sleep.',
        chapters: [
          _ChapterData(
            title: 'The Whispering Forest of Dreams',
            contentHtml: '<h1>The Whispering Forest of Dreams</h1><p>Take a deep, slow breath. Feel the weight of the day gently lift away from your shoulders.</p><p>Before you lies a path of soft silver moss, illuminated by the calm glow of distant stars. The nocturnal breeze carries the soothing scent of lavender and pine.</p><p>Step forward gently. Each breath brings deeper calm and tranquility.</p>',
          ),
        ],
      );
      books.add(sleepBook);
    } catch (_) {}

    // 4. The Time Machine (Sci-Fi)
    try {
      final timeMachine = await _createSynthesizedBook(
        bookId: 'book_timemachine',
        title: 'The Time Machine',
        creator: 'H. G. Wells',
        language: 'en',
        description: 'Pioneering science fiction exploration across millennia into the distant future.',
        chapters: [
          _ChapterData(
            title: 'The Four Dimensions',
            contentHtml: '<h1>The Four Dimensions</h1><p>The Time Traveller was expounding a recondite matter to us. His grey eyes shone and twinkled, and his usually pale face was flushed and animated.</p><p>"Scientific people know very well that Time is only a kind of Space," he explained, holding up a small metallic mechanism that shimmered with temporal light.</p>',
          ),
        ],
      );
      books.add(timeMachine);
    } catch (_) {}

    // 5. The Art of War (Philosophy & History)
    try {
      final artOfWar = await _createSynthesizedBook(
        bookId: 'book_artofwar',
        title: 'The Art of War (സുൻ സൂ)',
        creator: 'Sun Tzu',
        language: 'en',
        description: 'Timeless strategic philosophy on discipline, tactical positioning, and mastery.',
        chapters: [
          _ChapterData(
            title: 'Laying Plans',
            contentHtml: '<h1>Laying Plans</h1><p>Sun Tzu said: The art of war is of vital importance to the State. It is a matter of life and death, a road either to safety or to ruin.</p><blockquote><p>"All warfare is based on deception. Hence, when able to attack, we must seem unable."</p></blockquote><p>He who knows when he can fight and when he cannot will be victorious.</p>',
          ),
        ],
      );
      books.add(artOfWar);
    } catch (_) {}

    // 6. The Little Prince (Fantasy & Children)
    try {
      final littlePrince = await _createSynthesizedBook(
        bookId: 'book_littleprince',
        title: 'The Little Prince (കുഞ്ഞു രാജകുമാരൻ)',
        creator: 'Antoine de Saint-Exupéry',
        language: 'en',
        description: 'Poetic tale of a young prince who visits various planets, addressing themes of loneliness, friendship, and love.',
        chapters: [
          _ChapterData(
            title: 'The Star Asteroid B-612',
            contentHtml: '<h1>The Star Asteroid B-612</h1><p>It is only with the heart that one can see rightly; what is essential is invisible to the eye.</p><p>"Please... draw me a sheep!" said the little voice in the vast desert under the golden sunrise.</p>',
          ),
        ],
      );
      books.add(littlePrince);
    } catch (_) {}

    // 7. Indulekha (Malayalam Classic)
    try {
      final indulekha = await _createSynthesizedBook(
        bookId: 'book_indulekha',
        title: 'ഇന്ദുലേഖ (Indulekha)',
        creator: 'ഒ. ചന്തുമേനോൻ (O. Chandu Menon)',
        language: 'ml',
        description: 'മലയാളത്തിലെ ആദ്യത്തെ ലക്ഷണമൊത്ത നോവൽ. സാമൂഹിക പരിവർത്തനത്തിന്റെ നാഴികക്കല്ല്.',
        chapters: [
          _ChapterData(
            title: 'അദ്ധ്യായം 1: പൂവള്ളി വീട്',
            contentHtml: '<h1>അദ്ധ്യായം ഒന്ന്: പൂവള്ളി വീട്</h1><p>സൂര്യോദയസമയത്ത് പൂവള്ളി ഭവനത്തിൽ എല്ലാവരും ഉണർന്നു. ഇന്ദുലേഖ തന്റെ പഠനമുറിയിൽ പുസ്തകം വായിക്കുകയായിരുന്നു.</p><p>ഇംഗ്ലീഷ് വിദ്യാഭ്യാസവും സംസ്കൃത പാണ്ഡിത്യവും തികഞ്ഞ സൗന്ദര്യവുമുള്ള ഒരു യുവതിയായിരുന്നു അവൾ.</p>',
          ),
        ],
      );
      books.add(indulekha);
    } catch (_) {}

    // 8. Balyakalasakhi (Malayalam Classic)
    try {
      final balyakalasakhi = await _createSynthesizedBook(
        bookId: 'book_balyakalasakhi',
        title: 'ബാല്യകാലസഖി (Balyakalasakhi)',
        creator: 'വൈക്കം മുഹമ്മദ് ബഷീർ (Vaikom Muhammad Basheer)',
        language: 'ml',
        description: 'മജീദിന്റെയും സുഹ്റയുടെയും ഹൃദയസ്പർശിയായ പ്രണയകഥ.',
        chapters: [
          _ChapterData(
            title: 'മജീദും സുഹ്റയും',
            contentHtml: '<h1>മജീദും സുഹ്റയും</h1><p>അവർ ഒരേ പറമ്പിൽ കളിച്ചുവളർന്നവരാണ്. സുഹ്റയുടെ ചിരിയും കുറുമ്പുകളും മജീദിന്റെ ഓർമ്മകളിൽ എപ്പോഴും നിറഞ്ഞുനിന്നു.</p><p>"മജീദേ, നീ എന്നെ എപ്പോഴെങ്കിലും മറക്കുമോ?" സുഹ്റ ചോദിക്കാറുണ്ടായിരുന്നു.</p>',
          ),
        ],
      );
      books.add(balyakalasakhi);
    } catch (_) {}

    // 9. History of Kerala (History)
    try {
      final historyKerala = await _createSynthesizedBook(
        bookId: 'book_history_kerala',
        title: 'A Chronicle of Kerala & Spice Coast',
        creator: 'K. M. Panikkar',
        language: 'en',
        description: 'The ancient maritime trade, spice routes, and monumental heritage of Malabar and Travancore.',
        chapters: [
          _ChapterData(
            title: 'The Ancient Port of Muziris',
            contentHtml: '<h1>The Ancient Port of Muziris</h1><p>Centuries before the dawn of modern navigation, Roman and Phoenician vessels crossed the Arabian Sea to drop anchor at the legendary port of Muziris.</p><p>Bags of black pepper—the black gold of the Western Ghats—were exchanged for gold coins and Mediterranean amphorae of wine.</p>',
          ),
        ],
      );
      books.add(historyKerala);
    } catch (_) {}

    return books;
  }

  Future<Book> _createSynthesizedBook({
    required String bookId,
    required String title,
    required String creator,
    required String language,
    required String description,
    required List<_ChapterData> chapters,
  }) async {
    final Map<String, String> files = {};

    // Standard container
    files['mimetype'] = 'application/epub+zip';
    files['META-INF/container.xml'] = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

    // OPF manifest and spine items
    final manifestItems = <String>[];
    manifestItems.add('<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>');
    final spineItems = <String>[];
    final navPoints = <String>[];

    for (int i = 0; i < chapters.length; i++) {
      final chId = 'ch${i + 1}';
      final fileName = 'text/$chId.xhtml';
      manifestItems.add('<item id="$chId" href="$fileName" media-type="application/xhtml+xml"/>');
      spineItems.add('<itemref idref="$chId"/>');
      navPoints.add('''    <navPoint id="p${i + 1}" playOrder="${i + 1}">
      <navLabel><text>${_escapeXml(chapters[i].title)}</text></navLabel>
      <content src="$fileName"/>
    </navPoint>''');

      files['OEBPS/$fileName'] = '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>${_escapeXml(chapters[i].title)}</title></head>
<body>
${chapters[i].contentHtml}
</body>
</html>''';
    }

    files['OEBPS/content.opf'] = '''<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookId" version="2.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>${_escapeXml(title)}</dc:title>
    <dc:creator>${_escapeXml(creator)}</dc:creator>
    <dc:language>$language</dc:language>
    <dc:description>${_escapeXml(description)}</dc:description>
  </metadata>
  <manifest>
    ${manifestItems.join('\n    ')}
  </manifest>
  <spine toc="ncx">
    ${spineItems.join('\n    ')}
  </spine>
</package>''';

    files['OEBPS/toc.ncx'] = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
${navPoints.join('\n')}
  </navMap>
</ncx>''';

    final zipBytes = _createZipBytes(files);
    return _openEpubUseCase.fromBytes(zipBytes, bookId: bookId);
  }

  Uint8List _createZipBytes(Map<String, String> files) {
    final archive = Archive();
    files.forEach((name, content) {
      final bytes = utf8.encode(content);
      archive.addFile(ArchiveFile(name, bytes.length, bytes));
    });
    final encoder = ZipEncoder();
    return Uint8List.fromList(encoder.encode(archive)!);
  }

  String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

class _ChapterData {
  final String title;
  final String contentHtml;

  const _ChapterData({
    required this.title,
    required this.contentHtml,
  });
}
