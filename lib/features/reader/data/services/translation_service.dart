import 'dart:convert';
import 'package:epub_audio/features/reader/domain/entities/translation_result.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for translating selected text in books with online API and offline fallback.
class TranslationService {
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'ml': 'Malayalam (മലയാളം)',
    'hi': 'Hindi (हिन्दी)',
    'ta': 'Tamil (தமிழ்)',
    'te': 'Telugu (తెలుగు)',
    'kn': 'Kannada (ಕನ್ನಡ)',
    'ar': 'Arabic (العربية)',
    'es': 'Spanish (Español)',
    'fr': 'French (Français)',
    'de': 'German (Deutsch)',
  };

  /// Returns human readable language name from language code.
  String getLanguageName(String code) {
    return supportedLanguages[code] ?? code;
  }

  /// Translates [text] from [sourceLang] (or auto-detected) to [targetLang].
  Future<TranslationResult> translate(
    String text, {
    String? sourceLang,
    String? targetLang,
  }) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      return const TranslationResult(
        originalText: '',
        translatedText: '',
        sourceLanguage: 'auto',
        targetLanguage: 'en',
      );
    }

    final detectedSource = sourceLang ?? detectLanguage(cleanText);
    final target = targetLang ?? (detectedSource == 'ml' ? 'en' : 'ml');

    // 1. Check offline glossary for instant resolution
    final offlineMatch = _lookupOffline(cleanText, detectedSource, target);
    if (offlineMatch != null) {
      return TranslationResult(
        originalText: cleanText,
        translatedText: offlineMatch,
        sourceLanguage: detectedSource,
        targetLanguage: target,
      );
    }

    // 2. Query Google Translate public web API
    try {
      final uri = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=$detectedSource&tl=$target&dt=t&q=${Uri.encodeComponent(cleanText)}',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty && data[0] is List) {
          final buffer = StringBuffer();
          for (final item in data[0]) {
            if (item is List && item.isNotEmpty && item[0] is String) {
              buffer.write(item[0]);
            }
          }
          final translated = buffer.toString().trim();
          if (translated.isNotEmpty) {
            return TranslationResult(
              originalText: cleanText,
              translatedText: translated,
              sourceLanguage: detectedSource,
              targetLanguage: target,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[TranslationService] Primary translation error: $e');
    }

    // 3. Fallback to MyMemory Public API
    try {
      final langPair = '$detectedSource|$target';
      final uri = Uri.parse(
        'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(cleanText)}&langpair=$langPair',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final matches = data['responseData'];
        if (matches != null && matches['translatedText'] != null) {
          final translated = matches['translatedText'].toString().trim();
          if (translated.isNotEmpty && !translated.contains('MYMEMORY WARNING')) {
            return TranslationResult(
              originalText: cleanText,
              translatedText: translated,
              sourceLanguage: detectedSource,
              targetLanguage: target,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[TranslationService] Fallback translation error: $e');
    }

    // 4. Return graceful fallback
    return TranslationResult.failure(
      originalText: cleanText,
      sourceLanguage: detectedSource,
      targetLanguage: target,
      errorMessage: 'Translation currently unavailable. Please check your internet connection.',
    );
  }

  /// Automatically detects language from unicode script points.
  String detectLanguage(String text) {
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      // Malayalam: 0x0D00 - 0x0D7F
      if (code >= 0x0D00 && code <= 0x0D7F) return 'ml';
      // Devanagari / Hindi: 0x0900 - 0x097F
      if (code >= 0x0900 && code <= 0x097F) return 'hi';
      // Tamil: 0x0B80 - 0x0BFF
      if (code >= 0x0B80 && code <= 0x0BFF) return 'ta';
      // Arabic: 0x0600 - 0x06FF
      if (code >= 0x0600 && code <= 0x06FF) return 'ar';
    }
    return 'en';
  }

  String? _lookupOffline(String text, String from, String to) {
    final lower = text.toLowerCase().trim();
    if (from == 'ml' && to == 'en') {
      return _mlToEn[lower] ?? _mlToEn[text.trim()];
    } else if (from == 'en' && to == 'ml') {
      return _enToMl[lower];
    }
    return null;
  }

  static const Map<String, String> _mlToEn = {
    'ചെമ്മീൻ': 'Prawn / Shrimp (Chemmeen)',
    'കടൽ': 'Sea / Ocean',
    'തീരം': 'Shore / Coast',
    'കാറ്റ്': 'Wind / Breeze',
    'വള്ളം': 'Boat / Canoe',
    'വല': 'Net',
    'ജീവിതം': 'Life',
    'കടലമ്മ': 'Mother Sea (Goddess of the Sea)',
    'അദ്ധ്യായം': 'Chapter',
    'കറുത്തമ്മ': 'Karuthamma (Name)',
    'പരീക്കുട്ടി': 'Pareekutty (Name)',
    'ചെമ്പൻകുഞ്ഞ്': 'Chemban Kunju (Name)',
    'സൗഹൃദം': 'Friendship',
    'സ്നേഹം': 'Love / Affection',
    'പുസ്തകം': 'Book',
  };

  static const Map<String, String> _enToMl = {
    'chapter': 'അദ്ധ്യായം',
    'rabbit': 'മുയൽ (Rabbit)',
    'alice': 'ആലീസ് (Alice)',
    'sea': 'കടൽ',
    'ocean': 'സമുദ്രം',
    'book': 'പുസ്തകം',
    'read': 'വായിക്കുക',
    'listen': 'കേൾക്കുക',
    'wind': 'കാറ്റ്',
    'friendship': 'സൗഹൃദം',
    'love': 'സ്നേഹം',
  };
}
