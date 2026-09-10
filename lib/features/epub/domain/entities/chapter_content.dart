import 'package:epub_audio/features/epub/domain/entities/content_nodes.dart';
import 'package:meta/meta.dart';

/// Structured normalized content of a parsed EPUB chapter.
@immutable
class ChapterContent {
  final String chapterId;
  final String title;
  final String fullPath;
  final int spineIndex;
  final List<ContentBlockNode> blocks;

  const ChapterContent({
    required this.chapterId,
    required this.title,
    required this.fullPath,
    required this.spineIndex,
    required this.blocks,
  });

  /// Extracts complete sequential text of the chapter (useful for search, TTS, and AI processing).
  String get plainText => blocks.map((b) => b.toPlainText()).join('\n\n');

  /// Extracts readable text blocks suitable for paragraph-by-paragraph TTS narration.
  List<String> get paragraphsAsText {
    return blocks
        .map((b) => b.toPlainText().trim())
        .where((text) => text.isNotEmpty)
        .toList();
  }

  /// Locates the block index matching a specific anchor ID (for jumping to footnote or TOC bookmark).
  int? findBlockIndexByAnchor(String anchorId) {
    for (int i = 0; i < blocks.length; i++) {
      if (blocks[i].anchorId == anchorId) {
        return i;
      }
    }
    return null;
  }

  @override
  String toString() =>
      'ChapterContent(index: $spineIndex, title: "$title", blocks: ${blocks.length})';
}
