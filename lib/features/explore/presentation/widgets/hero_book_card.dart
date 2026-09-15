import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:flutter/material.dart';

/// Interactive Hero Book card for Explore screen with 3D tilt, gradient badge, and rich metadata.
class HeroBookCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;
  final VoidCallback? onReadTap;
  final VoidCallback? onListenTap;

  const HeroBookCard({
    super.key,
    required this.book,
    this.onTap,
    this.onReadTap,
    this.onListenTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1914) : const Color(0xFFF7F1E7);
    final borderColor = isDark ? const Color(0xFF382F24) : const Color(0xFFE2D6C5);
    final titleColor = isDark ? const Color(0xFFF5EFE6) : const Color(0xFF2B2217);
    final subColor = isDark ? const Color(0xFFA89F91) : const Color(0xFF7A6E5F);
    final accentColor = const Color(0xFFD4A373);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Subtle background gradient
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentColor.withValues(alpha: isDark ? 0.22 : 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 3D perspective mini cover
                    _buildCoverPreview(accentColor, isDark),
                    const SizedBox(width: 14),
                    // Metadata & Actions
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              book.metadata.language == 'ml' ? 'മലയാളം • SPOTLIGHT' : 'FEATURED',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            book.metadata.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            book.metadata.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: subColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (book.metadata.description != null && book.metadata.description!.isNotEmpty)
                            Text(
                              book.metadata.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: subColor.withValues(alpha: 0.9),
                                height: 1.25,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: onReadTap ?? onTap,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: titleColor,
                                    side: BorderSide(color: borderColor),
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    minimumSize: const Size(0, 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(Icons.auto_stories_rounded, size: 13),
                                  label: const Text(
                                    'Read',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: onListenTap ?? onTap,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentColor,
                                    foregroundColor: const Color(0xFF1E140A),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    minimumSize: const Size(0, 32),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  icon: const Icon(Icons.headphones_rounded, size: 13),
                                  label: const Text(
                                    'Listen',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPreview(Color accent, bool isDark) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.002)
        ..rotateY(-0.12),
      child: Container(
        width: 95,
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF2C2218), const Color(0xFF18120B)]
                : [const Color(0xFFE8D7C3), const Color(0xFFC9B299)],
          ),
          border: Border.all(
            color: accent.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(4, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Spine highlight
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 8,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.white.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.2),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    book.metadata.language == 'ml' ? Icons.menu_book_rounded : Icons.auto_stories_rounded,
                    size: 20,
                    color: accent,
                  ),
                  Text(
                    book.metadata.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark ? const Color(0xFFF5EFE6) : const Color(0xFF2B2217),
                      height: 1.15,
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
}
