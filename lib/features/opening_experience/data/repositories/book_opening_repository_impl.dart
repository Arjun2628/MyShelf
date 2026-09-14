import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:epub_audio/features/explore/domain/repositories/explore_repository.dart';
import 'package:epub_audio/features/opening_experience/domain/entities/book_opening_config.dart';
import 'package:epub_audio/features/opening_experience/domain/repositories/book_opening_repository.dart';

/// Concrete implementation resolving BookOpeningConfig with cascading resolution:
/// Book Overrides -> Category Experience -> Global Default.
class BookOpeningRepositoryImpl implements BookOpeningRepository {
  final ExploreRepository _exploreRepository;

  BookOpeningRepositoryImpl({
    ExploreRepository? exploreRepository,
  }) : _exploreRepository = exploreRepository ?? ExploreRepositoryImpl();

  @override
  Future<BookOpeningConfig> resolveOpeningConfig({
    required Book book,
    String? categoryId,
  }) async {
    // 1. Check for Book-specific character voices
    final characterVoices = _resolveCharacterVoices(book);

    // 2. Check for explicit Book-specific experience override
    final bookSpecificConfig = _resolveBookOverride(book.id, characterVoices);
    if (bookSpecificConfig != null) {
      return bookSpecificConfig;
    }

    // 3. Resolve by Category Experience if categoryId is given
    if (categoryId != null) {
      final category = await _exploreRepository.getCategoryById(categoryId);
      if (category != null) {
        final expConfig = await _exploreRepository.getCategoryExperienceConfig(category.experienceId);
        return BookOpeningConfig.fromCategoryConfig(
          categoryConfig: expConfig,
          characterVoices: characterVoices,
        );
      }
    }

    // 4. Fallback based on language or global default
    if (book.metadata.language == 'ml') {
      final expConfig = await _exploreRepository.getCategoryExperienceConfig('exp_malayalam');
      return BookOpeningConfig.fromCategoryConfig(
        categoryConfig: expConfig,
        characterVoices: characterVoices,
      );
    }

    return BookOpeningConfig(
      themeId: 'obsidian',
      gradientHexColors: const ['0xFF1B1510', '0xFF0B0806'],
      typographyId: 'modern',
      accentColorHex: '0xFFD4A373',
      atmosphereEffectId: 'golden_glow',
      animationType: 'perspective_tilt',
      ambientAudioId: 'warm_ambience',
      characterVoiceNames: characterVoices,
    );
  }

  List<String> _resolveCharacterVoices(Book book) {
    final title = book.metadata.title.toLowerCase();
    final bookId = book.id.toLowerCase();

    if (bookId.contains('chemmeen') || title.contains('chemmeen') || title.contains('ചെമ്മീൻ')) {
      return ['Narrator (വിവരണക്കാരൻ)', 'കറുത്തമ്മ (Female)', 'പരീക്കുട്ടി (Male)', 'ചെമ്പൻകുഞ്ഞ് (Elder)'];
    } else if (bookId.contains('sherlock') || title.contains('sherlock')) {
      return ['Narrator (Dr. Watson)', 'Sherlock Holmes (Analytical)', 'Irene Adler (Female)', 'Inspector Lestrade'];
    } else if (bookId.contains('alice') || title.contains('alice')) {
      return ['Narrator', 'Alice (Youth)', 'White Rabbit (Hasty)', 'Cheshire Cat (Whimsical)'];
    } else if (bookId.contains('dracula') || title.contains('dracula')) {
      return ['Jonathan Harker (Journal)', 'Count Dracula (Deep)', 'Mina Harker (Female)', 'Van Helsing (Scholar)'];
    } else if (bookId.contains('starlight') || title.contains('starlight')) {
      return ['Whispering Guide (Soft Calm)', 'Dream Narrator (Soothing)'];
    } else if (bookId.contains('timemachine') || title.contains('time machine')) {
      return ['The Time Traveller (Visionary)', 'Narrator (Observer)', 'Weena (Eloi)'];
    } else if (bookId.contains('indulekha') || title.contains('ഇന്ദുലേഖ')) {
      return ['Narrator (വിവരണക്കാരൻ)', 'ഇന്ദുലേഖ (Female)', 'മാധവൻ (Male)'];
    } else if (bookId.contains('balyakalasakhi') || title.contains('ബാല്യകാലസഖി')) {
      return ['Narrator (വിവരണക്കാരൻ)', 'മജീദ് (Male)', 'സുഹ്റ (Female)'];
    }

    return ['Narrator (Primary Voice)', 'Character Voices (Auto-mapped)'];
  }

