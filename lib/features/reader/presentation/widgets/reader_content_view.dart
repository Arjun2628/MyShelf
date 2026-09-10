import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/epub/domain/entities/chapter_content.dart';
import 'package:epub_audio/features/epub/domain/entities/content_nodes.dart';
import 'package:epub_audio/features/reader/domain/entities/reader_preferences.dart';
import 'package:epub_audio/features/reader/presentation/widgets/image_block_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Renders structured [ChapterContent] into styled Flutter widgets with real-time audio synchronization.
class ReaderContentView extends StatelessWidget {
  final ChapterContent content;
  final Book book;
  final ReaderPreferences preferences;
  final int? activeParagraphIndex;
  final void Function(int paragraphIndex)? onParagraphTapped;
  final void Function(LinkSpanNode link)? onLinkTapped;
  final ScrollController? scrollController;

  const ReaderContentView({
    super.key,
    required this.content,
    required this.book,
    required this.preferences,
    this.activeParagraphIndex,
    this.onParagraphTapped,
    this.onLinkTapped,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final colors = preferences.colors;

    final Map<int, int> blockIndexToParaIndex = {};
    int textParaCount = 0;
    for (int i = 0; i < content.blocks.length; i++) {
      final b = content.blocks[i];
      if (b is ParagraphNode || b is HeadingNode) {
        blockIndexToParaIndex[i] = textParaCount++;
      }
    }

    return SelectionArea(
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: preferences.horizontalPadding,
          vertical: 32,
        ),
        itemCount: content.blocks.length,
        itemBuilder: (context, index) {
          final block = content.blocks[index];
          final currentParaIdx = blockIndexToParaIndex[index];
          final isHighlight = activeParagraphIndex != null &&
              currentParaIdx != null &&
              activeParagraphIndex == currentParaIdx;

          return GestureDetector(
            onTap: currentParaIdx != null ? () => onParagraphTapped?.call(currentParaIdx) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: isHighlight
                  ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                  : EdgeInsets.zero,
              decoration: isHighlight
                  ? BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border(
                        left: BorderSide(color: colors.accent, width: 3.5),
                      ),
                    )
                  : null,
              child: _buildBlockWidget(context, block, colors),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBlockWidget(
    BuildContext context,
    ContentBlockNode block,
    ReaderThemeColors colors,
  ) {
    if (block is HeadingNode) {
      return _buildHeading(block, colors);
    } else if (block is ParagraphNode) {
      return _buildParagraph(block, colors);
    } else if (block is BlockquoteNode) {
      return _buildBlockquote(context, block, colors);
    } else if (block is ImageBlockNode) {
      return ImageBlockWidget(node: block, book: book, colors: colors);
    } else if (block is ListBlockNode) {
      return _buildListBlock(block, colors);
    } else if (block is DividerNode) {
      return Divider(color: colors.divider, height: 48, thickness: 1);
    } else if (block is CodeBlockNode) {
      return _buildCodeBlock(block, colors);
    }

    return const SizedBox.shrink();
  }

  Widget _buildHeading(HeadingNode heading, ReaderThemeColors colors) {
    double headingSize;
    FontWeight weight = FontWeight.w700;
    double topMargin = 28.0;
    double bottomMargin = 12.0;

    switch (heading.level) {
      case 1:
        headingSize = preferences.fontSize * 1.6;
        topMargin = 36.0;
        break;
      case 2:
        headingSize = preferences.fontSize * 1.35;
        break;
      case 3:
        headingSize = preferences.fontSize * 1.2;
        break;
      default:
        headingSize = preferences.fontSize * 1.1;
        weight = FontWeight.w600;
    }

    return Container(
      margin: EdgeInsets.only(top: topMargin, bottom: bottomMargin),
      child: Text.rich(
        TextSpan(
          children: heading.spans
              .map((s) => _buildInlineSpan(s, colors, baseFontSize: headingSize))
              .toList(),
        ),
        style: TextStyle(
          color: colors.text,
          fontSize: headingSize,
          fontWeight: weight,
          fontFamily: _getFontFamily(),
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildParagraph(ParagraphNode paragraph, ReaderThemeColors colors) {
    return Container(
      margin: EdgeInsets.only(bottom: preferences.fontSize * 0.8),
      child: Text.rich(
        TextSpan(
          children: paragraph.spans.map((s) => _buildInlineSpan(s, colors)).toList(),
        ),
        style: TextStyle(
          color: colors.text,
          fontSize: preferences.fontSize,
          height: preferences.lineHeight,
          fontFamily: _getFontFamily(),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildBlockquote(
    BuildContext context,
    BlockquoteNode blockquote,
    ReaderThemeColors colors,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border(
          left: BorderSide(color: colors.accent, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: blockquote.children
            .map((b) => _buildBlockWidget(context, b, colors))
            .toList(),
      ),
    );
  }

  Widget _buildListBlock(ListBlockNode listBlock, ReaderThemeColors colors) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: listBlock.items.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final prefix = listBlock.isOrdered ? '${idx + 1}.  ' : '•  ';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  prefix,
                  style: TextStyle(
                    color: colors.accent,
                    fontWeight: FontWeight.bold,
                    fontSize: preferences.fontSize,
                    fontFamily: _getFontFamily(),
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: item.spans.map((s) => _buildInlineSpan(s, colors)).toList(),
                    ),
                    style: TextStyle(
                      color: colors.text,
                      fontSize: preferences.fontSize,
                      height: preferences.lineHeight,
                      fontFamily: _getFontFamily(),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCodeBlock(CodeBlockNode codeBlock, ReaderThemeColors colors) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.divider),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(
          codeBlock.code,
          style: TextStyle(
            color: colors.text,
            fontFamily: 'monospace',
            fontSize: preferences.fontSize * 0.85,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  InlineSpan _buildInlineSpan(
    InlineSpanNode span,
    ReaderThemeColors colors, {
    double? baseFontSize,
  }) {
    final effectiveSize = baseFontSize ?? preferences.fontSize;

    if (span is TextSpanNode) {
      TextStyle style = TextStyle(
        color: colors.text,
        fontSize: span.isSuperscript || span.isSubscript
            ? effectiveSize * 0.75
            : effectiveSize,
        fontWeight: span.isBold ? FontWeight.bold : FontWeight.normal,
        fontStyle: span.isItalic ? FontStyle.italic : FontStyle.normal,
        decoration: _getTextDecoration(span),
        fontFamily: span.isCode ? 'monospace' : _getFontFamily(),
      );

      return TextSpan(text: span.text, style: style);
    } else if (span is LinkSpanNode) {
      return TextSpan(
        children: span.spans
            .map((s) => _buildInlineSpan(s, colors, baseFontSize: effectiveSize))
            .toList(),
        style: TextStyle(
          color: colors.accent,
          decoration: TextDecoration.underline,
          decorationColor: colors.accent.withValues(alpha: 0.6),
          fontFamily: _getFontFamily(),
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            onLinkTapped?.call(span);
          },
      );
    } else if (span is InlineImageNode) {
      final bytes = book.readAsset(span.fullPath);
      if (bytes != null && bytes.isNotEmpty) {
        return WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Image.memory(
              bytes,
              height: effectiveSize * 1.5,
              fit: BoxFit.contain,
            ),
          ),
        );
      }
      return TextSpan(text: span.toPlainText());
    }

    return TextSpan(text: span.toPlainText());
  }

  TextDecoration? _getTextDecoration(TextSpanNode span) {
    if (span.isUnderline && span.isStrikethrough) {
      return TextDecoration.combine([
        TextDecoration.underline,
        TextDecoration.lineThrough,
      ]);
    }
    if (span.isUnderline) return TextDecoration.underline;
    if (span.isStrikethrough) return TextDecoration.lineThrough;
    return null;
  }

  String? _getFontFamily() {
    switch (preferences.fontFamily) {
      case 'Serif':
        return 'Times New Roman';
      case 'Sans-Serif':
        return 'Helvetica Neue';
      case 'Monospace':
        return 'Courier';
      default:
        return null;
    }
  }
}
