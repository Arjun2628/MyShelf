import 'package:epub_audio/core/utils/path_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EpubPathUtils', () {
    test('normalize removes redundant parts, leading slashes, and backslashes', () {
      expect(EpubPathUtils.normalize(r'OEBPS\text\..\images\cover.jpg'), 'OEBPS/images/cover.jpg');
      expect(EpubPathUtils.normalize('/META-INF/container.xml'), 'META-INF/container.xml');
      expect(EpubPathUtils.normalize('./OEBPS/content.opf'), 'OEBPS/content.opf');
      expect(EpubPathUtils.normalize('chapter%201.xhtml'), 'chapter 1.xhtml');
    });

    test('resolve resolves relative paths against base path', () {
      expect(
        EpubPathUtils.resolve('OEBPS/content.opf', 'toc.ncx'),
        'OEBPS/toc.ncx',
      );
      expect(
        EpubPathUtils.resolve('OEBPS/text/ch1.xhtml', '../images/pic.png'),
        'OEBPS/images/pic.png',
      );
      expect(
        EpubPathUtils.resolve('content.opf', 'chapter1.xhtml'),
        'chapter1.xhtml',
      );
    });

    test('getDirectory extracts directory in posix format', () {
      expect(EpubPathUtils.getDirectory('OEBPS/text/ch1.xhtml'), 'OEBPS/text');
      expect(EpubPathUtils.getDirectory('content.opf'), '');
    });
  });
}
