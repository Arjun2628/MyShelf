import 'package:epub_audio/features/reader/domain/entities/reader_preferences.dart';
import 'package:epub_audio/features/reader/domain/entities/text_highlight.dart';
import 'package:flutter/material.dart';

/// Floating Contextual Toolbar for selected text in Reader.
class HighlightPickerMenu extends StatelessWidget {
  final ReaderPreferences preferences;
  final ValueChanged<HighlightColorOption> onColorSelected;
  final VoidCallback onTranslate;
  final VoidCallback onSpeak;
  final VoidCallback onCopy;

  const HighlightPickerMenu({
    super.key,
    required this.preferences,
    required this.onColorSelected,
    required this.onTranslate,
    required this.onSpeak,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final colors = preferences.colors;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.divider.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color Circles
            ...TextHighlight.defaultColors.map((opt) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: InkWell(
                  onTap: () => onColorSelected(opt),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: opt.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(width: 6),
            Container(width: 1, height: 20, color: colors.divider),
            const SizedBox(width: 6),

            // Translate Action
            IconButton(
              icon: Icon(Icons.translate_rounded, color: colors.accent, size: 20),
              tooltip: 'Translate',
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              onPressed: onTranslate,
            ),
            const SizedBox(width: 4),

            // Speak Action
            IconButton(
              icon: Icon(Icons.volume_up_rounded, color: colors.text, size: 20),
              tooltip: 'Pronounce / Speak',
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              onPressed: onSpeak,
            ),
            const SizedBox(width: 4),

            // Copy Action
            IconButton(
              icon: Icon(Icons.copy_rounded, color: colors.text, size: 18),
              tooltip: 'Copy',
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              onPressed: onCopy,
            ),
          ],
        ),
      ),
    );
  }
}
