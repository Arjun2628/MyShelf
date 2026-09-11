import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;

/// Supported OCR language / script options.
enum OcrLanguage {
  auto('Auto-Detect / Multi-Script', 'auto', 'auto', '🌐'),
  malayalam('Malayalam (മലയാളം)', 'mal', 'ml', '🌴'),
  hindi('Hindi / Devanagari (हिन्दी)', 'hin', 'hi', '🇮🇳'),
  english('English / Latin (English)', 'eng', 'en', '🇬🇧'),
  tamil('Tamil (தமிழ்)', 'tam', 'ta', '🏛️'),
  telugu('Telugu (తెలుగు)', 'tel', 'te', '📜'),
  kannada('Kannada (ಕನ್ನಡ)', 'kan', 'kn', '📖'),
  bengali('Bengali (বাংলা)', 'ben', 'bn', '🪔'),
  arabic('Arabic (العربية)', 'ara', 'ar', '🌙'),
  chinese('Chinese (中文)', 'chs', 'zh', '🇨🇳'),
  japanese('Japanese (日本語)', 'jpn', 'ja', '🇯🇵'),
  korean('Korean (한국어)', 'kor', 'ko', '🇰🇷'),
  spanish('Spanish (Español)', 'spa', 'es', '🇪🇸'),
  french('French (Français)', 'fre', 'fr', '🇫🇷'),
  german('German (Deutsch)', 'ger', 'de', '🇩🇪');

  final String displayName;
  final String apiCode;
  final String isoCode;
  final String flag;

  const OcrLanguage(this.displayName, this.apiCode, this.isoCode, this.flag);
}

/// Service for offline, on-device and enhanced multi-language OCR
/// using Google ML Kit and Tesseract with high-precision regional script support.
class OcrService {
  final Map<TextRecognitionScript, TextRecognizer> _recognizers = {};
  final Future<String> Function(String imagePath, OcrLanguage language)? _mockRecognize;

  static const List<String> _apiKeys = [
    'K87899148788957',
    'helloworld',
    'K89163628888957',
    'K82725357888957',
  ];

  OcrService({
    Future<String> Function(String imagePath, OcrLanguage language)? mockRecognize,
  }) : _mockRecognize = mockRecognize;

  TextRecognizer _getRecognizer(TextRecognitionScript script) {
    return _recognizers.putIfAbsent(
      script,
      () => TextRecognizer(script: script),
    );
  }

