import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An interactive 2-tier 3D wooden bookshelf displaying realistic book spines,
/// horizontal book stacks, leaning books, dramatic 3D wall cast shadows, and
/// floating category hotspot pills seamlessly integrated on the page background.
///
/// Tapping any category hotspot selects and filters the corresponding category of books.
class InteractiveBookshelfCategoryWidget extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final bool isDark;
  final Color goldAccent;
  final Color textPrimary;
  final Color textSecondary;

  const InteractiveBookshelfCategoryWidget({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.isDark,
    required this.goldAccent,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: SizedBox(
        height: 175,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Realistic Canvas: Wall cast shadow, 3D shelves, book spines & stacks
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RealisticBookshelfPainter(
                      isDark: isDark,
                      goldAccent: goldAccent,
                    ),
                  ),
                ),

                // 2. Hotspot Pill: Top-Left ("Malayalam Classics Collection")
                _buildFloatingPill(
                  top: 14,
                  left: math.max(16.0, w * 0.12),
                  label: 'Malayalam Classics Collection',
                  categoryKey: 'Malayalam',
                  tooltip: 'Explore Malayalam Masterpieces',
                ),

                // 3. Hotspot Pill: Top-Center-Right ("EPUB Only")
                _buildFloatingPill(
                  top: 18,
                  left: math.min(w - 180, w * 0.52),
                  label: 'EPUB Only',
                  categoryKey: 'EPUB',
                  tooltip: 'EPUB Format Books',
                ),

                // 4. Hotspot Pill: Top-Right ("Sync & Audio Support")
                _buildFloatingPill(
                  top: 56,
                  right: math.max(12.0, w * 0.08),
                  label: 'Sync & Audio Support',
                  categoryKey: 'Audio',
                  tooltip: 'Books with Narrated Audio',
                ),

                // 5. Hotspot Pill: Bottom-Left ("Featured Author: VKN")
                _buildFloatingPill(
                  bottom: 34,
                  left: math.max(16.0, w * 0.14),
                  label: 'Featured Author: VKN',
                  categoryKey: 'Classics',
                  tooltip: 'World & Malayalam Classics',
                ),

                // 6. Hotspot Pill: Bottom-Right ("Poetry Selection")
                _buildFloatingPill(
                  bottom: 24,
                  right: math.max(12.0, w * 0.06),
                  label: 'Poetry Selection',
                  categoryKey: 'Imported',
                  tooltip: 'Imported Documents & Notes',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFloatingPill({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required String label,
    required String categoryKey,
    required String tooltip,
  }) {
    final bool isSelected = selectedCategory == categoryKey;

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (isSelected) {
                onCategorySelected('All');
              } else {
                onCategorySelected(categoryKey);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? goldAccent : const Color(0xFF2B2620))
                    : (isDark
                        ? const Color(0xFF2C241B).withValues(alpha: 0.94)
                        : Colors.white.withValues(alpha: 0.95)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? goldAccent
                      : (isDark
                          ? const Color(0xFF5A4B3C)
                          : const Color(0xFFDDD3C4)),
                  width: isSelected ? 1.5 : 0.9,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? goldAccent.withValues(alpha: 0.35)
                        : Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.12,
                          ),
                    blurRadius: isSelected ? 8 : 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    Icon(
                      Icons.check_circle_rounded,
                      size: 11,
                      color: isDark
                          ? const Color(0xFF1E1812)
                          : const Color(0xFFF7F1E6),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.2,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      fontFamily: 'serif',
                      letterSpacing: 0.2,
                      color: isSelected
                          ? (isDark
                              ? const Color(0xFF1E1812)
                              : const Color(0xFFF7F1E6))
                          : (isDark
                              ? const Color(0xFFF3ECE0)
                              : const Color(0xFF332B22)),
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
}

/// Custom Painter creating the exact 3D floating bookshelf look from the reference design:
/// - Dramatic diagonal wall shadow on the left side
/// - Top and bottom wooden shelves with 3D bevels and deep under-shelf shadows
/// - Rich array of books with colorful textured spines, horizontal stacks, and leaning books
class _RealisticBookshelfPainter extends CustomPainter {
  final bool isDark;
  final Color goldAccent;

  _RealisticBookshelfPainter({
    required this.isDark,
    required this.goldAccent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Shelf coordinates
    final shelfY1 = height * 0.44; // Top Shelf plank Y
    final shelfY2 = height * 0.88; // Bottom Shelf plank Y
    const shelfThickness = 8.5;
    const shelfMargin = 24.0;
    final shelfLeft = shelfMargin;
    final shelfRight = width - shelfMargin;
    final shelfW = shelfRight - shelfLeft;

    // 1. Draw Dramatic Angled Cast Shadow on Left Wall
    _drawDramaticWallShadow(
      canvas,
      shelfLeft,
      shelfY1,
      shelfY2,
      shelfThickness,
      height,
    );

    // 2. Draw Under-Shelf Deep Horizontal Shadows
    final underShelfShadow = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.45 : 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(shelfLeft + 4, shelfY1 + shelfThickness, shelfW - 8, 8),
        const Radius.circular(3),
      ),
      underShelfShadow,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(shelfLeft + 4, shelfY2 + shelfThickness, shelfW - 8, 10),
        const Radius.circular(3),
      ),
      underShelfShadow,
    );

    // 3. Draw Top Shelf Books
    _drawTopShelfBooks(canvas, shelfLeft + 8, shelfRight - 8, shelfY1);

    // 4. Draw Top Wooden Shelf (3D Bevel)
    _draw3DWoodPlank(
      canvas,
      shelfLeft,
      shelfY1,
      shelfW,
      shelfThickness,
    );

    // 5. Draw Bottom Shelf Books (Including horizontal book stack)
    _drawBottomShelfBooks(canvas, shelfLeft + 8, shelfRight - 8, shelfY2);

    // 6. Draw Bottom Wooden Shelf (3D Bevel)
    _draw3DWoodPlank(
      canvas,
      shelfLeft,
      shelfY2,
      shelfW,
      shelfThickness,
    );
  }

  /// Draws the realistic 45-degree angle drop shadow on the left wall
  void _drawDramaticWallShadow(
    Canvas canvas,
    double shelfLeft,
    double shelfY1,
    double shelfY2,
    double shelfThickness,
    double totalHeight,
  ) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Top shelf angled shadow polygon
    final path1 = Path();
    path1.moveTo(shelfLeft + 6, shelfY1 - 55); // Top of first book
    path1.lineTo(shelfLeft - 22, shelfY1 + 22); // Diagonal cast down-left
    path1.lineTo(shelfLeft - 22, shelfY1 + shelfThickness + 14);
    path1.lineTo(shelfLeft + 30, shelfY1 + shelfThickness + 4);
    path1.lineTo(shelfLeft + 30, shelfY1 - 10);
    path1.close();
    canvas.drawPath(path1, shadowPaint);

    // Bottom shelf angled shadow polygon
    final path2 = Path();
    path2.moveTo(shelfLeft + 6, shelfY2 - 58);
    path2.lineTo(shelfLeft - 26, shelfY2 + 24);
    path2.lineTo(shelfLeft - 26, shelfY2 + shelfThickness + 18);
    path2.lineTo(shelfLeft + 36, shelfY2 + shelfThickness + 6);
    path2.lineTo(shelfLeft + 36, shelfY2 - 12);
    path2.close();
    canvas.drawPath(path2, shadowPaint);
  }

  /// Draws 3D wooden plank with lighter top face and darker front face
  void _draw3DWoodPlank(
    Canvas canvas,
    double x,
    double y,
    double width,
    double thickness,
  ) {
    final topWoodColor = isDark
        ? const Color(0xFF8C5832)
        : const Color(0xFFC48E60);
    final frontWoodColor = isDark
        ? const Color(0xFF6B3F1E)
        : const Color(0xFFA16F43);
    final highlightEdge = isDark
        ? const Color(0xFFA67146)
        : const Color(0xFFDEC0A2);
    final shadowEdge = isDark
        ? const Color(0xFF45240E)
        : const Color(0xFF7A4F2C);

    // Front face
    final frontRect = Rect.fromLTWH(x, y, width, thickness);
    final frontPaint = Paint()..color = frontWoodColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(frontRect, const Radius.circular(2)),
      frontPaint,
    );

    // Top bevel surface
    final topRect = Rect.fromLTWH(x, y, width, 2.5);
    final topPaint = Paint()..color = topWoodColor;
    canvas.drawRect(topRect, topPaint);

    // Top edge highlight line
    final hlPaint = Paint()
      ..color = highlightEdge
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(x + 1, y + 0.5), Offset(x + width - 1, y + 0.5), hlPaint);

    // Bottom edge shadow line
    final shPaint = Paint()
      ..color = shadowEdge
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(x + 1, y + thickness - 0.5),
      Offset(x + width - 1, y + thickness - 0.5),
      shPaint,
    );
  }

  void _drawTopShelfBooks(
    Canvas canvas,
    double startX,
    double endX,
    double shelfY,
  ) {
    // Curated color palette matching reference design
    final colors = [
      const Color(0xFFD66848), // Warm Terracotta
      const Color(0xFFE5A952), // Mustard Gold
      const Color(0xFF6A937D), // Sage Green
      const Color(0xFFE08354), // Coral Orange
      const Color(0xFF4D6F80), // Slate Teal
      const Color(0xFFD4A359), // Warm Ochre
      const Color(0xFF5B8A99), // Ocean Teal
      const Color(0xFFD66D52), // Terracotta Rust
      const Color(0xFF6E9B82), // Soft Emerald
      const Color(0xFFDCA451), // Golden Mustard
      const Color(0xFF537A8C), // Slate Blue
      const Color(0xFFCC6644), // Burnt Sienna
      const Color(0xFF739E88), // Sage Olive
      const Color(0xFFE8B058), // Light Ochre
      const Color(0xFF446878), // Deep Slate
      const Color(0xFFDB7555), // Coral
    ];

    final heights = [
      58.0, 52.0, 60.0, 54.0, 62.0, 50.0, 56.0, 63.0, 53.0, 59.0, 51.0, 61.0, 55.0, 48.0, 57.0, 53.0
    ];
    final widths = [
      11.0, 13.0, 10.0, 14.0, 12.0, 15.0, 11.0, 13.0, 16.0, 10.0, 14.0, 12.0, 15.0, 11.0, 13.0, 12.0
    ];

    double currentX = startX;
    int index = 0;

    while (currentX < endX - 16) {
      final h = heights[index % heights.length];
      final w = widths[index % widths.length];
      final color = colors[index % colors.length];

      // Occasional leaning book on the right end
      if (currentX > endX - 35) {
        _drawLeaningBook(canvas, currentX, shelfY, h, w, color, tiltRight: true);
        currentX += w + 6;
      } else {
        _drawSpineBook(
          canvas,
          currentX,
          shelfY,
          h,
          w,
          color,
          hasAccentBand: index % 3 == 0,
          accentBandColor: colors[(index + 4) % colors.length],
        );
        currentX += w + 1.6;
      }
      index++;
    }
  }

  void _drawBottomShelfBooks(
    Canvas canvas,
    double startX,
    double endX,
    double shelfY,
  ) {
    final colors = [
      const Color(0xFF4D6F80), // Slate Blue
      const Color(0xFFD66848), // Warm Terracotta
      const Color(0xFFE5A952), // Mustard Gold
      const Color(0xFF6A937D), // Sage Green
      const Color(0xFFCC6644), // Burnt Sienna
      const Color(0xFF5B8A99), // Ocean Teal
      const Color(0xFFD4A359), // Warm Ochre
      const Color(0xFF537A8C), // Slate Blue
      const Color(0xFFD66D52), // Terracotta Rust
      const Color(0xFF739E88), // Sage Olive
      const Color(0xFFE08354), // Coral Orange
      const Color(0xFF446878), // Deep Slate
    ];

    double currentX = startX;
    int index = 0;

    // 1. First: Leaning book on left
    _drawLeaningBook(
      canvas,
      currentX + 4,
      shelfY,
      56.0,
      12.0,
      colors[0],
      tiltRight: false,
    );
    currentX += 18.0;

    // 2. Standing books before stack
    for (int i = 0; i < 4 && currentX < endX - 110; i++) {
      _drawSpineBook(
        canvas,
        currentX,
        shelfY,
        54.0 + (i % 3) * 4,
        11.0 + (i % 2) * 2,
        colors[(i + 1) % colors.length],
        hasAccentBand: i == 1,
        accentBandColor: colors[(i + 5) % colors.length],
      );
      currentX += 13.0;
    }

    // 3. Realistic Horizontal Stack of 3 Books in middle-left!
    final stackWidth = 38.0;
    _drawHorizontalBookStack(
      canvas,
      currentX,
      shelfY,
      stackWidth,
      [
        colors[3], // Top book
        colors[2], // Middle book
        colors[1], // Bottom book
      ],
    );
    currentX += stackWidth + 3.0;

    // 4. Remaining Standing Books & Leaning Book on right
    final heights = [58.0, 52.0, 62.0, 55.0, 60.0, 51.0, 57.0, 53.0];
    final widths = [12.0, 10.0, 14.0, 11.0, 13.0, 12.0, 15.0, 11.0];

    while (currentX < endX - 14) {
      final h = heights[index % heights.length];
      final w = widths[index % widths.length];
      final color = colors[(index + 4) % colors.length];

      if (currentX > endX - 32) {
        _drawLeaningBook(canvas, currentX, shelfY, h, w, color, tiltRight: true);
        currentX += w + 6;
      } else {
        _drawSpineBook(
          canvas,
          currentX,
          shelfY,
          h,
          w,
          color,
          hasAccentBand: index % 2 == 1,
          accentBandColor: colors[(index + 7) % colors.length],
        );
        currentX += w + 1.6;
      }
      index++;
    }
  }

  void _drawSpineBook(
    Canvas canvas,
    double x,
    double shelfY,
    double height,
    double width,
    Color color, {
    bool hasAccentBand = false,
    Color? accentBandColor,
  }) {
    final bookRect = Rect.fromLTWH(x, shelfY - height, width, height);

    // Book spine body
    final bookPaint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bookRect, const Radius.circular(1.5)),
      bookPaint,
    );

    // Top page edge (3D thickness of book top)
    final topPagePaint = Paint()
      ..color = isDark
          ? const Color(0xFFC7BAA7)
          : const Color(0xFFFFFDF5);
    canvas.drawRect(
      Rect.fromLTWH(x + 1, shelfY - height, width - 2, 1.8),
      topPagePaint,
    );

    // Left spine crease shadow
    final creasePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(x + 1.0, shelfY - height + 2),
      Offset(x + 1.0, shelfY - 1),
      creasePaint,
    );

    // Optional multi-tone color band on spine
    if (hasAccentBand && accentBandColor != null && height > 46) {
      final bandPaint = Paint()..color = accentBandColor;
      final bandRect = Rect.fromLTWH(
        x + 0.5,
        shelfY - height + (height * 0.32),
        width - 1.0,
        height * 0.16,
      );
      canvas.drawRect(bandRect, bandPaint);
    }
  }

  /// Draws a stack of 3 books laid flat horizontally
  void _drawHorizontalBookStack(
    Canvas canvas,
    double x,
    double shelfY,
    double stackWidth,
    List<Color> bookColors,
  ) {
    const bookThickness = 7.0;

    for (int i = 0; i < bookColors.length; i++) {
      final bookY = shelfY - ((i + 1) * bookThickness);
      final bookRect = Rect.fromLTWH(x, bookY, stackWidth, bookThickness);

      // Book spine
      final bookPaint = Paint()..color = bookColors[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(bookRect, const Radius.circular(1.5)),
        bookPaint,
      );

      // Top edge highlight
      final hlPaint = Paint()
        ..color = isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.1)
        ..strokeWidth = 0.7;
      canvas.drawLine(
        Offset(x + 1, bookY + 0.5),
        Offset(x + stackWidth - 1, bookY + 0.5),
        hlPaint,
      );

      // Page edge on right side
      final pagePaint = Paint()
        ..color = isDark
            ? const Color(0xFFC7BAA7)
            : const Color(0xFFFFFDF5);
      canvas.drawRect(
        Rect.fromLTWH(x + stackWidth - 2.5, bookY + 1, 2.0, bookThickness - 2),
        pagePaint,
      );
    }
  }

  void _drawLeaningBook(
    Canvas canvas,
    double x,
    double shelfY,
    double height,
    double width,
    Color color, {
    required bool tiltRight,
  }) {
    canvas.save();
    final angle = (tiltRight ? 1 : -1) * (14.0 * math.pi / 180.0);
    canvas.translate(x + width / 2, shelfY);
    canvas.rotate(angle);

    final bookRect = Rect.fromLTWH(-width / 2, -height, width, height);
    final bookPaint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bookRect, const Radius.circular(1.5)),
      bookPaint,
    );

    // Top page edge
    final topPagePaint = Paint()
      ..color = isDark
          ? const Color(0xFFC7BAA7)
          : const Color(0xFFFFFDF5);
    canvas.drawRect(
      Rect.fromLTWH(-width / 2 + 1, -height, width - 2, 1.8),
      topPagePaint,
    );

    // Spine edge shadow
    final edgePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(-width / 2 + 1, -height + 2),
      Offset(-width / 2 + 1, -1),
      edgePaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RealisticBookshelfPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.goldAccent != goldAccent;
  }
}
