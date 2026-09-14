import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:flutter/material.dart';

/// Card showing audiobook playback in progress with audio wave badge and resume trigger.
class ContinueListeningCard extends StatelessWidget {
  final Book book;
  final double progressPercent;
  final String durationText;
  final VoidCallback? onTap;

  const ContinueListeningCard({
    super.key,
    required this.book,
    this.progressPercent = 0.50,
    this.durationText = '12m left',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B1D28) : const Color(0xFFF4F6FB);
    final borderColor = isDark ? const Color(0xFF2C3246) : const Color(0xFFD6DFEF);
    final titleColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const accentColor = Color(0xFF38BDF8);

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
            // Mini audio cover with play button overlay
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 48,
                  height: 68,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF243048), const Color(0xFF111827)]
                          : [const Color(0xFFD8E4F8), const Color(0xFFB5CBEF)],
                    ),
                    border: Border.all(color: borderColor),
                  ),
                ),
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    size: 16,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
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
                      const Icon(Icons.headphones_rounded, size: 12, color: accentColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'AUDIOBOOK • $durationText',
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
                    book.metadata.author,
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
                      backgroundColor: isDark ? const Color(0xFF232B3E) : const Color(0xFFD4E1F5),
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
