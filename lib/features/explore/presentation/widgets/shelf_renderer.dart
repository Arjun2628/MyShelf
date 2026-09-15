import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/explore/domain/entities/book_shelf.dart';
import 'package:epub_audio/features/explore/presentation/widgets/hero_book_card.dart';
import 'package:epub_audio/features/explore/presentation/widgets/story_card.dart';
import 'package:flutter/material.dart';

/// Unified dynamic renderer that displays a list of books according to the specified [ShelfDisplayStyle].
class ShelfRenderer extends StatelessWidget {
  final ShelfDisplayStyle displayStyle;
  final List<Book> books;
  final String? title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;
  final Function(Book book)? onBookTap;
  final Function(Book book)? onReadTap;
  final Function(Book book)? onListenTap;

  const ShelfRenderer({
    super.key,
    required this.displayStyle,
    required this.books,
    this.title,
    this.subtitle,
    this.actionLabel,
    this.onActionTap,
    this.onBookTap,
    this.onReadTap,
    this.onListenTap,
  });

  @override
  Widget build(BuildContext context) {
    if (books.isEmpty && displayStyle != ShelfDisplayStyle.largeFeatured) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFF6EFE6) : const Color(0xFF261D13);
    final subColor = isDark ? const Color(0xFFA89F91) : const Color(0xFF7A6E5F);
    const accentColor = Color(0xFFD4A373);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header (if title is provided)
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: titleColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: subColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (actionLabel != null || onActionTap != null)
                  GestureDetector(
                    onTap: onActionTap,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Row(
                        children: [
                          Text(
                            actionLabel ?? 'See all',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 11, color: accentColor),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // Specific style rendering
        _renderStyleContent(context, isDark, accentColor, titleColor, subColor),
      ],
    );
  }

  Widget _renderStyleContent(
    BuildContext context,
    bool isDark,
    Color accent,
    Color titleColor,
    Color subColor,
  ) {
    switch (displayStyle) {
      case ShelfDisplayStyle.largeFeatured:
        return _buildLargeFeatured(context);
      case ShelfDisplayStyle.horizontalCarousel:
        return _buildHorizontalCarousel(context, isDark, accent, titleColor, subColor);
      case ShelfDisplayStyle.horizontalShelf:
        return _buildHorizontalShelf(context, isDark, accent, titleColor, subColor);
      case ShelfDisplayStyle.grid:
        return _buildGrid(context, isDark, accent, titleColor, subColor);
      case ShelfDisplayStyle.verticalList:
        return _buildVerticalList(context, isDark, accent, titleColor, subColor);
      case ShelfDisplayStyle.coverCarousel:
        return _buildCoverCarousel(context, isDark, accent);
      case ShelfDisplayStyle.storyCards:
        return _buildStoryCards(context);
    }
  }

  // 1. Large Featured Hero Cards
  Widget _buildLargeFeatured(BuildContext context) {
    if (books.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 235,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.92),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return HeroBookCard(
            book: book,
            onTap: () => onBookTap?.call(book),
            onReadTap: () => onReadTap?.call(book),
            onListenTap: () => onListenTap?.call(book),
          );
        },
      ),
    );
  }

  // 2. Horizontal Carousel (Standard Book Cards)
  Widget _buildHorizontalCarousel(
    BuildContext context,
    bool isDark,
    Color accent,
    Color titleColor,
    Color subColor,
  ) {
    return SizedBox(
      height: 215,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return _buildStandardBookItem(book, isDark, accent, titleColor, subColor);
        },
      ),
    );
  }

  // 3. Horizontal Bookshelf (Simulated Wooden Shelf Plinth)
  Widget _buildHorizontalShelf(
    BuildContext context,
    bool isDark,
    Color accent,
    Color titleColor,
    Color subColor,
  ) {
    final shelfPlinthColor = isDark ? const Color(0xFF2C2218) : const Color(0xFFD6C5B2);
    final shelfShadowColor = isDark ? const Color(0xFF140E0A) : const Color(0xFFB5A18C);

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 12),
      child: Stack(
        children: [
          // Shelf Wood Plinth Bar at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 4,
            child: Column(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: shelfPlinthColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 6,
                  color: shelfShadowColor,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 190,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return GestureDetector(
                  onTap: () => onBookTap?.call(book),
                  child: Container(
                    width: 110,
                    margin: const EdgeInsets.only(right: 14, bottom: 16),
                    child: _buildBookCover3D(book, 105, 150, isDark, accent),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 4. Grid View
  Widget _buildGrid(
    BuildContext context,
    bool isDark,
    Color accent,
    Color titleColor,
    Color subColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
        ),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return _buildStandardBookItem(book, isDark, accent, titleColor, subColor, width: double.infinity);
        },
      ),
    );
  }

  // 5. Vertical List
  Widget _buildVerticalList(
    BuildContext context,
    bool isDark,
    Color accent,
    Color titleColor,
    Color subColor,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: books.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final book = books[index];
        return GestureDetector(
          onTap: () => onBookTap?.call(book),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1612) : const Color(0xFFF9F4EC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? const Color(0xFF33291F) : const Color(0xFFE4D7C7),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _buildBookCover3D(book, 55, 78, isDark, accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.metadata.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        book.metadata.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              book.metadata.language == 'ml' ? 'Malayalam' : 'Classic',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${book.chapterCount} chapters',
                            style: TextStyle(fontSize: 11, color: subColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => onBookTap?.call(book),
                  icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  color: subColor,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 6. Cover Carousel (Large 3D Covers Focused)
  Widget _buildCoverCarousel(BuildContext context, bool isDark, Color accent) {
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return GestureDetector(
            onTap: () => onBookTap?.call(book),
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: _buildBookCover3D(book, 130, 195, isDark, accent),
            ),
          );
        },
      ),
    );
  }

  // 7. Story Cards Row
  Widget _buildStoryCards(BuildContext context) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          return StoryCard(
            book: book,
            onTap: () => onBookTap?.call(book),
          );
        },
      ),
    );
  }

  // Common Standard Book Item for Carousel and Grid
  Widget _buildStandardBookItem(
    Book book,
    bool isDark,
    Color accent,
    Color titleColor,
    Color subColor, {
    double width = 115,
  }) {
    return GestureDetector(
      onTap: () => onBookTap?.call(book),
      child: Container(
        width: width,
        margin: width == double.infinity ? EdgeInsets.zero : const EdgeInsets.only(right: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookCover3D(book, width == double.infinity ? 140 : width, 155, isDark, accent),
            const SizedBox(height: 8),
            Text(
              book.metadata.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              book.metadata.author,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: subColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCover3D(Book book, double width, double height, bool isDark, Color accent) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2C2218), const Color(0xFF161009)]
              : [const Color(0xFFF0E2D2), const Color(0xFFCEB89E)],
        ),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.3 : 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
            blurRadius: 10,
            offset: const Offset(2, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Spine effect
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 7,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.white.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.2),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  book.metadata.language == 'ml' ? Icons.menu_book_rounded : Icons.auto_stories_rounded,
                  size: 18,
                  color: accent,
                ),
                Text(
                  book.metadata.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFF6EFE6) : const Color(0xFF261D13),
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
