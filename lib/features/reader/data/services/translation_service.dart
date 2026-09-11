import 'dart:convert';
import 'package:epub_audio/features/epub/domain/entities/chapter_content.dart';
import 'package:epub_audio/features/epub/domain/entities/content_nodes.dart';
import 'package:epub_audio/features/reader/domain/entities/translation_result.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Language metadata model for translation picker.
class TranslationLanguageInfo {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const TranslationLanguageInfo({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });

  String get displayName => '$name ($nativeName)';
}

/// Service for translating text, full chapters, and entire books with online API and offline fallback.
class TranslationService {
  static const List<TranslationLanguageInfo> languages = [
    TranslationLanguageInfo(code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം', flag: '🌴'),
    TranslationLanguageInfo(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', flag: '🇮🇳'),
    TranslationLanguageInfo(code: 'en', name: 'English', nativeName: 'English', flag: '🇬🇧'),
    TranslationLanguageInfo(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்', flag: '🏛️'),
    TranslationLanguageInfo(code: 'te', name: 'Telugu', nativeName: 'తెలుగు', flag: '📜'),
    TranslationLanguageInfo(code: 'kn', name: 'Kannada', nativeName: 'ಕನ್ನಡ', flag: '📖'),
    TranslationLanguageInfo(code: 'bn', name: 'Bengali', nativeName: 'বাংলা', flag: '🪔'),
    TranslationLanguageInfo(code: 'es', name: 'Spanish', nativeName: 'Español', flag: '🇪🇸'),
    TranslationLanguageInfo(code: 'fr', name: 'French', nativeName: 'Français', flag: '🇫🇷'),
    TranslationLanguageInfo(code: 'de', name: 'German', nativeName: 'Deutsch', flag: '🇩🇪'),
    TranslationLanguageInfo(code: 'ar', name: 'Arabic', nativeName: 'العربية', flag: '🌙'),
    TranslationLanguageInfo(code: 'zh-CN', name: 'Chinese', nativeName: '中文', flag: '🇨🇳'),
    TranslationLanguageInfo(code: 'ja', name: 'Japanese', nativeName: '日本語', flag: '🇯🇵'),
    TranslationLanguageInfo(code: 'ko', name: 'Korean', nativeName: '한국어', flag: '🇰🇷'),
  ];

  static Map<String, String> get supportedLanguages {
    return {for (final l in languages) l.code: l.displayName};
  }

  /// Returns human readable language name from language code.
  String getLanguageName(String code) {
    for (final l in languages) {
      if (l.code == code || l.code.startsWith(code)) return l.displayName;
    }
    return code;
  }

  String getLanguageFlag(String code) {
    for (final l in languages) {
      if (l.code == code || l.code.startsWith(code)) return l.flag;
    }
    return '🌐';
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

    if (detectedSource == target) {
      return TranslationResult(
        originalText: cleanText,
        translatedText: cleanText,
        sourceLanguage: detectedSource,
        targetLanguage: target,
      );
    }

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

      final response = await http.get(uri).timeout(const Duration(seconds: 8));
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

      final response = await http.get(uri).timeout(const Duration(seconds: 6));
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

  /// Translates an entire [ChapterContent] into [targetLanguage], producing a fully-structured
  /// chapter with translated headings, paragraphs, and list items while preserving layout anchors.
  Future<ChapterContent> translateChapter(
    ChapterContent chapter, {
    required String targetLanguage,
    void Function(double progress, String status)? onProgress,
  }) async {
    onProgress?.call(0.05, 'Translating chapter title...');

    // Translate Title
    String translatedTitle = chapter.title;
    try {
      final titleResult = await translate(chapter.title, targetLang: targetLanguage);
      if (titleResult.isSuccess && titleResult.translatedText.isNotEmpty) {
        translatedTitle = titleResult.translatedText;
      }
    } catch (e) {
      debugPrint('[TranslationService] Error translating chapter title: $e');
    }

    final totalBlocks = chapter.blocks.length;
    final translatedBlocks = <ContentBlockNode>[];

    // Process blocks in chunks to prevent network bottlenecks
    for (int i = 0; i < totalBlocks; i++) {
      final block = chapter.blocks[i];
      final prog = 0.1 + (0.85 * (i / totalBlocks));
      onProgress?.call(prog, 'Translating paragraph ${i + 1} of $totalBlocks...');

      if (block is ParagraphNode) {
        final plainText = block.toPlainText().trim();
        if (plainText.isEmpty) {
          translatedBlocks.add(block);
        } else {
          final res = await translate(plainText, targetLang: targetLanguage);
          final translatedText = res.isSuccess ? res.translatedText : plainText;
          translatedBlocks.add(ParagraphNode(
            spans: [TextSpanNode(text: translatedText)],
            anchorId: block.anchorId,
          ));
        }
      } else if (block is HeadingNode) {
        final plainText = block.toPlainText().trim();
        if (plainText.isEmpty) {
          translatedBlocks.add(block);
        } else {
          final res = await translate(plainText, targetLang: targetLanguage);
          final translatedText = res.isSuccess ? res.translatedText : plainText;
          translatedBlocks.add(HeadingNode(
            level: block.level,
            spans: [TextSpanNode(text: translatedText)],
            anchorId: block.anchorId,
          ));
        }
      } else if (block is BlockquoteNode) {
        final plainText = block.toPlainText().trim();
        if (plainText.isEmpty) {
          translatedBlocks.add(block);
        } else {
          final res = await translate(plainText, targetLang: targetLanguage);
          final translatedText = res.isSuccess ? res.translatedText : plainText;
          translatedBlocks.add(BlockquoteNode(
            children: [
              ParagraphNode(spans: [TextSpanNode(text: translatedText)]),
            ],
            anchorId: block.anchorId,
          ));
        }
      } else if (block is ListBlockNode) {
        final translatedItems = <ListItemNode>[];
        for (final item in block.items) {
          final itemText = item.toPlainText().trim();
          if (itemText.isEmpty) {
            translatedItems.add(item);
          } else {
            final res = await translate(itemText, targetLang: targetLanguage);
            final translatedText = res.isSuccess ? res.translatedText : itemText;
            translatedItems.add(ListItemNode(spans: [TextSpanNode(text: translatedText)]));
          }
        }
        translatedBlocks.add(ListBlockNode(
          isOrdered: block.isOrdered,
          items: translatedItems,
          anchorId: block.anchorId,
        ));
      } else {
        // ImageBlockNode, Divider, etc. remain unchanged
        translatedBlocks.add(block);
      }
    }

    onProgress?.call(1.0, 'Chapter translation ready!');

    return ChapterContent(
      chapterId: chapter.chapterId,
      title: translatedTitle,
      fullPath: chapter.fullPath,
      spineIndex: chapter.spineIndex,
      blocks: translatedBlocks,
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
      // Telugu: 0x0C00 - 0x0C7F
      if (code >= 0x0C00 && code <= 0x0C7F) return 'te';
      // Kannada: 0x0C80 - 0x0CFF
      if (code >= 0x0C80 && code <= 0x0CFF) return 'kn';
      // Bengali: 0x0980 - 0x09FF
      if (code >= 0x0980 && code <= 0x09FF) return 'bn';
      // Arabic: 0x0600 - 0x06FF
      if (code >= 0x0600 && code <= 0x06FF) return 'ar';
      // Chinese: 0x4E00 - 0x9FFF
      if (code >= 0x4E00 && code <= 0x9FFF) return 'zh-CN';
      // Japanese Hiragana & Katakana: 0x3040 - 0x30FF
      if (code >= 0x3040 && code <= 0x30FF) return 'ja';
      // Korean Hangul: 0xAC00 - 0xD7AF
      if (code >= 0xAC00 && code <= 0xD7AF) return 'ko';
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
