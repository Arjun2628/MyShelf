import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../epub/domain/entities/book.dart';

/// A luxury Multi-Row Circular Arc 3D Shelf widget.
///
/// Features:
/// - Multiple independent horizontally scrollable rows (e.g. Malayalam Classics, World Masterpieces, Imports).
/// - Cylindrical / circular 3D arc perspective transformation: books naturally curve along the circular shelf contour.
/// - Dynamic 3D lighting, edge curvature, depth shadows, and realistic wooden arc shelf base under each row.
/// - Quick Read / Listen action chips on each book card.
class CircularArcShelfWidget extends StatefulWidget {
  final List<CircularShelfRowData> rows;
  final bool isDark;
  final Color goldAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final ValueChanged<Book> onBookTap;
  final ValueChanged<Book> onReadPressed;
  final ValueChanged<Book> onListenPressed;

  const CircularArcShelfWidget({
    super.key,
    required this.rows,
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
  State<CircularArcShelfWidget> createState() => _CircularArcShelfWidgetState();
}

class _CircularArcShelfWidgetState extends State<CircularArcShelfWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.goldAccent.withValues(alpha: 0.28),
                      widget.goldAccent.withValues(alpha: 0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.goldAccent.withValues(alpha: 0.4),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.goldAccent.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.album_rounded,
                  size: 17,
                  color: widget.goldAccent,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Circular Library Arc',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 16.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                      color: widget.textPrimary,
                    ),
                  ),
                  Text(
                    'Curved 3D Rotational Shelves • Scroll each tier',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: widget.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Multi-tier independent circular rows
        ...widget.rows.asMap().entries.map((entry) {
          final index = entry.key;
          final rowData = entry.value;
          return _buildCircularRow(rowData, index);
        }),
      ],
    );
  }

  Widget _buildCircularRow(CircularShelfRowData rowData, int rowIndex) {
    if (rowData.books.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row title & badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 3.5,
                  height: 14,
                  decoration: BoxDecoration(
                    color: rowData.accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  rowData.title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'serif',
                    color: widget.textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: rowData.accentColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${rowData.books.length}',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: rowData.accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Scrollable Circular Arc Tier
          _CircularRowViewport(
            books: rowData.books,
            accentColor: rowData.accentColor,
            isDark: widget.isDark,
            goldAccent: widget.goldAccent,
            textPrimary: widget.textPrimary,
            textSecondary: widget.textSecondary,
            cardBg: widget.cardBg,
            onBookTap: widget.onBookTap,
            onReadPressed: widget.onReadPressed,
            onListenPressed: widget.onListenPressed,
          ),
        ],
      ),
    );
  }
}

/// Model representing each independent circular shelf tier
class CircularShelfRowData {
  final String title;
  final List<Book> books;
  final Color accentColor;

  const CircularShelfRowData({
    required this.title,
    required this.books,
    required this.accentColor,
  });
}

/// The stateful viewport for each independently scrollable circular arc row
class _CircularRowViewport extends StatefulWidget {
  final List<Book> books;
  final Color accentColor;
  final bool isDark;
  final Color goldAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final ValueChanged<Book> onBookTap;
  final ValueChanged<Book> onReadPressed;
  final ValueChanged<Book> onListenPressed;