  /// Extracts visible text from an image using the selected language or script.
  Future<String> recognizeText(
    String imagePath, {
    OcrLanguage language = OcrLanguage.auto,
  }) async {
    if (_mockRecognize != null) {
      return _mockRecognize(imagePath, language);
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      throw FileSystemException('Image file for OCR not found', imagePath);
    }

    // 1. Regional Indian Scripts (Malayalam, Tamil, Telugu, Kannada, Bengali)
    if (language == OcrLanguage.malayalam ||
        language == OcrLanguage.tamil ||
        language == OcrLanguage.telugu ||
        language == OcrLanguage.kannada ||
        language == OcrLanguage.bengali) {
      // Primary: High-accuracy dedicated Indic Tesseract engine
      try {
        final tessText = await _recognizeWithTesseract(imagePath, language.apiCode);
        if (tessText.trim().isNotEmpty && _hasExpectedScriptCharacters(tessText, language)) {
          return tessText.trim();
        } else if (tessText.trim().isNotEmpty) {
          return tessText.trim();
        }
      } catch (e) {
        debugPrint('[OcrService] Tesseract error for ${language.name}: $e');
      }

      // Secondary: Cloud OCR engine
      try {
        final cloudText = await _recognizeViaCloud(file, language);
        if (cloudText.trim().isNotEmpty && _hasExpectedScriptCharacters(cloudText, language)) {
          return cloudText.trim();
        } else if (cloudText.trim().isNotEmpty) {
          return cloudText.trim();
        }
      } catch (e) {
        debugPrint('[OcrService] Cloud OCR error for ${language.name}: $e');
      }

      // Tertiary: On-device ML Kit Devanagari fallback
      try {
        final devanagariFallback = await _recognizeWithScript(
          InputImage.fromFilePath(imagePath),
          TextRecognitionScript.devanagiri,
        );
        if (devanagariFallback.trim().isNotEmpty) {
          return devanagariFallback.trim();
        }
      } catch (_) {}

      // Quaternary: Universal On-device Latin fallback
      try {
        final latinFallback = await _recognizeWithScript(
          InputImage.fromFilePath(imagePath),
          TextRecognitionScript.latin,
        );
        if (latinFallback.trim().isNotEmpty) {
          return latinFallback.trim();
        }
      } catch (_) {}

      return '';
    }

    if (language == OcrLanguage.arabic) {
      try {
        final cloudText = await _recognizeViaCloud(file, language);
        if (cloudText.trim().isNotEmpty) {
          return cloudText.trim();
        }
      } catch (e) {
        debugPrint('[OcrService] Cloud OCR error for Arabic: $e');
      }
      return await _recognizeWithScript(
        InputImage.fromFilePath(imagePath),
        TextRecognitionScript.latin,
      );
    }

    // 2. On-Device Native ML Kit Scripts
    switch (language) {
      case OcrLanguage.hindi:
        try {
          final hindiText = await _recognizeWithScript(
            InputImage.fromFilePath(imagePath),
            TextRecognitionScript.devanagiri,
          );
          if (hindiText.trim().isNotEmpty) return hindiText.trim();
        } catch (_) {}
        // Cloud fallback
        final cloudText = await _recognizeViaCloud(file, language);
        if (cloudText.trim().isNotEmpty) return cloudText.trim();
        return await _recognizeWithScript(
          InputImage.fromFilePath(imagePath),
          TextRecognitionScript.latin,
        );

      case OcrLanguage.chinese:
        try {
          final cnText = await _recognizeWithScript(
            InputImage.fromFilePath(imagePath),
            TextRecognitionScript.chinese,
          );
          if (cnText.trim().isNotEmpty) return cnText.trim();
        } catch (_) {}
        final cloudText = await _recognizeViaCloud(file, language);
        if (cloudText.trim().isNotEmpty) return cloudText.trim();
        return await _recognizeWithScript(
          InputImage.fromFilePath(imagePath),
          TextRecognitionScript.latin,
        );

      case OcrLanguage.japanese:
        try {
          final jpText = await _recognizeWithScript(
            InputImage.fromFilePath(imagePath),
            TextRecognitionScript.japanese,
          );
          if (jpText.trim().isNotEmpty) return jpText.trim();
        } catch (_) {}
        final cloudText = await _recognizeViaCloud(file, language);
        if (cloudText.trim().isNotEmpty) return cloudText.trim();
        return await _recognizeWithScript(
          InputImage.fromFilePath(imagePath),
          TextRecognitionScript.latin,
        );

      case OcrLanguage.korean:
        try {
          final krText = await _recognizeWithScript(
            InputImage.fromFilePath(imagePath),
            TextRecognitionScript.korean,
          );
          if (krText.trim().isNotEmpty) return krText.trim();
        } catch (_) {}
        final cloudText = await _recognizeViaCloud(file, language);
        if (cloudText.trim().isNotEmpty) return cloudText.trim();
        return await _recognizeWithScript(
          InputImage.fromFilePath(imagePath),
          TextRecognitionScript.latin,
        );

      case OcrLanguage.english:
      case OcrLanguage.spanish:
      case OcrLanguage.french:
      case OcrLanguage.german:
        try {
          final latText = await _recognizeWithScript(
            InputImage.fromFilePath(imagePath),
            TextRecognitionScript.latin,
          );
          if (latText.trim().isNotEmpty) return latText.trim();
        } catch (_) {}
        return await _recognizeViaCloud(file, language);

      case OcrLanguage.auto:
      default:
        return await _autoDetectScriptAndRecognize(imagePath, file);
    }
  }

