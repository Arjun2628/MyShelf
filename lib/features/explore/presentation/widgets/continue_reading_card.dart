import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:flutter/material.dart';

/// Card showing reading in progress with progress ring and resume trigger.
class ContinueReadingCard extends StatelessWidget {
  final Book book;
  final double progressPercent;
  final int currentChapter;
  final VoidCallback? onTap;

  const ContinueReadingCard({
    super.key,
    required this.book,
    this.progressPercent = 0.35,
    this.currentChapter = 1,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1A16) : const Color(0xFFFAF5EE);
    final borderColor = isDark ? const Color(0xFF382F24) : const Color(0xFFE2D6C5);
    final titleColor = isDark ? const Color(0xFFF5EFE6) : const Color(0xFF2B2217);
    final subColor = isDark ? const Color(0xFFA89F91) : const Color(0xFF7A6E5F);
    const accentColor = Color(0xFFD4A373);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 270,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Mini cover
            Container(
              width: 48,
              height: 68,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF2C2218), const Color(0xFF16110A)]
                      : [const Color(0xFFE5D5C2), const Color(0xFFC7B197)],
                ),
                border: Border.all(color: borderColor),
              ),
              child: const Icon(Icons.menu_book_rounded, size: 20, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bookmark_added_rounded, size: 12, color: accentColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'READING • ${(progressPercent * 100).toInt()}%',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    book.metadata.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Chapter $currentChapter of ${book.chapterCount}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, color: subColor),
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressPercent.clamp(0.0, 1.0),
                      minHeight: 3.5,
                      backgroundColor: isDark ? const Color(0xFF2A231C) : const Color(0xFFE0D2BF),
                      valueColor: const AlwaysStoppedAnimation<Color>(accentColor),
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
