import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:epub_audio/core/errors/epub_exceptions.dart';
import 'package:epub_audio/features/epub/data/datasources/epub_archive_loader.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List createMockZip(Map<String, String> files) {
  final archive = Archive();
  files.forEach((name, content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  final encoder = ZipEncoder();
  final zipData = encoder.encode(archive);
  return Uint8List.fromList(zipData!);
}

void main() {
  group('EpubArchiveLoader', () {
    const loader = EpubArchiveLoader();

    test('successfully extracts valid zip archive into EpubArchive', () async {
      final zipBytes = createMockZip({
        'mimetype': 'application/epub+zip',
        'META-INF/container.xml': '<container/>',
        'OEBPS/content.opf': '<package/>',
      });

      final archive = await loader.loadFromBytes(zipBytes);

      expect(archive.length, 3);
      expect(archive.hasFile('mimetype'), isTrue);
      expect(archive.hasFile('META-INF/container.xml'), isTrue);
      expect(archive.hasFile('OEBPS/content.opf'), isTrue);
      expect(archive.readText('mimetype'), 'application/epub+zip');
      expect(archive.readText('META-INF/container.xml'), '<container/>');
    });

    test('throws EpubInvalidArchiveException when given empty bytes', () async {
      expect(
        () => loader.loadFromBytes(Uint8List(0)),
        throwsA(isA<EpubInvalidArchiveException>()),
      );
    });

    test('throws EpubInvalidArchiveException when given corrupt/random bytes', () async {
      final badBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      expect(
        () => loader.loadFromBytes(badBytes),
        throwsA(isA<EpubInvalidArchiveException>()),
      );
    });

    test('throws EpubFileNotFoundException for non-existent path', () async {
      expect(
        () => loader.loadFromPath('/non/existent/path/book.epub'),
        throwsA(isA<EpubFileNotFoundException>()),
      );
    });
  });
}
