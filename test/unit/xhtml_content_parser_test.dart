import 'package:epub_audio/features/epub/data/parsers/xhtml_content_parser.dart';
import 'package:epub_audio/features/epub/domain/entities/content_nodes.dart';
import 'package:epub_audio/features/epub/domain/entities/epub_chapter.dart';
import 'package:epub_audio/features/epub/domain/usecases/parse_chapter_content_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('XhtmlContentParser', () {
    const parser = XhtmlContentParser();
    const useCase = ParseChapterContentUseCase(parser: parser);

    test('parses headings, paragraphs, and inline formatting correctly', () {
      const xhtml = '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Chapter 1</title></head>
<body>
  <h1 id="intro">അദ്ധ്യായം ഒന്ന് (Chapter 1)</h1>
  <p>This is a <b>bold</b> and <i>italic</i> word with <u>underline</u> and <sup>superscript</sup>.</p>
  <hr/>
  <p id="p2">Second paragraph with <code>inline code</code>.</p>
</body>
</html>''';

      final chapter = EpubChapter(
        id: 'c1',
        title: 'Chapter 1',
        fullPath: 'OEBPS/text/ch1.xhtml',
        spineIndex: 0,
        rawXhtml: xhtml,
      );

      final content = useCase.execute(chapter);

      expect(content.blocks.length, 4);

      // Heading block
      final heading = content.blocks[0] as HeadingNode;
      expect(heading.level, 1);
      expect(heading.anchorId, 'intro');
      expect(heading.toPlainText(), 'അദ്ധ്യായം ഒന്ന് (Chapter 1)');

      // Paragraph 1
      final p1 = content.blocks[1] as ParagraphNode;
      expect(p1.spans.length, 9);
      expect((p1.spans[1] as TextSpanNode).text, 'bold');
      expect((p1.spans[1] as TextSpanNode).isBold, isTrue);
      expect((p1.spans[3] as TextSpanNode).text, 'italic');
      expect((p1.spans[3] as TextSpanNode).isItalic, isTrue);
      expect((p1.spans[5] as TextSpanNode).text, 'underline');
      expect((p1.spans[5] as TextSpanNode).isUnderline, isTrue);

      // Divider
      expect(content.blocks[2], isA<DividerNode>());

      // Paragraph 2
      final p2 = content.blocks[3] as ParagraphNode;
      expect(p2.anchorId, 'p2');
      expect(p2.toPlainText(), 'Second paragraph with inline code.');
    });

    test('parses standalone and inline images with resolved paths', () {
      const xhtml = '''<html><body>
  <p><img src="../images/scenery.jpg" alt="Sea View" width="400" height="300"/></p>
  <p>Here is an icon <img src="../icons/star.png" alt="Star"/> in the text.</p>
</body></html>''';

      final chapter = EpubChapter(
        id: 'c1',
        title: 'Ch 1',
        fullPath: 'OEBPS/text/ch1.xhtml',
        spineIndex: 0,
        rawXhtml: xhtml,
      );

      final content = parser.parseChapter(chapter);

      expect(content.blocks.length, 2);

      // Block Image
      final imgBlock = content.blocks[0] as ImageBlockNode;
      expect(imgBlock.fullPath, 'OEBPS/images/scenery.jpg');
      expect(imgBlock.alt, 'Sea View');
      expect(imgBlock.width, 400.0);
      expect(imgBlock.height, 300.0);

      // Inline Image inside paragraph
      final p = content.blocks[1] as ParagraphNode;
      expect(p.spans.any((s) => s is InlineImageNode), isTrue);
      final inlineImg = p.spans.firstWhere((s) => s is InlineImageNode) as InlineImageNode;
      expect(inlineImg.fullPath, 'OEBPS/icons/star.png');
    });

    test('parses hyperlinks with relative path and anchor resolution', () {
      const xhtml = '''<html><body>
  <p>See <a href="ch2.xhtml#footnote1">Chapter 2 footnote</a> for details.</p>
</body></html>''';

      final chapter = EpubChapter(
        id: 'c1',
        title: 'Ch 1',
        fullPath: 'OEBPS/text/ch1.xhtml',
        spineIndex: 0,
        rawXhtml: xhtml,
      );

      final content = parser.parseChapter(chapter);
      final p = content.blocks[0] as ParagraphNode;
      final link = p.spans.firstWhere((s) => s is LinkSpanNode) as LinkSpanNode;

      expect(link.targetPath, 'OEBPS/text/ch2.xhtml');
      expect(link.anchor, 'footnote1');
      expect(link.toPlainText(), 'Chapter 2 footnote');
    });

    test('parses ordered and unordered lists and blockquotes', () {
      const xhtml = '''<html><body>
  <blockquote>
    <p>A famous quote.</p>
  </blockquote>
  <ul>
    <li>First point</li>
    <li>Second point</li>
  </ul>
</body></html>''';

      final chapter = EpubChapter(
        id: 'c1',
        title: 'Ch 1',
        fullPath: 'ch1.xhtml',
        spineIndex: 0,
        rawXhtml: xhtml,
      );

      final content = parser.parseChapter(chapter);

      expect(content.blocks[0], isA<BlockquoteNode>());
      final listBlock = content.blocks[1] as ListBlockNode;
      expect(listBlock.isOrdered, isFalse);
      expect(listBlock.items.length, 2);
      expect(listBlock.items[0].toPlainText(), 'First point');
    });

    test('provides clean plainText and paragraphsAsText for TTS audio engine', () {
      const xhtml = '''<html><body>
  <h1>തലക്കെട്ട് (Heading)</h1>
  <p>ഒന്നാമത്തെ ഖണ്ഡിക (First paragraph text).</p>
  <p>രണ്ടാമത്തെ ഖണ്ഡിക (Second paragraph text).</p>
</body></html>''';

      final chapter = EpubChapter(
        id: 'c1',
        title: 'Ch 1',
        fullPath: 'ch1.xhtml',
        spineIndex: 0,
        rawXhtml: xhtml,
      );

      final content = parser.parseChapter(chapter);
      final paragraphs = content.paragraphsAsText;

      expect(paragraphs.length, 3);
      expect(paragraphs[0], 'തലക്കെട്ട് (Heading)');
      expect(paragraphs[1], 'ഒന്നാമത്തെ ഖണ്ഡിക (First paragraph text).');
      expect(paragraphs[2], 'രണ്ടാമത്തെ ഖണ്ഡിക (Second paragraph text).');
    });
  });
}