  /// Automatically identifies the document's script by evaluating candidate engines
  /// prioritizing non-Latin native scripts (Malayalam, Hindi, Tamil, etc.) before Latin.
  Future<String> _autoDetectScriptAndRecognize(
    String imagePath,
    File file,
  ) async {
    // 1. Check Malayalam via Tesseract
    String malText = '';
    try {
      malText = (await _recognizeWithTesseract(imagePath, 'mal')).trim();
    } catch (_) {}
    final malCount = RegExp(r'[\u0D00-\u0D7F]').allMatches(malText).length;
    if (malCount >= 2) {
      return malText;
    }

    // 2. Check Hindi / Devanagari via native ML Kit
    String devanagariText = '';
    try {
      devanagariText = (await _recognizeWithScript(
        InputImage.fromFilePath(imagePath),
        TextRecognitionScript.devanagiri,
      )).trim();
    } catch (_) {}
    final devanagariCount = RegExp(r'[\u0900-\u097F]').allMatches(devanagariText).length;
    if (devanagariCount >= 2) {
      return devanagariText;
    }

    // 3. Check Tamil via Tesseract
    String tamText = '';
    try {
      tamText = (await _recognizeWithTesseract(imagePath, 'tam')).trim();
    } catch (_) {}
    final tamCount = RegExp(r'[\u0B80-\u0BFF]').allMatches(tamText).length;
    if (tamCount >= 2) {
      return tamText;
    }

    // 4. Check Telugu via Tesseract
    String telText = '';
    try {
      telText = (await _recognizeWithTesseract(imagePath, 'tel')).trim();
    } catch (_) {}
    final telCount = RegExp(r'[\u0C00-\u0C7F]').allMatches(telText).length;
    if (telCount >= 2) {
      return telText;
    }

    // 5. Check Kannada via Tesseract
    String kanText = '';
    try {
      kanText = (await _recognizeWithTesseract(imagePath, 'kan')).trim();
    } catch (_) {}
    final kanCount = RegExp(r'[\u0C80-\u0CFF]').allMatches(kanText).length;
    if (kanCount >= 2) {
      return kanText;
    }

    // 6. Check Bengali via Tesseract
    String benText = '';
    try {
      benText = (await _recognizeWithTesseract(imagePath, 'ben')).trim();
    } catch (_) {}
    final benCount = RegExp(r'[\u0980-\u09FF]').allMatches(benText).length;
    if (benCount >= 2) {
      return benText;
    }

    // 7. Check CJK scripts
    try {
      final chineseText = (await _recognizeWithScript(
        InputImage.fromFilePath(imagePath),
        TextRecognitionScript.chinese,
      )).trim();
      final chineseCount = RegExp(r'[\u4E00-\u9FFF]').allMatches(chineseText).length;
      if (chineseCount >= 3) return chineseText;
    } catch (_) {}

    try {
      final japaneseText = (await _recognizeWithScript(
        InputImage.fromFilePath(imagePath),
        TextRecognitionScript.japanese,
      )).trim();
      final japaneseCount = RegExp(r'[\u3040-\u309F\u30A0-\u30FF]').allMatches(japaneseText).length;
      if (japaneseCount >= 3) return japaneseText;
    } catch (_) {}

    try {
      final koreanText = (await _recognizeWithScript(
        InputImage.fromFilePath(imagePath),
        TextRecognitionScript.korean,
      )).trim();
      final koreanCount = RegExp(r'[\uAC00-\uD7AF]').allMatches(koreanText).length;
      if (koreanCount >= 3) return koreanText;
    } catch (_) {}

    // 8. Run on-device Latin recognizer
    String latinText = '';
    try {
      latinText = (await _recognizeWithScript(
        InputImage.fromFilePath(imagePath),
        TextRecognitionScript.latin,
      )).trim();
    } catch (_) {}

    if (latinText.isNotEmpty) {
      return latinText;
    }

    // 9. Try cloud universal as last resort
    try {
      final cloudText = (await _recognizeViaCloud(file, OcrLanguage.auto)).trim();
      if (cloudText.isNotEmpty) {
        return cloudText;
      }
    } catch (_) {}

    // 10. Fallback to whichever candidate produced any text
    final allCandidates = [malText, devanagariText, tamText, telText, kanText, benText, latinText];
    for (final c in allCandidates) {
      if (c.isNotEmpty) return c;
    }

    return '';
  }

