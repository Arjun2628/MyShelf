import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../epub/domain/entities/book.dart';

/// A high-fidelity 3D Spine Rack Carousel & Center Hardcover Showcase widget
/// matching the luxury Gallery Obsidian dark design.
///
/// Features:
/// - Continuous horizontal rack of 3D vertical book spines (~40px wide) with
///   leather/cloth textures, gold embossing, and bottom progress ribbons.
/// - The center active book is pulled out into a prominent 3D Hardcover Showcase
///   with 3D perspective rotation, 3D paper page block thickness, and realistic cast shadow.
/// - Auto-cycles / switches active book every 5 seconds.
/// - Smooth horizontal drag / snap gestures with haptic feedback.
/// - Metadata display below with subtitle, serif title, and author/year.
class SpineRack3dCarouselWidget extends StatefulWidget {
  final List<Book> books;
  final int initialIndex;
  final bool isDark;
  final Color goldAccent;
  final ValueChanged<Book>? onBookSelected;
  final ValueChanged<Book>? onReadPressed;
  final ValueChanged<Book>? onListenPressed;
  final VoidCallback? onExplorePressed;

  const SpineRack3dCarouselWidget({
    super.key,
    required this.books,
    this.initialIndex = 0,
    required this.isDark,
    required this.goldAccent,
    this.onBookSelected,
    this.onReadPressed,
    this.onListenPressed,
    this.onExplorePressed,
  });

  @override
  State<SpineRack3dCarouselWidget> createState() =>
      _SpineRack3dCarouselWidgetState();
}

