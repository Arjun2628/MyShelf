import 'package:epub_audio/core/utils/path_utils.dart';
import 'package:epub_audio/features/epub/domain/entities/chapter_content.dart';
import 'package:epub_audio/features/epub/domain/entities/content_nodes.dart';
import 'package:epub_audio/features/epub/domain/entities/epub_chapter.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

/// Parses raw XHTML/HTML chapter documents into normalized [ChapterContent] trees.
class XhtmlContentParser {
  const XhtmlContentParser();

  /// Converts an [EpubChapter] into a structured [ChapterContent] model.
  ChapterContent parseChapter(EpubChapter chapter) {
    final blocks = parseXhtml(chapter.rawXhtml, chapter.fullPath);
    return ChapterContent(
      chapterId: chapter.id,
      title: chapter.title,
      fullPath: chapter.fullPath,
      spineIndex: chapter.spineIndex,
      blocks: blocks,
    );
  }

  /// Parses raw XHTML string and resolves relative asset paths against [chapterFilePath].
  List<ContentBlockNode> parseXhtml(String xhtmlContent, String chapterFilePath) {
    if (xhtmlContent.trim().isEmpty) return const [];

    final document = html_parser.parse(xhtmlContent);
    final body = document.body ?? document.documentElement;
    if (body == null) return const [];

    final blocks = <ContentBlockNode>[];
    _parseBlockChildren(body.nodes, chapterFilePath, blocks);
    return blocks;
  }

  void _parseBlockChildren(
    List<dom.Node> nodes,
    String chapterFilePath,
    List<ContentBlockNode> output,
  ) {
    for (final node in nodes) {
      if (node is dom.Element) {
        final block = _parseElementAsBlock(node, chapterFilePath);
        if (block != null) {
          output.add(block);
        }
      } else if (node is dom.Text) {
        final text = node.text.trim();
        if (text.isNotEmpty) {
          output.add(
            ParagraphNode(
              spans: [TextSpanNode(text: text)],
            ),
          );
        }
      }
    }
  }

  ContentBlockNode? _parseElementAsBlock(
    dom.Element element,
    String chapterFilePath,
  ) {
    final tagName = element.localName?.toLowerCase();
    final anchorId = _extractAnchorId(element);

    // Skip non-visual tags
    if (tagName == 'script' ||
        tagName == 'style' ||
        tagName == 'head' ||
        tagName == 'noscript') {
      return null;
    }

    // 1. Headings (h1 - h6)
    if (tagName != null && RegExp(r'^h[1-6]$').hasMatch(tagName)) {
      final level = int.tryParse(tagName.substring(1)) ?? 1;
      final spans = _parseInlineChildren(element.nodes, chapterFilePath);
      if (spans.isEmpty) return null;
      return HeadingNode(level: level, spans: spans, anchorId: anchorId);
    }

    // 2. Paragraphs (<p>)
    if (tagName == 'p') {
      // Check if this paragraph contains exclusively a single image (no non-empty text around it)
      final hasOtherContent = element.nodes.any((n) {
        if (n is dom.Text && n.text.trim().isNotEmpty) return true;
        if (n is dom.Element && n.localName != 'img' && n.localName != 'image') return true;
        return false;
      });

      final imgChild = !hasOtherContent && element.children.length == 1 &&
              (element.children.first.localName == 'img' ||
                  element.children.first.localName == 'image')
          ? element.children.first
          : null;

      if (imgChild != null) {
        return _parseImageBlock(imgChild, chapterFilePath, anchorId: anchorId);
      }

      final spans = _parseInlineChildren(element.nodes, chapterFilePath);
      if (spans.isEmpty) return null;
      return ParagraphNode(spans: spans, anchorId: anchorId);
    }

    // 3. Blockquotes (<blockquote>)
    if (tagName == 'blockquote') {
      final subBlocks = <ContentBlockNode>[];
      _parseBlockChildren(element.nodes, chapterFilePath, subBlocks);
      if (subBlocks.isEmpty) {
        final spans = _parseInlineChildren(element.nodes, chapterFilePath);
        if (spans.isNotEmpty) {
          subBlocks.add(ParagraphNode(spans: spans));
        }
      }
      return BlockquoteNode(children: subBlocks, anchorId: anchorId);
    }

    // 4. Standalone Images (<img>, <image>)
    if (tagName == 'img' || tagName == 'image') {
      return _parseImageBlock(element, chapterFilePath, anchorId: anchorId);
    }

    // 5. Lists (<ul>, <ol>)
    if (tagName == 'ul' || tagName == 'ol') {
      final isOrdered = tagName == 'ol';
      final items = <ListItemNode>[];

      for (final li in element.children.where((c) => c.localName == 'li')) {
        final spans = _parseInlineChildren(li.nodes, chapterFilePath);
        final subLists = <ListBlockNode>[];
        for (final subListEl in li.children.where((c) => c.localName == 'ul' || c.localName == 'ol')) {
          final subListBlock = _parseElementAsBlock(subListEl, chapterFilePath);
          if (subListBlock is ListBlockNode) {
            subLists.add(subListBlock);
          }
        }
        items.add(ListItemNode(spans: spans, subLists: subLists));
      }

      if (items.isEmpty) return null;
      return ListBlockNode(isOrdered: isOrdered, items: items, anchorId: anchorId);
    }

    // 6. Horizontal Rule (<hr>)
    if (tagName == 'hr') {
      return DividerNode(anchorId: anchorId);
    }

    // 7. Preformatted Code (<pre>)
    if (tagName == 'pre') {
      final text = element.text;
      if (text.trim().isEmpty) return null;
      return CodeBlockNode(code: text, anchorId: anchorId);
    }

    // 8. Containers (<div>, <section>, <article>, <main>, <body>)
    if (tagName == 'div' ||
        tagName == 'section' ||
        tagName == 'article' ||
        tagName == 'main' ||
        tagName == 'body') {
      final subBlocks = <ContentBlockNode>[];
      _parseBlockChildren(element.nodes, chapterFilePath, subBlocks);
      if (subBlocks.isNotEmpty) {
        if (subBlocks.length == 1) return subBlocks.first;
        return BlockquoteNode(children: subBlocks, anchorId: anchorId);
      }

      // If div has no block elements, treat its text as a paragraph
      final spans = _parseInlineChildren(element.nodes, chapterFilePath);
      if (spans.isNotEmpty) {
        return ParagraphNode(spans: spans, anchorId: anchorId);
      }
      return null;
    }

    // Fallback: Parse inline spans as paragraph
    final spans = _parseInlineChildren(element.nodes, chapterFilePath);
    if (spans.isNotEmpty) {
      return ParagraphNode(spans: spans, anchorId: anchorId);
    }

    return null;
  }

