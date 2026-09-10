import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/epub/domain/entities/chapter_content.dart';
import 'package:epub_audio/features/epub/domain/entities/content_nodes.dart';
import 'package:epub_audio/features/reader/domain/entities/reader_preferences.dart';
import 'package:epub_audio/features/reader/domain/entities/text_highlight.dart';
import 'package:epub_audio/features/reader/presentation/widgets/image_block_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Renders structured [ChapterContent] into styled Flutter widgets with real-time audio synchronization and instant text selection actions.
class ReaderContentView extends StatefulWidget {
  final ChapterContent content;
  final Book book;
  final int chapterIndex;
  final ReaderPreferences preferences;
  final int? activeParagraphIndex;
  final int? charOffset;
  final bool isPlaying;
  final List<TextHighlight> highlights;
  final void Function(int paragraphIndex)? onParagraphTapped;
  final void Function(LinkSpanNode link)? onLinkTapped;
  final void Function(TextHighlight highlight)? onHighlightCreated;
  final void Function(String selectedText)? onTranslateRequested;
  final void Function(String selectedText)? onSpeakTextRequested;
  final ScrollController? scrollController;

  const ReaderContentView({
    super.key,
    required this.content,
    required this.book,
    this.chapterIndex = 0,
    required this.preferences,
    this.activeParagraphIndex,
    this.charOffset,
    this.isPlaying = false,
    this.highlights = const [],
    this.onParagraphTapped,
    this.onLinkTapped,
    this.onHighlightCreated,
    this.onTranslateRequested,
    this.onSpeakTextRequested,
    this.scrollController,
  });

  @override
  State<ReaderContentView> createState() => _ReaderContentViewState();
}

class _ReaderContentViewState extends State<ReaderContentView> {
  String _selectedText = '';
  late List<TextHighlight> _activeHighlights;

  @override
  void initState() {
    super.initState();
    _activeHighlights = List.from(widget.highlights);
  }

  @override
  void didUpdateWidget(covariant ReaderContentView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final Map<String, TextHighlight> map = {
      for (final h in _activeHighlights) h.id: h,
    };
    for (final h in widget.highlights) {
      map[h.id] = h;
    }
    _activeHighlights = map.values.toList();
  }

  void _applyHighlight(TextHighlight hl) {
    setState(() {
      _activeHighlights.add(hl);
      _selectedText = '';
    });
    widget.onHighlightCreated?.call(hl);
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.preferences.colors;

    final Map<int, int> blockIndexToParaIndex = {};
    int textParaCount = 0;
    for (int i = 0; i < widget.content.blocks.length; i++) {
      final b = widget.content.blocks[i];
      if (b is ParagraphNode || b is HeadingNode) {
        blockIndexToParaIndex[i] = textParaCount++;
      }
    }

    final hasSelection = _selectedText.trim().isNotEmpty;

    return Stack(
      children: [
        SelectionArea(
          onSelectionChanged: (SelectedContent? content) {
            final text = content?.plainText ?? '';
            if (text != _selectedText) {
              setState(() {
                _selectedText = text;
              });
            }
          },
          contextMenuBuilder: (BuildContext context, SelectableRegionState selectableRegionState) {
            final targetText = _selectedText.trim().isNotEmpty
                ? _selectedText.trim()
                : ((selectableRegionState as dynamic)._lastSelectedContent?.plainText ?? '');

            final buttonItems = <ContextMenuButtonItem>[
              ContextMenuButtonItem(
                label: 'Highlight',
                onPressed: () {
                  selectableRegionState.hideToolbar();
                  if (targetText.isNotEmpty) {
                    _showHighlightColorSheet(context, targetText);
                  }
                },
              ),
              ContextMenuButtonItem(
                label: 'Translate',
                onPressed: () {
                  selectableRegionState.hideToolbar();
                  if (targetText.isNotEmpty) {
                    widget.onTranslateRequested?.call(targetText);
                  }
                },
              ),
              ContextMenuButtonItem(
                label: 'Pronounce',
                onPressed: () {
                  selectableRegionState.hideToolbar();
                  if (targetText.isNotEmpty) {
                    widget.onSpeakTextRequested?.call(targetText);
                  }
                },
              ),
              ...selectableRegionState.contextMenuButtonItems,
            ];

            return AdaptiveTextSelectionToolbar.buttonItems(
              anchors: selectableRegionState.contextMenuAnchors,
              buttonItems: buttonItems,
            );
          },
          child: ListView.builder(
            controller: widget.scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: widget.preferences.horizontalPadding,
              vertical: 32,
            ),
            itemCount: widget.content.blocks.length,
            itemBuilder: (context, index) {
              final block = widget.content.blocks[index];
              final currentParaIdx = blockIndexToParaIndex[index];
              final isHighlight = widget.activeParagraphIndex != null &&
                  currentParaIdx != null &&
                  widget.activeParagraphIndex == currentParaIdx;

              return Container(
                margin: isHighlight
                    ? const EdgeInsets.symmetric(vertical: 4)
                    : EdgeInsets.zero,
                padding: isHighlight
                    ? const EdgeInsets.fromLTRB(12, 6, 12, 6)
                    : EdgeInsets.zero,
                decoration: isHighlight
                    ? BoxDecoration(
                        color: colors.accent.withValues(
                            alpha: widget.isPlaying ? 0.12 : 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border(
                          left: BorderSide(
                            color: colors.accent,
                            width: 4.0,
                          ),
                        ),
                      )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isHighlight)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: colors.accent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    widget.isPlaying
                                        ? Icons.volume_up_rounded
                                        : Icons.pause_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.isPlaying
                                        ? (widget.charOffset != null && widget.charOffset! > 0
                                            ? 'PLAYING FROM WORD'
                                            : 'PLAYING')
                                        : (widget.charOffset != null && widget.charOffset! > 0
                                            ? 'PAUSED AT WORD'
                                            : 'PAUSED'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
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
              );
            },
          ),
        ),

        // Floating Selection Action Bar (Always visible immediately on selection)
        AnimatedPositioned(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          left: 16,
          right: 16,
          bottom: hasSelection ? 16 : -120,
          child: _buildFloatingSelectionBar(colors),
        ),
      ],
    );
  }

