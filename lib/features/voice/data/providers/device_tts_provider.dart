import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/entities/voice_profile.dart';
import '../../domain/entities/audio_segment.dart';
import '../../domain/services/tts_provider.dart';

/// Device OS TTS provider implementing the [TTSProvider] abstraction.
class DeviceTtsProvider implements TTSProvider {
  FlutterTts? _flutterTts;
  bool _isInitialized = false;

  void Function()? _onCompletion;
  void Function(String word, int startOffset, int endOffset)? _onProgress;
  void Function(String error)? _onError;

  DeviceTtsProvider({FlutterTts? flutterTts}) : _flutterTts = flutterTts;

  FlutterTts get _tts {
    return _flutterTts ??= FlutterTts();
  }

  @override
  String get providerId => 'device_tts';

  @override
  String get displayName => 'Device Built-in TTS';

  @override
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        try {
          await _tts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
              IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            ],
          );
        } catch (_) {}
      }

      await _tts.awaitSpeakCompletion(false);

      _tts.setCompletionHandler(() {
        _onCompletion?.call();
      });

      _tts.setProgressHandler((dynamic text, dynamic start, dynamic end, dynamic word) {
        final startOffset = start is int ? start : int.tryParse(start.toString()) ?? 0;
        final endOffset = end is int ? end : int.tryParse(end.toString()) ?? 0;
        final wordStr = word?.toString() ?? '';
        _onProgress?.call(wordStr, startOffset, endOffset);
      });

      _tts.setErrorHandler((dynamic msg) {
        _onError?.call(msg.toString());
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('[DeviceTtsProvider] Init error: $e');
    }
  }

  @override
  Future<List<Map<String, String>>> getAvailableVoices() async {
    await init();
    final List<Map<String, String>> result = [];
    try {
      final voices = await _tts.getVoices;
      if (voices is List) {
        for (final v in voices) {
          if (v is Map) {
            final name = v['name']?.toString() ?? '';
            final locale = v['locale']?.toString() ?? '';
            if (name.isNotEmpty) {
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
      debugPrint('[DeviceTtsProvider] Error querying voices: $e');
    }

    if (result.isEmpty) {
      // Fallback default system voices across Android & iOS
      result.addAll([
        {'id': 'en-us-x-sfg#female_1-local', 'name': 'English US Female 1 (Clear)', 'locale': 'en-US'},
        {'id': 'en-us-x-iom-local', 'name': 'English US Male 1 (Deep Natural)', 'locale': 'en-US'},
        {'id': 'en-us-x-iol-local', 'name': 'English US Female 2 (Expressive)', 'locale': 'en-US'},
        {'id': 'en-gb-x-rjs-local', 'name': 'English GB Male (Distinct British)', 'locale': 'en-GB'},
      ]);
    }
    return result;
  }

  Future<void> _applyVoiceProfile(VoiceProfile profile) async {
    await init();
    try {
      // Rate mapping: default base is ~0.38 for FlutterTts on mobile
      final adjustedRate = (0.38 * profile.speed).clamp(0.1, 1.0);
      await _tts.setSpeechRate(adjustedRate);

      // Pitch: 0.5 to 2.0
      await _tts.setPitch(profile.pitch.clamp(0.5, 2.0));

      // Volume: 0.0 to 1.0
      await _tts.setVolume(profile.volume.clamp(0.0, 1.0));

      if (profile.language.isNotEmpty) {
        await _tts.setLanguage(profile.language);
      }

      if (profile.providerVoiceId.isNotEmpty && profile.providerVoiceId != 'default') {
        try {
          await _tts.setVoice({
            'name': profile.providerVoiceId,
            'locale': profile.language,
          });
          debugPrint('[DeviceTtsProvider] Switched voice model to: ${profile.providerVoiceId} (locale: ${profile.language})');
        } catch (e) {
          debugPrint('[DeviceTtsProvider] Warning: could not set voice model ${profile.providerVoiceId}: $e');
        }
      }
    } catch (e) {
      debugPrint('[DeviceTtsProvider] Error applying profile: $e');
    }
  }

  @override
  Future<AudioSegment> generate({
    required ContentBlock block,
    required VoiceProfile profile,
    String? targetFilePath,
  }) async {
    await init();
    await _applyVoiceProfile(profile);

    if (targetFilePath != null && !kIsWeb) {
      try {
        final targetFile = File(targetFilePath);
        if (!targetFile.parent.existsSync()) {
          targetFile.parent.createSync(recursive: true);
        }
        
        // Synthesize to file via flutter_tts if supported
        final result = await _tts.synthesizeToFile(block.text, targetFilePath);
        if (result == 1 || targetFile.existsSync()) {
          return AudioSegment(
            id: 'seg_${block.id}',
            contentBlockId: block.id,
            speakerId: block.speakerId,
            voiceProfileId: profile.id,
            audioPath: targetFilePath,
            status: AudioSegmentStatus.ready,
          );
        }
      } catch (e) {
        debugPrint('[DeviceTtsProvider] synthesizeToFile not supported/failed: $e');
      }
    }

    // Direct streaming segment
    return AudioSegment(
      id: 'seg_${block.id}',
      contentBlockId: block.id,
      speakerId: block.speakerId,
      voiceProfileId: profile.id,
      status: AudioSegmentStatus.ready,
    );
  }

  @override
  Future<void> speakDirectly(
    String text,
    VoiceProfile profile, {
    void Function()? onCompletion,
    void Function(String word, int startOffset, int endOffset)? onProgress,
    void Function(String error)? onError,
  }) async {
    _onCompletion = onCompletion;
    _onProgress = onProgress;
    _onError = onError;

    await _applyVoiceProfile(profile);
    await _tts.speak(text);
  }

  @override
  Future<void> pause() async {
    try {
      await _tts.pause();
    } catch (e) {
      debugPrint('[DeviceTtsProvider] Pause error: $e');
    }
  }

  @override
  Future<void> resume() async {
    // FlutterTts doesn't have resume on some platforms, handled by caller
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('[DeviceTtsProvider] Stop error: $e');
    }
  }

  @override
  void dispose() {
    if (_flutterTts != null) {
      _tts.stop();
    }
  }
}
