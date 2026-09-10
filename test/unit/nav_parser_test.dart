import 'package:epub_audio/features/epub/data/parsers/nav_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NavParser', () {
    const parser = NavParser();

    test('parses EPUB 3 navigation list with nested items', () {
      const navXhtml = '''<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <body>
    <nav epub:type="toc">
      <h1>Table of Contents</h1>
      <ol>
        <li><a href="ch1.xhtml">Part 1</a>
          <ol>
            <li><a href="ch1.xhtml#s1">Intro</a></li>
          </ol>
        </li>
        <li><a href="ch2.xhtml">Part 2</a></li>
      </ol>
    </nav>
  </body>
</html>''';

      final entries = parser.parse(navXhtml, 'EPUB/nav.xhtml');

      expect(entries.length, 2);
      expect(entries[0].title, 'Part 1');
      expect(entries[0].fullPath, 'EPUB/ch1.xhtml');
      expect(entries[0].children.length, 1);
      expect(entries[0].children[0].title, 'Intro');
      expect(entries[0].children[0].anchor, 's1');
      expect(entries[1].title, 'Part 2');
      expect(entries[1].fullPath, 'EPUB/ch2.xhtml');
    });
  });
}
