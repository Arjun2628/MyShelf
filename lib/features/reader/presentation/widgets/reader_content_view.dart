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
  final Map<int, GlobalKey> _paragraphKeys = {};

  @override
  void initState() {
    super.initState();
    _activeHighlights = List.from(widget.highlights);
    if (widget.activeParagraphIndex != null && widget.isPlaying) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToActiveParagraph(animate: false);
      });
    }
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

    if (widget.chapterIndex != oldWidget.chapterIndex ||
        widget.content != oldWidget.content) {
      _paragraphKeys.clear();
    }

    if (widget.activeParagraphIndex != null) {
      final paraChanged = widget.activeParagraphIndex != oldWidget.activeParagraphIndex;
      final playStarted = widget.isPlaying && !oldWidget.isPlaying;
      if (paraChanged || playStarted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToActiveParagraph(animate: true);
        });
      }
    }
  }

  void _scrollToActiveParagraph({bool animate = true}) {
    final activeIndex = widget.activeParagraphIndex;
    if (activeIndex == null) return;

    final key = _paragraphKeys[activeIndex];
    final targetContext = key?.currentContext;
    if (targetContext != null && targetContext.mounted) {
      if (animate) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeInOutCubic,
          alignment: 0.18,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        );
      } else {
        Scrollable.ensureVisible(
          targetContext,
          duration: Duration.zero,
          alignment: 0.18,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        );
      }
    }
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

              final itemKey = currentParaIdx != null
                  ? _paragraphKeys.putIfAbsent(currentParaIdx, () => GlobalKey())
                  : null;

              return Container(
                key: itemKey,
                child: InkWell(
                  onTap: currentParaIdx != null
                      ? () {
                          widget.onParagraphTapped?.call(currentParaIdx);
                        }
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  splashColor: colors.accent.withValues(alpha: 0.08),
                  highlightColor: colors.accent.withValues(alpha: 0.04),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: _buildBlockWidget(
                      context,
                      block,
                      colors,
                      isHighlight: isHighlight,
                    ),
                  ),
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

          // Row 2: Color Highlight Palette with smooth horizontal scroll & sleek chips
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.palette_outlined, size: 14, color: colors.secondaryText),
                    const SizedBox(width: 4),
                    Text(
                      'Highlight:',
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: TextHighlight.defaultColors.map((opt) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: opt.color.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: opt.color.withValues(alpha: 0.9),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: opt.color.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: opt.color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
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
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: TextHighlight.defaultColors.map((opt) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: GestureDetector(
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
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: opt.color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: opt.color.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              opt.name,
                              style: TextStyle(
                                color: colors.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
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
            isHighlight: isHighlight,
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
            isHighlight: isHighlight,
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
                        isHighlight: isHighlight,
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

  /// Builds inline spans with rich highlight and real-time TTS word-by-word highlighting that seamlessly spans across formatting boundaries.
  List<InlineSpan> _buildSpansWithHighlights(
    List<InlineSpanNode> nodes,
    ReaderThemeColors colors, {
    double? baseFontSize,
    Color? customTextColor,
    bool isHighlight = false,
  }) {
    final effectiveSize = baseFontSize ?? widget.preferences.fontSize;
    final effectiveTextColor = customTextColor ?? colors.text;

    // 1. Calculate plain text for the block and character offsets for each child span
    final StringBuffer blockBuffer = StringBuffer();
    final List<int> spanStartOffsets = [];
    for (final node in nodes) {
      spanStartOffsets.add(blockBuffer.length);
      blockBuffer.write(node.toPlainText());
    }
    final fullBlockText = blockBuffer.toString();

    // 2. Identify active spoken word range if this block is currently playing/highlighted
    int? activeWordStart;
    int? activeWordEnd;
    if (isHighlight && widget.charOffset != null && fullBlockText.isNotEmpty) {
      int offset = widget.charOffset!.clamp(0, fullBlockText.length);
      // Skip leading whitespaces if offset lands on a space
      while (offset < fullBlockText.length && RegExp(r'\s').hasMatch(fullBlockText[offset])) {
        offset++;
      }
      if (offset < fullBlockText.length) {
        int end = offset;
        while (end < fullBlockText.length && !RegExp(r'\s').hasMatch(fullBlockText[end])) {
          end++;
        }
        if (end > offset) {
          activeWordStart = offset;
          activeWordEnd = end;
        }
      }
    }

    // 3. Identify all user highlight ranges in fullBlockText
    final List<_HighlightRange> ranges = [];
    for (final h in _activeHighlights) {
      final target = h.selectedText.trim();
      if (target.isEmpty) continue;

      // 3a. Direct case-insensitive search
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

      // 3b. Regex whitespace-tolerant fallback
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

    if (ranges.isEmpty && activeWordStart == null) {
      return nodes
          .map((s) => _buildInlineSpan(
                s,
                colors,
                baseFontSize: effectiveSize,
                customTextColor: customTextColor,
              ))
          .toList();
    }

    // 4. For each node, split according to overlapping ranges and spoken word
    final List<InlineSpan> resultSpans = [];

    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final nodeStart = spanStartOffsets[i];
      final nodeText = node.toPlainText();
      final nodeEnd = nodeStart + nodeText.length;

      if (node is TextSpanNode) {
        final TextStyle baseStyle = TextStyle(
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

        // Collect all cut points within [0, nodeText.length]
        final Set<int> cutPoints = {0, nodeText.length};

        for (final r in ranges) {
          if (r.end > nodeStart && r.start < nodeEnd) {
            cutPoints.add((r.start - nodeStart).clamp(0, nodeText.length));
            cutPoints.add((r.end - nodeStart).clamp(0, nodeText.length));
          }
        }

        if (activeWordStart != null && activeWordEnd != null) {
          if (activeWordEnd > nodeStart && activeWordStart < nodeEnd) {
            cutPoints.add((activeWordStart - nodeStart).clamp(0, nodeText.length));
            cutPoints.add((activeWordEnd - nodeStart).clamp(0, nodeText.length));
          }
        }

        final sortedCuts = cutPoints.toList()..sort();

        for (int c = 0; c < sortedCuts.length - 1; c++) {
          final segLocalStart = sortedCuts[c];
          final segLocalEnd = sortedCuts[c + 1];
          if (segLocalEnd <= segLocalStart) continue;

          final segGlobalStart = nodeStart + segLocalStart;
          final segGlobalEnd = nodeStart + segLocalEnd;
          final segText = node.text.substring(segLocalStart, segLocalEnd);

          // Check if this segment is in active spoken word
          final isSpoken = activeWordStart != null &&
              activeWordEnd != null &&
              segGlobalEnd > activeWordStart &&
              segGlobalStart < activeWordEnd;

          // Check if this segment is in any user highlight
          Color? userHighlightColor;
          for (final r in ranges) {
            if (segGlobalEnd > r.start && segGlobalStart < r.end) {
              userHighlightColor = r.highlight.color;
              break;
            }
          }

          TextStyle segStyle = baseStyle;

          if (isSpoken) {
            segStyle = segStyle.copyWith(
              backgroundColor: userHighlightColor != null
                  ? colors.accent.withValues(alpha: 0.55)
                  : colors.accent.withValues(alpha: 0.38),
              color: colors.accent,
              fontWeight: FontWeight.w900,
            );
          } else if (userHighlightColor != null) {
            segStyle = segStyle.copyWith(
              backgroundColor: userHighlightColor.withValues(alpha: 0.50),
            );
          }

          resultSpans.add(TextSpan(text: segText, style: segStyle));
        }
      } else if (node is LinkSpanNode) {
        resultSpans.add(
          TextSpan(
            children: _buildSpansWithHighlights(
              node.spans,
              colors,
              baseFontSize: effectiveSize,
              customTextColor: colors.accent,
              isHighlight: isHighlight,
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
