import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An interactive 2-tier 3D wooden bookshelf displaying realistic book spines,
/// leaning books, warm drop shadows, and category hotspot pills.
///
/// Tapping any hotspot selects and filters the corresponding category of books.
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1712) : const Color(0xFFF7F2E8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF382F24) : const Color(0xFFE2D6C5),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background subtle gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? [const Color(0xFF221B14), const Color(0xFF18130E)]
                        : [const Color(0xFFFAF6EE), const Color(0xFFF1E9DA)],
                  ),
                ),
              ),
            ),

            // Top Header & Category Count
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: goldAccent.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: goldAccent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          Icons.shelves,
                          color: goldAccent,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Curated Library Shelves',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (selectedCategory != 'All')
                    GestureDetector(
                      onTap: () => onCategorySelected('All'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2.5,
                        ),
                        decoration: BoxDecoration(
                          color: goldAccent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: goldAccent.withValues(alpha: 0.5),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Show All',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: goldAccent,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.close_rounded,
                              size: 12,
                              color: goldAccent,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // 2-Tier Realistic Bookshelf with CustomPainter & Interactive Hotspots
            Padding(
              padding: const EdgeInsets.only(top: 36, bottom: 8),
              child: SizedBox(
                height: 175,
                width: double.infinity,
                child: Stack(
                  children: [
                    // 1. Realistic Canvas Painted Books & Wood Shelves
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _BookshelfIllustrationPainter(
                          isDark: isDark,
                          goldAccent: goldAccent,
                        ),
                      ),
                    ),

                    // 2. Interactive Hotspot Pill: Top-Left (Malayalam Classics Collection)
                    _buildHotspotPill(
                      top: 10,
                      left: 12,
                      label: 'Malayalam Classics Collection',
                      categoryKey: 'Malayalam',
                      tooltip: 'Explore Malayalam Masterpieces',
                    ),

                    // 3. Interactive Hotspot Pill: Top-Center (EPUB Only)
                    _buildHotspotPill(
                      top: 10,
                      right: 120,
                      label: 'EPUB Only',
                      categoryKey: 'EPUB',
                      tooltip: 'EPUB Format Books',
                    ),

                    // 4. Interactive Hotspot Pill: Top-Right (Sync & Audio Support)
                    _buildHotspotPill(
                      top: 36,
                      right: 10,
                      label: 'Sync & Audio Support',
                      categoryKey: 'Audio',
                      tooltip: 'Books with Narrated Audio',
                    ),

                    // 5. Interactive Hotspot Pill: Bottom-Left (Featured Author: VKN)
                    _buildHotspotPill(
                      bottom: 22,
                      left: 20,
                      label: 'Featured Author: VKN',
                      categoryKey: 'Classics',
                      tooltip: 'World & Malayalam Classics',
                    ),

                    // 6. Interactive Hotspot Pill: Bottom-Right (Poetry Selection)
                    _buildHotspotPill(
                      bottom: 18,
                      right: 14,
                      label: 'Poetry Selection',
                      categoryKey: 'Imported',
                      tooltip: 'Imported Documents & Notes',
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

  Widget _buildHotspotPill({
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? goldAccent : const Color(0xFF2B2620))
                    : (isDark
                        ? const Color(0xFF2C241B).withValues(alpha: 0.92)
                        : Colors.white.withValues(alpha: 0.94)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? goldAccent
                      : (isDark
                          ? const Color(0xFF4A3E31)
                          : const Color(0xFFD6CAB4)),
                  width: isSelected ? 1.4 : 0.9,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? goldAccent.withValues(alpha: 0.35)
                        : Colors.black.withValues(
                            alpha: isDark ? 0.3 : 0.1,
                          ),
                    blurRadius: isSelected ? 6 : 3,
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
                      size: 11,
                      color: isDark
                          ? const Color(0xFF1E1812)
                          : const Color(0xFFF7F1E6),
                    ),
                    const SizedBox(width: 3),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9.8,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      fontFamily: 'serif',
                      color: isSelected
                          ? (isDark
                              ? const Color(0xFF1E1812)
                              : const Color(0xFFF7F1E6))
                          : (isDark
                              ? const Color(0xFFF3ECE0)
                              : const Color(0xFF2B2620)),
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

/// High-fidelity Custom Painter rendering realistic wooden planks, cast shadows,
/// standing book spines of varying heights and widths, and leaning books.
class _BookshelfIllustrationPainter extends CustomPainter {
  final bool isDark;
  final Color goldAccent;

  _BookshelfIllustrationPainter({
    required this.isDark,
    required this.goldAccent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final woodPlankColor =
        isDark ? const Color(0xFF7A4E2B) : const Color(0xFFB57D4F);
    final woodHighlight =
        isDark ? const Color(0xFF915E36) : const Color(0xFFCCA17A);
    final woodShadow =
        isDark ? const Color(0xFF422814) : const Color(0xFF7D4E2A);

    final shelfY1 = height * 0.44; // Top Shelf plank Y
    final shelfY2 = height * 0.88; // Bottom Shelf plank Y
    const shelfThickness = 7.5;

    // 1. Draw Cast Shadows on Wall behind books and under planks
    final wallShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Shadow under Top Shelf
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, shelfY1 + shelfThickness, width - 20, 6),
        const Radius.circular(3),
      ),
      wallShadowPaint,
    );

    // Shadow under Bottom Shelf
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, shelfY2 + shelfThickness, width - 20, 8),
        const Radius.circular(3),
      ),
      wallShadowPaint,
    );

    // 2. Draw Top Shelf Books
    _drawTopShelfBooks(canvas, shelfY1, width);

    // 3. Draw Top Shelf Wooden Plank
    _drawWoodenPlank(
      canvas,
      shelfY1,
      shelfThickness,
      width,
      woodPlankColor,
      woodHighlight,
      woodShadow,
    );

    // 4. Draw Bottom Shelf Books
    _drawBottomShelfBooks(canvas, shelfY2, width);

    // 5. Draw Bottom Shelf Wooden Plank
    _drawWoodenPlank(
      canvas,
      shelfY2,
      shelfThickness,
      width,
      woodPlankColor,
      woodHighlight,
      woodShadow,
    );
  }

  void _drawWoodenPlank(
    Canvas canvas,
    double y,
    double thickness,
    double width,
    Color plankColor,
    Color highlightColor,
    Color shadowColor,
  ) {
    const margin = 10.0;
    final plankRect = Rect.fromLTWH(margin, y, width - (margin * 2), thickness);
    final plankRRect = RRect.fromRectAndRadius(
      plankRect,
      const Radius.circular(2.5),
    );

    // Main wood surface
    final plankPaint = Paint()..color = plankColor;
    canvas.drawRRect(plankRRect, plankPaint);

    // Top edge highlight
    final highlightPaint = Paint()
      ..color = highlightColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(margin + 2, y + 0.5),
      Offset(width - margin - 2, y + 0.5),
      highlightPaint,
    );

    // Bottom edge shadow
    final shadowPaint = Paint()
      ..color = shadowColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(margin + 2, y + thickness - 0.5),
      Offset(width - margin - 2, y + thickness - 0.5),
      shadowPaint,
    );
  }

  void _drawTopShelfBooks(Canvas canvas, double shelfY, double totalWidth) {
    // Book Palette (Terracotta, Ochre, Emerald, Amber, Navy, Burgundy, Sage)
    final palette = [
      const Color(0xFFC25E3E), // Terracotta
      const Color(0xFFD49B4B), // Warm Ochre
      const Color(0xFF3F7058), // Emerald Green
      const Color(0xFFD97706), // Amber Gold
      const Color(0xFF476282), // Slate Navy
      const Color(0xFF8F3B3B), // Burgundy Red
      const Color(0xFF829460), // Sage Olive
      const Color(0xFFB45309), // Bronze
      const Color(0xFF4F46E5), // Indigo
      const Color(0xFF78350F), // Deep Ochre
      const Color(0xFF2B5B66), // Teal Marine
      const Color(0xFF9A3412), // Rust Orange
    ];

    double currentX = 18.0;
    final endX = totalWidth - 18.0;
    int index = 0;

    // Pattern of heights & widths (scaled for 175px total height)
    final heights = [
      48.0, 56.0, 44.0, 58.0, 52.0, 49.0, 57.0, 46.0, 54.0, 51.0, 60.0, 50.0, 55.0, 45.0, 56.0, 52.0
    ];
    final widths = [
      9.0, 12.0, 8.0, 13.0, 10.0, 12.0, 9.0, 11.0, 14.0, 9.0, 12.0, 10.0, 13.0, 8.0, 11.0, 12.0
    ];

    while (currentX < endX - 12) {
      final h = heights[index % heights.length];
      final w = widths[index % widths.length];
      final color = palette[index % palette.length];

      // Occasional leaning book
      if (index == 5 || index == 11) {
        _drawLeaningBook(canvas, currentX, shelfY, h, w, color,
            tiltRight: index == 5);
        currentX += w + 5.0;
      } else {
        _drawSpineBook(canvas, currentX, shelfY, h, w, color);
        currentX += w + 1.5;
      }
      index++;
    }
  }

  void _drawBottomShelfBooks(Canvas canvas, double shelfY, double totalWidth) {
    final palette = [
      const Color(0xFF4A6B82), // Slate Blue
      const Color(0xFFC06C4E), // Coral Brown
      const Color(0xFF5E8B68), // Green
      const Color(0xFFB45309), // Amber
      const Color(0xFF8B4265), // Plum Violet
      const Color(0xFFB28247), // Mustard Ochre
      const Color(0xFF3B6E73), // Deep Teal
      const Color(0xFFB94747), // Crimson
      const Color(0xFF6B7280), // Slate
      const Color(0xFF92400E), // Russet
      const Color(0xFF4338CA), // Royal Blue
      const Color(0xFF7E22CE), // Purple
    ];

    double currentX = 18.0;
    final endX = totalWidth - 18.0;
    int index = 0;

    final heights = [
      52.0, 46.0, 58.0, 49.0, 60.0, 54.0, 48.0, 56.0, 51.0, 62.0, 47.0, 57.0, 52.0, 55.0, 48.0, 59.0
    ];
    final widths = [
      11.0, 8.0, 12.0, 10.0, 13.0, 9.0, 11.0, 8.0, 14.0, 10.0, 12.0, 8.0, 11.0, 13.0, 9.0, 11.0
    ];

    while (currentX < endX - 12) {
      final h = heights[index % heights.length];
      final w = widths[index % widths.length];
      final color = palette[index % palette.length];

      if (index == 4 || index == 12) {
        _drawLeaningBook(canvas, currentX, shelfY, h, w, color,
            tiltRight: index == 12);
        currentX += w + 5.0;
      } else {
        _drawSpineBook(canvas, currentX, shelfY, h, w, color);
        currentX += w + 1.5;
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
    Color color,
  ) {
    final bookRect = Rect.fromLTWH(x, shelfY - height, width, height);

    // Book Base
    final bookPaint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(bookRect, const Radius.circular(1.5)),
      bookPaint,
    );

    // Left spine vertical crease
    final creasePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(x + 1.2, shelfY - height + 2),
      Offset(x + 1.2, shelfY - 1),
      creasePaint,
    );

    // Spine gold band / rib ornament
    if (height > 50) {
      final bandPaint = Paint()
        ..color = isDark
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.black.withValues(alpha: 0.1)
        ..strokeWidth = 0.8;
      canvas.drawLine(
        Offset(x + 1, shelfY - height + 10),
        Offset(x + width - 1, shelfY - height + 10),
        bandPaint,
      );
      canvas.drawLine(
        Offset(x + 1, shelfY - 10),
        Offset(x + width - 1, shelfY - 10),
        bandPaint,
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
      RRect.fromRectAndRadius(bookRect, const Radius.circular(1.5)),
      bookPaint,
    );

    // Edge shadow
    final edgePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..strokeWidth = 0.8;
    canvas.drawLine(
      Offset(-width / 2 + 1, -height + 2),
      Offset(-width / 2 + 1, -1),
      edgePaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BookshelfIllustrationPainter oldDelegate) {
    return oldDelegate.isDark != isDark || oldDelegate.goldAccent != goldAccent;
  }
}
