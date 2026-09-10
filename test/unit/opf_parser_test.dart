import 'package:epub_audio/core/errors/epub_exceptions.dart';
import 'package:epub_audio/features/epub/data/parsers/opf_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OpfParser', () {
    const parser = OpfParser();

    test('parses metadata, manifest, spine and detects cover and TOC in EPUB 2', () {
      const opfXml = '''<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookId" version="2.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
    <dc:title>Chemmeen (ചെമ്മീൻ)</dc:title>
    <dc:creator>Thakazhi Sivasankara Pillai</dc:creator>
    <dc:language>ml</dc:language>
    <dc:identifier id="BookId">urn:uuid:12345-6789</dc:identifier>
    <meta name="cover" content="cover-image"/>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="cover-image" href="images/cover.jpg" media-type="image/jpeg"/>
    <item id="chapter1" href="text/ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="chapter2" href="text/ch2.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="chapter1"/>
    <itemref idref="chapter2"/>
  </spine>
</package>''';

      final data = parser.parse(opfXml, 'OEBPS/content.opf');

      expect(data.metadata.title, 'Chemmeen (ചെമ്മീൻ)');
      expect(data.metadata.author, 'Thakazhi Sivasankara Pillai');
      expect(data.metadata.language, 'ml');
      expect(data.metadata.identifier, 'urn:uuid:12345-6789');

      expect(data.manifest.length, 4);
      expect(data.manifest['chapter1']?.fullPath, 'OEBPS/text/ch1.xhtml');
      expect(data.manifest['cover-image']?.fullPath, 'OEBPS/images/cover.jpg');

      expect(data.spine.length, 2);
      expect(data.spine[0].idref, 'chapter1');
      expect(data.spine[0].fullPath, 'OEBPS/text/ch1.xhtml');
      expect(data.spine[1].idref, 'chapter2');

      expect(data.tocItem?.id, 'ncx');
      expect(data.coverItem?.id, 'cover-image');
    });

    test('parses EPUB 3 navigation document and cover-image properties', () {
      const opfXml = '''<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="pub-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>EPUB 3 Sample</dc:title>
    <dc:creator>Author One</dc:creator>
    <dc:creator>Author Two</dc:creator>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="cover" href="cover.png" media-type="image/png" properties="cover-image"/>
    <item id="c1" href="c1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="c1"/>
  </spine>
</package>''';

      final data = parser.parse(opfXml, 'content.opf');

      expect(data.metadata.title, 'EPUB 3 Sample');
      expect(data.metadata.author, 'Author One, Author Two');
      expect(data.tocItem?.id, 'nav');
      expect(data.coverItem?.id, 'cover');
      expect(data.spine.length, 1);
    });

    test('throws EpubOpfException on missing manifest or spine', () {
      const badOpf = '<package><metadata><title>Hi</title></metadata></package>';
      expect(() => parser.parse(badOpf, 'content.opf'), throwsA(isA<EpubOpfException>()));
    });
  });
}
