import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/explore/domain/entities/category.dart';
import 'package:epub_audio/features/explore/domain/entities/category_experience_config.dart';
import 'package:epub_audio/features/explore/domain/entities/explore_section.dart';
import 'package:epub_audio/features/explore/domain/repositories/explore_repository.dart';
import 'package:epub_audio/features/explore/presentation/screens/category_experience_screen.dart';
import 'package:epub_audio/features/explore/presentation/widgets/category_card.dart';
import 'package:epub_audio/features/explore/presentation/widgets/continue_listening_card.dart';
import 'package:epub_audio/features/explore/presentation/widgets/continue_reading_card.dart';
import 'package:epub_audio/features/explore/presentation/widgets/grand_bookshelf_wall_widget.dart';
import 'package:epub_audio/features/explore/presentation/widgets/shelf_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available view modes for the Explore screen.
enum ExploreViewMode {
  /// Immersive animated Grand Bookshelf Wall exploration (Full-wall multi-tier authentic library).
  discoveryStage,

  /// Preserved Classic Editorial Catalog Feed with customizable dynamic shelves.
  catalogFeed,
}

/// Main Explore discovery screen with dual view modes:
/// 1. 3D Discovery Stage (Animated Spotlight carousel, tabletop bookcase with Spine & Face views, category portals).
/// 2. Classic Catalog Feed (Preserved editorial shelves, mood categories, continuation cards).
class ExploreScreen extends StatefulWidget {
  final ExploreRepository repository;
  final Function(Book book)? onBookSelected;
  final Function(Book book)? onReadBook;
  final Function(Book book)? onListenBook;
  final VoidCallback? onProfileTap;
  final ExploreViewMode initialViewMode;

