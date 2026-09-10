import 'package:epub_audio/core/errors/epub_exceptions.dart';
import 'package:epub_audio/features/epub/data/datasources/epub_archive_loader.dart';
import 'package:epub_audio/features/epub/data/parsers/container_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import 'epub_archive_loader_test.dart';

void main() {
  group('ContainerParser', () {
    const parser = ContainerParser();
    const loader = EpubArchiveLoader();

    test('correctly parses standard container.xml with full-path', () async {
      const containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
    <rootfiles>
        <rootfile full-path="OEBPS/package.opf" media-type="application/oebps-package+xml"/>
    </rootfiles>
</container>''';

      final zipBytes = createMockZip({
        'META-INF/container.xml': containerXml,
      });

      final archive = await loader.loadFromBytes(zipBytes);
      final opfPath = parser.parseOpfPath(archive);

      expect(opfPath, 'OEBPS/package.opf');
    });

    test('handles container.xml with leading slashes and whitespace', () {
      const containerXml = '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
    <rootfiles>
        <rootfile full-path=" /OPS/content.opf " media-type="application/oebps-package+xml"/>
    </rootfiles>
</container>''';

      final opfPath = parser.parseOpfPathFromXml(containerXml);
      expect(opfPath, 'OPS/content.opf');
    });

    test('throws EpubContainerNotFoundException when container.xml is missing', () async {
      final zipBytes = createMockZip({
        'mimetype': 'application/epub+zip',
      });
      final archive = await loader.loadFromBytes(zipBytes);

      expect(
        () => parser.parseOpfPath(archive),
        throwsA(isA<EpubContainerNotFoundException>()),
      );
    });

    test('throws EpubInvalidContainerException when XML is invalid', () {
      expect(
        () => parser.parseOpfPathFromXml('<invalid>'),
        throwsA(isA<EpubInvalidContainerException>()),
      );
    });

    test('throws EpubInvalidContainerException when no rootfiles are found', () {
      const emptyContainer = '<container><rootfiles></rootfiles></container>';
      expect(
        () => parser.parseOpfPathFromXml(emptyContainer),
        throwsA(isA<EpubInvalidContainerException>()),
      );
    });
  });
}
