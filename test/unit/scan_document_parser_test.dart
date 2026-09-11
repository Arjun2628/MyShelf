import 'dart:typed_data';
import 'package:epub_audio/features/scan/data/parsers/scan_document_parser.dart';
import 'package:epub_audio/features/scan/data/services/ocr_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScanDocumentParser Tests', () {
    late ScanDocumentParser parser;

    setUp(() {
      parser = ScanDocumentParser();
    });

    test('parses single page scan into a valid Book entity', () {
      final pages = [
        const ScannedPageData(
          pageNumber: 1,
          rawText: 'CHAPTER I\n\nIt was the best of times, it was the worst of times.',
        ),
      ];

      final book = parser.parse(
        pages: pages,
        bookId: 'scan_test_1',
        title: 'Tale of Two Cities (Page 1)',
        coverBytes: Uint8List.fromList([1, 2, 3, 4]),
      );

      expect(book.id, equals('scan_test_1'));
      expect(book.metadata.title, equals('Tale of Two Cities (Page 1)'));
      expect(book.metadata.author, equals('Photo Scan'));
      expect(book.isScan, isTrue);
      expect(book.isPdf, isFalse);
      expect(book.chapterCount, equals(1));
      expect(book.coverImageBytes, isNotNull);

      final chapter = book.getChapter(0);
      expect(chapter.title, equals('Tale of Two Cities (Page 1)'));
      expect(chapter.rawXhtml, contains('CHAPTER I'));
      expect(chapter.rawXhtml, contains('It was the best of times, it was the worst of times.'));
    });

    test('parses multiple pages into ordered chapters in spine and TOC', () {
      final pages = [
        const ScannedPageData(
          pageNumber: 2,
          rawText: 'Page 2 content with second paragraph.',
        ),
        const ScannedPageData(
          pageNumber: 1,
          rawText: 'Page 1 introductory text.',
        ),
      ];

      final book = parser.parse(
        pages: pages,
        bookId: 'scan_batch_1',
        title: 'Multi-Page Scan',
      );

      expect(book.chapterCount, equals(2));
      expect(book.toc.length, equals(2));

      final ch1 = book.getChapter(0);
      expect(ch1.title, equals('Page 1'));
      expect(ch1.rawXhtml, contains('Page 1 introductory text.'));

      final ch2 = book.getChapter(1);
      expect(ch2.title, equals('Page 2'));
      expect(ch2.rawXhtml, contains('Page 2 content with second paragraph.'));
    });

    test('handles empty scan with graceful fallback', () {
      final book = parser.parse(
        pages: [],
        bookId: 'scan_empty',
      );

      expect(book.chapterCount, equals(1));
      final ch = book.getChapter(0);
      expect(ch.rawXhtml, contains('No text was recognized'));
    });

    test('serializes and deserializes book via toJson and fromJson roundtrip', () {
      final pages = [
        const ScannedPageData(
          pageNumber: 1,
          rawText: 'First paragraph.\n\nSecond paragraph.',
        ),
        const ScannedPageData(
          pageNumber: 2,
          rawText: 'Third paragraph on next page.',
        ),
      ];

      final originalBook = parser.parse(
        pages: pages,
        bookId: 'scan_roundtrip',
        title: 'Serialized Book',
      );

      final jsonMap = parser.toJson(originalBook);
      expect(jsonMap['id'], equals('scan_roundtrip'));
      expect(jsonMap['title'], equals('Serialized Book'));
      expect(jsonMap['isScan'], isTrue);
      expect((jsonMap['pages'] as List).length, equals(2));

      final restoredBook = parser.fromJson(jsonMap);
      expect(restoredBook.id, equals('scan_roundtrip'));
      expect(restoredBook.metadata.title, equals('Serialized Book'));
      expect(restoredBook.isScan, isTrue);
      expect(restoredBook.chapterCount, equals(2));

      final ch1 = restoredBook.getChapter(0);
      expect(ch1.rawXhtml, contains('First paragraph.'));
      expect(ch1.rawXhtml, contains('Second paragraph.'));
    });

    test('merges broken OCR line breaks without creating unwanted extra paragraphs', () {
      // Line breaks in the middle of sentences should not create new <p> tags
      final pages = [
        const ScannedPageData(
          pageNumber: 1,
          rawText: 'This is a single continuous\nsentence that was split\n\nacross multiple lines\nby the camera OCR.\n\nHere is a second genuine paragraph.',
        ),
      ];

      final book = parser.parse(
        pages: pages,
        bookId: 'scan_para_test',
        title: 'Paragraph Test',
      );

      final chapter = book.getChapter(0);
      final pMatches = RegExp(r'<p>(.*?)</p>').allMatches(chapter.rawXhtml).toList();

      // Expect exactly 2 paragraphs: the first merged sentence and the second paragraph
      expect(pMatches.length, equals(2));
      expect(pMatches[0].group(1), equals('This is a single continuous sentence that was split across multiple lines by the camera OCR.'));
      expect(pMatches[1].group(1), equals('Here is a second genuine paragraph.'));
    });

    test('merges OCR hyphenated words at line breaks', () {
      final pages = [
        const ScannedPageData(
          pageNumber: 1,
          rawText: 'The soft-\nware appli-\ncation was created successfully.',
        ),
      ];

      final book = parser.parse(
        pages: pages,
        bookId: 'scan_hyphen_test',
      );

      final chapter = book.getChapter(0);
      final pMatches = RegExp(r'<p>(.*?)</p>').allMatches(chapter.rawXhtml).toList();

      expect(pMatches.length, equals(1));
      expect(pMatches[0].group(1), equals('The software application was created successfully.'));
    });
  });

  group('OcrService Mocked Tests', () {
    test('recognizes text with mock handler across languages', () async {
      final ocrService = OcrService(
        mockRecognize: (imagePath, language) async {
          if (language == OcrLanguage.malayalam) {
            return 'മലയാള സാഹിത്യം ചെമ്മീൻ താളിന്റെ വരികൾ';
          } else if (language == OcrLanguage.hindi) {
            return 'हिन्दी साहित्य और पुस्तक पृष्ठ';
          }
          return 'Recognized text from mock photo $imagePath in ${language.displayName}';
        },
      );

      final resultMl = await ocrService.recognizeText('ml_page.jpg', language: OcrLanguage.malayalam);
      expect(resultMl, contains('മലയാള സാഹിത്യം'));

      final resultHi = await ocrService.recognizeText('hi_page.jpg', language: OcrLanguage.hindi);
      expect(resultHi, contains('हिन्दी साहित्य'));

      final resultEn = await ocrService.recognizeText('en_page.jpg', language: OcrLanguage.english);
      expect(resultEn, contains('English'));

      final resultAuto = await ocrService.recognizeText('auto_page.jpg', language: OcrLanguage.auto);
      expect(resultAuto, contains('Auto-Detect'));
    });
  });
}