  const ExploreScreen({
    super.key,
    required this.repository,
    this.onBookSelected,
    this.onReadBook,
    this.onListenBook,
    this.onProfileTap,
    this.initialViewMode = ExploreViewMode.discoveryStage,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  static const String _prefViewModeKey = 'explore_view_mode_pref';

  List<ExploreSection> _sections = [];
  Map<String, List<Book>> _sectionBooks = {};
  List<Category> _categories = [];
  Map<String, CategoryExperienceConfig> _categoryConfigs = {};
  bool _isLoading = true;
  late ExploreViewMode _currentViewMode;

  @override
  void initState() {
    super.initState();
    _currentViewMode = widget.initialViewMode;
    _loadViewModePref();
    _loadExploreData();
  }

  Future<void> _loadViewModePref() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt(_prefViewModeKey);
      if (modeIndex != null &&
          modeIndex >= 0 &&
          modeIndex < ExploreViewMode.values.length) {
        if (mounted) {
          setState(() {
            _currentViewMode = ExploreViewMode.values[modeIndex];
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleViewMode(ExploreViewMode mode) async {
    if (_currentViewMode == mode) return;
    HapticFeedback.selectionClick();
    setState(() => _currentViewMode = mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefViewModeKey, mode.index);
    } catch (_) {}
  }

  Future<void> _loadExploreData() async {
    final sections = await widget.repository.getExploreSections();
    final categories = await widget.repository.getCategories();

    final Map<String, List<Book>> sectionBooksMap = {};
    for (final section in sections) {
      if (section.bookIds.isNotEmpty) {
        final books = await widget.repository.getBooksByIds(section.bookIds);
        sectionBooksMap[section.id] = books;
      }
    }

    final Map<String, CategoryExperienceConfig> configMap = {};
    for (final cat in categories) {
      final config =
          await widget.repository.getCategoryExperienceConfig(cat.experienceId);
      configMap[cat.id] = config;
    }

    if (mounted) {
      setState(() {
        _sections = sections;
        _sectionBooks = sectionBooksMap;
        _categories = categories;
        _categoryConfigs = configMap;
        _isLoading = false;
      });
    }
  }

  void _navigateToCategory(Category category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CategoryExperienceScreen(
          category: category,
          repository: widget.repository,
          onBookSelected: widget.onBookSelected,
          onReadBook: widget.onReadBook,
          onListenBook: widget.onListenBook,
        ),
      ),
    );
  }

  List<Book> get _allBooks {
    final Map<String, Book> map = {};
    for (final books in _sectionBooks.values) {
      for (final book in books) {
        map[book.id] = book;
      }
    }
    return map.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvasBg = isDark ? const Color(0xFF14161A) : const Color(0xFFFBF7F0);
    final titleColor = isDark ? const Color(0xFFE4E0D8) : const Color(0xFF261D13);
    final subColor = isDark ? const Color(0xFF9499A5) : const Color(0xFF7A6E5F);
    const accentColor = Color(0xFFD4AF7A);

    return Scaffold(
      backgroundColor: canvasBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : _currentViewMode == ExploreViewMode.discoveryStage
              ? GrandBookshelfWallWidget(
                  key: const ValueKey('grand_bookshelf_wall'),
                  allBooks: _allBooks,
                  categories: _categories,
                  onBookSelected: (book) =>
                      widget.onBookSelected?.call(book),
                  onReadBook: widget.onReadBook,
                  onListenBook: widget.onListenBook,
                  topHeader: _buildGreetingHeader(
                    context,
                    isDark,
                    titleColor,
                    subColor,
                    accentColor,
                    isTranslucent: true,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadExploreData,
                  color: accentColor,
                  child: Column(
                    children: [
                      // 1. Top Header with Greeting & Mode Switcher
                      _buildGreetingHeader(
                        context,
                        isDark,
                        titleColor,
                        subColor,
                        accentColor,
                        isTranslucent: false,
                      ),

                      // 2. Classic Catalog Feed
                      Expanded(
                        child: _buildCatalogFeed(
                          isDark: isDark,
                          titleColor: titleColor,
                          subColor: subColor,
                          accentColor: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  // ==========================================================================
  // TOP GREETING HEADER WITH DUAL MODE SWITCHER
  // ==========================================================================

  Widget _buildGreetingHeader(
    BuildContext context,
    bool isDark,
    Color titleColor,
    Color subColor,
    Color accentColor, {
    bool isTranslucent = false,
  }) {
    final hour = DateTime.now().hour;
    String greeting = 'Good evening';
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    }

    final effectiveTitleColor = isTranslucent
        ? (isDark ? const Color(0xFFF9F5EC) : const Color(0xFF1C1917))
        : titleColor;
    final effectiveSubColor = isTranslucent
        ? (isDark ? const Color(0xFFD4AF7A) : const Color(0xFF6B5843))
        : subColor;

    return Container(
      padding: EdgeInsets.fromLTRB(
          18, isTranslucent ? 44 : 48, 18, isTranslucent ? 6 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting, Reader',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: effectiveTitleColor,
                      letterSpacing: -0.4,
                      shadows: isTranslucent
                          ? [
                              Shadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.8)
                                    : Colors.white.withValues(alpha: 0.9),
                                blurRadius: isDark ? 8 : 4,
                                offset: const Offset(0, 1.0),
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Curated books, worlds & audio experiences',
                    style: TextStyle(
                      fontSize: 12,
                      color: effectiveSubColor,
                      shadows: isTranslucent
                          ? [
                              Shadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.7)
                                    : Colors.white.withValues(alpha: 0.8),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: widget.onProfileTap,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [accentColor, accentColor.withValues(alpha: 0.6)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: Color(0xFF1B140B),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Mode Toggle Bar (Discovery Stage vs Classic Catalog)
          Container(
            decoration: BoxDecoration(
              color: isTranslucent
                  ? (isDark
                      ? Colors.black.withValues(alpha: 0.45)
                      : Colors.white.withValues(alpha: 0.80))
                  : (isDark
                      ? const Color(0xFF1B1F27)
                      : const Color(0xFFEFE6D8)),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? accentColor.withValues(alpha: 0.35)
                    : const Color(0xFFB8934C).withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            padding: const EdgeInsets.all(3),
            child: Row(
              children: [
                Expanded(
                  child: _buildModeToggleTab(
                    label: 'Grand Bookshelf',
                    icon: Icons.shelves,
                    isActive:
                        _currentViewMode == ExploreViewMode.discoveryStage,
                    accentColor: accentColor,
                    isDark: isDark,
                    onTap: () =>
                        _toggleViewMode(ExploreViewMode.discoveryStage),
                  ),
                ),
                Expanded(
                  child: _buildModeToggleTab(
                    label: 'Editorial Feed',
                    icon: Icons.view_agenda_rounded,
                    isActive: _currentViewMode == ExploreViewMode.catalogFeed,
                    accentColor: accentColor,
                    isDark: isDark,
                    onTap: () => _toggleViewMode(ExploreViewMode.catalogFeed),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggleTab({
    required String label,
    required IconData icon,
    required bool isActive,
    required Color accentColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive
                  ? const Color(0xFF1A1107)
                  : (isDark ? const Color(0xFF9E9A92) : const Color(0xFF6E6355)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                color: isActive
                    ? const Color(0xFF1A1107)
                    : (isDark ? const Color(0xFF9E9A92) : const Color(0xFF6E6355)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // PRESERVED CLASSIC CATALOG FEED MODE
  // ==========================================================================

  Widget _buildCatalogFeed({
    required bool isDark,
    required Color titleColor,
    required Color subColor,
    required Color accentColor,
  }) {
    return CustomScrollView(
      key: const ValueKey('explore_catalog_feed'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final section = _sections[index];
              return _buildSectionItem(
                section,
                isDark,
                titleColor,
                subColor,
                accentColor,
              );
            },
            childCount: _sections.length,
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildSectionItem(
    ExploreSection section,
    bool isDark,
    Color titleColor,
    Color subColor,
    Color accentColor,
  ) {
    switch (section.type) {
      case ExploreSectionType.greeting:
        return const SizedBox.shrink();

      case ExploreSectionType.categories:
        return _buildCategoriesSection(
          section,
          isDark,
          titleColor,
          subColor,
          accentColor,
        );

      case ExploreSectionType.continueReading:
        final books = _sectionBooks[section.id] ?? [];
        if (books.isEmpty) return const SizedBox.shrink();
        return _buildContinueReadingSection(
          section,
          books,
          titleColor,
          subColor,
        );

      case ExploreSectionType.continueListening:
        final books = _sectionBooks[section.id] ?? [];
        if (books.isEmpty) return const SizedBox.shrink();
        return _buildContinueListeningSection(
          section,
          books,
          titleColor,
          subColor,
        );

      case ExploreSectionType.featured:
      case ExploreSectionType.popular:
      case ExploreSectionType.newReleases:
      case ExploreSectionType.recommended:
      case ExploreSectionType.curated:
        final books = _sectionBooks[section.id] ?? [];
        return ShelfRenderer(
          displayStyle: section.displayStyle,
          books: books,
          title: section.title,
          subtitle: section.subtitle,
          actionLabel: section.actionLabel,
          onBookTap: widget.onBookSelected,
          onReadTap: widget.onReadBook,
          onListenTap: widget.onListenBook,
        );
    }
  }

  Widget _buildCategoriesSection(
    ExploreSection section,
    bool isDark,
    Color titleColor,
    Color subColor,
    Color accentColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                  letterSpacing: -0.2,
                ),
              ),
              if (section.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  section.subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: subColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final config = _categoryConfigs[cat.id];
              return Container(
                width: 175,
                margin: const EdgeInsets.only(right: 12),
                child: CategoryCard(
                  category: cat,
                  experienceConfig: config,
                  onTap: () => _navigateToCategory(cat),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContinueReadingSection(
    ExploreSection section,
    List<Book> books,
    Color titleColor,
    Color subColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                  letterSpacing: -0.2,
                ),
              ),
              if (section.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  section.subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: subColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: 106,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return ContinueReadingCard(
                book: book,
                progressPercent: 0.45 + (index * 0.15),
                currentChapter: index + 1,
                onTap: () => widget.onReadBook?.call(book) ??
                    widget.onBookSelected?.call(book),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContinueListeningSection(
    ExploreSection section,
    List<Book> books,
    Color titleColor,
    Color subColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                  letterSpacing: -0.2,
                ),
              ),
              if (section.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  section.subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: subColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: 106,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return ContinueListeningCard(
                book: book,
                progressPercent: 0.60,
                durationText: '8m left',
                onTap: () => widget.onListenBook?.call(book) ??
                    widget.onBookSelected?.call(book),
              );
            },
          ),
        ),
      ],
    );
  }
}
