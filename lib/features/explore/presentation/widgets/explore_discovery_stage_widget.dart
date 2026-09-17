import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../epub/domain/entities/book.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_experience_config.dart';
import '../../domain/entities/explore_section.dart';

/// An immersive, futuristic & luxury 3D Discovery Stage widget for the Explore screen.
///
/// Features a unique architectural design distinct from the traditional wooden library:
/// 1. Top 3D Spotlight Discovery Showcase with 5-second auto-cycle and perspective transforms.
/// 2. Interactive metadata action stage (Read, Listen, 3D Inspect).
/// 3. Thematic Category Discovery Portals with atmospheric gradients.
/// 4. **Explorer's Exhibition Gallery (Floating Glass & Brushed Gold Pedestals)**:
///    - Sleek cantilevered frosted glass decks with under-shelf ambient illumination strips.
///    - **Gallery Pedestals Mode**: Tilted 3D showcase easels with glowing rank badges (#01, #02...) and glass floor reflections.
///    - **Prism Archways Mode**: Stepped illuminated holographic book slots with gold-embossed spine edges.
///    - Geometric champagne-gold brackets, glass reflection sheens, and glowing crystal classification pillars.
/// 5. Dynamic Category Filter Chips.
class ExploreDiscoveryStageWidget extends StatefulWidget {
  final List<ExploreSection> sections;
  final Map<String, List<Book>> sectionBooks;
  final List<Category> categories;
  final Map<String, CategoryExperienceConfig> categoryConfigs;
  final bool isDark;
  final Color goldAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final ValueChanged<Book>? onBookSelected;
  final ValueChanged<Book>? onReadBook;
  final ValueChanged<Book>? onListenBook;
  final ValueChanged<Category>? onCategorySelected;
  final ValueChanged<Book>? onInspect3DBook;

  const ExploreDiscoveryStageWidget({
    super.key,
    required this.sections,
    required this.sectionBooks,
    required this.categories,
    required this.categoryConfigs,
    required this.isDark,
    required this.goldAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    this.onBookSelected,
    this.onReadBook,
    this.onListenBook,
    this.onCategorySelected,
    this.onInspect3DBook,
  });

  @override
  State<ExploreDiscoveryStageWidget> createState() =>
      _ExploreDiscoveryStageWidgetState();
}

