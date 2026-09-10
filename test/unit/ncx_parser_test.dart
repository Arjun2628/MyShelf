import 'package:epub_audio/features/epub/data/parsers/ncx_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NcxParser', () {
    const parser = NcxParser();

    test('parses hierarchical navPoints with anchors', () {
      const ncxXml = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="nav1" playOrder="1">
      <navLabel><text>Chapter 1: The Beginning</text></navLabel>
      <content src="text/ch1.xhtml"/>
      <navPoint id="nav1_1" playOrder="2">
        <navLabel><text>Section 1.1</text></navLabel>
        <content src="text/ch1.xhtml#sec1"/>
      </navPoint>
    </navPoint>
    <navPoint id="nav2" playOrder="3">
      <navLabel><text>Chapter 2: The Journey</text></navLabel>
      <content src="text/ch2.xhtml"/>
    </navPoint>
  </navMap>
</ncx>''';

      final entries = parser.parse(ncxXml, 'OEBPS/toc.ncx');

      expect(entries.length, 2);
      expect(entries[0].title, 'Chapter 1: The Beginning');
      expect(entries[0].fullPath, 'OEBPS/text/ch1.xhtml');
      expect(entries[0].anchor, isNull);
      expect(entries[0].children.length, 1);

      final subItem = entries[0].children[0];
      expect(subItem.title, 'Section 1.1');
      expect(subItem.fullPath, 'OEBPS/text/ch1.xhtml');
      expect(subItem.anchor, 'sec1');

      expect(entries[1].title, 'Chapter 2: The Journey');
      expect(entries[1].fullPath, 'OEBPS/text/ch2.xhtml');

      // Test flatten
      final flattened = entries.expand((e) => e.flatten()).toList();
      expect(flattened.length, 3);
    });
  });
}