  ImageBlockNode? _parseImageBlock(
    dom.Element imgElement,
    String chapterFilePath, {
    String? anchorId,
  }) {
    final src = imgElement.attributes['src'] ??
        imgElement.attributes['xlink:href'] ??
        imgElement.attributes['href'];
    if (src == null || src.trim().isEmpty) return null;

    final fullPath = EpubPathUtils.resolve(chapterFilePath, src);
    final alt = imgElement.attributes['alt'] ?? imgElement.attributes['title'];
    final width = double.tryParse(imgElement.attributes['width'] ?? '');
    final height = double.tryParse(imgElement.attributes['height'] ?? '');

    return ImageBlockNode(
      src: src,
      fullPath: fullPath,
      alt: alt,
      width: width,
      height: height,
      anchorId: anchorId ?? _extractAnchorId(imgElement),
    );
  }

  List<InlineSpanNode> _parseInlineChildren(
    List<dom.Node> nodes,
    String chapterFilePath, {
    bool isBold = false,
    bool isItalic = false,
    bool isUnderline = false,
    bool isStrikethrough = false,
    bool isCode = false,
    bool isSuperscript = false,
    bool isSubscript = false,
  }) {
    final spans = <InlineSpanNode>[];

    for (final node in nodes) {
      if (node is dom.Text) {
        final text = node.text;
        if (text.isNotEmpty) {
          spans.add(
            TextSpanNode(
              text: text,
              isBold: isBold,
              isItalic: isItalic,
              isUnderline: isUnderline,
              isStrikethrough: isStrikethrough,
              isCode: isCode,
              isSuperscript: isSuperscript,
              isSubscript: isSubscript,
            ),
          );
        }
      } else if (node is dom.Element) {
        final tag = node.localName?.toLowerCase();

        // Line break (<br>)
        if (tag == 'br') {
          spans.add(const TextSpanNode(text: '\n'));
          continue;
        }

        // Inline Image
        if (tag == 'img' || tag == 'image') {
          final src = node.attributes['src'] ??
              node.attributes['xlink:href'] ??
              node.attributes['href'];
          if (src != null && src.isNotEmpty) {
            final fullPath = EpubPathUtils.resolve(chapterFilePath, src);
            final alt = node.attributes['alt'];
            spans.add(InlineImageNode(src: src, fullPath: fullPath, alt: alt));
          }
          continue;
        }

        // Link (<a>)
        if (tag == 'a') {
          final href = node.attributes['href'] ?? '';
          String? targetPath;
          String? anchor;
          if (href.isNotEmpty) {
            if (href.contains('#')) {
              final parts = href.split('#');
              final pathPart = parts[0];
              anchor = parts.length > 1 ? parts[1] : null;
              targetPath = pathPart.isNotEmpty
                  ? EpubPathUtils.resolve(chapterFilePath, pathPart)
                  : chapterFilePath;
            } else {
              targetPath = EpubPathUtils.resolve(chapterFilePath, href);
            }
          }
          final innerSpans = _parseInlineChildren(
            node.nodes,
            chapterFilePath,
            isBold: isBold,
            isItalic: isItalic,
            isUnderline: isUnderline,
            isStrikethrough: isStrikethrough,
            isCode: isCode,
            isSuperscript: isSuperscript,
            isSubscript: isSubscript,
          );
          spans.add(
            LinkSpanNode(
              href: href,
              targetPath: targetPath,
              anchor: anchor,
              spans: innerSpans.isNotEmpty
                  ? innerSpans
                  : [TextSpanNode(text: node.text.isNotEmpty ? node.text : href)],
            ),
          );
          continue;
        }

        // Nested formatting flags
        final nextBold = isBold || tag == 'b' || tag == 'strong';
        final nextItalic = isItalic || tag == 'i' || tag == 'em' || tag == 'cite';
        final nextUnderline = isUnderline || tag == 'u' || tag == 'ins';
        final nextStrike = isStrikethrough || tag == 's' || tag == 'strike' || tag == 'del';
        final nextCode = isCode || tag == 'code' || tag == 'kbd' || tag == 'samp' || tag == 'tt';
        final nextSuper = isSuperscript || tag == 'sup';
        final nextSub = isSubscript || tag == 'sub';

        spans.addAll(
          _parseInlineChildren(
            node.nodes,
            chapterFilePath,
            isBold: nextBold,
            isItalic: nextItalic,
            isUnderline: nextUnderline,
            isStrikethrough: nextStrike,
            isCode: nextCode,
            isSuperscript: nextSuper,
            isSubscript: nextSub,
          ),
        );
      }
    }

    return _coalesceAdjacentTextSpans(spans);
  }

