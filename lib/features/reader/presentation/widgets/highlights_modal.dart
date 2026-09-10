import 'package:epub_audio/features/reader/domain/entities/reader_preferences.dart';
import 'package:epub_audio/features/reader/domain/entities/text_highlight.dart';
import 'package:flutter/material.dart';

/// Modal bottom sheet displaying all saved highlights and notes for a book.
class HighlightsModal extends StatelessWidget {
  final List<TextHighlight> highlights;
  final ReaderPreferences preferences;
  final void Function(TextHighlight highlight)? onHighlightSelected;
  final void Function(TextHighlight highlight)? onHighlightDeleted;

  const HighlightsModal({
    super.key,
    required this.highlights,
    required this.preferences,
    this.onHighlightSelected,
    this.onHighlightDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final colors = preferences.colors;

    return Container(
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            children: [
              Icon(Icons.border_color_rounded, color: colors.accent, size: 22),
              const SizedBox(width: 8),
              Text(
                'Highlights & Notes (${highlights.length})',
                style: TextStyle(
                  color: colors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Highlights List or Empty State
          Expanded(
            child: highlights.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.highlight_rounded,
                          size: 48,
                          color: colors.secondaryText.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No highlights yet',
                          style: TextStyle(
                            color: colors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Select any text while reading to highlight or translate.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: highlights.length,
                    separatorBuilder: (ctx, i) => Divider(color: colors.divider, height: 16),
                    itemBuilder: (ctx, index) {
                      final h = highlights[index];
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          onHighlightSelected?.call(h);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Color Indicator Pill
                              Container(
                                width: 5,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: h.color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: h.color.withValues(alpha: 0.35),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Chapter ${h.chapterIndex + 1}',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: colors.text,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          _formatDate(h.createdAt),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colors.secondaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '"${h.selectedText}"',
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colors.text,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    if (h.note != null && h.note!.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: colors.background,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.notes_rounded, size: 14, color: colors.accent),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                h.note!,
                                                style: TextStyle(
                                                  color: colors.text,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Delete Button
                              IconButton(
                                icon: Icon(Icons.delete_outline_rounded, size: 18, color: colors.secondaryText),
                                tooltip: 'Delete highlight',
                                onPressed: () => onHighlightDeleted?.call(h),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
