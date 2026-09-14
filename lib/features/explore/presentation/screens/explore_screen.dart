import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:epub_audio/features/explore/domain/entities/category.dart';
import 'package:epub_audio/features/explore/domain/entities/category_experience_config.dart';
import 'package:epub_audio/features/explore/domain/entities/explore_section.dart';
import 'package:epub_audio/features/explore/domain/repositories/explore_repository.dart';
import 'package:epub_audio/features/explore/presentation/screens/category_experience_screen.dart';
import 'package:epub_audio/features/explore/presentation/widgets/category_card.dart';
import 'package:epub_audio/features/explore/presentation/widgets/continue_listening_card.dart';
import 'package:epub_audio/features/explore/presentation/widgets/continue_reading_card.dart';
import 'package:epub_audio/features/explore/presentation/widgets/shelf_renderer.dart';
import 'package:flutter/material.dart';

/// Main Explore discovery screen with dynamic section architecture, multiple shelf styles, and category browser.
class ExploreScreen extends StatefulWidget {
  final ExploreRepository repository;
  final Function(Book book)? onBookSelected;
  final Function(Book book)? onReadBook;
  final Function(Book book)? onListenBook;
  final VoidCallback? onProfileTap;

  const ExploreScreen({
    super.key,
    required this.repository,
    this.onBookSelected,
    this.onReadBook,
    this.onListenBook,
    this.onProfileTap,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<ExploreSection> _sections = [];
  Map<String, List<Book>> _sectionBooks = {};
  List<Category> _categories = [];
  Map<String, CategoryExperienceConfig> _categoryConfigs = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExploreData();
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
      final config = await widget.repository.getCategoryExperienceConfig(cat.experienceId);
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvasBg = isDark ? const Color(0xFF14100C) : const Color(0xFFFBF7F0);
    final titleColor = isDark ? const Color(0xFFF7F2EB) : const Color(0xFF261D13);
    final subColor = isDark ? const Color(0xFFA89F93) : const Color(0xFF7A6E5F);
    const accentColor = Color(0xFFD4A373);

    return Scaffold(
      backgroundColor: canvasBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadExploreData,
              color: accentColor,
              child: CustomScrollView(
                slivers: [
                  // 1. Top Greeting Bar
                  SliverToBoxAdapter(
                    child: _buildGreetingHeader(context, isDark, titleColor, subColor, accentColor),
                  ),

                  // 2. Dynamic Sections
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final section = _sections[index];
                        return _buildSectionItem(section, isDark, titleColor, subColor, accentColor);
                      },
                      childCount: _sections.length,
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildGreetingHeader(
    BuildContext context,
    bool isDark,
    Color titleColor,
    Color subColor,
    Color accentColor,
  ) {
    final hour = DateTime.now().hour;
    String greeting = 'Good evening';
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 50, 18, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, Reader',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: titleColor,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'What world would you like to explore today?',
                style: TextStyle(
                  fontSize: 12.5,
                  color: subColor,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: widget.onProfileTap,
            child: Container(
              width: 44,
              height: 44,
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
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
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
        return _buildCategoriesSection(section, isDark, titleColor, subColor, accentColor);

      case ExploreSectionType.continueReading:
        final books = _sectionBooks[section.id] ?? [];
        if (books.isEmpty) return const SizedBox.shrink();
        return _buildContinueReadingSection(section, books, titleColor, subColor);

      case ExploreSectionType.continueListening:
        final books = _sectionBooks[section.id] ?? [];
        if (books.isEmpty) return const SizedBox.shrink();
        return _buildContinueListeningSection(section, books, titleColor, subColor);

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
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CategoryExperienceScreen(
                          category: cat,
                          repository: widget.repository,
                          onBookSelected: widget.onBookSelected,
                          onReadBook: widget.onReadBook,
                          onListenBook: widget.onListenBook,
                        ),
                      ),
                    );
                  },
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
                onTap: () => widget.onReadBook?.call(book) ?? widget.onBookSelected?.call(book),
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
                onTap: () => widget.onListenBook?.call(book) ?? widget.onBookSelected?.call(book),
              );
            },
          ),
        ),
      ],
    );
  }
}