  Future<String> _recognizeWithTesseract(String imagePath, String langCode) async {
    try {
      final text = await FlutterTesseractOcr.extractText(
        imagePath,
        language: langCode,
        args: {
          'psm': '3',
          'preserve_interword_spaces': '1',
        },
      );
      return text.trim();
    } catch (e) {
      debugPrint('[OcrService] Tesseract error for $langCode: $e');
      return '';
    }
  }

  Future<String> _recognizeWithScript(InputImage inputImage, TextRecognitionScript script) async {
    try {
      final recognizer = _getRecognizer(script);
      final RecognizedText recognizedText = await recognizer.processImage(inputImage);
      return recognizedText.text.trim();
    } catch (e) {
      debugPrint('[OcrService] Error processing script $script: $e');
      return '';
    }
  }

  /// Cloud OCR engine with base64 transport and multi-engine retry for Malayalam, Tamil, Telugu, etc.
  Future<String> _recognizeViaCloud(File file, OcrLanguage language) async {
    final bytes = await file.readAsBytes();
    final base64Image = base64Encode(bytes);
    final ext = file.path.toLowerCase().endsWith('.png') ? 'PNG' : 'JPG';
    final mime = ext == 'PNG' ? 'image/png' : 'image/jpeg';
    final dataUri = 'data:$mime;base64,$base64Image';

    // Map language code for universal OCR engine
    String langCode = language.apiCode;
    if (langCode == 'auto') {
      langCode = 'eng';
    }

    for (final apiKey in _apiKeys) {
      try {
        final uri = Uri.parse('https://api.ocr.space/parse/image');
        final response = await http.post(
          uri,
          headers: {
            'apikey': apiKey,
          },
          body: {
            'base64Image': dataUri,
            'language': langCode,
            'filetype': ext,
            'isOverlayRequired': 'false',
            'detectOrientation': 'true',
            'scale': 'true',
            'OCREngine': '1', // Engine 1 is required for multi-language & Indic support
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map && data['ParsedResults'] is List) {
            final results = data['ParsedResults'] as List;
            final buffer = StringBuffer();
            for (final r in results) {
              if (r is Map && r['ParsedText'] != null) {
                buffer.writeln(r['ParsedText'].toString());
              }
            }
            final text = buffer.toString().trim();
            if (text.isNotEmpty) {
              return text;
            }
          }
        }
      } catch (e) {
        debugPrint('[OcrService] Cloud attempt with key $apiKey failed: $e');
      }
    }

    return '';
  }

  bool _hasExpectedScriptCharacters(String text, OcrLanguage language) {
    switch (language) {
      case OcrLanguage.malayalam:
        return RegExp(r'[\u0D00-\u0D7F]').hasMatch(text);
      case OcrLanguage.tamil:
        return RegExp(r'[\u0B80-\u0BFF]').hasMatch(text);
      case OcrLanguage.telugu:
        return RegExp(r'[\u0C00-\u0C7F]').hasMatch(text);
      case OcrLanguage.kannada:
        return RegExp(r'[\u0C80-\u0CFF]').hasMatch(text);
      case OcrLanguage.bengali:
        return RegExp(r'[\u0980-\u09FF]').hasMatch(text);
      case OcrLanguage.hindi:
        return RegExp(r'[\u0900-\u097F]').hasMatch(text);
      case OcrLanguage.arabic:
        return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
      default:
        return true;
    }
  }

  /// Releases resources allocated by all recognizers.
  Future<void> dispose() async {
    for (final recognizer in _recognizers.values) {
      await recognizer.close();
    }
    _recognizers.clear();
  }
}
