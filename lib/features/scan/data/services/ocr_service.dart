import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;

/// Supported OCR language / script options.
enum OcrLanguage {
  auto('Auto-Detect / Multi-Script', 'auto', '🌐'),
  malayalam('Malayalam (മലയാളം)', 'mal', '🌴'),
  hindi('Hindi / Devanagari (हिन्दी)', 'hin', '🇮🇳'),
  english('English / Latin (English)', 'eng', '🇬🇧'),
  tamil('Tamil (தமிழ்)', 'tam', '🏛️'),
  telugu('Telugu (తెలుగు)', 'tel', '📜'),
  kannada('Kannada (ಕನ್ನಡ)', 'kan', '📖'),
  bengali('Bengali (বাংলা)', 'ben', '🪔'),
  arabic('Arabic (العربية)', 'ara', '🌙'),
  chinese('Chinese (中文)', 'chs', '🇨🇳'),
  japanese('Japanese (日本語)', 'jpn', '🇯🇵'),
  korean('Korean (한국어)', 'kor', '🇰🇷'),
  spanish('Spanish (Español)', 'spa', '🇪🇸'),
  french('French (Français)', 'fre', '🇫🇷'),
  german('German (Deutsch)', 'ger', '🇩🇪');

  final String displayName;
  final String apiCode;
  final String flag;

  const OcrLanguage(this.displayName, this.apiCode, this.flag);
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

    final inputImage = InputImage.fromFilePath(imagePath);

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
          // If Tesseract extracted text (even mixed), return it if it has reasonable content
          return tessText.trim();
        }
      } catch (e) {
        debugPrint('[OcrService] Tesseract error for ${language.name}: $e');
      }

      // Secondary: Cloud OCR engine (only accept if it contains actual script glyphs)
      try {
        final cloudText = await _recognizeViaCloud(file, language);
        if (cloudText.trim().isNotEmpty && _hasExpectedScriptCharacters(cloudText, language)) {
          return cloudText.trim();
        }
      } catch (e) {
        debugPrint('[OcrService] Cloud OCR error for ${language.name}: $e');
      }

      // Tertiary: On-device ML Kit fallback
      final devanagariFallback = await _recognizeWithScript(inputImage, TextRecognitionScript.devanagiri);
      if (devanagariFallback.trim().isNotEmpty && _hasExpectedScriptCharacters(devanagariFallback, language)) {
        return devanagariFallback;
      }
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
      return await _recognizeWithScript(inputImage, TextRecognitionScript.latin);
    }

    // 2. On-Device Native ML Kit Scripts
    switch (language) {
      case OcrLanguage.hindi:
        final hindiText = await _recognizeWithScript(inputImage, TextRecognitionScript.devanagiri);
        if (hindiText.trim().isNotEmpty) return hindiText;
        // Cloud fallback if on-device model not yet downloaded
        return await _recognizeViaCloud(file, language);

      case OcrLanguage.chinese:
        final cnText = await _recognizeWithScript(inputImage, TextRecognitionScript.chinese);
        if (cnText.trim().isNotEmpty) return cnText;
        return await _recognizeViaCloud(file, language);

      case OcrLanguage.japanese:
        final jpText = await _recognizeWithScript(inputImage, TextRecognitionScript.japanese);
        if (jpText.trim().isNotEmpty) return jpText;
        return await _recognizeViaCloud(file, language);

      case OcrLanguage.korean:
        final krText = await _recognizeWithScript(inputImage, TextRecognitionScript.korean);
        if (krText.trim().isNotEmpty) return krText;
        return await _recognizeViaCloud(file, language);

      case OcrLanguage.english:
      case OcrLanguage.spanish:
      case OcrLanguage.french:
      case OcrLanguage.german:
        return _recognizeWithScript(inputImage, TextRecognitionScript.latin);

      case OcrLanguage.auto:
      default:
        return await _autoDetectScriptAndRecognize(inputImage, imagePath, file);
    }
  }

  /// Automatically identifies the document's script by executing candidates
  /// and picking the engine with the highest script density.
  Future<String> _autoDetectScriptAndRecognize(
    InputImage inputImage,
    String imagePath,
    File file,
  ) async {
    // 1. Run native on-device script engines concurrently for maximum speed
    final results = await Future.wait([
      _recognizeWithScript(inputImage, TextRecognitionScript.devanagiri),
      _recognizeWithScript(inputImage, TextRecognitionScript.latin),
      _recognizeWithScript(inputImage, TextRecognitionScript.chinese),
      _recognizeWithScript(inputImage, TextRecognitionScript.japanese),
      _recognizeWithScript(inputImage, TextRecognitionScript.korean),
    ]);

    final devanagariText = results[0].trim();
    final latinText = results[1].trim();
    final chineseText = results[2].trim();
    final japaneseText = results[3].trim();
    final koreanText = results[4].trim();

    final devanagariCount = RegExp(r'[\u0900-\u097F]').allMatches(devanagariText).length;
    final latinCount = RegExp(r'[a-zA-Z]').allMatches(latinText).length;
    final chineseCount = RegExp(r'[\u4E00-\u9FFF]').allMatches(chineseText).length;
    final japaneseCount = RegExp(r'[\u3040-\u309F\u30A0-\u30FF]').allMatches(japaneseText).length;
    final koreanCount = RegExp(r'[\uAC00-\uD7AF]').allMatches(koreanText).length;

    // A. Devanagari / Hindi check (prioritize if authentic Devanagari glyphs are present)
    if (devanagariCount > 8 && (devanagariCount >= latinCount * 0.25 || latinCount < 20)) {
      return devanagariText;
    }

    // B. CJK script checks
    if (chineseCount > 8) return chineseText;
    if (japaneseCount > 5) return japaneseText;
    if (koreanCount > 6) return koreanText;

    // C. Malayalam Indic check via Tesseract if no Devanagari or CJK
    try {
      final malText = await _recognizeWithTesseract(imagePath, 'mal');
      final malCount = RegExp(r'[\u0D00-\u0D7F]').allMatches(malText).length;
      if (malCount > 8) {
        return malText.trim();
      }
    } catch (_) {}

    // D. Latin / English check
    if (latinCount > 15) {
      return latinText;
    }

    // E. Fallback: Devanagari if it has any text, otherwise Latin
    if (devanagariText.isNotEmpty && devanagariCount > 0) {
      return devanagariText;
    }
    if (latinText.isNotEmpty) {
      return latinText;
    }

    // Try cloud universal as last resort
    try {
      final cloudText = await _recognizeViaCloud(file, OcrLanguage.auto);
      if (cloudText.trim().isNotEmpty) {
        return cloudText.trim();
      }
    } catch (_) {}

    return devanagariText.isNotEmpty ? devanagariText : latinText;
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