class _ExploreDiscoveryStageWidgetState
    extends State<ExploreDiscoveryStageWidget> {
  late PageController _spotlightController;
  int _spotlightIndex = 0;
  Timer? _autoSwitchTimer;
  bool _isPedestalView = true; // Pedestals vs Prism Archways
  String? _selectedCategoryFilter;

  @override
  void initState() {
    super.initState();
    _spotlightController = PageController(
      initialPage: 0,
      viewportFraction: 0.58,
    );
    _startAutoSwitchTimer();
  }

  void _startAutoSwitchTimer() {
    _autoSwitchTimer?.cancel();
    _autoSwitchTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_spotlightController.hasClients) return;
      final spotlightBooks = _getSpotlightBooks();
      if (spotlightBooks.length <= 1) return;
      final nextPage = (_spotlightIndex + 1) % spotlightBooks.length;
      _spotlightController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoSwitchTimer?.cancel();
    _spotlightController.dispose();
    super.dispose();
  }

  List<Book> _getSpotlightBooks() {
    final List<Book> books = [];
    for (final section in widget.sections) {
      final sBooks = widget.sectionBooks[section.id] ?? [];
      for (final b in sBooks) {
        if (!books.any((existing) => existing.id == b.id)) {
          books.add(b);
        }
      }
    }
    return books;
  }

  List<ExploreShelfRowData> _buildDiscoveryShelfRows() {
    final List<ExploreShelfRowData> rows = [];

    for (final section in widget.sections) {
      if (section.type == ExploreSectionType.greeting ||
          section.type == ExploreSectionType.categories) {
        continue;
      }
      var books = widget.sectionBooks[section.id] ?? [];
      if (_selectedCategoryFilter != null) {
        final filterLower = _selectedCategoryFilter!.toLowerCase();
        books = books.where((b) {
          final title = b.metadata.title.toLowerCase();
          final author = b.metadata.author.toLowerCase();
          final desc = (b.metadata.description ?? '').toLowerCase();
          return title.contains(filterLower) ||
              author.contains(filterLower) ||
              desc.contains(filterLower);
        }).toList();
      }

      if (books.isNotEmpty) {
        rows.add(
          ExploreShelfRowData(
            id: section.id,
            title: section.title,
            subtitle: section.subtitle ?? 'Exhibition gallery collection',
            books: books,
            accentColor: widget.goldAccent,
          ),
        );
      }
    }

    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final spotlightBooks = _getSpotlightBooks();
    final shelfRows = _buildDiscoveryShelfRows();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),

          // 1. Top 3D Spotlight Discovery Showcase
          if (spotlightBooks.isNotEmpty) ...[
            _buildSpotlightHeader(),
            _buildSpotlightCarousel(spotlightBooks),
            _buildSpotlightActiveBookMeta(spotlightBooks),
            const SizedBox(height: 20),
          ],

          // 2. Thematic Category Discovery Portals
          if (widget.categories.isNotEmpty) ...[
            _buildCategoryPortalsSection(),
            const SizedBox(height: 22),
          ],

          // 3. Category Filter Chips for Exhibition Stands
          _buildFilterChipsRow(),
          const SizedBox(height: 14),

          // 4. Explorer's Floating Glass & Gold Gallery Vitrine
          if (shelfRows.isNotEmpty)
            _buildGalleryExhibitionVitrine(shelfRows)
          else
            _buildEmptyState(),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  // ==========================================================================
  // 1. 3D SPOTLIGHT CAROUSEL
  // ==========================================================================

  Widget _buildSpotlightHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 18,
                decoration: BoxDecoration(
                  color: widget.goldAccent,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: widget.goldAccent.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'DISCOVERY SPOTLIGHT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: widget.goldAccent,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: widget.goldAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.goldAccent.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 12, color: widget.goldAccent),
                const SizedBox(width: 4),
                Text(
                  '3D Stage',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.goldAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotlightCarousel(List<Book> books) {
    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient floor reflection & radial shadow
          Positioned(
            bottom: 4,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                width: 170,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(85),
                  gradient: RadialGradient(
                    colors: [
                      Colors.black.withValues(alpha: widget.isDark ? 0.75 : 0.28),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // PageView with 3D perspective transforms
          PageView.builder(
            controller: _spotlightController,
            itemCount: books.length,
            onPageChanged: (index) {
              setState(() => _spotlightIndex = index);
              HapticFeedback.selectionClick();
              _startAutoSwitchTimer();
            },
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _spotlightController,
                builder: (context, child) {
                  double page = index.toDouble();
                  if (_spotlightController.position.haveDimensions) {
                    page = _spotlightController.page ?? _spotlightIndex.toDouble();
                  }
                  final diff = (index - page);
                  final normalizedDiff = diff.clamp(-1.0, 1.0);
                  final scale = (1.0 - (normalizedDiff.abs() * 0.22)).clamp(0.78, 1.0);
                  final rotateY = normalizedDiff * -0.32;
                  final elevation = (1.0 - normalizedDiff.abs()).clamp(0.0, 1.0);

                  final book = books[index];

                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0018)
                      ..rotateY(rotateY)
                      ..scaleByDouble(scale, scale, 1.0, 1.0),
                    child: _buildSpotlightHardcoverBook(
                      book: book,
                      isCenter: normalizedDiff.abs() < 0.15,
                      elevation: elevation,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpotlightHardcoverBook({
    required Book book,
    required bool isCenter,
    required double elevation,
  }) {
    final hasCover = book.coverImageBytes != null && book.coverImageBytes!.isNotEmpty;
    final isMalayalam = (book.metadata.language ?? '').toLowerCase().contains('ml') ||
        book.id.contains('chemmeen');

    return Center(
      child: GestureDetector(
        onTap: () {
          widget.onBookSelected?.call(book);
        },
        child: Container(
          width: 148,
          height: 222,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(3),
              bottomLeft: Radius.circular(3),
              topRight: Radius.circular(7),
              bottomRight: Radius.circular(7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: widget.isDark ? (0.4 + 0.4 * elevation) : (0.2 + 0.25 * elevation),
                ),
                blurRadius: 16 * elevation + 6,
                offset: Offset(6 * elevation, 8 * elevation + 3),
              ),
              if (isCenter)
                BoxShadow(
                  color: widget.goldAccent.withValues(alpha: 0.22),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(3),
              bottomLeft: Radius.circular(3),
              topRight: Radius.circular(7),
              bottomRight: Radius.circular(7),
            ),
            child: Stack(
              children: [
                // Cover Artwork or Rich Thematic Gradient
                if (hasCover)
                  Positioned.fill(
                    child: Image.memory(
                      book.coverImageBytes!,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Positioned.fill(
                    child: _buildFallbackBookCover(book, isMalayalam),
                  ),

                // Spine Crease Shadow overlay (Left edge)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 14,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.black.withValues(alpha: 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Right Hardcover Edge Highlight
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Audio Availability Ribbon Badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: widget.goldAccent.withValues(alpha: 0.7),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.graphic_eq_rounded, size: 10, color: Color(0xFFD4AF7A)),
                        SizedBox(width: 3),
                        Text(
                          'AUDIO',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: Color(0xFFD4AF7A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackBookCover(Book book, bool isMalayalam) {
    final title = book.metadata.title;
    final author = book.metadata.author;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isMalayalam
              ? [const Color(0xFF1E3A2F), const Color(0xFF0F1E18), const Color(0xFF070E0B)]
              : [const Color(0xFF2C1E38), const Color(0xFF180F21), const Color(0xFF0A050E)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(14, 18, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.menu_book_rounded, size: 16, color: widget.goldAccent.withValues(alpha: 0.8)),
              Text(
                'COLLECTION',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: widget.goldAccent.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFF0EBE1),
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: widget.goldAccent.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
          Container(
            height: 1.5,
            width: 32,
            color: widget.goldAccent.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotlightActiveBookMeta(List<Book> books) {
    if (_spotlightIndex >= books.length) return const SizedBox.shrink();
    final activeBook = books[_spotlightIndex];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.goldAccent.withValues(alpha: 0.25),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.4 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeBook.metadata.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: widget.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'by ${activeBook.metadata.author}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: widget.goldAccent,
                      ),
                    ),
                  ],
                ),
              ),
              // Chapters Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.goldAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD4AF7A)),
                    const SizedBox(width: 3),
                    Text(
                      '${activeBook.chapterCount} Ch',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: widget.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (activeBook.metadata.description != null &&
              activeBook.metadata.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              activeBook.metadata.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: widget.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Action Buttons: Read, Listen, and 3D Inspect
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (widget.onReadBook != null) {
                      widget.onReadBook!(activeBook);
                    } else {
                      widget.onBookSelected?.call(activeBook);
                    }
                  },
                  icon: const Icon(Icons.auto_stories_rounded, size: 15),
                  label: const Text('Read Book', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.goldAccent,
                    foregroundColor: const Color(0xFF1C130A),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (widget.onListenBook != null) {
                      widget.onListenBook!(activeBook);
                    } else {
                      widget.onBookSelected?.call(activeBook);
                    }
                  },
                  icon: const Icon(Icons.headphones_rounded, size: 15),
                  label: const Text('Listen Audio', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.goldAccent,
                    side: BorderSide(color: widget.goldAccent.withValues(alpha: 0.6), width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Inspect 3D Cover',
                onPressed: () {
                  if (widget.onInspect3DBook != null) {
                    widget.onInspect3DBook!(activeBook);
                  } else {
                    widget.onBookSelected?.call(activeBook);
                  }
                },
                icon: const Icon(Icons.view_in_ar_rounded, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: widget.goldAccent.withValues(alpha: 0.15),
                  foregroundColor: widget.goldAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // 2. THEMATIC CATEGORY DISCOVERY PORTALS
  // ==========================================================================

  Widget _buildCategoryPortalsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DISCOVERY PORTALS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                  color: widget.goldAccent,
                ),
              ),
              Text(
                '${widget.categories.length} Worlds',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: widget.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: widget.categories.length,
            itemBuilder: (context, index) {
              final cat = widget.categories[index];
              final config = widget.categoryConfigs[cat.id];
              return _buildCategoryPortalCard(cat, config);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPortalCard(Category category, CategoryExperienceConfig? config) {
    final ambientColor = _parseColor(config?.accentColorHex, widget.goldAccent);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onCategorySelected?.call(category);
      },
      child: Container(
        width: 154,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: widget.isDark
                ? [
                    ambientColor.withValues(alpha: 0.28),
                    const Color(0xFF181B22),
                    const Color(0xFF0F1117),
                  ]
                : [
                    ambientColor.withValues(alpha: 0.20),
                    const Color(0xFFFFFDF8),
                    const Color(0xFFF5EFEB),
                  ],
          ),
          border: Border.all(
            color: ambientColor.withValues(alpha: 0.45),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: ambientColor.withValues(alpha: widget.isDark ? 0.18 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ambientColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _resolveCategoryIcon(category.iconName),
                    size: 16,
                    color: ambientColor,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: ambientColor.withValues(alpha: 0.8),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: widget.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category.tagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    color: widget.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String? hexString, Color fallback) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      final cleanHex = hexString.replaceAll('#', '').replaceAll('0x', '');
      return Color(int.parse('FF$cleanHex', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  IconData _resolveCategoryIcon(String iconName) {
    switch (iconName) {
      case 'temple_buddhist_rounded':
      case 'history_edu_rounded':
        return Icons.auto_stories_rounded;
      case 'rocket_launch_rounded':
        return Icons.rocket_launch_rounded;
      case 'psychology_rounded':
        return Icons.psychology_rounded;
      case 'theater_comedy_rounded':
        return Icons.theater_comedy_rounded;
      case 'castle_rounded':
        return Icons.fort_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  // ==========================================================================
  // 3. CATEGORY FILTER CHIPS
  // ==========================================================================

  Widget _buildFilterChipsRow() {
    final filterOptions = ['All Books', ...widget.categories.map((c) => c.name)];

    return SizedBox(
      height: 34,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: filterOptions.length,
        itemBuilder: (context, index) {
          final label = filterOptions[index];
          final isSelected = (index == 0 && _selectedCategoryFilter == null) ||
              (_selectedCategoryFilter == label);

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedCategoryFilter = index == 0 ? null : label;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? widget.goldAccent
                    : widget.cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? widget.goldAccent
                      : widget.goldAccent.withValues(alpha: 0.25),
                  width: 0.9,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: widget.goldAccent.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF1B1209)
                        : widget.textPrimary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================================================
  // 4. EXPLORER'S EXHIBITION VITRINE (FLOATING GLASS & BRUSHED GOLD PEDESTALS)
  // ==========================================================================

  Widget _buildGalleryExhibitionVitrine(List<ExploreShelfRowData> rows) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Exhibition Pavilion Canopy with Holographic Prism & View Mode Switcher
          _ExhibitionPavilionCanopy(
            isDark: widget.isDark,
            goldAccent: widget.goldAccent,
            textPrimary: widget.textPrimary,
            textSecondary: widget.textSecondary,
            cardBg: widget.cardBg,
            isPedestalView: _isPedestalView,
            onViewModeChanged: (val) {
              HapticFeedback.selectionClick();
              setState(() => _isPedestalView = val);
            },
          ),

          // Main Glass Vitrine Unit (Cantilevered Glass Platforms with LED under-glow)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: widget.isDark
                    ? const [
                        Color(0xFF161A22),
                        Color(0xFF0F1218),
                        Color(0xFF0A0C10),
                      ]
                    : const [
                        Color(0xFFF3ECE1),
                        Color(0xFFE9DFCF),
                        Color(0xFFDFD4C2),
                      ],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              border: Border.all(
                color: widget.goldAccent.withValues(alpha: widget.isDark ? 0.35 : 0.25),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.goldAccent.withValues(
                    alpha: widget.isDark ? 0.12 : 0.05,
                  ),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: Stack(
                children: [
                  // Exhibition Terraces
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: rows.asMap().entries.map((entry) {
                      final index = entry.key;
                      final rowData = entry.value;
                      return _ExhibitionTerracePlatform(
                        key: ValueKey('gallery_terrace_${rowData.id}_${_isPedestalView ? "pedestal" : "prism"}_$index'),
                        rowData: rowData,
                        terraceIndex: index,
                        totalTerraces: rows.length,
                        isPedestalView: _isPedestalView,
                        isDark: widget.isDark,
                        goldAccent: widget.goldAccent,
                        textPrimary: widget.textPrimary,
                        textSecondary: widget.textSecondary,
                        cardBg: widget.cardBg,
                        onBookTap: (book) => widget.onBookSelected?.call(book),
                        onReadPressed: (book) => widget.onReadBook?.call(book),
                        onListenPressed: (book) => widget.onListenBook?.call(book),
                      );
                    }).toList(),
                  ),

                  // Left Brushed Brass Pillar with LED accent
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: 5,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              widget.goldAccent,
                              widget.goldAccent.withValues(alpha: 0.4),
                              widget.goldAccent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Right Brushed Brass Pillar with LED accent
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: 5,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              widget.goldAccent,
                              widget.goldAccent.withValues(alpha: 0.4),
                              widget.goldAccent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.goldAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_outlined, size: 36, color: widget.goldAccent),
          const SizedBox(height: 10),
          Text(
            'No books match the selected category',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: widget.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try selecting "All Books" to view the full exhibition gallery.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: widget.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DATA MODEL FOR EXPLORE SHELF ROWS
// ============================================================================

class ExploreShelfRowData {
  final String id;
  final String title;
  final String subtitle;
  final List<Book> books;
  final Color accentColor;

  const ExploreShelfRowData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.books,
    required this.accentColor,
  });
}

// ============================================================================
// EXHIBITION PAVILION CANOPY (ARCHITECTURAL GLASS & BRASS TOP)
// ============================================================================

class _ExhibitionPavilionCanopy extends StatelessWidget {
  final bool isDark;
  final Color goldAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final bool isPedestalView;
  final ValueChanged<bool> onViewModeChanged;

  const _ExhibitionPavilionCanopy({
    required this.isDark,
    required this.goldAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.isPedestalView,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF242A35),
                  const Color(0xFF1B202A),
                  const Color(0xFF12161E),
                ]
              : [
                  const Color(0xFFFAF3E8),
                  const Color(0xFFEFE4D2),
                  const Color(0xFFE4D3BD),
                ],
        ),
        border: Border.all(
          color: goldAccent.withValues(alpha: 0.5),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Celestial Armillary Prism Icon & Title
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [goldAccent, goldAccent.withValues(alpha: 0.5)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: goldAccent.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.diamond_rounded,
                      size: 15,
                      color: Color(0xFF17130B),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'DISCOVERY VITRINE',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                          color: isDark ? const Color(0xFFF9F5EC) : const Color(0xFF2C2216),
                        ),
                      ),
                      Text(
                        'Curated Exhibition Gallery',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: goldAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right: Exhibition View Mode Switcher (Pedestals vs Archways)
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF10141C) : const Color(0xFFD6C8B5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: goldAccent.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            padding: const EdgeInsets.all(2.5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCanopyTab(
                  label: 'Pedestals',
                  icon: Icons.dashboard_customize_rounded,
                  isActive: isPedestalView,
                  onTap: () => onViewModeChanged(true),
                ),
                _buildCanopyTab(
                  label: 'Prisms',
                  icon: Icons.auto_awesome_motion_rounded,
                  isActive: !isPedestalView,
                  onTap: () => onViewModeChanged(false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanopyTab({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
        decoration: BoxDecoration(
          color: isActive ? goldAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: goldAccent.withValues(alpha: 0.35),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 11.5,
              color: isActive
                  ? const Color(0xFF191107)
                  : (isDark ? const Color(0xFFD8D2C5) : const Color(0xFF5A4A38)),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                color: isActive
                    ? const Color(0xFF191107)
                    : (isDark ? const Color(0xFFD8D2C5) : const Color(0xFF5A4A38)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EXHIBITION TERRACE PLATFORM (PEDESTALS VS PRISM ARCHWAYS)
// ============================================================================

class _ExhibitionTerracePlatform extends StatelessWidget {
  final ExploreShelfRowData rowData;
  final int terraceIndex;
  final int totalTerraces;
  final bool isPedestalView;
  final bool isDark;
  final Color goldAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final ValueChanged<Book> onBookTap;
  final ValueChanged<Book> onReadPressed;
  final ValueChanged<Book> onListenPressed;

  const _ExhibitionTerracePlatform({
    super.key,
    required this.rowData,
    required this.terraceIndex,
    required this.totalTerraces,
    required this.isPedestalView,
    required this.isDark,
    required this.goldAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.onBookTap,
    required this.onReadPressed,
    required this.onListenPressed,
  });

  @override
  Widget build(BuildContext context) {
    final books = rowData.books;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF12161E).withValues(alpha: 0.7)
            : const Color(0xFFF7F1E6).withValues(alpha: 0.7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Terrace Header Strip with Neon/Gold Tag
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [goldAccent, goldAccent.withValues(alpha: 0.6)],
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '0${terraceIndex + 1}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF18120A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rowData.title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.1,
                            color: isDark ? const Color(0xFFF5EFE3) : const Color(0xFF261D13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  rowData.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: goldAccent,
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Showcase Items (Pedestals or Prism Archways)
          SizedBox(
            height: isPedestalView ? 215 : 175,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              itemCount: books.length,
              itemBuilder: (context, bookIndex) {
                final book = books[bookIndex];
                final showDivider = bookIndex > 0 && bookIndex % 4 == 0;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (showDivider) _buildCrystalPillarDivider(),
                    if (isPedestalView)
                      _buildTiltedGalleryPedestal(book, bookIndex)
                    else
                      _buildPrismArchwaySlot(book, bookIndex),
                  ],
                );
              },
            ),
          ),

          // Cantilevered Illuminated Glass Deck Base with LED Glow
          _buildCantileveredGlassDeck(),
        ],
      ),
    );
  }

  Widget _buildCrystalPillarDivider() {
    return Container(
      width: 20,
      height: isPedestalView ? 190 : 155,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Center(
        child: Container(
          width: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                goldAccent.withValues(alpha: 0.9),
                goldAccent.withValues(alpha: 0.2),
                goldAccent.withValues(alpha: 0.9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: goldAccent.withValues(alpha: 0.4),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.blur_on_rounded,
              size: 10,
              color: Color(0xFF1B140B),
            ),
          ),
        ),
      ),
    );
  }

  // 1. TILTED 3D GALLERY PEDESTAL WITH RANK BADGE & ACRYLIC STAND
  Widget _buildTiltedGalleryPedestal(Book book, int index) {
    final hasCover = book.coverImageBytes != null && book.coverImageBytes!.isNotEmpty;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onBookTap(book);
      },
      child: Container(
        width: 132,
        margin: const EdgeInsets.only(right: 14),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Acrylic Glass Pedestal Floor Base
            Positioned(
              bottom: 0,
              left: 6,
              right: 6,
              height: 14,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            goldAccent.withValues(alpha: 0.35),
                            Colors.black.withValues(alpha: 0.8),
                          ]
                        : [
                            goldAccent.withValues(alpha: 0.45),
                            const Color(0xFFD6C8B5),
                          ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: goldAccent.withValues(alpha: 0.2),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),

            // Standing Hardcover Book with 3D Easel Tilt
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              width: 124,
              height: 185,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.65 : 0.25),
                    blurRadius: 12,
                    offset: const Offset(4, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    // Book Cover or Gradient
                    if (hasCover)
                      Positioned.fill(
                        child: Image.memory(
                          book.coverImageBytes!,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: isDark
                                  ? [const Color(0xFF2C241B), const Color(0xFF14100C)]
                                  : [const Color(0xFFFAF0E1), const Color(0xFFE4D3BC)],
                            ),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(Icons.auto_stories, size: 16, color: goldAccent),
                              Text(
                                book.metadata.title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                book.metadata.author,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: goldAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Top Left Rank Number Badge (#01, #02...)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: goldAccent.withValues(alpha: 0.8),
                            width: 0.7,
                          ),
                        ),
                        child: Text(
                          '#${(index + 1).toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: goldAccent,
                          ),
                        ),
                      ),
                    ),

                    // Spine Left Depth Shadow
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. PRISM ARCHWAY SLOTS WITH HOLOGRAPHIC ENGRAVING
  Widget _buildPrismArchwaySlot(Book book, int index) {
    final prismPalettes = isDark
        ? const [
            [Color(0xFF283446), Color(0xFF141C28)],
            [Color(0xFF382C3D), Color(0xFF1F1624)],
            [Color(0xFF1E3A36), Color(0xFF0F211F)],
            [Color(0xFF3D3220), Color(0xFF241C0F)],
          ]
        : const [
            [Color(0xFF5A7294), Color(0xFF3D5270)],
            [Color(0xFF886394), Color(0xFF62416E)],
            [Color(0xFF4A887E), Color(0xFF2E635A)],
            [Color(0xFF88724A), Color(0xFF63502E)],
          ];

    final colors = prismPalettes[index % prismPalettes.length];
    final slotHeight = 145.0 + (index % 3) * 8.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onBookTap(book);
      },
      child: Container(
        width: 42,
        height: slotHeight,
        margin: const EdgeInsets.only(right: 7),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: colors,
          ),
          border: Border.all(
            color: goldAccent.withValues(alpha: 0.4),
            width: 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(1, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Glowing Beacon Dot
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: goldAccent,
                boxShadow: [
                  BoxShadow(
                    color: goldAccent.withValues(alpha: 0.8),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),

            // Vertical Title
            Expanded(
              child: Center(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    book.metadata.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Color(0xFFF9F6EE),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Audio / Chapter icon
            Icon(Icons.graphic_eq_rounded, size: 12, color: goldAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildCantileveredGlassDeck() {
    return Container(
      height: 14,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  goldAccent.withValues(alpha: 0.6),
                  const Color(0xFF1B222E),
                  const Color(0xFF0F141C),
                ]
              : [
                  goldAccent.withValues(alpha: 0.8),
                  const Color(0xFFE4D5BF),
                  const Color(0xFFD4C2A7),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: goldAccent.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Container(
          height: 1.5,
          margin: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white.withValues(alpha: isDark ? 0.6 : 0.9),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
