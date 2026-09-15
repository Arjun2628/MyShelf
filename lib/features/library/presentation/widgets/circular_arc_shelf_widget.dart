import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../epub/domain/entities/book.dart';

/// A realistic wooden library bookcase with toggleable Spine and Face views.
///
/// Features:
/// - Realistic solid oak / walnut wooden bookcase furniture frame on all 4 sides.
/// - Tabletop with ceramic potted plant (trailing vines), coffee cup, and journal notebook.
/// - Horizontal scrolling shelves with realistic hardcover book spines.
/// - Section classification partition dividers (every 5 books with brass cartouche `§` plaques).
/// - Dual View Switcher (Spines / Face View).
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
  bool _isFaceView = false;

  @override
  Widget build(BuildContext context) {
    if (widget.rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Table Top Surface with Potted Plant, Coffee Cup, Journal & View Switcher
          _BookshelfTableTop(
            isDark: widget.isDark,
            goldAccent: widget.goldAccent,
            textPrimary: widget.textPrimary,
            textSecondary: widget.textSecondary,
            cardBg: widget.cardBg,
            isFaceView: _isFaceView,
            onViewModeChanged: (val) {
              HapticFeedback.selectionClick();
              setState(() => _isFaceView = val);
            },
          ),

          // 2. The Main Wooden Bookcase Unit (Continuous outer frame + shelves)
          Container(
            decoration: BoxDecoration(
              color: widget.isDark
                  ? const Color(0xFF22150C)
                  : const Color(0xFF8A623C),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: widget.isDark ? 0.65 : 0.25,
                  ),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(4),
              ),
              child: Stack(
                children: [
                  // Bookcase vertical shelf tiers
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: widget.rows.asMap().entries.map((entry) {
                      final index = entry.key;
                      final rowData = entry.value;
                      return _BookcaseShelfTier(
                        key: ValueKey(
                          'shelf_tier_${rowData.title}_${_isFaceView ? "face" : "spine"}_$index',
                        ),
                        rowData: rowData,
                        tierIndex: index,
                        totalTiers: widget.rows.length,
                        isFaceView: _isFaceView,
                        isDark: widget.isDark,
                        goldAccent: widget.goldAccent,
                        textPrimary: widget.textPrimary,
                        textSecondary: widget.textSecondary,
                        cardBg: widget.cardBg,
                        onBookTap: widget.onBookTap,
                        onReadPressed: widget.onReadPressed,
                        onListenPressed: widget.onListenPressed,
                      );
                    }).toList(),
                  ),

                  // Left Outer Frame Pillar
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: 0,
                    width: 9,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: widget.isDark
                                ? [
                                    const Color(0xFF452B17),
                                    const Color(0xFF2E1A0C),
                                    const Color(0xFF1B0F06),
                                  ]
                                : [
                                    const Color(0xFFC79E72),
                                    const Color(0xFFA67B4F),
                                    const Color(0xFF7A5432),
                                  ],
                          ),
                          border: Border(
                            right: BorderSide(
                              color: Colors.black.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Right Outer Frame Pillar
                  Positioned(
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: 9,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            colors: widget.isDark
                                ? [
                                    const Color(0xFF452B17),
                                    const Color(0xFF2E1A0C),
                                    const Color(0xFF1B0F06),
                                  ]
                                : [
                                    const Color(0xFFC79E72),
                                    const Color(0xFFA67B4F),
                                    const Color(0xFF7A5432),
                                  ],
                          ),
                          border: Border(
                            left: BorderSide(
                              color: Colors.black.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Bookcase Base Plinth and Legs
          _BookshelfBasePlinth(isDark: widget.isDark),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Model representing each shelf tier data
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

// ============================================================================
// 1. TABLE TOP HEADER SECTION (PLANT, COFFEE CUP, JOURNAL & CONTROLS)
// ============================================================================

class _BookshelfTableTop extends StatelessWidget {
  final bool isDark;
  final Color goldAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final bool isFaceView;
  final ValueChanged<bool> onViewModeChanged;

  const _BookshelfTableTop({
    required this.isDark,
    required this.goldAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBg,
    required this.isFaceView,
    required this.onViewModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Decor objects sitting on top of the wooden slab
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Left: Potted Houseplant with trailing ivy/vine leaves
              const _PottedPlantWithVines(),

              const Spacer(),

              // Center: Subtle Dual View Switcher (Spines / Face View)
              _buildArrangementSwitcher(),

              const Spacer(),

              // Right: Coffee Cup & Hardbound Journal laying flat
              _CupAndJournalWidget(
                isDark: isDark,
                goldAccent: goldAccent,
              ),
            ],
          ),
        ),

        // Solid Wooden Tabletop Slab (Overhanging top board)
        Container(
          height: 14,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      const Color(0xFF5A3920),
                      const Color(0xFF3F2613),
                      const Color(0xFF261509),
                    ]
                  : [
                      const Color(0xFFD8B084),
                      const Color(0xFFB88C5E),
                      const Color(0xFF8C643D),
                    ],
            ),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: isDark ? 0.7 : 0.35,
                ),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Top bevel highlight line
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 1.5,
                child: Container(
                  color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.35),
                ),
              ),
              // Bottom underside shadow line
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 2,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArrangementSwitcher() {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E140C) : const Color(0xFFEADBC8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: goldAccent.withValues(alpha: isDark ? 0.35 : 0.5),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSwitcherOption(
            label: 'Spines',
            icon: Icons.view_headline_rounded,
            isSelected: !isFaceView,
            onTap: () {
              if (isFaceView) {
                onViewModeChanged(false);
              }
            },
          ),
          const SizedBox(width: 3),
          _buildSwitcherOption(
            label: 'Face View',
            icon: Icons.grid_view_rounded,
            isSelected: isFaceView,
            onTap: () {
              if (!isFaceView) {
                onViewModeChanged(true);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwitcherOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF382618) : const Color(0xFFC7A279))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: goldAccent.withValues(alpha: 0.8),
                  width: 0.9,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: goldAccent.withValues(alpha: 0.25),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? (isDark ? goldAccent : const Color(0xFF2C190B)) : textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? (isDark ? goldAccent : const Color(0xFF2C190B)) : textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// TABLETOP DECORATION 1: CERAMIC POTTED PLANT WITH TRAILING VINES
// ----------------------------------------------------------------------------

class _PottedPlantWithVines extends StatelessWidget {
  const _PottedPlantWithVines();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Trailing Ivy Vine Leaves spilling left
          Positioned(
            left: -10,
            bottom: 0,
            child: SizedBox(
              width: 50,
              height: 48,
              child: CustomPaint(
                painter: _TrailingVinePainter(),
              ),
            ),
          ),

          // Ceramic Plant Pot
          Positioned(
            left: 14,
            bottom: 0,
            child: Container(
              width: 38,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEDE3D3),
                    Color(0xFFDACBB7),
                    Color(0xFFB5A48F),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                  topLeft: Radius.circular(2),
                  topRight: Radius.circular(2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Pot Rim
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE4D5C2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lush Leaves Emerging from the Pot
          Positioned(
            left: 6,
            top: 2,
            child: SizedBox(
              width: 58,
              height: 38,
              child: CustomPaint(
                painter: _PlantLeavesPainter(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlantLeavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final leafPaint = Paint()..style = PaintingStyle.fill;
    final leafBorder = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = const Color(0xFF1E3A1A).withValues(alpha: 0.4);

    final leaves = [
      {'x': 18.0, 'y': 8.0, 'r': 7.5, 'color': const Color(0xFF4E7D3F)},
      {'x': 28.0, 'y': 4.0, 'r': 8.5, 'color': const Color(0xFF5E994D)},
      {'x': 38.0, 'y': 10.0, 'r': 8.0, 'color': const Color(0xFF3F6933)},
      {'x': 24.0, 'y': 16.0, 'r': 7.0, 'color': const Color(0xFF6DA858)},
      {'x': 36.0, 'y': 18.0, 'r': 7.5, 'color': const Color(0xFF48733A)},
      {'x': 12.0, 'y': 15.0, 'r': 6.5, 'color': const Color(0xFF5A8E47)},
    ];

    for (final leaf in leaves) {
      final center = Offset(leaf['x'] as double, leaf['y'] as double);
      final radius = leaf['r'] as double;
      leafPaint.color = leaf['color'] as Color;

      canvas.drawOval(
        Rect.fromCenter(center: center, width: radius * 2, height: radius * 1.5),
        leafPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: center, width: radius * 2, height: radius * 1.5),
        leafBorder,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrailingVinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = const Color(0xFF3D6132)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final leafPaint = Paint()..style = PaintingStyle.fill;

    // Curved stem trailing downwards
    final path = Path()
      ..moveTo(size.width - 6, 8)
      ..quadraticBezierTo(size.width - 18, 16, size.width - 24, 28)
      ..quadraticBezierTo(size.width - 32, 38, 4, 46);

    canvas.drawPath(path, stemPaint);

    // Trailing leaves along vine
    final trailingLeaves = [
      {'x': size.width - 16, 'y': 14.0, 'color': const Color(0xFF4C7B3C)},
      {'x': size.width - 26, 'y': 24.0, 'color': const Color(0xFF5B9448)},
      {'x': size.width - 32, 'y': 36.0, 'color': const Color(0xFF3C662F)},
      {'x': 10.0, 'y': 44.0, 'color': const Color(0xFF4D803D)},
    ];

    for (final leaf in trailingLeaves) {
      leafPaint.color = leaf['color'] as Color;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(leaf['x'] as double, leaf['y'] as double),
          width: 9,
          height: 6.5,
        ),
        leafPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------------------------------
// TABLETOP DECORATION 2: COFFEE MUG & HARDBOUND JOURNAL
// ----------------------------------------------------------------------------

class _CupAndJournalWidget extends StatelessWidget {
  final bool isDark;
  final Color goldAccent;

  const _CupAndJournalWidget({
    required this.isDark,
    required this.goldAccent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 48,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Hardbound Journal Book lying flat
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 56,
              height: 14,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1E3A2F),
                    Color(0xFF142921),
                    Color(0xFF0C1A14),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 3,
                    offset: const Offset(1, 1.5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Exposed cream page edge block on left
                  Positioned(
                    left: 2,
                    top: 2,
                    bottom: 2,
                    width: 4,
                    child: Container(
                      color: const Color(0xFFF3EBDF),
                    ),
                  ),
                  // Golden ribbon bookmark tail extending out
                  Positioned(
                    left: 6,
                    bottom: -3,
                    width: 4,
                    height: 7,
                    child: Container(
                      color: goldAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ceramic Coffee Cup / Stoneware Tumbler
          Positioned(
            right: 36,
            bottom: 2,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF5EFE6),
                    Color(0xFFDDD2C1),
                    Color(0xFFB5A795),
                  ],
                ),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 4,
                    offset: const Offset(1, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Ceramic top rim
                  Positioned(
                    top: 2,
                    left: 3,
                    right: 3,
                    height: 6,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A2E1B), // Coffee liquid surface
                        borderRadius: BorderRadius.circular(3),
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
}

// ============================================================================
// 2. SHELF TIER (WARM WOOD BACKBOARD + SCROLLABLE HARDCOVER BOOKS)
// ============================================================================

class _BookcaseShelfTier extends StatefulWidget {
  final CircularShelfRowData rowData;
  final int tierIndex;
  final int totalTiers;
  final bool isFaceView;
  final bool isDark;
  final Color goldAccent;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBg;
  final ValueChanged<Book> onBookTap;
  final ValueChanged<Book> onReadPressed;
  final ValueChanged<Book> onListenPressed;

  const _BookcaseShelfTier({
    super.key,
    required this.rowData,
    required this.tierIndex,
    required this.totalTiers,
    required this.isFaceView,
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
  State<_BookcaseShelfTier> createState() => _BookcaseShelfTierState();
}

class _BookcaseShelfTierState extends State<_BookcaseShelfTier> {
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

  void _showBookActionSheet(Book book) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BookQuickActionSheet(
        book: book,
        isDark: widget.isDark,
        goldAccent: widget.goldAccent,
        textPrimary: widget.textPrimary,
        textSecondary: widget.textSecondary,
        onReadPressed: () {
          Navigator.pop(ctx);
          widget.onReadPressed(book);
        },
        onListenPressed: () {
          Navigator.pop(ctx);
          widget.onListenPressed(book);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final books = widget.rowData.books;
    if (books.isEmpty) {
      return const SizedBox.shrink();
    }

    // Repeat items to fill shelf horizontal scrolling
    final displayBooks = <Book>[];
    final minCount = widget.isFaceView ? 10 : 16;
    while (displayBooks.length < minCount) {
      displayBooks.addAll(books);
    }

    // Construct shelf slots inserting a wooden partition barrier every 5 books
    final displaySlots = <_ShelfSlot>[];
    int barrierCount = 1;
    for (int i = 0; i < displayBooks.length; i++) {
      if (i > 0 && i % 5 == 0) {
        displaySlots.add(_ShelfSlot.barrier(barrierIndex: barrierCount++));
      }
      displaySlots.add(_ShelfSlot.book(book: displayBooks[i], bookIndex: i));
    }

    final shelfHeight = widget.isFaceView ? 190.0 : 172.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Shelf Cavity with Wood Backboard & Standing Books
        SizedBox(
          height: shelfHeight,
          child: Stack(
            children: [
              // 1. Warm Oak / Walnut Vertical Wood Planks Backing
              Positioned.fill(
                child: CustomPaint(
                  painter: _WoodBackboardPainter(isDark: widget.isDark),
                ),
              ),

              // 2. Top Cavity Cast Shadow
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 16,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(
                          alpha: widget.isDark ? 0.65 : 0.30,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Horizontal list of standing books and classification dividers
              ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: displaySlots.length,
                itemBuilder: (context, slotIndex) {
                  final slot = displaySlots[slotIndex];
                  if (slot.isBarrier) {
                    return _buildClassificationDivider(
                      barrierIndex: slot.barrierIndex,
                      isFaceView: widget.isFaceView,
                    );
                  }
                  final book = slot.book!;
                  return widget.isFaceView
                      ? _buildFaceCard(book: book, index: slot.bookIndex!)
                      : _buildBookSpine(book: book, index: slot.bookIndex!);
                },
              ),
            ],
          ),
        ),

        // Solid Horizontal Wooden Shelf Board separating rows
        _WoodenShelfDividerPlank(
          isDark: widget.isDark,
          goldAccent: widget.goldAccent,
          categoryTitle: widget.rowData.title,
        ),
      ],
    );
  }

  // ----------------- SECTION CLASSIFICATION DIVIDER (EVERY 5 BOOKS) -----------------

  Widget _buildClassificationDivider({
    required int barrierIndex,
    required bool isFaceView,
  }) {
    final romanNumerals = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'];
    final roman = romanNumerals[(barrierIndex - 1) % romanNumerals.length];

    final width = isFaceView ? 28.0 : 22.0;
    final height = isFaceView ? 166.0 : 152.0;

    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.bottomCenter,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: widget.isDark
                ? [
                    const Color(0xFF8A7A66),
                    const Color(0xFFB5A692),
                    const Color(0xFF6E6050),
                  ]
                : [
                    const Color(0xFFDCD2C3),
                    const Color(0xFFF0E8DC),
                    const Color(0xFFC4B8A6),
                  ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(2),
            topRight: Radius.circular(2),
          ),
          border: Border.all(
            color: Colors.black.withValues(alpha: 0.35),
            width: 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 4,
              offset: const Offset(1, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Top Grooved Crown Band
            Positioned(
              top: 10,
              left: 0,
              right: 0,
              height: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: Colors.black.withValues(alpha: 0.25),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),

            // Center Brass Classification Cartouche Plaque
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 6.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFE5C07B),
                      Color(0xFFC79E55),
                      Color(0xFF8A6830),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: const Color(0xFF5A4018),
                    width: 0.7,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 2.5,
                      offset: const Offset(0.5, 1),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '§',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF261805),
                        height: 1,
                      ),
                    ),
                    Text(
                      roman,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF261805),
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Grooved Band
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              height: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  border: Border.symmetric(
                    horizontal: BorderSide(
                      color: Colors.black.withValues(alpha: 0.25),
                      width: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------- STANDING BOOK SPINE (MATCHING REFERENCE IMAGE) -----------------

  Widget _buildBookSpine({
    required Book book,
    required int index,
  }) {
    final hash = (book.id.hashCode + index * 37).abs();
    final spineWidth = 36.0 + (hash % 4) * 4.0; // 36px - 48px
    final spineHeight = 146.0 + (hash % 3) * 6.0; // 146px - 158px

    // Exact classic leather/cloth palette from the reference image
    final List<List<Color>> palettes = [
      [const Color(0xFF481622), const Color(0xFF320E17), const Color(0xFF1B070C)], // Oxblood Maroon
      [const Color(0xFF142540), const Color(0xFF0C192E), const Color(0xFF060E1A)], // Navy Buckram
      [const Color(0xFF183B28), const Color(0xFF0F261A), const Color(0xFF08140E)], // Forest Green
      [const Color(0xFF3D2717), const Color(0xFF29180D), const Color(0xFF170C06)], // Warm Leather Brown
      [const Color(0xFFC7BBAA), const Color(0xFFA89A86), const Color(0xFF857765)], // Parchment Grey
      [const Color(0xFF202024), const Color(0xFF131316), const Color(0xFF09090B)], // Charcoal Obsidian
    ];

    final spineColors = palettes[hash % palettes.length];
    final isParchment = (hash % palettes.length) == 4;
    final titleColor = isParchment
        ? const Color(0xFF1A140F)
        : (widget.isDark ? const Color(0xFFF7F1E5) : const Color(0xFFFFF9EE));
    final goldFoilColor = isParchment
        ? const Color(0xFF6E5630)
        : const Color(0xFFE5C07B);

    return Container(
      width: spineWidth,
      margin: const EdgeInsets.symmetric(horizontal: 1.5),
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onTap: () => _showBookActionSheet(book),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Exposed Top Paper Head Block (Pages with cream rib lines)
            Container(
              width: spineWidth * 0.88,
              height: 5,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? const Color(0xFFE8DECF)
                    : const Color(0xFFF5EDE0),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(2),
                  topRight: Radius.circular(2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const CustomPaint(
                painter: _PaperLinesPainter(),
              ),
            ),

            // 2. Standing Hardcover Spine Body
            Container(
              height: spineHeight,
              width: spineWidth,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: spineColors,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  topRight: Radius.circular(3),
                ),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.35),
                  width: 0.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 4,
                    offset: const Offset(1.5, 3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Top Golden Crest / Emblem
                  Positioned(
                    top: 5,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Icon(
                        book.isPdf
                            ? Icons.picture_as_pdf_rounded
                            : Icons.auto_stories_rounded,
                        size: 9.5,
                        color: goldFoilColor.withValues(alpha: 0.9),
                      ),
                    ),
                  ),

                  // Top Gold Accent Stripe
                  Positioned(
                    top: 17,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1.8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            goldFoilColor.withValues(alpha: 0.3),
                            goldFoilColor,
                            goldFoilColor.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Vertical Spine Title (Serif, matching reference photo)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 2,
                      ),
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Center(
                          child: Text(
                            book.metadata.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: spineWidth < 38 ? 10.0 : 11.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: titleColor,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  blurRadius: 2,
                                  offset: const Offset(0.5, 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom Gold Accent Stripe
                  Positioned(
                    bottom: 14,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 1.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            goldFoilColor.withValues(alpha: 0.2),
                            goldFoilColor,
                            goldFoilColor.withValues(alpha: 0.2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------- FACE VIEW (STANDING 3D HARDCOVER BOOK) -----------------

  Widget _buildFaceCard({
    required Book book,
    required int index,
  }) {
    const bookWidth = 112.0;
    const bookHeight = 162.0;

    return Container(
      width: bookWidth + 8.0,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _showBookActionSheet(book),
        child: SizedBox(
          width: bookWidth,
          height: bookHeight + 8.0,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Contact Shadow
              Positioned(
                bottom: 1,
                left: 6,
                right: 4,
                height: 10,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: widget.isDark ? 0.75 : 0.35,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),

              // Fore-edge Paper Block
              Positioned(
                top: 3,
                bottom: 4,
                right: 0,
                width: 7,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.isDark
                          ? [const Color(0xFF7A6C58), const Color(0xFFB5A48C)]
                          : [const Color(0xFFA59278), const Color(0xFFD4C4AC)],
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(2),
                      bottomRight: Radius.circular(2),
                    ),
                  ),
                  child: const CustomPaint(
                    painter: _PaperLinesPainter(isHorizontal: true),
                  ),
                ),
              ),

              // Front Cover Board
              Positioned(
                top: 3,
                bottom: 4,
                left: 0,
                right: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: book.coverImageBytes != null
                      ? Image.memory(book.coverImageBytes!, fit: BoxFit.cover)
                      : Container(
                          color: widget.isDark
                              ? const Color(0xFF382315)
                              : const Color(0xFF8F6744),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                book.metadata.title,
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// WOODEN SHELF PLANK DIVIDER (BETWEEN ROWS)
// ----------------------------------------------------------------------------

class _WoodenShelfDividerPlank extends StatelessWidget {
  final bool isDark;
  final Color goldAccent;
  final String categoryTitle;

  const _WoodenShelfDividerPlank({
    required this.isDark,
    required this.goldAccent,
    required this.categoryTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF4A2F1A),
                  const Color(0xFF331F10),
                  const Color(0xFF1C1007),
                ]
              : [
                  const Color(0xFFC79E72),
                  const Color(0xFFA67B4F),
                  const Color(0xFF7A5432),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Top edge wood highlight
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 1.2,
            child: Container(
              color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.3),
            ),
          ),

          // Subtle Antique Brass Category Label Tag
          Positioned(
            left: 14,
            top: 2,
            bottom: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: goldAccent.withValues(alpha: 0.35),
                  width: 0.5,
                ),
              ),
              child: Center(
                child: Text(
                  categoryTitle,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: goldAccent.withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// BOOKCASE BASE PLINTH AND LEGS
// ----------------------------------------------------------------------------

class _BookshelfBasePlinth extends StatelessWidget {
  final bool isDark;

  const _BookshelfBasePlinth({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Foot Leg
          Container(
            width: 14,
            height: 16,
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF331F10), const Color(0xFF1C1007)]
                    : [const Color(0xFFA67B4F), const Color(0xFF6E4A2B)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(3),
                bottomRight: Radius.circular(3),
              ),
            ),
          ),

          // Base Plinth Rail
          Expanded(
            child: Container(
              height: 5,
              margin: const EdgeInsets.only(bottom: 11),
              color: isDark ? const Color(0xFF261509) : const Color(0xFF7A5432),
            ),
          ),

          // Right Foot Leg
          Container(
            width: 14,
            height: 16,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF331F10), const Color(0xFF1C1007)]
                    : [const Color(0xFFA67B4F), const Color(0xFF6E4A2B)],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(3),
                bottomRight: Radius.circular(3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// HELPER PAINTERS & QUICK ACTION MODAL
// ============================================================================

/// Backboard vertical wooden plank grain painter
class _WoodBackboardPainter extends CustomPainter {
  final bool isDark;

  const _WoodBackboardPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [
              const Color(0xFF1F130A),
              const Color(0xFF150B04),
              const Color(0xFF100702),
            ]
          : [
              const Color(0xFFB5885C),
              const Color(0xFF9E7247),
              const Color(0xFF805A34),
            ],
    );
    canvas.drawRect(rect, Paint()..shader = bgGradient.createShader(rect));

    // Vertical plank lines
    final plankPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.35 : 0.18)
      ..strokeWidth = 1.0;

    for (double x = 40; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), plankPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WoodBackboardPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

/// Paper lines painter for fore-edge and top head block
class _PaperLinesPainter extends CustomPainter {
  final bool isHorizontal;

  const _PaperLinesPainter({this.isHorizontal = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = 0.55;

    if (isHorizontal) {
      for (double y = 2; y < size.height; y += 2.5) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else {
      for (double x = 2; x < size.width; x += 2.5) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PaperLinesPainter oldDelegate) =>
      oldDelegate.isHorizontal != isHorizontal;
}

/// Helper slot representation
class _ShelfSlot {
  final bool isBarrier;
  final Book? book;
  final int? bookIndex;
  final int barrierIndex;

  const _ShelfSlot.book({required this.book, required this.bookIndex})
      : isBarrier = false,
        barrierIndex = 0;

  const _ShelfSlot.barrier({required this.barrierIndex})
      : isBarrier = true,
        book = null,
        bookIndex = null;
}

/// Quick action modal sheet when tapping a book
class _BookQuickActionSheet extends StatelessWidget {
  final Book book;
  final bool isDark;
  final Color goldAccent;
  final Color textPrimary;
  final Color textSecondary;
  final VoidCallback onReadPressed;
  final VoidCallback onListenPressed;

  const _BookQuickActionSheet({
    required this.book,
    required this.isDark,
    required this.goldAccent,
    required this.textPrimary,
    required this.textSecondary,
    required this.onReadPressed,
    required this.onListenPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1711) : const Color(0xFFFFFBF5),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: goldAccent.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.7 : 0.25),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: textSecondary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 58,
                height: 82,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: book.coverImageBytes != null
                      ? Image.memory(book.coverImageBytes!, fit: BoxFit.cover)
                      : Container(
                          color: isDark
                              ? const Color(0xFF382A1B)
                              : const Color(0xFFE2D2BC),
                          child: Icon(Icons.book_rounded, color: goldAccent),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.metadata.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      book.metadata.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: goldAccent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        book.isPdf
                            ? 'PDF Document'
                            : (book.isScan ? 'OCR Scan' : 'EPUB Book'),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: goldAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Read',
                  icon: Icons.menu_book_rounded,
                  color: goldAccent,
                  isPrimary: false,
                  onTap: onReadPressed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  label: 'Listen',
                  icon: Icons.headphones_rounded,
                  color: goldAccent,
                  isPrimary: true,
                  onTap: onListenPressed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isPrimary
              ? color
              : color.withValues(alpha: isDark ? 0.16 : 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color,
            width: 1.2,
          ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary ? Colors.black : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isPrimary ? Colors.black : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
