import 'dart:io';
import 'package:epub_audio/features/audio/domain/services/audio_source_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Concrete [AudioSourceEngine] implementation utilizing [FlutterTts] with fallback support.
class FlutterTtsAudioEngine implements AudioSourceEngine {
  final FlutterTts _flutterTts;
  VoidCallback? _onCompletion;
  void Function(String message)? _onError;
  void Function(String text, int startOffset, int endOffset, String word)? _onProgress;
  bool _isInitialized = false;
  String? _lastText;
  String? _currentConfiguredLanguage;
  bool _fallbackAttempted = false;

  FlutterTtsAudioEngine({FlutterTts? flutterTts})
      : _flutterTts = flutterTts ?? FlutterTts();

  @override
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        try {
          await _flutterTts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
              IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            ],
          );
        } catch (_) {}
      }

      await _flutterTts.setSpeechRate(0.38);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.awaitSpeakCompletion(false);

      // Print engine diagnostics for troubleshooting
      try {
        final engines = await _flutterTts.getEngines;
        final defaultEngine = await _flutterTts.getDefaultEngine;
        final languages = await _flutterTts.getLanguages;
        final defaultVoice = await _flutterTts.getDefaultVoice;
        debugPrint('[TTS Diagnostics] Available engines: $engines | Default engine: $defaultEngine');
        debugPrint('[TTS Diagnostics] Available languages count: ${languages is List ? languages.length : languages}');
        debugPrint('[TTS Diagnostics] Default voice: $defaultVoice');
      } catch (e) {
        debugPrint('[TTS Diagnostics] Could not query engine metadata: $e');
      }

      _flutterTts.setStartHandler(() {
        debugPrint('[TTS] Speech started');
      });

      _flutterTts.setProgressHandler((dynamic text, dynamic start, dynamic end, dynamic word) {
        final startOffset = start is int ? start : int.tryParse(start.toString()) ?? 0;
        final endOffset = end is int ? end : int.tryParse(end.toString()) ?? 0;
        final wordStr = word?.toString() ?? '';
        final textStr = text?.toString() ?? '';
        _onProgress?.call(textStr, startOffset, endOffset, wordStr);
      });

      _flutterTts.setCompletionHandler(() {
        debugPrint('[TTS] Paragraph completed');
        _fallbackAttempted = false;
        _onCompletion?.call();
      });

      _flutterTts.setErrorHandler((dynamic msg) async {
        final errStr = msg.toString();
        debugPrint('[TTS] Error: $errStr');

        // Error -7 is ERROR_NOT_INSTALLED_YET on Android TTS
        if ((errStr.contains('-7') || errStr.contains('NOT_INSTALLED')) &&
            !_fallbackAttempted &&
            _lastText != null &&
            _lastText!.trim().isNotEmpty) {
          _fallbackAttempted = true;
          debugPrint(
              '[TTS] Voice data not installed for requested language. Automatically falling back to default voice...');
          try {
            await _flutterTts.setLanguage('en-US');
            _currentConfiguredLanguage = 'en-US';
            final res = await _flutterTts.speak(_lastText!);
            debugPrint('[TTS] Fallback speak result: $res');
            return;
          } catch (e) {
            debugPrint('[TTS] Fallback speak error: $e');
          }
        }

        _onError?.call(errStr);
      });

      _flutterTts.setCancelHandler(() {
        debugPrint('[TTS] Speech cancelled/stopped');
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('[TTS] Init exception: $e');
      _isInitialized = true;
    }
  }

  Future<void> _configureLanguage(String rawLanguage) async {
    final normalizedLang = _normalizeLanguageTag(rawLanguage);
    if (_currentConfiguredLanguage == normalizedLang) return;

    bool canUseLang = false;
    try {
      final isInstalled = await _flutterTts.isLanguageInstalled(normalizedLang);
      if (isInstalled == true || isInstalled == 1) {
        canUseLang = true;
      }
    } catch (_) {
      try {
        final isAvail = await _flutterTts.isLanguageAvailable(normalizedLang);
        if (isAvail == true || isAvail == 1) {
          canUseLang = true;
        }
      } catch (_) {
        canUseLang = true;
      }
    }

    if (canUseLang) {
      try {
        await _flutterTts.setLanguage(normalizedLang);
        _currentConfiguredLanguage = normalizedLang;
        debugPrint('[TTS] Configured language to $normalizedLang');
      } catch (_) {}
    } else {
      debugPrint(
          '[TTS] Language $normalizedLang voice not installed/available, keeping default/en-US voice.');
      try {
        await _flutterTts.setLanguage('en-US');
        _currentConfiguredLanguage = 'en-US';
      } catch (_) {}
    }
  }

  @override
  Future<void> speakParagraph(String text, {String? language}) async {
    await init();
    if (text.trim().isEmpty) {
      _onCompletion?.call();
      return;
    }

    _lastText = text;
    _fallbackAttempted = false;

    try {
      await _flutterTts.stop();
      if (language != null) {
        final normalized = _normalizeLanguageTag(language);
        if (_currentConfiguredLanguage != normalized) {
          await _configureLanguage(language);
        }
      }

      final result = await _flutterTts.speak(text);
      debugPrint(
          '[TTS] speak result: $result for "${text.substring(0, text.length.clamp(0, 30))}..."');
    } catch (e) {
      debugPrint('[TTS] Speak error: $e');
      _onError?.call('TTS speak error: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _flutterTts.pause();
    } catch (_) {}
  }

  @override
  Future<void> resume() async {
    try {
      // Platform-specific resume
    } catch (_) {}
  }

  @override
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }

  @override
  Future<void> setRate(double rate) async {
    try {
      // In flutter_tts, 0.38 gives a pleasant, comfortable reading pace for 1.0x
      final ttsRate = (rate * 0.38).clamp(0.10, 1.0);
      await _flutterTts.setSpeechRate(ttsRate);
    } catch (_) {}
  }

  @override
  Future<void> setPitch(double pitch) async {
    try {
      await _flutterTts.setPitch(pitch.clamp(0.5, 2.0));
    } catch (_) {}
  }

  @override
  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
    } catch (_) {}
  }

  @override
  void setOnCompletion(VoidCallback callback) {
    _onCompletion = callback;
  }

  @override
  void setOnProgress(void Function(String text, int startOffset, int endOffset, String word) callback) {
    _onProgress = callback;
  }

  @override
  void setOnError(void Function(String message) callback) {
    _onError = callback;
  }

  @override
  void dispose() {
    stop();
    _lastText = null;
    _onCompletion = null;
    _onProgress = null;
    _onError = null;
  }

  String _normalizeLanguageTag(String lang) {
    final lower = lang.toLowerCase().trim();
    if (lower.startsWith('ml')) return 'ml-IN';
    if (lower.startsWith('hi')) return 'hi-IN';
    if (lower.startsWith('ta')) return 'ta-IN';
    if (lower.startsWith('en')) return 'en-US';
    if (lower.startsWith('es')) return 'es-ES';
    if (lower.startsWith('fr')) return 'fr-FR';
    if (lower.startsWith('de')) return 'de-DE';
    return lang;
  }
}
