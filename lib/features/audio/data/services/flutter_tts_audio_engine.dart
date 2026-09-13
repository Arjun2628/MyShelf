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

      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.awaitSpeakCompletion(true);

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
        debugPrint('[TTS] Paragraph completed via handler');
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

  final Map<String, String> _voiceLocalesCache = {};
  String? _currentVoiceName;
  String? _currentVoiceLocale;
  double? _currentPitch;
  double? _currentRate;

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
      if (language != null && _currentVoiceName == null) {
        final normalized = _normalizeLanguageTag(language);
        if (_currentConfiguredLanguage != normalized) {
          await _configureLanguage(language);
        }
      }

      final result = await _flutterTts.speak(text);
      debugPrint(
          '[TTS] speak completed: result=$result for "${text.substring(0, text.length.clamp(0, 30))}..."');
      _onCompletion?.call();
    } catch (e) {
      debugPrint('[TTS] Speak error: $e');
      _onError?.call('TTS speak error: $e');
    }
  }

  @override
  Future<void> pause() async {
    try {
      await _flutterTts.stop();
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
      final ttsRate = (rate * 0.45).clamp(0.15, 1.0);
      if (_currentRate != null && (_currentRate! - ttsRate).abs() < 0.01) {
        return;
      }
      _currentRate = ttsRate;
      await _flutterTts.setSpeechRate(ttsRate);
    } catch (_) {}
  }

  @override
  Future<void> setPitch(double pitch) async {
    try {
      final clampedPitch = pitch.clamp(0.5, 2.0);
      if (_currentPitch != null && (_currentPitch! - clampedPitch).abs() < 0.01) {
        return;
      }
      _currentPitch = clampedPitch;
      await _flutterTts.setPitch(clampedPitch);
    } catch (_) {}
  }

  @override
  Future<void> setVolume(double volume) async {
    try {
      await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
    } catch (_) {}
  }

  @override
  Future<void> setVoice(String voiceName, {String? locale}) async {
    await init();
    if (voiceName.isEmpty || voiceName == 'default') return;

    try {
      // Find matching locale from cache or voice name prefix
      var loc = locale ?? _voiceLocalesCache[voiceName];
      if (loc == null || loc.isEmpty) {
        final lower = voiceName.toLowerCase();
        if (lower.startsWith('en-gb') || lower.contains('en_gb')) {
          loc = 'en-GB';
        } else if (lower.startsWith('en-au') || lower.contains('en_au')) {
          loc = 'en-AU';
        } else if (lower.startsWith('en-in') || lower.contains('en_in')) {
          loc = 'en-IN';
        } else if (lower.startsWith('en')) {
          loc = 'en-US';
        } else {
          loc = _currentConfiguredLanguage ?? 'en-US';
        }
      }

      if (_currentVoiceName == voiceName && _currentVoiceLocale == loc) {
        return; // Voice already configured, zero IPC latency
      }

      await _flutterTts.setVoice({
        'name': voiceName,
        'locale': loc,
      });
      _currentVoiceName = voiceName;
      _currentVoiceLocale = loc;
      _currentConfiguredLanguage = loc;
      debugPrint('[FlutterTtsAudioEngine] Voice set to: $voiceName (locale: $loc)');
    } catch (e) {
      debugPrint('[FlutterTtsAudioEngine] Could not set voice $voiceName: $e');
    }
  }

  @override
  Future<List<Map<String, String>>> getAvailableVoices() async {
    await init();
    final List<Map<String, String>> result = [];
    try {
      final voices = await _flutterTts.getVoices;
      if (voices is List) {
        for (final v in voices) {
          if (v is Map) {
            final name = v['name']?.toString() ?? '';
            final locale = v['locale']?.toString() ?? '';
            if (name.isNotEmpty) {
              _voiceLocalesCache[name] = locale;
              result.add({
                'id': name,
                'name': name,
                'locale': locale,
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[FlutterTtsAudioEngine] Error querying voices: $e');
    }

    if (result.isEmpty) {
      // Standard fallback voice models across Android/iOS
      result.addAll([
        {'id': 'en-us-x-sfg#female_1-local', 'name': 'en-us-x-sfg#female_1-local', 'locale': 'en-US'},
        {'id': 'en-us-x-iom-local', 'name': 'en-us-x-iom-local (Male 1)', 'locale': 'en-US'},
        {'id': 'en-us-x-iol-local', 'name': 'en-us-x-iol-local (Female 1)', 'locale': 'en-US'},
        {'id': 'en-gb-x-rjs-local', 'name': 'en-gb-x-rjs-local (British Accent)', 'locale': 'en-GB'},
      ]);
    }
    return result;
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
    if (lower.startsWith('te')) return 'te-IN';
    if (lower.startsWith('kn')) return 'kn-IN';
    if (lower.startsWith('bn') || lower.startsWith('ben')) return 'bn-IN';
    if (lower.startsWith('ar')) return 'ar-SA';
    if (lower.startsWith('zh') || lower.startsWith('cn') || lower.startsWith('chs')) return 'zh-CN';
    if (lower.startsWith('ja') || lower.startsWith('jp')) return 'ja-JP';
    if (lower.startsWith('ko') || lower.startsWith('kr')) return 'ko-KR';
    if (lower.startsWith('en')) return 'en-US';
    if (lower.startsWith('es')) return 'es-ES';
    if (lower.startsWith('fr')) return 'fr-FR';
    if (lower.startsWith('de')) return 'de-DE';
    return lang;
  }
}
