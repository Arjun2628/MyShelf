import 'dart:io';
import 'package:epub_audio/features/audio/domain/services/audio_source_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Concrete [AudioSourceEngine] implementation utilizing [FlutterTts] with fallback support.
class FlutterTtsAudioEngine implements AudioSourceEngine {
  final FlutterTts _flutterTts;
  VoidCallback? _onCompletion;
  void Function(String message)? _onError;
  bool _isInitialized = false;

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

      // Ensure speak() triggers handlers asynchronously without deadlocking
      await _flutterTts.awaitSpeakCompletion(false);

      _flutterTts.setStartHandler(() {
        debugPrint('[TTS] Speech started');
      });

      _flutterTts.setCompletionHandler(() {
        debugPrint('[TTS] Paragraph completed');
        _onCompletion?.call();
      });

      _flutterTts.setErrorHandler((dynamic msg) {
        debugPrint('[TTS] Error: $msg');
        _onError?.call(msg.toString());
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

  @override
  Future<void> speakParagraph(String text, {String? language}) async {
    await init();
    if (text.trim().isEmpty) {
      _onCompletion?.call();
      return;
    }

    try {
      if (language != null) {
        final normalizedLang = _normalizeLanguageTag(language);
        try {
          final isAvail = await _flutterTts.isLanguageAvailable(normalizedLang);
          if (isAvail == true || isAvail == 1) {
            await _flutterTts.setLanguage(normalizedLang);
          } else {
            debugPrint('[TTS] Language $normalizedLang unavailable, falling back to default voice');
          }
        } catch (_) {
          // Some desktop platforms don't support isLanguageAvailable, attempt direct set
          try {
            await _flutterTts.setLanguage(normalizedLang);
          } catch (_) {}
        }
      }

      await _flutterTts.setVolume(1.0);
      final result = await _flutterTts.speak(text);
      debugPrint('[TTS] speak result: $result for "${text.substring(0, text.length.clamp(0, 30))}..."');
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
      final ttsRate = (rate * 0.5).clamp(0.1, 1.0);
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
  void setOnError(void Function(String message) callback) {
    _onError = callback;
  }

  @override
  void dispose() {
    stop();
    _onCompletion = null;
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