  const _CircularRowViewport({
    required this.books,
    required this.accentColor,
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
  State<_CircularRowViewport> createState() => _CircularRowViewportState();
}

class _CircularRowViewportState extends State<_CircularRowViewport> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const cardWidth = 148.0;
    const cardHeight = 220.0;
    const shelfHeight = 236.0;

    return SizedBox(
      height: shelfHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Curved 3D Wooden Shelf Plank Background
          Positioned(
            left: 0,
            right: 0,
            bottom: 4,
            child: Container(
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: widget.isDark
                      ? [
                          const Color(0xFF2E2419),
                          const Color(0xFF1F170E),
                          const Color(0xFF140E08),
                        ]
                      : [
                          const Color(0xFFE2D4BF),
                          const Color(0xFFC7B399),
                          const Color(0xFF9E8A70),
                        ],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: widget.isDark ? 0.65 : 0.2,
                    ),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: widget.goldAccent.withValues(
                      alpha: widget.isDark ? 0.35 : 0.5,
                    ),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),

          // 2. Horizontally scrollable curved book list
          AnimatedBuilder(
            animation: _scrollController,
            builder: (context, child) {
              return ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.books.length,
                itemBuilder: (context, index) {
                  final book = widget.books[index];
                  return _buildCircularArcItem(
                    book: book,
                    index: index,
                    cardWidth: cardWidth,
                    cardHeight: cardHeight,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCircularArcItem({
    required Book book,
    required int index,
    required double cardWidth,
    required double cardHeight,
  }) {
    // Calculate curvature angle based on scroll offset
    double relativeOffset = 0.0;
    if (_scrollController.hasClients && _scrollController.position.haveDimensions) {
      final itemPosition = index * (cardWidth + 14);
      final viewportCenter = _scrollController.offset + (_scrollController.position.viewportDimension / 2) - (cardWidth / 2);
      relativeOffset = ((itemPosition - viewportCenter) / 320.0).clamp(-1.2, 1.2);
    }

    final rotationY = relativeOffset * 0.28; // 3D cylindrical rotation
    final scale = (1.0 - (relativeOffset.abs() * 0.08)).clamp(0.90, 1.0);
    final shadowOffset = relativeOffset * 10.0;

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.only(right: 14),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0016)
          ..rotateY(rotationY)
          ..scaleByDouble(scale, scale, 1.0, 1.0),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onBookTap(book);
          },
          child: Container(
            height: cardHeight,
            decoration: BoxDecoration(
              color: widget.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: widget.isDark
                    ? const Color(0xFF382F24)
                    : const Color(0xFFDED3C2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: widget.isDark ? 0.45 : 0.14,
                  ),
                  blurRadius: 10,
                  offset: Offset(shadowOffset, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book Cover Top Area
                  Expanded(
                    flex: 12,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (book.coverImageBytes != null)
                          Image.memory(
                            book.coverImageBytes!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildCoverFallback(book),
                          )
                        else
                          _buildCoverFallback(book),

                        // Top right format badge
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: widget.goldAccent.withValues(alpha: 0.5),
                                width: 0.6,
                              ),
                            ),
                            child: Text(
                              book.isPdf
                                  ? 'PDF'
                                  : (book.isScan
                                      ? 'OCR'
                                      : (book.isText ? 'TXT' : 'EPUB')),
                              style: TextStyle(
                                color: widget.goldAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        // Subtle glossy reflection
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.15),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom metadata & quick action buttons
                  Container(
                    padding: const EdgeInsets.all(7),
                    color: widget.isDark
                        ? const Color(0xFF1A140F)
                        : const Color(0xFFF7F1E7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.metadata.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                            color: widget.textPrimary,
                          ),
                        ),
                        Text(
                          book.metadata.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            color: widget.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMiniActionButton(
                                label: 'Read',
                                icon: Icons.menu_book_rounded,
                                onTap: () => widget.onReadPressed(book),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: _buildMiniActionButton(
                                label: 'Listen',
                                icon: Icons.headphones_rounded,
                                onTap: () => widget.onListenPressed(book),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
        decoration: BoxDecoration(
          color: widget.goldAccent.withValues(
            alpha: widget.isDark ? 0.18 : 0.14,
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: widget.goldAccent.withValues(
              alpha: widget.isDark ? 0.4 : 0.35,
            ),
            width: 0.8,
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 11, color: widget.goldAccent),
                const SizedBox(width: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: widget.goldAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoverFallback(Book book) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isDark
              ? [const Color(0xFF2C2216), const Color(0xFF1A140D)]
              : [const Color(0xFFE8DCCB), const Color(0xFFD3C2AC)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.book_rounded,
                size: 28,
                color: widget.goldAccent.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 4),
              Text(
                book.metadata.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: widget.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
