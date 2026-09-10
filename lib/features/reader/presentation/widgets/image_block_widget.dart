import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/epub/domain/entities/content_nodes.dart';
import 'package:epub_audio/features/reader/domain/entities/reader_preferences.dart';
import 'package:flutter/material.dart';

/// Renders a standalone image block by loading raw bytes from the [Book] archive.
class ImageBlockWidget extends StatelessWidget {
  final ImageBlockNode node;
  final Book book;
  final ReaderThemeColors colors;

  const ImageBlockWidget({
    super.key,
    required this.node,
    required this.book,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = book.readAsset(node.fullPath);

    if (bytes == null || bytes.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.divider),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.broken_image_rounded, size: 40, color: colors.secondaryText),
            if (node.alt != null && node.alt!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                node.alt!,
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              bytes,
              width: node.width,
              height: node.height,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.broken_image_rounded,
                  size: 48,
                  color: colors.secondaryText,
                );
              },
            ),
          ),
          if (node.alt != null && node.alt!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              node.alt!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
