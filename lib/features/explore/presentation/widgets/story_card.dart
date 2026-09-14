import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:flutter/material.dart';

/// Tall vertical Story Card with atmospheric gradient, quote highlight, and action tags.
class StoryCard extends StatelessWidget {
  final Book book;
  final VoidCallback? onTap;

  const StoryCard({
    super.key,
    required this.book,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accentColor = Color(0xFFD4A373);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF281F17), const Color(0xFF130E09)]
                : [const Color(0xFFFAF2E6), const Color(0xFFDFCCB6)],
          ),
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.35 : 0.2),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Atmospheric backdrop icon
              Positioned(
                right: -10,
                bottom: 40,
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 110,
                  color: accentColor.withValues(alpha: isDark ? 0.06 : 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'STORY SPOTLIGHT',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          book.metadata.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFFF7F1E8) : const Color(0xFF241B12),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.metadata.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFFA89F93) : const Color(0xFF7A6F62),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (book.metadata.description != null && book.metadata.description!.isNotEmpty)
                          Text(
                            '"${book.metadata.description!}"',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontStyle: FontStyle.italic,
                              color: isDark ? const Color(0xFFD4C8B8) : const Color(0xFF5A4F42),
                              height: 1.3,
                            ),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.touch_app_rounded, size: 13, color: accentColor),
                            const SizedBox(width: 4),
                            Text(
                              'Tap to open',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : const Color(0xFF3D3225),
                              ),
                            ),
                          ],
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
    );
  }
}