  Widget _buildFloatingSelectionBar(ReaderThemeColors colors) {
    final cleanText = _selectedText.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.cardBackground.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.divider.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Actions (Translate, Pronounce, Copy, Close)
          Row(
            children: [
              Expanded(
                child: Text(
                  cleanText.length > 30 ? '${cleanText.substring(0, 30)}...' : cleanText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.secondaryText,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Translate Button
              TextButton.icon(
                icon: Icon(Icons.translate_rounded, size: 16, color: colors.accent),
                label: Text(
                  'Translate',
                  style: TextStyle(color: colors.accent, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  backgroundColor: colors.accent.withValues(alpha: 0.12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  widget.onTranslateRequested?.call(cleanText);
                },
              ),
              const SizedBox(width: 6),

              // Pronounce Button
              IconButton(
                icon: Icon(Icons.volume_up_rounded, size: 18, color: colors.text),
                tooltip: 'Pronounce',
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                onPressed: () {
                  widget.onSpeakTextRequested?.call(cleanText);
                },
              ),
              const SizedBox(width: 4),

              // Copy Button
              IconButton(
                icon: Icon(Icons.copy_rounded, size: 16, color: colors.text),
                tooltip: 'Copy',
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: cleanText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),

              // Close Selection
              IconButton(
                icon: Icon(Icons.close_rounded, size: 18, color: colors.secondaryText),
                tooltip: 'Clear Selection',
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(),
                onPressed: () {
                  setState(() {
                    _selectedText = '';
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 8),
          Divider(height: 1, color: colors.divider.withValues(alpha: 0.6)),
          const SizedBox(height: 8),

          // Row 2: Color Highlight Palette
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Highlight:',
                style: TextStyle(
                  color: colors.secondaryText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ...TextHighlight.defaultColors.map((opt) {
                return InkWell(
                  onTap: () {
                    final hl = TextHighlight(
                      id: 'hl_${DateTime.now().millisecondsSinceEpoch}',
                      bookId: widget.book.id,
                      chapterIndex: widget.chapterIndex,
                      selectedText: cleanText,
                      colorValue: opt.color.toARGB32(),
                      createdAt: DateTime.now(),
                    );
                    _applyHighlight(hl);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: opt.color.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: opt.color, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: opt.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          opt.name,
                          style: TextStyle(
                            color: colors.text,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  void _showHighlightColorSheet(BuildContext context, String selectedText) {
    final colors = widget.preferences.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: colors.divider),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.format_paint_rounded, size: 20, color: colors.accent),
                  const SizedBox(width: 8),
                  Text(
                    'Highlight Color',
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '"$selectedText"',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.secondaryText,
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: TextHighlight.defaultColors.map((opt) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      final hl = TextHighlight(
                        id: 'hl_${DateTime.now().millisecondsSinceEpoch}',
                        bookId: widget.book.id,
                        chapterIndex: widget.chapterIndex,
                        selectedText: selectedText,
                        colorValue: opt.color.toARGB32(),
                        createdAt: DateTime.now(),
                      );
                      _applyHighlight(hl);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: opt.color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.15),
                              width: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          opt.name,
                          style: TextStyle(
                            color: colors.text,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
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
      return ImageBlockWidget(node: block, book: widget.book, colors: colors);
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
        headingSize = widget.preferences.fontSize * 1.6;
        topMargin = 36.0;
        break;
      case 2:
        headingSize = widget.preferences.fontSize * 1.35;
        break;
      case 3:
        headingSize = widget.preferences.fontSize * 1.2;
        break;
      default:
        headingSize = widget.preferences.fontSize * 1.1;
        weight = FontWeight.w600;
    }

    final textColor = isHighlight ? colors.accent : colors.text;

    return Container(
      margin: EdgeInsets.only(top: isHighlight ? 4 : topMargin, bottom: bottomMargin),
      child: Text.rich(
        TextSpan(
          children: _buildSpansWithHighlights(
            heading.spans,
            colors,
            baseFontSize: headingSize,
            customTextColor: isHighlight ? textColor : null,
          ),
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
      margin: EdgeInsets.only(bottom: isHighlight ? 4 : widget.preferences.fontSize * 0.8),
      child: Text.rich(
        TextSpan(
          children: _buildSpansWithHighlights(
            paragraph.spans,
            colors,
            customTextColor: isHighlight ? textColor : null,
          ),
        ),
        style: TextStyle(
          color: textColor,
          fontSize: widget.preferences.fontSize,
          fontWeight: isHighlight ? FontWeight.w700 : FontWeight.normal,
          height: widget.preferences.lineHeight,
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
                    fontSize: widget.preferences.fontSize,
                    fontFamily: _getFontFamily(),
                  ),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: _buildSpansWithHighlights(
                        item.spans,
                        colors,
                        customTextColor: isHighlight ? textColor : null,
                      ),
                    ),
                    style: TextStyle(
                      color: textColor,
                      fontSize: widget.preferences.fontSize,
                      fontWeight: isHighlight ? FontWeight.w700 : FontWeight.normal,
                      height: widget.preferences.lineHeight,
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
            fontSize: widget.preferences.fontSize * 0.85,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  /// Builds inline spans with rich highlight background rendering that seamlessly spans across formatting boundaries.
  List<InlineSpan> _buildSpansWithHighlights(
    List<InlineSpanNode> nodes,
    ReaderThemeColors colors, {
    double? baseFontSize,
    Color? customTextColor,
  }) {
    final effectiveSize = baseFontSize ?? widget.preferences.fontSize;
    final effectiveTextColor = customTextColor ?? colors.text;

    if (_activeHighlights.isEmpty) {
      return nodes
          .map((s) => _buildInlineSpan(
                s,
                colors,
                baseFontSize: effectiveSize,
                customTextColor: customTextColor,
              ))
          .toList();
    }

    // 1. Calculate plain text for the block and character offsets for each child span
    final StringBuffer blockBuffer = StringBuffer();
    final List<int> spanStartOffsets = [];
    for (final node in nodes) {
      spanStartOffsets.add(blockBuffer.length);
      blockBuffer.write(node.toPlainText());
    }
    final fullBlockText = blockBuffer.toString();

    // 2. Identify all highlight ranges in fullBlockText
    final List<_HighlightRange> ranges = [];
    for (final h in _activeHighlights) {
      final target = h.selectedText.trim();
      if (target.isEmpty) continue;

      // 2a. Direct case-insensitive search
      final targetLower = target.toLowerCase();
      final fullLower = fullBlockText.toLowerCase();
      int startIdx = 0;
      bool foundDirect = false;
      while ((startIdx = fullLower.indexOf(targetLower, startIdx)) != -1) {
        ranges.add(_HighlightRange(
          start: startIdx,
          end: startIdx + target.length,
          highlight: h,
        ));
        startIdx += target.length;
        foundDirect = true;
      }

      // 2b. Regex whitespace-tolerant fallback
      if (!foundDirect) {
        final words = target.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
        if (words.isNotEmpty) {
          final pattern = words.map(RegExp.escape).join(r'\s+');
          try {
            final regex = RegExp(pattern, caseSensitive: false);
            for (final match in regex.allMatches(fullBlockText)) {
              ranges.add(_HighlightRange(
                start: match.start,
                end: match.end,
                highlight: h,
              ));
            }
          } catch (_) {}
        }
      }
    }

    if (ranges.isEmpty) {
      return nodes
          .map((s) => _buildInlineSpan(
                s,
                colors,
                baseFontSize: effectiveSize,
                customTextColor: customTextColor,
              ))
          .toList();
    }

    ranges.sort((a, b) => a.start.compareTo(b.start));

    // 3. For each node, split according to overlapping ranges
    final List<InlineSpan> resultSpans = [];

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final nodeStart = spanStartOffsets[i];
      final nodeText = node.toPlainText();
      final nodeEnd = nodeStart + nodeText.length;

      if (node is TextSpanNode) {
        final TextStyle style = TextStyle(
          color: effectiveTextColor,
          fontSize: node.isSuperscript || node.isSubscript
              ? effectiveSize * 0.75
              : effectiveSize,
          fontWeight: customTextColor != null
              ? (node.isBold ? FontWeight.w900 : FontWeight.w700)
              : (node.isBold ? FontWeight.bold : FontWeight.normal),
          fontStyle: node.isItalic ? FontStyle.italic : FontStyle.normal,
          decoration: _getTextDecoration(node),
          fontFamily: node.isCode ? 'monospace' : _getFontFamily(),
        );

        // Find ranges overlapping [nodeStart, nodeEnd]
        final overlappingRanges = <_HighlightRange>[];
        for (final r in ranges) {
          if (r.end > nodeStart && r.start < nodeEnd) {
            final localStart = (r.start - nodeStart).clamp(0, nodeText.length);
            final localEnd = (r.end - nodeStart).clamp(0, nodeText.length);
            if (localEnd > localStart) {
              overlappingRanges.add(_HighlightRange(
                start: localStart,
                end: localEnd,
                highlight: r.highlight,
              ));
            }
          }
        }

        if (overlappingRanges.isEmpty) {
          resultSpans.add(TextSpan(text: node.text, style: style));
        } else {
          overlappingRanges.sort((a, b) => a.start.compareTo(b.start));
          int cur = 0;
          for (final r in overlappingRanges) {
            if (r.start < cur) continue;
            if (r.start > cur) {
              resultSpans.add(TextSpan(
                text: node.text.substring(cur, r.start),
                style: style,
              ));
            }
            if (r.start >= cur && r.end <= node.text.length) {
              resultSpans.add(TextSpan(
                text: node.text.substring(r.start, r.end),
                style: style.copyWith(
                  backgroundColor: r.highlight.color.withValues(alpha: 0.50),
                ),
              ));
              cur = r.end;
            }
          }
          if (cur < node.text.length) {
            resultSpans.add(TextSpan(
              text: node.text.substring(cur),
              style: style,
            ));
          }
        }
      } else if (node is LinkSpanNode) {
        resultSpans.add(
          TextSpan(
            children: _buildSpansWithHighlights(
              node.spans,
              colors,
              baseFontSize: effectiveSize,
              customTextColor: colors.accent,
            ),
            style: TextStyle(
              color: colors.accent,
              decoration: TextDecoration.underline,
              decorationColor: colors.accent.withValues(alpha: 0.6),
              fontFamily: _getFontFamily(),
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                widget.onLinkTapped?.call(node);
              },
          ),
        );
      } else {
        resultSpans.add(_buildInlineSpan(
          node,
          colors,
          baseFontSize: effectiveSize,
          customTextColor: customTextColor,
        ));
      }
    }

    return resultSpans;
  }

  InlineSpan _buildInlineSpan(
    InlineSpanNode span,
    ReaderThemeColors colors, {
    double? baseFontSize,
    Color? customTextColor,
  }) {
    final effectiveSize = baseFontSize ?? widget.preferences.fontSize;
    final effectiveTextColor = customTextColor ?? colors.text;

    if (span is TextSpanNode) {
      final TextStyle style = TextStyle(
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
            widget.onLinkTapped?.call(span);
          },
      );
    } else if (span is InlineImageNode) {
      final bytes = widget.book.readAsset(span.fullPath);
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
    switch (widget.preferences.fontFamily) {
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

class _HighlightRange {
  final int start;
  final int end;
  final TextHighlight highlight;

  const _HighlightRange({
    required this.start,
    required this.end,
    required this.highlight,
  });
}
