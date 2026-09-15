import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:flutter/material.dart';

/// Interactive 3D Book Cover Stage featuring 3D perspective tilt, page thickness depth,
/// spine shadow, and entrance animation.
class BookCover3DStage extends StatefulWidget {
  final Book book;
  final Color accentColor;
  final bool isDark;
  final String animationType;

  const BookCover3DStage({
    super.key,
    required this.book,
    required this.accentColor,
    required this.isDark,
    this.animationType = 'perspective_tilt',
  });

  @override
  State<BookCover3DStage> createState() => _BookCover3DStageState();
}

class _BookCover3DStageState extends State<BookCover3DStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _entranceAnim;
  double _dragRotationY = 0.0;
  double _dragRotationX = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _entranceAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entranceAnim,
      builder: (context, _) {
        final entranceScale = 0.88 + (_entranceAnim.value * 0.12);
        final entranceRotateY = (1.0 - _entranceAnim.value) * 0.45;
        final currentRotateY = -0.16 + entranceRotateY + _dragRotationY;
        final currentRotateX = 0.04 + _dragRotationX;

        return GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _dragRotationY = (_dragRotationY + details.delta.dx * 0.003).clamp(-0.35, 0.35);
              _dragRotationX = (_dragRotationX - details.delta.dy * 0.003).clamp(-0.20, 0.20);
            });
          },
          onPanEnd: (_) {
            setState(() {
              _dragRotationY = 0.0;
              _dragRotationX = 0.0;
            });
          },
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0016)
              ..rotateX(currentRotateX)
              ..rotateY(currentRotateY)
              ..scaleByDouble(entranceScale, entranceScale, entranceScale, 1.0),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Ground 3D Drop Shadow
                Positioned(
                  bottom: -18,
                  child: Container(
                    width: 170,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: widget.isDark ? 0.65 : 0.25),
                          blurRadius: 28,
                          spreadRadius: 4,
                          offset: const Offset(10, 8),
                        ),
                      ],
                    ),
                  ),
                ),

                // Pages Block Depth (Simulated Right Edge Pages)
                Positioned(
                  right: -10,
                  top: 4,
                  bottom: 4,
                  width: 14,
                  child: Transform(
                    alignment: Alignment.centerLeft,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.002)
                      ..rotateY(1.3),
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.isDark ? const Color(0xFFC7B8A5) : const Color(0xFFFAF2E6),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(3),
                          bottomRight: Radius.circular(3),
                        ),
                        border: Border.all(color: const Color(0xFF9E8A73), width: 0.5),
                      ),
                    ),
                  ),
                ),

                // Main Front Cover
                Container(
                  width: 180,
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isDark
                          ? [const Color(0xFF2C2218), const Color(0xFF140E0A)]
                          : [const Color(0xFFF3E5D5), const Color(0xFFD6C0A8)],
                    ),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.45),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: widget.isDark ? 0.5 : 0.18),
                        blurRadius: 18,
                        offset: const Offset(6, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Spine Shadow & Ridges Overlay
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: 12,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.45),
                                Colors.white.withValues(alpha: 0.15),
                                Colors.black.withValues(alpha: 0.25),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Ornamental Inner Border
                      Positioned.fill(
                        child: Container(
                          margin: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: widget.accentColor.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                        ),
                      ),

                      // Cover Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 20, 18, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  widget.book.metadata.language == 'ml'
                                      ? Icons.menu_book_rounded
                                      : Icons.auto_stories_rounded,
                                  size: 26,
                                  color: widget.accentColor,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: widget.accentColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    (widget.book.metadata.language ?? 'en').toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: widget.accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.book.metadata.title,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                    color: widget.isDark ? const Color(0xFFF7F2EB) : const Color(0xFF261D13),
                                    height: 1.2,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  widget.book.metadata.author,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: widget.isDark ? const Color(0xFFA89F93) : const Color(0xFF7A6E5F),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Bookmark Ribbon hint
                      Positioned(
                        right: 24,
                        top: 0,
                        child: Container(
                          width: 14,
                          height: 38,
                          decoration: BoxDecoration(
                            color: widget.accentColor,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(3),
                              bottomRight: Radius.circular(3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
      },
    );
  }
}
