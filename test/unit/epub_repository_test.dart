import 'package:epub_audio/features/epub/data/repositories/epub_repository_impl.dart';
import 'package:epub_audio/features/epub/domain/usecases/open_epub_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import 'epub_archive_loader_test.dart';

void main() {
  group('EpubRepository and OpenEpubUseCase End-to-End', () {
    const repository = EpubRepositoryImpl();
    const useCase = OpenEpubUseCase(repository);

    test('loads and builds complete Book model from EPUB 2 archive bytes', () async {
      final zipBytes = createMockZip({
        'mimetype': 'application/epub+zip',
        'META-INF/container.xml': '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''',
        'OEBPS/content.opf': '''<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="BookId" version="2.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Chemmeen</dc:title>
    <dc:creator>Thakazhi</dc:creator>
    <dc:language>ml</dc:language>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="ch1" href="text/ch1.xhtml" media-type="application/xhtml+xml"/>
    <item id="ch2" href="text/ch2.xhtml" media-type="application/xhtml+xml"/>
    <item id="cover" href="images/cover.jpg" media-type="image/jpeg"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="ch1"/>
    <itemref idref="ch2"/>
  </spine>
</package>''',
        'OEBPS/toc.ncx': '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="p1" playOrder="1">
      <navLabel><text>Chapter 1: The Sea</text></navLabel>
      <content src="text/ch1.xhtml"/>
    </navPoint>
    <navPoint id="p2" playOrder="2">
      <navLabel><text>Chapter 2: Karuthamma</text></navLabel>
      <content src="text/ch2.xhtml"/>
    </navPoint>
  </navMap>
</ncx>''',
        'OEBPS/text/ch1.xhtml': '<html><body><h1>Chapter 1</h1><p>The sea is calm.</p></body></html>',
        'OEBPS/text/ch2.xhtml': '<html><body><h1>Chapter 2</h1><p>Karuthamma watched.</p></body></html>',
        'OEBPS/images/cover.jpg': 'mock_jpeg_bytes_header',
      });

      final book = await useCase.fromBytes(zipBytes, bookId: 'chemmeen_01');

      expect(book.id, 'chemmeen_01');
      expect(book.metadata.title, 'Chemmeen');
      expect(book.metadata.author, 'Thakazhi');
      expect(book.metadata.language, 'ml');

      expect(book.chapterCount, 2);
      expect(book.toc.length, 2);
      expect(book.toc[0].title, 'Chapter 1: The Sea');
      expect(book.toc[1].title, 'Chapter 2: Karuthamma');

      // Test Chapter retrieval
      final chapter1 = book.getChapter(0);
      expect(chapter1.id, 'ch1');
      expect(chapter1.title, 'Chapter 1: The Sea');
      expect(chapter1.rawXhtml, contains('The sea is calm.'));

      final chapter2 = book.getChapter(1);
      expect(chapter2.id, 'ch2');
      expect(chapter2.title, 'Chapter 2: Karuthamma');
      expect(chapter2.rawXhtml, contains('Karuthamma watched.'));

      // Test Asset retrieval
      final coverBytes = book.readAsset('images/cover.jpg', baseFilePath: 'OEBPS/content.opf');
      expect(coverBytes, isNotNull);
    });
  });
}
