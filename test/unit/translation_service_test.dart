import 'package:epub_audio/features/epub/domain/entities/chapter_content.dart';
import 'package:epub_audio/features/epub/domain/entities/content_nodes.dart';
import 'package:epub_audio/features/reader/data/services/translation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TranslationService', () {
    late TranslationService service;

    setUp(() {
      service = TranslationService();
    });

    test('detectLanguage identifies Malayalam, Hindi, Tamil, Arabic, and English', () {
      expect(service.detectLanguage('നമസ്കാരം സുഹൃത്തേ'), equals('ml'));
      expect(service.detectLanguage('नमस्ते आप कैसे हैं'), equals('hi'));
      expect(service.detectLanguage('வணக்கம்'), equals('ta'));
      expect(service.detectLanguage('مرحبا'), equals('ar'));
      expect(service.detectLanguage('Hello World! This is a test.'), equals('en'));
    });

    test('getLanguageName returns correct human readable name', () {
      expect(service.getLanguageName('ml'), contains('Malayalam'));
      expect(service.getLanguageName('en'), contains('English'));
      expect(service.getLanguageName('hi'), contains('Hindi'));
      expect(service.getLanguageName('ta'), contains('Tamil'));
      expect(service.getLanguageName('ar'), contains('Arabic'));
    });

    test('translate translates basic words or provides fallback translation result', () async {
      final res = await service.translate('Hello', sourceLang: 'en', targetLang: 'ml');
      expect(res.originalText, equals('Hello'));
      expect(res.isSuccess, isTrue);
      expect(res.translatedText.isNotEmpty, isTrue);
    });

    test('translate translates Malayalam word to English', () async {
      final res = await service.translate('പുസ്തകം', sourceLang: 'ml', targetLang: 'en');
      expect(res.originalText, equals('പുസ്തകം'));
      expect(res.isSuccess, isTrue);
      expect(res.translatedText.isNotEmpty, isTrue);
    });

    test('translateChapter translates entire ChapterContent while preserving layout nodes', () async {
      final chapter = ChapterContent(
        chapterId: 'ch_1',
        title: 'Chapter 1',
        fullPath: 'ch1.xhtml',
        spineIndex: 0,
        blocks: [
          const HeadingNode(level: 1, spans: [TextSpanNode(text: 'Chapter 1')]),
          const ParagraphNode(spans: [TextSpanNode(text: 'Hello world! Welcome to the book.')]),
          const BlockquoteNode(children: [
            ParagraphNode(spans: [TextSpanNode(text: 'Knowledge is power.')]),
          ]),
        ],
      );

      final translated = await service.translateChapter(chapter, targetLanguage: 'ml');
      expect(translated.chapterId, equals('ch_1'));
      expect(translated.blocks.length, equals(3));
      expect(translated.blocks[0], isA<HeadingNode>());
      expect(translated.blocks[1], isA<ParagraphNode>());
      expect(translated.blocks[2], isA<BlockquoteNode>());
      expect(translated.paragraphsAsText.length, greaterThanOrEqualTo(2));
    });
  });
}