  /// Merges consecutive TextSpanNodes that have identical formatting.
  List<InlineSpanNode> _coalesceAdjacentTextSpans(List<InlineSpanNode> spans) {
    if (spans.length <= 1) return spans;

    final result = <InlineSpanNode>[];
    TextSpanNode? current;

    for (final span in spans) {
      if (span is TextSpanNode) {
        if (current == null) {
          current = span;
        } else if (_canMerge(current, span)) {
          current = current.copyWith(text: current.text + span.text);
        } else {
          result.add(current);
          current = span;
        }
      } else {
        if (current != null) {
          result.add(current);
          current = null;
        }
        result.add(span);
      }
    }

    if (current != null) {
      result.add(current);
    }

    return result;
  }

  bool _canMerge(TextSpanNode a, TextSpanNode b) {
    return a.isBold == b.isBold &&
        a.isItalic == b.isItalic &&
        a.isUnderline == b.isUnderline &&
        a.isStrikethrough == b.isStrikethrough &&
        a.isCode == b.isCode &&
        a.isSuperscript == b.isSuperscript &&
        a.isSubscript == b.isSubscript;
  }

  String? _extractAnchorId(dom.Element element) {
    final id = element.id;
    if (id.isNotEmpty) return id;

    final name = element.attributes['name'];
    if (name != null && name.isNotEmpty) return name;

    // Check if element has an immediate child <a id="..." name="...">
    final aChild = element.children.firstWhere(
      (c) => c.localName == 'a' && (c.id.isNotEmpty || c.attributes.containsKey('name')),
      orElse: () => dom.Element.tag('none'),
    );
    if (aChild.localName == 'a') {
      return aChild.id.isNotEmpty ? aChild.id : aChild.attributes['name'];
    }

    return null;
  }
}
