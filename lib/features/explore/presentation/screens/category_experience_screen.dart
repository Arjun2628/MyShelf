import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/explore/domain/entities/book_shelf.dart';
import 'package:epub_audio/features/explore/domain/entities/category.dart';
import 'package:epub_audio/features/explore/domain/entities/category_experience_config.dart';
import 'package:epub_audio/features/explore/domain/repositories/explore_repository.dart';
import 'package:epub_audio/features/explore/presentation/widgets/shelf_renderer.dart';
import 'package:flutter/material.dart';

/// Screen displaying a specific category with its immersive visual theme and atmospheric backdrop.
class CategoryExperienceScreen extends StatefulWidget {
  final Category category;
  final ExploreRepository repository;
  final Function(Book book)? onBookSelected;
  final Function(Book book)? onReadBook;
  final Function(Book book)? onListenBook;

  const CategoryExperienceScreen({
    super.key,
    required this.category,
    required this.repository,
    this.onBookSelected,
    this.onReadBook,
    this.onListenBook,
  });

  @override
  State<CategoryExperienceScreen> createState() => _CategoryExperienceScreenState();
}

class _CategoryExperienceScreenState extends State<CategoryExperienceScreen> {
  CategoryExperienceConfig _experienceConfig = CategoryExperienceConfig.defaultConfig;
  List<Book> _categoryBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExperienceData();
  }

  Future<void> _loadExperienceData() async {
    final config = await widget.repository.getCategoryExperienceConfig(widget.category.experienceId);
    final books = await widget.repository.getCategoryBooks(widget.category.id);

    if (mounted) {
      setState(() {
        _experienceConfig = config;
        _categoryBooks = books;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = _parseColor(_experienceConfig.accentColorHex, const Color(0xFFD4A373));
    final gradientColors = _experienceConfig.gradientHexColors.isNotEmpty
        ? _experienceConfig.gradientHexColors
            .map((h) => _parseColor(h, isDark ? const Color(0xFF1B1510) : const Color(0xFFFAF4EC)))
            .toList()
        : [
            isDark ? const Color(0xFF1F1812) : const Color(0xFFF7EFE4),
            isDark ? const Color(0xFF0F0B07) : const Color(0xFFE8DBCF),
          ];

    final titleColor = isDark ? const Color(0xFFF8F3ED) : const Color(0xFF261D13);
    final subColor = isDark ? const Color(0xFFA89F93) : const Color(0xFF6B5E50);

    return Scaffold(
      backgroundColor: gradientColors.last,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Atmospheric App Bar Header
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: gradientColors.first,
                  foregroundColor: titleColor,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      widget.category.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                        fontSize: 16,
                      ),
                    ),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: gradientColors,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // Atmosphere background effect hint
                          Positioned(
                            right: -20,
                            bottom: -20,
                            child: Icon(
                              _resolveCategoryIcon(widget.category.iconName),
                              size: 160,
                              color: accentColor.withValues(alpha: isDark ? 0.08 : 0.12),
                            ),
                          ),
                          Positioned(
                            left: 20,
                            right: 20,
                            bottom: 50,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'EXPERIENCE • ${_experienceConfig.themeId.toUpperCase()}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: accentColor,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.category.tagline,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: subColor,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Tags bar
                if (widget.category.tags.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.category.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2B2217) : const Color(0xFFEBE0D2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              '#$tag',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                // Books Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Text(
                      'Curated Titles (${_categoryBooks.length})',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                  ),
                ),

                // Books Grid
                SliverToBoxAdapter(
                  child: ShelfRenderer(
                    displayStyle: ShelfDisplayStyle.grid,
                    books: _categoryBooks,
                    onBookTap: widget.onBookSelected,
                    onReadTap: widget.onReadBook,
                    onListenTap: widget.onListenBook,
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: 60),
                ),
              ],
            ),
    );
  }

  Color _parseColor(String hexStr, Color fallback) {
    try {
      final clean = hexStr.replaceAll('#', '').replaceAll('0x', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  IconData _resolveCategoryIcon(String iconName) {
    switch (iconName) {
      case 'history_edu_rounded':
        return Icons.history_edu_rounded;
      case 'psychology_alt_rounded':
        return Icons.psychology_alt_rounded;
      case 'menu_book_rounded':
        return Icons.menu_book_rounded;
      case 'rocket_launch_rounded':
        return Icons.rocket_launch_rounded;
      case 'bedtime_rounded':
        return Icons.bedtime_rounded;
      case 'auto_fix_high_rounded':
        return Icons.auto_fix_high_rounded;
      case 'child_care_rounded':
        return Icons.child_care_rounded;
      case 'lightbulb_rounded':
        return Icons.lightbulb_rounded;
      default:
        return Icons.auto_stories_rounded;
    }
  }
}
