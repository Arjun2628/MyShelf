import 'dart:typed_data';
import 'dart:ui';
import 'package:epub_audio/features/pdf/data/parsers/pdf_document_parser.dart';
import 'package:epub_audio/features/pdf/domain/usecases/open_pdf_usecase.dart';
import 'package:epub_audio/features/reader/presentation/controllers/reader_controller.dart';
import 'package:epub_audio/features/session/presentation/controllers/book_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Helper to generate a test PDF document with text and metadata in memory.
Uint8List createSamplePdfBytes({
  String title = 'Sample PDF Book',
  String author = 'Test Author',
  List<String> pageTexts = const [
    'Chapter 1: The Beginning.\n\nThis is the first paragraph of page one.\n\nHere is another paragraph describing the scenery.',
    'Chapter 2: The Journey Continues.\n\nThis is the second page of our wonderful document.\n\nAudio narration and reading should sync smoothly.',
  ],
}) {
  final document = PdfDocument();
  document.documentInformation.title = title;
  document.documentInformation.author = author;
  document.documentInformation.subject = 'A test document for PDF reading';

  final font = PdfStandardFont(PdfFontFamily.helvetica, 12);

  for (final text in pageTexts) {
    final page = document.pages.add();
    page.graphics.drawString(
      text,
      font,
      bounds: const Rect.fromLTWH(0, 0, 500, 700),
    );
  }

  final bytes = Uint8List.fromList(document.saveSync());
  document.dispose();
  return bytes;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfDocumentParser & OpenPdfUseCase Tests', () {
    late Uint8List pdfBytes;

    setUp(() {
      pdfBytes = createSamplePdfBytes(
        title: 'Modern Architecture Guide',
        author: 'Flutter Master',
      );
    });

    test('PdfDocumentParser extracts metadata and creates a Book model', () {
      final parser = PdfDocumentParser();
      final book = parser.parse(pdfBytes, bookId: 'test_pdf_1');

      expect(book.id, equals('test_pdf_1'));
      expect(book.metadata.title, equals('Modern Architecture Guide'));
      expect(book.metadata.author, equals('Flutter Master'));
      expect(book.chapterCount, equals(2));
      expect(book.toc.length, equals(2));
      expect(book.toc[0].title, equals('Page 1'));
      expect(book.toc[1].title, equals('Page 2'));
    });

    test('PdfDocumentParser builds valid reflowable XHTML for chapters', () {
      final parser = PdfDocumentParser();
      final book = parser.parse(pdfBytes, bookId: 'test_pdf_2');

      final chapter1 = book.getChapter(0);
      expect(chapter1.title, equals('Page 1'));
      expect(chapter1.rawXhtml, contains('<h2>Page 1</h2>'));
      expect(chapter1.rawXhtml, contains('<p>'));
      expect(chapter1.rawXhtml, contains('Chapter 1: The Beginning.'));

      final chapter2 = book.getChapter(1);
      expect(chapter2.title, equals('Page 2'));
      expect(chapter2.rawXhtml, contains('Chapter 2: The Journey Continues.'));
    });

    test('OpenPdfUseCase loads PDF from bytes cleanly', () async {
      final useCase = OpenPdfUseCase();
      final book = await useCase.fromBytes(pdfBytes, bookId: 'usecase_pdf');

      expect(book.id, equals('usecase_pdf'));
      expect(book.metadata.title, equals('Modern Architecture Guide'));
      expect(book.chapterCount, equals(2));
    });

    test('ReaderController loads and renders PDF Book with pagination', () async {
      final useCase = OpenPdfUseCase();
      final book = await useCase.fromBytes(pdfBytes, bookId: 'reader_pdf');

      final readerController = ReaderController(book: book);
      expect(readerController.currentChapterIndex, equals(0));
      expect(readerController.currentChapterContent, isNotNull);
      expect(readerController.currentChapterContent!.blocks.isNotEmpty, isTrue);

      // Navigate to next page/chapter
      readerController.nextChapter();
      expect(readerController.currentChapterIndex, equals(1));
      expect(readerController.currentChapterContent!.title, equals('Page 2'));
    });

    test('BookSessionController synchronizes audio narration with PDF Book', () async {
      final useCase = OpenPdfUseCase();
      final book = await useCase.fromBytes(pdfBytes, bookId: 'audio_pdf');

      final session = BookSessionController(book: book);
      expect(session.currentChapterIndex, equals(0));
      expect(session.currentParagraphIndex, equals(0));
      expect(session.currentChapterParagraphs.isNotEmpty, isTrue);

      // Advance paragraph in audio
      session.nextAudioParagraph();
      expect(session.currentParagraphIndex, equals(1));

      // Seeking paragraph
      session.seekToParagraph(0);
      expect(session.currentParagraphIndex, equals(0));
    });
  });
}