class _SpineRack3dCarouselWidgetState extends State<SpineRack3dCarouselWidget> {
  late PageController _pageController;
  int _currentIndex = 0;
  Timer? _autoSwitchTimer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(
      0,
      widget.books.isEmpty ? 0 : widget.books.length - 1,
    );
    _pageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 0.52,
    );
    _startAutoSwitchTimer();
  }

  void _startAutoSwitchTimer() {
    _autoSwitchTimer?.cancel();
    if (widget.books.length <= 1) return;
    _autoSwitchTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted || !_pageController.hasClients || widget.books.length <= 1) {
        return;
      }
      final nextPage = (_currentIndex + 1) % widget.books.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void didUpdateWidget(covariant SpineRack3dCarouselWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.books.isNotEmpty && _currentIndex >= widget.books.length) {
      _currentIndex = widget.books.length - 1;
    }
    if (widget.books.length != oldWidget.books.length) {
      _startAutoSwitchTimer();
    }
  }

  @override
  void dispose() {
    _autoSwitchTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (index != _currentIndex && index >= 0 && index < widget.books.length) {
      setState(() {
        _currentIndex = index;
      });
      HapticFeedback.selectionClick();
      widget.onBookSelected?.call(widget.books[index]);
      _startAutoSwitchTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.books.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeBook = widget.books[_currentIndex];
    final title = activeBook.metadata.title;
    final author = activeBook.metadata.author;
    final isMalayalam =
        (activeBook.metadata.language ?? '').toLowerCase().contains('ml') ||
        activeBook.id.contains('chemmeen');
    final subtitle = isMalayalam
        ? 'മലയാള സാഹിത്യം • CLASSICS'
        : (activeBook.id.contains('alice')
            ? 'LEWIS CARROLL • VICTORIAN FANTASY'
            : (activeBook.metadata.description?.isNotEmpty == true
                ? activeBook.metadata.description!.toUpperCase()
                : 'ORIGINAL EDITION'));
    final year = isMalayalam
        ? '1956'
        : (activeBook.id.contains('alice') ? '1865' : '2024');

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Spine Rack & 3D Hardcover Showcase PageView Carousel
        SizedBox(
          height: 250,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background continuous rack shelf shadow line
              Positioned(
                bottom: 22,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        widget.isDark
                            ? Colors.black.withValues(alpha: 0.6)
                            : const Color(0xFFC4B8A5).withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              PageView.builder(
                controller: _pageController,
                itemCount: widget.books.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final book = widget.books[index];
                  final isCenter = index == _currentIndex;

                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double pageOffset = 0.0;
                      if (_pageController.position.haveDimensions) {
                        pageOffset = _pageController.page! - index;
                      } else {
                        pageOffset = (_currentIndex - index).toDouble();
                      }

                      final dist = pageOffset.abs().clamp(0.0, 2.0);
                      final scale = 1.0 - (dist * 0.14);
                      final opacity = (1.0 - (dist * 0.35)).clamp(0.4, 1.0);
                      final rotationY = (pageOffset * -0.28).clamp(-0.6, 0.6);

                      return Center(
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0018)
                            ..rotateY(rotationY)
                            ..scaleByDouble(scale, scale, 1.0, 1.0),
                          child: Opacity(
                            opacity: opacity,
                            child: isCenter
                                ? _buildCenter3dHardcover(book)
                                : _buildStandingSpine(book, index),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 2. Book Metadata Display (Subtitle, Title, Year / Author)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: widget.isDark
                      ? const Color(0xFF9499A5)
                      : const Color(0xFF7A6E5E),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'serif',
                  letterSpacing: -0.4,
                  color: widget.isDark
                      ? const Color(0xFFE4E0D8)
                      : const Color(0xFF1E1812),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                '$year / $author',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark
                      ? const Color(0xFFB0B5C0)
                      : const Color(0xFF6B5F4E),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds the center pulled-out 3D Hardcover Book Showcase
  Widget _buildCenter3dHardcover(Book book) {
    final spineColor = _getBookSpineColor(book);

    return GestureDetector(
      onTap: () => widget.onReadPressed?.call(book),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 3D Cast Drop Shadow
          Positioned(
            bottom: -10,
            child: Container(
              width: 130,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: widget.isDark ? 0.7 : 0.35,
                    ),
                    blurRadius: 18,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),

          // 3D Hardcover Body with Book Spine and Right Page Block Edge
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Book Spine Crease
              Container(
                width: 7,
                height: 194,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      spineColor.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.4),
                      spineColor,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3),
                    bottomLeft: Radius.circular(3),
                  ),
                ),
              ),

              // Front Cover Card
              Container(
                width: 132,
                height: 198,
                decoration: BoxDecoration(
                  color: spineColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(3),
                    bottomRight: Radius.circular(3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(3, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(3),
                    bottomRight: Radius.circular(3),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Cover Image or Styled Gradient Cover
                      if (book.coverImageBytes != null)
                        Image.memory(
                          book.coverImageBytes!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultCoverGraphic(book, spineColor),
                        )
                      else
                        _buildDefaultCoverGraphic(book, spineColor),

                      // Glossy Cover Light Reflection
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.16),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.25),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3D Right Paper Page Block (Simulating 3D page edges)
              Container(
                width: 9,
                height: 190,
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? const Color(0xFFD6CCA9)
                      : const Color(0xFFF9F5EA),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.18),
                    width: 0.6,
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(2),
                    bottomRight: Radius.circular(2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(3, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    12,
                    (i) => Container(
                      height: 0.8,
                      color: Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Default styled graphic cover for books without explicit cover image
  Widget _buildDefaultCoverGraphic(Book book, Color spineColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            spineColor,
            Color.lerp(spineColor, Colors.black, 0.45)!,
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Icon(
              book.isPdf
                  ? Icons.picture_as_pdf_rounded
                  : (book.isScan
                      ? Icons.document_scanner_rounded
                      : (book.isText
                          ? Icons.edit_note_rounded
                          : Icons.auto_stories_rounded)),
              color: widget.goldAccent.withValues(alpha: 0.8),
              size: 16,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                book.metadata.title,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: Color(0xFFF7F1E6),
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                width: 32,
                height: 1.2,
                color: widget.goldAccent,
              ),
            ],
          ),
          Text(
            book.metadata.author,
            style: TextStyle(
              fontSize: 10,
              color: const Color(0xFFF7F1E6).withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStandingSpine(Book book, int index) {
    final spineColor = _getBookSpineColor(book);

    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      },
      child: Container(
        width: 42,
        height: 184,
        margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.lerp(spineColor, Colors.white, 0.15)!,
            spineColor,
            Color.lerp(spineColor, Colors.black, 0.35)!,
          ],
        ),
        borderRadius: BorderRadius.circular(2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Left crease shadow
          Positioned(
            left: 2,
            top: 2,
            bottom: 2,
            child: Container(
              width: 1.5,
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),

          // Top page edge highlight
          Positioned(
            top: 0,
            left: 2,
            right: 2,
            child: Container(
              height: 2,
              color: const Color(0xFFFFFDF5).withValues(alpha: 0.7),
            ),
          ),

          // Spine vertical title text
          Center(
            child: RotatedBox(
              quarterTurns: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  book.metadata.title.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: const Color(0xFFF7F1E6).withValues(alpha: 0.92),
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 3,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),

          // Bottom continuous progress ribbon / accent bookmark
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: widget.goldAccent,
                boxShadow: [
                  BoxShadow(
                    color: widget.goldAccent.withValues(alpha: 0.5),
                    blurRadius: 4,
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



  Color _getBookSpineColor(Book book) {
    if (book.id.contains('chemmeen') ||
        book.metadata.title.contains('ചെമ്മീൻ')) {
      return const Color(0xFF8B2519); // Rich Crimson / Terracotta
    } else if (book.id.contains('alice')) {
      return const Color(0xFF2C4A6F); // Midnight Navy
    } else if (book.isPdf) {
      return const Color(0xFF8F3B3B); // Burgundy
    } else if (book.isScan) {
      return const Color(0xFF4A6B5D); // Emerald Sage
    } else if (book.isText) {
      return const Color(0xFFB47228); // Warm Amber
    }

    final hash = book.id.hashCode.abs();
    final palette = [
      const Color(0xFF7A3E2D),
      const Color(0xFF385566),
      const Color(0xFF8C5D38),
      const Color(0xFF4E6B56),
      const Color(0xFF6B4C72),
      const Color(0xFF8C4848),
    ];
    return palette[hash % palette.length];
  }
}
