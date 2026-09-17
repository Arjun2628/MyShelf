import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modal bottom sheet for inspecting a pulled book with rich reading and listening actions.
class BookExplorationInspectionSheet extends StatelessWidget {
  final Book book;
  final VoidCallback? onRead;
  final VoidCallback? onListen;
  final VoidCallback? onInspect3D;

  const BookExplorationInspectionSheet({
    super.key,
    required this.book,
    this.onRead,
    this.onListen,
    this.onInspect3D,
  });

  static Future<void> show(
    BuildContext context, {
    required Book book,
    VoidCallback? onRead,
    VoidCallback? onListen,
    VoidCallback? onInspect3D,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookExplorationInspectionSheet(
        book: book,
        onRead: onRead,
        onListen: onListen,
        onInspect3D: onInspect3D,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const goldAccent = Color(0xFFD4AF37);
    final cardBg = isDark ? const Color(0xFF1E1914) : const Color(0xFFFAF6F0);
    final textPrimary = isDark ? const Color(0xFFF9F5EC) : const Color(0xFF2B2015);
    final textSecondary = isDark ? const Color(0xFFC7BCAE) : const Color(0xFF6B5846);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: goldAccent.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle Pill
          Center(
            child: Container(
              width: 42,
              height: 4.5,
              decoration: BoxDecoration(
                color: goldAccent.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header: Category Badge & Close
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: goldAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: goldAccent.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_stories_rounded,
                      size: 13,
                      color: goldAccent,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'FEATURED',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: goldAccent,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                color: textSecondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Book Details Row (Cover + Info)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Card with Soft Drop Shadow & Gold Edge
              Container(
                width: 90,
                height: 135,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(2, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: book.coverImageBytes != null &&
                          book.coverImageBytes!.isNotEmpty
                      ? Image.memory(
                          book.coverImageBytes!,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: isDark
                              ? const Color(0xFF382A1E)
                              : const Color(0xFFDCC8B3),
                          child: Center(
                            child: Icon(
                              Icons.menu_book_rounded,
                              size: 36,
                              color: goldAccent.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),

              // Title, Author, Description & Badges
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
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${book.metadata.author}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: goldAccent,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Metadata chips
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _metaChip(
                          icon: Icons.format_list_numbered_rounded,
                          label: '${book.chapterCount} Chapters',
                          isDark: isDark,
                        ),
                        _metaChip(
                          icon: Icons.star_rounded,
                          label: '4.9 ★',
                          isDark: isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if ((book.metadata.description ?? '').isNotEmpty)
                      Text(
                        book.metadata.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: textSecondary,
                          height: 1.3,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action Buttons: Read Now & Listen Audiobook
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onRead?.call();
                  },
                  icon: const Icon(Icons.chrome_reader_mode_rounded, size: 18),
                  label: const Text(
                    'Read Book',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldAccent,
                    foregroundColor: const Color(0xFF1F170D),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onListen?.call();
                  },
                  icon: const Icon(Icons.headphones_rounded, size: 18),
                  label: const Text(
                    'Listen Audio',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: goldAccent,
                    side: const BorderSide(color: goldAccent, width: 1.4),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _metaChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C241B) : const Color(0xFFEBE0D2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFFD4AF37)),
          const SizedBox(width: 3.5),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFE2D6C5) : const Color(0xFF4A3828),
            ),
          ),
        ],
      ),
    );
  }
}