  BookOpeningConfig? _resolveBookOverride(String bookId, List<String> characterVoices) {
    switch (bookId) {
      case 'sample_chemmeen':
      case 'book_indulekha':
      case 'book_balyakalasakhi':
        return BookOpeningConfig(
          themeId: 'kerala_heritage',
          gradientHexColors: const ['0xFF24180C', '0xFF120B05'],
          typographyId: 'classical',
          accentColorHex: '0xFFF59E0B',
          atmosphereEffectId: 'golden_glow',
          animationType: 'book_unfold',
          ambientAudioId: 'temple_rain',
          characterVoiceNames: characterVoices,
        );

      case 'book_sherlock':
        return BookOpeningConfig(
          themeId: 'dark_mystery',
          gradientHexColors: const ['0xFF161826', '0xFF0A0B12'],
          typographyId: 'suspense',
          accentColorHex: '0xFF8B5CF6',
          atmosphereEffectId: 'shadow_mist',
          animationType: 'perspective_tilt',
          ambientAudioId: 'suspense_ambience',
          characterVoiceNames: characterVoices,
        );

      case 'book_dracula':
        return BookOpeningConfig(
          themeId: 'gothic_horror',
          gradientHexColors: const ['0xFF1F1014', '0xFF0D0407'],
          typographyId: 'suspense',
          accentColorHex: '0xFFEF4444',
          atmosphereEffectId: 'shadow_mist',
          animationType: 'perspective_tilt',
          ambientAudioId: 'suspense_ambience',
          characterVoiceNames: characterVoices,
        );

      case 'book_starlight':
        return BookOpeningConfig(
          themeId: 'night_sky',
          gradientHexColors: const ['0xFF0A182E', '0xFF030814'],
          typographyId: 'soft',
          accentColorHex: '0xFF60A5FA',
          atmosphereEffectId: 'starfield',
          animationType: 'floating_glow',
          ambientAudioId: 'calm_ambience',
          characterVoiceNames: characterVoices,
        );

      case 'sample_alice':
      case 'book_littleprince':
        return BookOpeningConfig(
          themeId: 'magical_realm',
          gradientHexColors: const ['0xFF221124', '0xFF0F0512'],
          typographyId: 'fantasy',
          accentColorHex: '0xFFEC4899',
          atmosphereEffectId: 'magical_sparkles',
          animationType: 'book_unfold',
          ambientAudioId: 'enchanted_forest',
          characterVoiceNames: characterVoices,
        );

      case 'book_timemachine':
        return BookOpeningConfig(
          themeId: 'cosmic_scifi',
          gradientHexColors: const ['0xFF0B192C', '0xFF040C17'],
          typographyId: 'modern',
          accentColorHex: '0xFF06B6D4',
          atmosphereEffectId: 'cosmic_pulse',
          animationType: 'perspective_tilt',
          ambientAudioId: 'deep_space',
          characterVoiceNames: characterVoices,
        );

      case 'book_artofwar':
      case 'book_history_kerala':
        return BookOpeningConfig(
          themeId: 'parchment',
          gradientHexColors: const ['0xFF2B2217', '0xFF161009'],
          typographyId: 'classical',
          accentColorHex: '0xFFD4A373',
          atmosphereEffectId: 'ink_dust',
          animationType: 'perspective_tilt',
          ambientAudioId: 'historical_ambience',
          characterVoiceNames: characterVoices,
        );

      default:
        return null;
    }
  }
}
