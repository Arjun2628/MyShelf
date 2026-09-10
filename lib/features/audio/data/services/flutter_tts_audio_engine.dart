import 'dart:io';
import 'package:epub_audio/features/audio/domain/services/audio_source_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Concrete [AudioSourceEngine] implementation utilizing [FlutterTts].
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
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
        );
      }

      await _flutterTts.awaitSpeakCompletion(true);

      _flutterTts.setCompletionHandler(() {
        _onCompletion?.call();
      });

      _flutterTts.setErrorHandler((dynamic msg) {
        _onError?.call(msg.toString());
      });

      _flutterTts.setCancelHandler(() {
        // Cancelled or stopped
      });

      _isInitialized = true;
    } catch (_) {
      // Allow graceful fallback in test / unsupported platforms
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
        await _flutterTts.setLanguage(normalizedLang);
      }

      await _flutterTts.speak(text);
    } catch (e) {
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
    // Note: Some platforms don't support resume directly without re-speaking
    try {
      // On Android/iOS, resume or re-speak is handled by the session controller
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
      // FlutterTts rate ranges from 0.0 to 1.0 (0.5 is default 1.0x speed)
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
    if (lower.startsWith('ml')) return 'ml-IN'; // Malayalam
    if (lower.startsWith('hi')) return 'hi-IN'; // Hindi
    if (lower.startsWith('ta')) return 'ta-IN'; // Tamil
    if (lower.startsWith('en')) return 'en-US'; // English
    if (lower.startsWith('es')) return 'es-ES'; // Spanish
    if (lower.startsWith('fr')) return 'fr-FR'; // French
    if (lower.startsWith('de')) return 'de-DE'; // German
    return lang;
  }
}
