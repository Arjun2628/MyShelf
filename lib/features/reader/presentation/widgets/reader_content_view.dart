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
  final int? charOffset;
  final bool isPlaying;
  final void Function(int paragraphIndex)? onParagraphTapped;
  final void Function(LinkSpanNode link)? onLinkTapped;
  final ScrollController? scrollController;

  const ReaderContentView({
    super.key,
    required this.content,
    required this.book,
    required this.preferences,
    this.activeParagraphIndex,
    this.charOffset,
    this.isPlaying = false,
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
            onTap: currentParaIdx != null
                ? () => onParagraphTapped?.call(currentParaIdx)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: isHighlight
                  ? const EdgeInsets.symmetric(vertical: 6)
                  : EdgeInsets.zero,
              padding: isHighlight
                  ? const EdgeInsets.fromLTRB(14, 10, 14, 10)
                  : EdgeInsets.zero,
              decoration: isHighlight
                  ? BoxDecoration(
                      color: colors.accent.withValues(
                          alpha: isPlaying ? 0.15 : 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isPlaying
                            ? colors.accent
                            : colors.accent.withValues(alpha: 0.6),
                        width: isPlaying ? 2.0 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: colors.accent.withValues(
                              alpha: isPlaying ? 0.18 : 0.06),
                          blurRadius: isPlaying ? 12 : 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isHighlight)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isPlaying
                                  ? colors.accent
                                  : colors.accent.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPlaying
                                      ? Icons.volume_up_rounded
                                      : Icons.pause_circle_filled_rounded,
                                  size: 13,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPlaying
                                      ? (charOffset != null && charOffset! > 0
                                          ? 'PLAYING FROM WORD'
                                          : 'PLAYING NOW')
                                      : (charOffset != null && charOffset! > 0
                                          ? 'PAUSED AT WORD'
                                          : 'PAUSED HERE'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildBlockWidget(context, block, colors,
                      isHighlight: isHighlight),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBlockWidget(
    BuildContext context,
    ContentBlockNode block,
    ReaderThemeColors colors, {
    bool isHighlight = false,
  }) {
    if (block is HeadingNode) {
      return _buildHeading(block, colors, isHighlight: isHighlight);
    } else if (block is ParagraphNode) {
      return _buildParagraph(block, colors, isHighlight: isHighlight);
    } else if (block is BlockquoteNode) {
      return _buildBlockquote(context, block, colors, isHighlight: isHighlight);
    } else if (block is ImageBlockNode) {
      return ImageBlockWidget(node: block, book: book, colors: colors);
    } else if (block is ListBlockNode) {
      return _buildListBlock(block, colors, isHighlight: isHighlight);
    } else if (block is DividerNode) {
      return Divider(color: colors.divider, height: 48, thickness: 1);
    } else if (block is CodeBlockNode) {
      return _buildCodeBlock(block, colors);
    }

    return const SizedBox.shrink();
  }

  Widget _buildHeading(
    HeadingNode heading,
    ReaderThemeColors colors, {
    bool isHighlight = false,
  }) {
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

    final textColor = isHighlight ? colors.accent : colors.text;

    return Container(
      margin: EdgeInsets.only(top: isHighlight ? 4 : topMargin, bottom: bottomMargin),
      child: Text.rich(
        TextSpan(
          children: heading.spans
              .map((s) => _buildInlineSpan(
                    s,
                    colors,
                    baseFontSize: headingSize,
                    customTextColor: isHighlight ? textColor : null,
                  ))
              .toList(),
        ),
        style: TextStyle(
          color: textColor,
          fontSize: headingSize,
          fontWeight: isHighlight ? FontWeight.w900 : weight,
          fontFamily: _getFontFamily(),
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildParagraph(
    ParagraphNode paragraph,
    ReaderThemeColors colors, {
    bool isHighlight = false,
  }) {
    final textColor = isHighlight ? colors.accent : colors.text;

    return Container(
      margin: EdgeInsets.only(bottom: isHighlight ? 4 : preferences.fontSize * 0.8),
      child: Text.rich(
        TextSpan(
          children: paragraph.spans
              .map((s) => _buildInlineSpan(
                    s,
                    colors,
                    customTextColor: isHighlight ? textColor : null,
                  ))
              .toList(),
        ),
        style: TextStyle(
          color: textColor,
          fontSize: preferences.fontSize,
          fontWeight: isHighlight ? FontWeight.w700 : FontWeight.normal,
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
    ReaderThemeColors colors, {
    bool isHighlight = false,
  }) {
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
            .map((b) => _buildBlockWidget(context, b, colors, isHighlight: isHighlight))
            .toList(),
      ),
    );
  }

  Widget _buildListBlock(
    ListBlockNode listBlock,
    ReaderThemeColors colors, {
    bool isHighlight = false,
  }) {
    final textColor = isHighlight ? colors.accent : colors.text;

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
                      children: item.spans
                          .map((s) => _buildInlineSpan(
                                s,
                                colors,
                                customTextColor: isHighlight ? textColor : null,
                              ))
                          .toList(),
                    ),
                    style: TextStyle(
                      color: textColor,
                      fontSize: preferences.fontSize,
                      fontWeight: isHighlight ? FontWeight.w700 : FontWeight.normal,
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
    Color? customTextColor,
  }) {
    final effectiveSize = baseFontSize ?? preferences.fontSize;
    final effectiveTextColor = customTextColor ?? colors.text;

    if (span is TextSpanNode) {
      TextStyle style = TextStyle(
        color: effectiveTextColor,
        fontSize: span.isSuperscript || span.isSubscript
            ? effectiveSize * 0.75
            : effectiveSize,
        fontWeight: customTextColor != null
            ? (span.isBold ? FontWeight.w900 : FontWeight.w700)
            : (span.isBold ? FontWeight.bold : FontWeight.normal),
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
