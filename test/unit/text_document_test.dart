import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:epub_audio/features/text_content/domain/entities/text_document.dart';
import 'package:epub_audio/features/text_content/data/parsers/text_document_parser.dart';
import 'package:epub_audio/features/text_content/data/services/shared_text_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TextDocument Entity Tests', () {
    test('Calculates word count, char count, and reading time correctly', () {
      final doc = TextDocument.fromRawText(
        id: 'doc_1',
        title: 'Morning Reflections',
        rawContent: 'This is a peaceful morning.\nThe birds are singing sweet melodies.\n\nTime to start coding Flutter apps!',
        source: 'direct_write',
      );

      expect(doc.id, equals('doc_1'));
      expect(doc.title, equals('Morning Reflections'));
      expect(doc.source, equals('direct_write'));
      expect(doc.paragraphs.length, equals(3));
      expect(doc.sentences.length, greaterThanOrEqualTo(3));
      expect(doc.wordCount, equals(17));
      expect(doc.characterCount, greaterThan(60));
      expect(doc.estimatedReadingMinutes, equals(1));
    });

    test('Serializes to and from JSON map correctly', () {
      final now = DateTime.now();
      final originalDoc = TextDocument(
        id: 'doc_json_test',
        title: 'Sample Title',
        content: 'First paragraph.\n\nSecond paragraph with more words.',
        createdAt: now,
        updatedAt: now,
        source: 'clipboard',
        metadata: {'author': 'Reader', 'tags': 'notes'},
      );

      final jsonMap = originalDoc.toJson();
      final restoredDoc = TextDocument.fromJson(jsonMap);

      expect(restoredDoc.id, equals(originalDoc.id));
      expect(restoredDoc.title, equals(originalDoc.title));
      expect(restoredDoc.content, equals(originalDoc.content));
      expect(restoredDoc.source, equals('clipboard'));
      expect(restoredDoc.paragraphs.length, equals(2));
      expect(restoredDoc.sentences.length, equals(2));
      expect(restoredDoc.wordCount, equals(originalDoc.wordCount));
      expect(restoredDoc.metadata?['tags'], equals('notes'));
    });

    test('copyWith updates fields as expected', () {
      final doc = TextDocument.fromRawText(
        id: 'doc_copy',
        title: 'Original Title',
        rawContent: 'Hello world.',
      );

      final updatedDoc = doc.copyWith(
        title: 'New Title',
        lastReadPosition: 42,
      );

      expect(updatedDoc.id, equals('doc_copy'));
      expect(updatedDoc.title, equals('New Title'));
      expect(updatedDoc.lastReadPosition, equals(42));
      expect(updatedDoc.content, equals('Hello world.'));
    });
  });

  group('TextDocumentParser Tests', () {
    late TextDocumentParser parser;

    setUp(() {
      parser = TextDocumentParser();
    });

    test('Parses TextDocument into a fully-fledged Book with XHTML chapters', () {
      final doc = TextDocument.fromRawText(
        id: 'doc_parse_1',
        title: 'The Great Essay',
        rawContent: '# Introduction\n\nThis is the opening chapter of the great essay.\n\n## Deep Dive\n\nHere we analyze the nuances in detail.',
        source: 'file_import',
      );

      final book = parser.parseDocumentToBook(doc);

      expect(book.id, equals('doc_parse_1'));
      expect(book.metadata.title, equals('The Great Essay'));
      expect(book.metadata.author, equals('Imported Text'));
      expect(book.isText, isTrue);
      expect(book.isPdf, isFalse);
      expect(book.isScan, isFalse);
      expect(book.chapterCount, equals(1));

      final chapter = book.getChapter(0);
      expect(chapter.id, equals('chapter_0'));
      expect(chapter.title, equals('The Great Essay'));
      expect(chapter.rawXhtml, contains('<h1 id="p_0">Introduction</h1>'));
      expect(chapter.rawXhtml, contains('<h2 id="p_2">Deep Dive</h2>'));
      expect(chapter.rawXhtml, contains('id="p_0"'));
      expect(chapter.rawXhtml, contains('id="p_1"'));
    });

    test('Parses raw text and auto-extracts first line as title if title is empty', () {
      const rawText = 'My Awesome Story Title\n\nOnce upon a time in a digital world, an AI assisted a developer.';
      final book = parser.parseRawTextToBook(
        rawText: rawText,
        id: 'story_1',
      );

      expect(book.metadata.title, equals('My Awesome Story Title'));
      expect(book.isText, isTrue);
      expect(book.getChapter(0).rawXhtml, contains('Once upon a time'));
    });

    test('Formats blockquotes and formatting correctly in XHTML', () {
      const raw = '> Knowledge is power.\n\n**Bold statement** and *italic note*.';
      final doc = TextDocument.fromRawText(
        id: 'quote_doc',
        title: 'Wisdom',
        rawContent: raw,
      );

      final book = parser.parseDocumentToBook(doc);
      final html = book.getChapter(0).rawXhtml;

      expect(html, contains('<blockquote id="p_0">Knowledge is power.</blockquote>'));
      expect(html, contains('<strong>Bold statement</strong>'));
      expect(html, contains('<em>italic note</em>'));
    });

    test('Detects language correctly based on Unicode script', () {
      expect(TextDocumentParser.detectLanguageFromText('ഇതൊരു മലയാളം വാചകമാണ്.'), equals('ml'));
      expect(TextDocumentParser.detectLanguageFromText('यह एक हिंदी वाक्य है।'), equals('hi'));
      expect(TextDocumentParser.detectLanguageFromText('This is pure English language.'), equals('en'));
    });
  });

  group('SharedTextService Tests', () {
    test('Handles getInitialSharedText and stream without error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.example.epub_audio/share_intent'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'getInitialSharedText') {
            return 'Shared text from Google Keep';
          }
          if (methodCall.method == 'clearSharedText') {
            return null;
          }
          return null;
        },
      );

      SharedTextService.initialize();
      final text = await SharedTextService.getInitialSharedText();
      expect(text, equals('Shared text from Google Keep'));
      await SharedTextService.clearSharedText();
    });
  });
}
