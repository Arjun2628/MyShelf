import 'package:meta/meta.dart';

/// Base abstract class for all normalized content nodes.
@immutable
abstract class ContentNode {
  const ContentNode();

  /// Plain text representation of this node.
  String toPlainText();
}

/// Base class for block-level elements (paragraphs, headings, blockquotes, images, lists).
abstract class ContentBlockNode extends ContentNode {
  final String? anchorId;

  const ContentBlockNode({this.anchorId});
}

/// Base class for inline elements within a block (text spans, links, inline images).
abstract class InlineSpanNode extends ContentNode {
  const InlineSpanNode();
}

/// Heading block (h1..h6).
class HeadingNode extends ContentBlockNode {
  final int level; // 1 to 6
  final List<InlineSpanNode> spans;

  const HeadingNode({
    required this.level,
    required this.spans,
    super.anchorId,
  });

  @override
  String toPlainText() => spans.map((s) => s.toPlainText()).join();

  @override
  String toString() => 'HeadingNode(h$level: "${toPlainText()}")';
}

/// Standard paragraph block.
class ParagraphNode extends ContentBlockNode {
  final List<InlineSpanNode> spans;

  const ParagraphNode({
    required this.spans,
    super.anchorId,
  });

  @override
  String toPlainText() => spans.map((s) => s.toPlainText()).join();

  @override
  String toString() => 'ParagraphNode("${toPlainText()}")';
}

/// Blockquote block.
class BlockquoteNode extends ContentBlockNode {
  final List<ContentBlockNode> children;

  const BlockquoteNode({
    required this.children,
    super.anchorId,
  });

  @override
  String toPlainText() => children.map((c) => c.toPlainText()).join('\n');

  @override
  String toString() => 'BlockquoteNode(children: ${children.length})';
}

/// Block-level standalone image.
class ImageBlockNode extends ContentBlockNode {
  final String src;
  final String fullPath;
  final String? alt;
  final double? width;
  final double? height;

  const ImageBlockNode({
    required this.src,
    required this.fullPath,
    this.alt,
    this.width,
    this.height,
    super.anchorId,
  });

  @override
  String toPlainText() => alt != null && alt!.isNotEmpty ? '[Image: $alt]' : '[Image]';

  @override
  String toString() => 'ImageBlockNode(fullPath: $fullPath, alt: "$alt")';
}

/// Single item within a list.
class ListItemNode extends ContentNode {
  final List<InlineSpanNode> spans;
  final List<ListBlockNode> subLists;

  const ListItemNode({
    required this.spans,
    this.subLists = const [],
  });

  @override
  String toPlainText() => spans.map((s) => s.toPlainText()).join();

  @override
  String toString() => 'ListItemNode("${toPlainText()}")';
}

/// List block (ordered `<ol>` or unordered `<ul>`).
class ListBlockNode extends ContentBlockNode {
  final bool isOrdered;
  final List<ListItemNode> items;

  const ListBlockNode({
    required this.isOrdered,
    required this.items,
    super.anchorId,
  });

  @override
  String toPlainText() => items
      .asMap()
      .entries
      .map((e) =>
          isOrdered ? '${e.key + 1}. ${e.value.toPlainText()}' : '• ${e.value.toPlainText()}')
      .join('\n');

  @override
  String toString() => 'ListBlockNode(ordered: $isOrdered, items: ${items.length})';
}

/// Horizontal divider (`<hr>`).
class DividerNode extends ContentBlockNode {
  const DividerNode({super.anchorId});

  @override
  String toPlainText() => '---';

  @override
  String toString() => 'DividerNode()';
}

/// Preformatted code block (`<pre><code>`).
class CodeBlockNode extends ContentBlockNode {
  final String code;

  const CodeBlockNode({
    required this.code,
    super.anchorId,
  });

  @override
  String toPlainText() => code;

  @override
  String toString() => 'CodeBlockNode(${code.length} chars)';
}

// ----------------- INLINE NODES -----------------

/// Rich text span with formatting styles.
class TextSpanNode extends InlineSpanNode {
  final String text;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool isStrikethrough;
  final bool isCode;
  final bool isSuperscript;
  final bool isSubscript;

  const TextSpanNode({
    required this.text,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
    this.isCode = false,
    this.isSuperscript = false,
    this.isSubscript = false,
  });

  TextSpanNode copyWith({
    String? text,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    bool? isStrikethrough,
    bool? isCode,
    bool? isSuperscript,
    bool? isSubscript,
  }) {
    return TextSpanNode(
      text: text ?? this.text,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      isStrikethrough: isStrikethrough ?? this.isStrikethrough,
      isCode: isCode ?? this.isCode,
      isSuperscript: isSuperscript ?? this.isSuperscript,
      isSubscript: isSubscript ?? this.isSubscript,
    );
  }

  @override
  String toPlainText() => text;

  @override
  String toString() => 'TextSpanNode("$text", b: $isBold, i: $isItalic)';
}

/// Hyperlink span (`<a href="...">`).
class LinkSpanNode extends InlineSpanNode {
  final String href;
  final String? targetPath;
  final String? anchor;
  final List<InlineSpanNode> spans;

  const LinkSpanNode({
    required this.href,
    required this.spans,
    this.targetPath,
    this.anchor,
  });

  @override
  String toPlainText() => spans.map((s) => s.toPlainText()).join();

  @override
  String toString() => 'LinkSpanNode(href: "$href", text: "${toPlainText()}")';
}

/// Inline image (`<img>` inside a line of text).
class InlineImageNode extends InlineSpanNode {
  final String src;
  final String fullPath;
  final String? alt;

  const InlineImageNode({
    required this.src,
    required this.fullPath,
    this.alt,
  });

  @override
  String toPlainText() => alt != null && alt!.isNotEmpty ? '[$alt]' : '[Image]';

  @override
  String toString() => 'InlineImageNode(fullPath: $fullPath)';
}
