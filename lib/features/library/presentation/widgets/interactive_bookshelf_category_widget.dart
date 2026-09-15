import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An interactive 3-tier 3D wooden bookshelf displaying realistic book spines,
/// horizontal book stacks, leaning books, dramatic 45-degree 3D wall cast shadows,
/// and floating category hotspot pills seamlessly integrated on the page background.
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: SizedBox(
        height: 195,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Realistic Canvas: 3-tier shelves, wall cast shadow, book spines & stacks
                Positioned.fill(
                  child: CustomPaint(
                    painter: _Realistic3TierBookshelfPainter(
                      isDark: isDark,
                      goldAccent: goldAccent,
                    ),
                  ),
                ),

                // 2. Tier 1 (Top Shelf) Hotspot Pills
                _buildFloatingPill(
                  top: 6,
                  left: math.max(14.0, w * 0.10),
                  label: 'Malayalam Classics Collection',
                  categoryKey: 'Malayalam',
                  tooltip: 'Explore Malayalam Masterpieces',
                ),
                _buildFloatingPill(
                  top: 6,
                  right: math.max(14.0, w * 0.10),
                  label: 'EPUB Only',
                  categoryKey: 'EPUB',
                  tooltip: 'EPUB Format Books',
                ),

                // 3. Tier 2 (Middle Shelf) Hotspot Pills
                _buildFloatingPill(
                  top: 64,
                  left: math.max(14.0, w * 0.08),
                  label: 'Sync & Audio Support',
                  categoryKey: 'Audio',
                  tooltip: 'Books with Narrated Audio',
                ),
                _buildFloatingPill(
                  top: 64,
                  right: math.max(14.0, w * 0.08),
                  label: 'Featured Author: VKN',
                  categoryKey: 'Classics',
                  tooltip: 'World & Malayalam Classics',
                ),

                // 4. Tier 3 (Bottom Shelf) Hotspot Pills
                _buildFloatingPill(
                  bottom: 12,
                  left: math.max(14.0, w * 0.12),
                  label: 'PDF & Scans',
                  categoryKey: 'PDF',
                  tooltip: 'PDF Books and OCR Scans',
                ),
                _buildFloatingPill(
                  bottom: 12,
                  right: math.max(14.0, w * 0.10),
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
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              if (isSelected) {
                onCategorySelected('All');
              } else {
                onCategorySelected(categoryKey);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 8.5, vertical: 3.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? goldAccent : const Color(0xFF2B2620))
                    : (isDark
                        ? const Color(0xFF2C241B).withValues(alpha: 0.94)
                        : Colors.white.withValues(alpha: 0.95)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? goldAccent
                      : (isDark
                          ? const Color(0xFF5A4B3C)
                          : const Color(0xFFDDD3C4)),
                  width: isSelected ? 1.4 : 0.85,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? goldAccent.withValues(alpha: 0.35)
                        : Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.12,
                          ),
                    blurRadius: isSelected ? 7 : 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected) ...[
                    Icon(
                      Icons.check_circle_rounded,
                      size: 10.5,
                      color: isDark
                          ? const Color(0xFF1E1812)
                          : const Color(0xFFF7F1E6),
                    ),
                    const SizedBox(width: 3.5),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9.8,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      fontFamily: 'serif',
                      letterSpacing: 0.15,
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

/// Custom Painter rendering a 3-tier wooden bookshelf with:
/// - Dramatic 45-degree angle drop shadow on the left wall across all 3 tiers
/// - Top, middle, and bottom 3D wooden planks with highlights, bevels, and under-shelf cast shadows
/// - Realistic standing books with 3D page edges, spine creases, color bands, horizontal stacks, and leaning books
class _Realistic3TierBookshelfPainter extends CustomPainter {
  final bool isDark;
  final Color goldAccent;

  _Realistic3TierBookshelfPainter({
    required this.isDark,
    required this.goldAccent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 3 Shelf Y coordinates
    final shelfY1 = height * 0.28; // Top Shelf plank Y
    final shelfY2 = height * 0.58; // Middle Shelf plank Y
    final shelfY3 = height * 0.88; // Bottom Shelf plank Y
    const shelfThickness = 7.0;
    const shelfMargin = 22.0;
    final shelfLeft = shelfMargin;
    final shelfRight = width - shelfMargin;
    final shelfW = shelfRight - shelfLeft;

    // 1. Draw Dramatic 45-degree Angled Cast Shadows on Left Wall
    _drawDramaticWallShadows(
      canvas,
      shelfLeft,
      shelfY1,
      shelfY2,
      shelfY3,
      shelfThickness,
      height,
    );

    // 2. Draw Under-Shelf Deep Horizontal Shadows for all 3 tiers
    final underShelfShadow = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.42 : 0.20)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.5);

    for (final y in [shelfY1, shelfY2, shelfY3]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(shelfLeft + 3, y + shelfThickness, shelfW - 6, 6.5),
          const Radius.circular(2.5),
        ),
        underShelfShadow,
      );
    }

    // 3. Draw Tier 1 (Top Shelf) Books
    _drawTier1Books(canvas, shelfLeft + 6, shelfRight - 6, shelfY1);

    // 4. Draw Tier 1 Wooden Plank (3D Bevel)
    _draw3DWoodPlank(canvas, shelfLeft, shelfY1, shelfW, shelfThickness);

    // 5. Draw Tier 2 (Middle Shelf) Books (with horizontal stack in middle)
    _drawTier2Books(canvas, shelfLeft + 6, shelfRight - 6, shelfY2);

    // 6. Draw Tier 2 Wooden Plank (3D Bevel)
    _draw3DWoodPlank(canvas, shelfLeft, shelfY2, shelfW, shelfThickness);

    // 7. Draw Tier 3 (Bottom Shelf) Books (with horizontal stack)
    _drawTier3Books(canvas, shelfLeft + 6, shelfRight - 6, shelfY3);

    // 8. Draw Tier 3 Wooden Plank (3D Bevel)
    _draw3DWoodPlank(canvas, shelfLeft, shelfY3, shelfW, shelfThickness);
  }

  /// Draws the realistic 45-degree angle drop shadow on the left wall across all 3 tiers
  void _drawDramaticWallShadows(
    Canvas canvas,
    double shelfLeft,
    double shelfY1,
    double shelfY2,
    double shelfY3,
    double shelfThickness,
    double totalHeight,
  ) {
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.13)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

    // Combined wall shadow polygon connecting top, middle, and bottom shelves
    final wallPath = Path();
    // Top tier shadow
    wallPath.moveTo(shelfLeft + 6, shelfY1 - 44);
    wallPath.lineTo(shelfLeft - 20, shelfY1 + 16);
    wallPath.lineTo(shelfLeft - 20, shelfY1 + shelfThickness + 10);
    wallPath.lineTo(shelfLeft + 24, shelfY1 + shelfThickness + 4);
    wallPath.lineTo(shelfLeft + 24, shelfY1 - 8);
    wallPath.close();
    canvas.drawPath(wallPath, shadowPaint);

    // Middle tier shadow
    final midPath = Path();
    midPath.moveTo(shelfLeft + 6, shelfY2 - 46);
    midPath.lineTo(shelfLeft - 22, shelfY2 + 18);
    midPath.lineTo(shelfLeft - 22, shelfY2 + shelfThickness + 12);
    midPath.lineTo(shelfLeft + 26, shelfY2 + shelfThickness + 4);
    midPath.lineTo(shelfLeft + 26, shelfY2 - 8);
    midPath.close();
    canvas.drawPath(midPath, shadowPaint);

    // Bottom tier shadow
    final botPath = Path();
    botPath.moveTo(shelfLeft + 6, shelfY3 - 48);
    botPath.lineTo(shelfLeft - 24, shelfY3 + 20);
    botPath.lineTo(shelfLeft - 24, shelfY3 + shelfThickness + 14);
    botPath.lineTo(shelfLeft + 28, shelfY3 + shelfThickness + 4);
    botPath.lineTo(shelfLeft + 28, shelfY3 - 8);
    botPath.close();
    canvas.drawPath(botPath, shadowPaint);
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
      RRect.fromRectAndRadius(frontRect, const Radius.circular(1.5)),
      frontPaint,
    );

    // Top bevel surface
    final topRect = Rect.fromLTWH(x, y, width, 2.0);
    final topPaint = Paint()..color = topWoodColor;
    canvas.drawRect(topRect, topPaint);

    // Top edge highlight line
    final hlPaint = Paint()
      ..color = highlightEdge
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(x + 1, y + 0.4), Offset(x + width - 1, y + 0.4), hlPaint);

    // Bottom edge shadow line
    final shPaint = Paint()
      ..color = shadowEdge
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(x + 1, y + thickness - 0.4),
      Offset(x + width - 1, y + thickness - 0.4),
      shPaint,
    );
  }

  void _drawTier1Books(
    Canvas canvas,
    double startX,
    double endX,
    double shelfY,
  ) {
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
    ];

    final heights = [44.0, 40.0, 46.0, 42.0, 48.0, 39.0, 45.0, 49.0, 41.0, 47.0, 43.0, 46.0];
    final widths = [9.0, 11.0, 8.0, 12.0, 10.0, 13.0, 9.0, 11.0, 14.0, 8.0, 12.0, 10.0];

    double currentX = startX;
    int index = 0;

    while (currentX < endX - 14) {
      final h = heights[index % heights.length];
      final w = widths[index % widths.length];
      final color = colors[index % colors.length];

      if (currentX > endX - 28) {
        _drawLeaningBook(canvas, currentX, shelfY, h, w, color, tiltRight: true);
        currentX += w + 5;
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
        currentX += w + 1.4;
      }
      index++;
    }
  }

  void _drawTier2Books(
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
    ];

    double currentX = startX;
    int index = 0;

    // 1. Leaning book on left
    _drawLeaningBook(
      canvas,
      currentX + 3,
      shelfY,
      44.0,
      10.0,
      colors[0],
      tiltRight: false,
    );
    currentX += 15.0;

    // 2. Standing books before stack
    for (int i = 0; i < 3 && currentX < endX - 90; i++) {
      _drawSpineBook(
        canvas,
        currentX,
        shelfY,
        42.0 + (i % 3) * 3,
        9.0 + (i % 2) * 2,
        colors[(i + 1) % colors.length],
        hasAccentBand: i == 1,
        accentBandColor: colors[(i + 5) % colors.length],
      );
      currentX += 11.0;
    }

    // 3. Horizontal Stack of 3 Books
    const stackWidth = 32.0;
    _drawHorizontalBookStack(
      canvas,
      currentX,
      shelfY,
      stackWidth,
      [colors[3], colors[2], colors[1]],
    );
    currentX += stackWidth + 3.0;

    // 4. Remaining Standing Books & Leaning Book on right
    final heights = [46.0, 41.0, 48.0, 43.0, 47.0, 40.0, 45.0];
    final widths = [10.0, 8.0, 12.0, 9.0, 11.0, 10.0, 12.0];

    while (currentX < endX - 12) {
      final h = heights[index % heights.length];
      final w = widths[index % widths.length];
      final color = colors[(index + 4) % colors.length];

      if (currentX > endX - 26) {
        _drawLeaningBook(canvas, currentX, shelfY, h, w, color, tiltRight: true);
        currentX += w + 5;
      } else {
        _drawSpineBook(
          canvas,
          currentX,
          shelfY,
          h,
          w,
          color,
          hasAccentBand: index % 2 == 1,
          accentBandColor: colors[(index + 6) % colors.length],
        );
        currentX += w + 1.4;
      }
      index++;
    }
  }

  void _drawTier3Books(
    Canvas canvas,
    double startX,
    double endX,
    double shelfY,
  ) {
    final colors = [
      const Color(0xFF6A937D), // Sage Green
      const Color(0xFFD66848), // Terracotta
      const Color(0xFF4D6F80), // Slate
      const Color(0xFFE5A952), // Mustard
      const Color(0xFFD66D52), // Rust
      const Color(0xFF5B8A99), // Ocean Teal
      const Color(0xFFCC6644), // Sienna
      const Color(0xFF739E88), // Olive
      const Color(0xFFD4A359), // Ochre
    ];

    double currentX = startX;
    int index = 0;

    // 1. Standing books on left
    for (int i = 0; i < 5 && currentX < endX - 70; i++) {
      _drawSpineBook(
        canvas,
        currentX,
        shelfY,
        43.0 + (i % 3) * 3,
        9.0 + (i % 2) * 3,
        colors[i % colors.length],
        hasAccentBand: i % 2 == 0,
        accentBandColor: colors[(i + 3) % colors.length],
      );
      currentX += 12.0;
    }

    // 2. Horizontal Stack of 2 Books on right-center
    const stackWidth = 30.0;
    _drawHorizontalBookStack(
      canvas,
      currentX,
      shelfY,
      stackWidth,
      [colors[4], colors[5]],
    );
    currentX += stackWidth + 3.0;

    // 3. Remaining Standing Books & Leaning Book on right
    final heights = [45.0, 42.0, 48.0, 40.0, 46.0];
    final widths = [11.0, 9.0, 12.0, 10.0, 13.0];

    while (currentX < endX - 12) {
      final h = heights[index % heights.length];
      final w = widths[index % widths.length];
      final color = colors[(index + 2) % colors.length];

      if (currentX > endX - 26) {
        _drawLeaningBook(canvas, currentX, shelfY, h, w, color, tiltRight: true);
        currentX += w + 5;
      } else {
        _drawSpineBook(
          canvas,
          currentX,
          shelfY,
          h,
          w,
          color,
          hasAccentBand: index == 1,
          accentBandColor: colors[(index + 5) % colors.length],
        );
        currentX += w + 1.4;
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
      RRect.fromRectAndRadius(bookRect, const Radius.circular(1.2)),
      bookPaint,
    );

    // Top page edge (3D thickness of book top)
    final topPagePaint = Paint()
      ..color = isDark
          ? const Color(0xFFC7BAA7)
          : const Color(0xFFFFFDF5);
    canvas.drawRect(
      Rect.fromLTWH(x + 0.8, shelfY - height, width - 1.6, 1.5),
      topPagePaint,
    );

    // Left spine crease shadow
    final creasePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..strokeWidth = 0.7;
    canvas.drawLine(
      Offset(x + 0.8, shelfY - height + 1.5),
      Offset(x + 0.8, shelfY - 0.8),
      creasePaint,
    );

    // Optional multi-tone color band on spine
    if (hasAccentBand && accentBandColor != null && height > 36) {
      final bandPaint = Paint()..color = accentBandColor;
      final bandRect = Rect.fromLTWH(
        x + 0.5,
        shelfY - height + (height * 0.30),
        width - 1.0,
        height * 0.18,
      );
      canvas.drawRect(bandRect, bandPaint);
    }
  }

  /// Draws a stack of books laid flat horizontally
  void _drawHorizontalBookStack(
    Canvas canvas,
    double x,
    double shelfY,
    double stackWidth,
    List<Color> bookColors,
  ) {
    const bookThickness = 5.5;

    for (int i = 0; i < bookColors.length; i++) {
      final bookY = shelfY - ((i + 1) * bookThickness);
      final bookRect = Rect.fromLTWH(x, bookY, stackWidth, bookThickness);

      // Book spine
      final bookPaint = Paint()..color = bookColors[i];
      canvas.drawRRect(
        RRect.fromRectAndRadius(bookRect, const Radius.circular(1.2)),
        bookPaint,
      );

      // Top edge highlight
      final hlPaint = Paint()
        ..color = isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.1)
        ..strokeWidth = 0.6;
      canvas.drawLine(
        Offset(x + 0.8, bookY + 0.4),
        Offset(x + stackWidth - 0.8, bookY + 0.4),
        hlPaint,
      );

      // Page edge on right side
      final pagePaint = Paint()
        ..color = isDark
            ? const Color(0xFFC7BAA7)
            : const Color(0xFFFFFDF5);
      canvas.drawRect(
        Rect.fromLTWH(x + stackWidth - 2.0, bookY + 0.8, 1.5, bookThickness - 1.6),
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
    final angle = (tiltRight ? 1 : -1) * (13.0 * math.pi / 180.0);
    canvas.translate(x + width / 2, shelfY);
    canvas.rotate(angle);

    final bookRect = Rect.fromLTWH(-width / 2, -height, width, height);
    final bookPaint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bookRect, const Radius.circular(1.2)),
      bookPaint,
    );

    // Top page edge
    final topPagePaint = Paint()
      ..color = isDark
          ? const Color(0xFFC7BAA7)
          : const Color(0xFFFFFDF5);
    canvas.drawRect(
      Rect.fromLTWH(-width / 2 + 0.8, -height, width - 1.6, 1.5),
      topPagePaint,
    );

    // Spine edge shadow
    final edgePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 0.7;
    canvas.drawLine(
      Offset(-width / 2 + 0.8, -height + 1.5),
      Offset(-width / 2 + 0.8, -0.8),
      edgePaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _Realistic3TierBookshelfPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.goldAccent != goldAccent;
  }
}
