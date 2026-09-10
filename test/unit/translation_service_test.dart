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
  });
}
