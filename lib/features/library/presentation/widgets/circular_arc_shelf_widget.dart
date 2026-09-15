import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../epub/domain/entities/book.dart';

/// A realistic 3D Cylindrical Rotunda Bookshelf with toggleable Spine and Face Views.
///
/// Features:
/// - Vertically stacked curved mahogany/walnut wooden rotunda shelves with convex 3D arc lips.
/// - **Dual View Arrangement Switcher**:
///   - **Spine View**: Dense standing vertical leather/cloth book spines with embossed lettering and paper edge lines.
///   - **Face View**: Front cover showcase with cover art, 3D paper page block thickness, format badges, and direct Read / Listen actions.
/// - Independent horizontal circular rotation for each row using real-time 3D Matrix4
///   cylindrical perspective transformations.
/// - Interactive tap to inspect book details with quick [ Read ] and [ Listen ] actions.
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
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        // Cylindrical woodgrain rotunda background
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.isDark
              ? [
                  const Color(0xFF160F0A),
                  const Color(0xFF22160E),
                  const Color(0xFF1A110B),
                  const Color(0xFF100A06),
                ]
              : [
                  const Color(0xFFE8DAC7),
                  const Color(0xFFD4BEA2),
                  const Color(0xFFC4AB8E),
                  const Color(0xFFB39879),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.6 : 0.15),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Dual View Arrangement Switcher
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.goldAccent.withValues(alpha: 0.3),
                        widget.goldAccent.withValues(alpha: 0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.goldAccent.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.view_carousel_rounded,
                    size: 18,
                    color: widget.goldAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rotunda Cylindrical Library',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                          color: widget.textPrimary,
                        ),
                      ),
                      Text(
                        _isFaceView
                            ? 'Face View • Rotating 3D cover cards'
                            : 'Spine View • Revolving leather spines',
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _buildArrangementSwitcher(),
              ],
            ),
          ),

          // Cylindrical Stacked Shelf Tiers
          ...widget.rows.asMap().entries.map((entry) {
            final index = entry.key;
            final rowData = entry.value;
            return _RotundaCylinderShelfTier(
              key: ValueKey('rotunda_tier_${rowData.title}_${_isFaceView ? "face" : "spine"}_$index'),
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
          }),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildArrangementSwitcher() {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF221911) : const Color(0xFFDAC6AD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.goldAccent.withValues(alpha: widget.isDark ? 0.35 : 0.45),
          width: 0.9,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSwitcherOption(
            label: 'Spines',
            icon: Icons.view_headline_rounded,
            isSelected: !_isFaceView,
            onTap: () {
              if (_isFaceView) {
                HapticFeedback.selectionClick();
                setState(() => _isFaceView = false);
              }
            },
          ),
          const SizedBox(width: 2),
          _buildSwitcherOption(
            label: 'Face View',
            icon: Icons.grid_view_rounded,
            isSelected: _isFaceView,
            onTap: () {
              if (!_isFaceView) {
                HapticFeedback.selectionClick();
                setState(() => _isFaceView = true);
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
        decoration: BoxDecoration(
          color: isSelected
              ? (widget.isDark ? const Color(0xFF382A1B) : const Color(0xFFFAF2E6))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(
                  color: widget.goldAccent.withValues(alpha: 0.7),
                  width: 1,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: widget.goldAccent.withValues(alpha: 0.2),
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
              color: isSelected ? widget.goldAccent : widget.textSecondary,
            ),
            const SizedBox(width: 3.5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? widget.goldAccent : widget.textSecondary,
              ),
            ),
          ],
        ),
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

/// Each independent rotunda cylindrical curved shelf tier
class _RotundaCylinderShelfTier extends StatefulWidget {
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

  const _RotundaCylinderShelfTier({
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
  State<_RotundaCylinderShelfTier> createState() =>
      _RotundaCylinderShelfTierState();
}

class _RotundaCylinderShelfTierState extends State<_RotundaCylinderShelfTier> {
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

    // Repeat items to fill rotunda circular revolution
    final displayBooks = <Book>[];
    final minCount = widget.isFaceView ? 10 : 16;
    while (displayBooks.length < minCount) {
      displayBooks.addAll(books);
    }

    final tierHeight = widget.isFaceView ? 228.0 : 178.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tier Header Tag
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          child: Row(
            children: [
              Container(
                width: 3.5,
                height: 13,
                decoration: BoxDecoration(
                  color: widget.rowData.accentColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.rowData.title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'serif',
                  color: widget.textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: widget.rowData.accentColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  '${books.length} titles',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: widget.rowData.accentColor,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3D Revolving Rotunda Tier Viewport
        SizedBox(
          height: tierHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Woodgrain shelf back wall
              Positioned.fill(
                child: CustomPaint(
                  painter: _RotundaCurvedWoodPainter(
                    isDark: widget.isDark,
                    tierIndex: widget.tierIndex,
                  ),
                ),
              ),

              // 2. Horizontally scrollable books (Spines or Face cards)
              AnimatedBuilder(
                animation: _scrollController,
                builder: (context, child) {
                  return ListView.builder(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: displayBooks.length,
                    itemBuilder: (context, index) {
                      final book = displayBooks[index];
                      return widget.isFaceView
                          ? _buildRotundaFaceCard(book: book, index: index)
                          : _buildRotundaSpine(book: book, index: index);
                    },
                  );
                },
              ),

              // 3. Thick 3D Convex Wooden Shelf Ledge / Lip at bottom
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: CustomPaint(
                  size: const Size(double.infinity, 22),
                  painter: _RotundaCurvedLedgePainter(
                    isDark: widget.isDark,
                    goldAccent: widget.goldAccent,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  // ----------------- FACE VIEW CARD (Full Cover Showcase) -----------------

  Widget _buildRotundaFaceCard({
    required Book book,
    required int index,
  }) {
    const cardWidth = 126.0;
    const cardHeight = 196.0;

    double relativeOffset = 0.0;
    if (_scrollController.hasClients && _scrollController.position.haveDimensions) {
      final itemCenter = index * (cardWidth + 10.0) + (cardWidth / 2);
      final viewportCenter = _scrollController.offset + (_scrollController.position.viewportDimension / 2);
      relativeOffset = ((itemCenter - viewportCenter) / 260.0).clamp(-1.2, 1.2);
    }

    final rotationY = relativeOffset * 0.28; // 3D Cylindrical curve
    final scale = (1.0 - (relativeOffset.abs() * 0.08)).clamp(0.90, 1.03);
    final shadowOffset = relativeOffset * 8.0;

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.bottomCenter,
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0016)
          ..rotateY(rotationY)
          ..scaleByDouble(scale, scale, 1.0, 1.0),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _showBookActionSheet(book);
          },
          child: Container(
            height: cardHeight,
            decoration: BoxDecoration(
              color: widget.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isDark
                    ? const Color(0xFF382F24)
                    : const Color(0xFFDED3C2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: widget.isDark ? 0.5 : 0.16,
                  ),
                  blurRadius: 10,
                  offset: Offset(shadowOffset, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover Art Top
                  Expanded(
                    flex: 11,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (book.coverImageBytes != null)
                          Image.memory(
                            book.coverImageBytes!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildFaceCoverFallback(book),
                          )
                        else
                          _buildFaceCoverFallback(book),

                        // Format Badge
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4.5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: widget.goldAccent.withValues(alpha: 0.6),
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
                                fontSize: 8.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        // Light Sheen
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.16),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Title & Mini Action Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                    color: widget.isDark
                        ? const Color(0xFF1B140E)
                        : const Color(0xFFF7EFE4),
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
                            fontSize: 10.5,
                            color: widget.textPrimary,
                          ),
                        ),
                        Text(
                          book.metadata.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            color: widget.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
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

  Widget _buildFaceCoverFallback(Book book) {
    final hash = book.id.hashCode.abs();
    final List<List<Color>> palettes = [
      [const Color(0xFF4A1515), const Color(0xFF220808)],
      [const Color(0xFF162B47), const Color(0xFF0A1524)],
      [const Color(0xFF163821), const Color(0xFF091A0E)],
      [const Color(0xFF4A3418), const Color(0xFF24180A)],
      [const Color(0xFF252528), const Color(0xFF111114)],
    ];
    final colors = palettes[hash % palettes.length];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 22,
                color: widget.goldAccent.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 3),
              Text(
                book.metadata.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF7F1E6),
                ),
              ),
            ],
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
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2.5),
        decoration: BoxDecoration(
          color: widget.goldAccent.withValues(
            alpha: widget.isDark ? 0.18 : 0.14,
          ),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: widget.goldAccent.withValues(
              alpha: widget.isDark ? 0.4 : 0.35,
            ),
            width: 0.7,
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 10, color: widget.goldAccent),
                const SizedBox(width: 2.5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8.5,
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

  // ----------------- SPINE VIEW (Dense Vertical Spines) -----------------

  Widget _buildRotundaSpine({
    required Book book,
    required int index,
  }) {
    final hash = (book.id.hashCode + index * 37).abs();
    final spineWidth = 32.0 + (hash % 5) * 4.0; // 32px - 48px
    final spineHeight = 142.0 + (hash % 4) * 6.0; // 142px - 160px

    final List<List<Color>> palettes = widget.isDark
        ? [
            [const Color(0xFF6E1B1B), const Color(0xFF3F0D0D), const Color(0xFF220505)],
            [const Color(0xFF1E3A5F), const Color(0xFF0F1E33), const Color(0xFF080F1B)],
            [const Color(0xFF1F4A2C), const Color(0xFF0F2617), const Color(0xFF07140B)],
            [const Color(0xFF634A26), const Color(0xFF3B2B15), const Color(0xFF20170A)],
            [const Color(0xFF2E2E32), const Color(0xFF1C1C1E), const Color(0xFF0E0E10)],
            [const Color(0xFF7A4B1A), const Color(0xFF482B0D), const Color(0xFF291705)],
            [const Color(0xFFD6C8B2), const Color(0xFFB5A48B), const Color(0xFF8C7A62)],
          ]
        : [
            [const Color(0xFF8B2C2C), const Color(0xFF5E1B1B), const Color(0xFF3F0F0F)],
            [const Color(0xFF2B4D78), const Color(0xFF1B3352), const Color(0xFF0F2035)],
            [const Color(0xFF2E5E3E), const Color(0xFF1C3D27), const Color(0xFF0E2215)],
            [const Color(0xFF806236), const Color(0xFF564021), const Color(0xFF332512)],
            [const Color(0xFF3D3D42), const Color(0xFF252528), const Color(0xFF141416)],
            [const Color(0xFF9E652A), const Color(0xFF6B4319), const Color(0xFF3E250C)],
            [const Color(0xFFE8DCC9), const Color(0xFFC7B79E), const Color(0xFFA39176)],
          ];

    final spineColors = palettes[hash % palettes.length];
    final isParchment = (hash % palettes.length) == 6;
    final titleColor = isParchment
        ? const Color(0xFF1A140F)
        : (widget.isDark ? const Color(0xFFF7F1E5) : const Color(0xFFFFF9EE));
    final goldFoilColor = isParchment
        ? const Color(0xFF6E5630)
        : const Color(0xFFE5C07B);

    double relativeOffset = 0.0;
    if (_scrollController.hasClients && _scrollController.position.haveDimensions) {
      final itemCenter = index * (spineWidth + 4.0) + (spineWidth / 2);
      final viewportCenter = _scrollController.offset + (_scrollController.position.viewportDimension / 2);
      relativeOffset = ((itemCenter - viewportCenter) / 220.0).clamp(-1.2, 1.2);
    }

    final rotationY = relativeOffset * 0.32;
    final scale = (1.0 - (relativeOffset.abs() * 0.07)).clamp(0.91, 1.04);
    final lightingDarken = (relativeOffset.abs() * 0.35).clamp(0.0, 0.45);

    return Container(
      width: spineWidth,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      alignment: Alignment.bottomCenter,
      child: Transform(
        alignment: Alignment.bottomCenter,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0016)
          ..rotateY(rotationY)
          ..scaleByDouble(scale, scale, 1.0, 1.0),
        child: GestureDetector(
          onTap: () => _showBookActionSheet(book),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top page block paper edge
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
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: _PaperLinesPainter(),
                ),
              ),

              // Standing Book Spine
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
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                      offset: const Offset(1.5, 3),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Gold Rib bands
                    Positioned(
                      top: 14,
                      left: 0,
                      right: 0,
                      child: _buildGoldSpineBand(goldFoilColor),
                    ),
                    Positioned(
                      bottom: 18,
                      left: 0,
                      right: 0,
                      child: _buildGoldSpineBand(goldFoilColor),
                    ),

                    // Vertical Spine Title
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
                                fontSize: spineWidth < 36 ? 9.5 : 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
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

                    // Format indicator icon
                    Positioned(
                      top: 4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Icon(
                          book.isPdf
                              ? Icons.picture_as_pdf_rounded
                              : (book.isScan
                                  ? Icons.document_scanner_rounded
                                  : Icons.auto_stories_rounded),
                          size: 9,
                          color: goldFoilColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ),

                    // Ambient Darken
                    if (lightingDarken > 0)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withValues(alpha: lightingDarken),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoldSpineBand(Color goldColor) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            goldColor.withValues(alpha: 0.3),
            goldColor,
            goldColor.withValues(alpha: 0.3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for top paper page edges
class _PaperLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = 0.5;

    for (double x = 2; x < size.width; x += 2.5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for the curved wood back of the rotunda cylinder
class _RotundaCurvedWoodPainter extends CustomPainter {
  final bool isDark;
  final int tierIndex;

  _RotundaCurvedWoodPainter({
    required this.isDark,
    required this.tierIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: isDark
          ? [
              const Color(0xFF0F0A06),
              const Color(0xFF26190E),
              const Color(0xFF332213),
              const Color(0xFF26190E),
              const Color(0xFF0F0A06),
            ]
          : [
              const Color(0xFF947B5F),
              const Color(0xFFC7B093),
              const Color(0xFFDFCAB0),
              const Color(0xFFC7B093),
              const Color(0xFF947B5F),
            ],
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _RotundaCurvedWoodPainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.tierIndex != tierIndex;
}

/// Custom painter for the 3D convex curved wooden shelf lip/ledge
class _RotundaCurvedLedgePainter extends CustomPainter {
  final bool isDark;
  final Color goldAccent;

  _RotundaCurvedLedgePainter({
    required this.isDark,
    required this.goldAccent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final ledgeGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: isDark
          ? [
              const Color(0xFF4A341E),
              const Color(0xFF2D1E11),
              const Color(0xFF1A1109),
              const Color(0xFF0A0703),
            ]
          : [
              const Color(0xFFE8DAC7),
              const Color(0xFFBA9E7E),
              const Color(0xFF8F7457),
              const Color(0xFF5E4933),
            ],
    );

    final ledgePaint = Paint()..shader = ledgeGradient.createShader(rect);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 4, size.width, size.height - 4),
      const Radius.circular(4),
    );
    canvas.drawRRect(rrect, ledgePaint);

    final edgePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          goldAccent.withValues(alpha: isDark ? 0.6 : 0.8),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 3, size.width, 1.5))
      ..strokeWidth = 1.5;

    canvas.drawLine(const Offset(0, 4), Offset(size.width, 4), edgePaint);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isDark ? 0.7 : 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 2, size.width, 4), shadowPaint);
  }

  @override
  bool shouldRepaint(covariant _RotundaCurvedLedgePainter oldDelegate) =>
      oldDelegate.isDark != isDark || oldDelegate.goldAccent != goldAccent;
}

/// Interactive quick-action modal when a book spine/card is tapped in the rotunda
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
          // Handle
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: textSecondary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Book Details Header
          Row(
            children: [
              // Cover
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
                          color: isDark ? const Color(0xFF382A1B) : const Color(0xFFE2D2BC),
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
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: goldAccent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        book.isPdf ? 'PDF Document' : (book.isScan ? 'OCR Scan' : 'EPUB Book'),
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

          // Action Buttons
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
