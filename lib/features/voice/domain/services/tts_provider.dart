import '../entities/content_block.dart';
import '../entities/voice_profile.dart';
import '../entities/audio_segment.dart';

/// Pluggable provider interface for text-to-speech engines (device TTS, cloud neural speech, etc.).
abstract class TTSProvider {
  /// Unique identifier of this provider (e.g. 'device_tts', 'elevenlabs', 'google_cloud').
  String get providerId;

  /// Display name for the provider in settings.
  String get displayName;

  /// Initializes the provider.
  Future<void> init();

  /// Returns list of available voices from the engine (id, name, locale).
  Future<List<Map<String, String>>> getAvailableVoices();

  /// Synthesizes speech for a given block using the assigned voice profile.
  /// If [targetFilePath] is provided, saves synthesized audio to that path and returns a ready AudioSegment.
  Future<AudioSegment> generate({
    required ContentBlock block,
    required VoiceProfile profile,
    String? targetFilePath,
  });

  /// Plays text directly through the speaker output with real-time word boundary callbacks.
  Future<void> speakDirectly(
    String text,
    VoiceProfile profile, {
    void Function()? onCompletion,
    void Function(String word, int startOffset, int endOffset)? onProgress,
    void Function(String error)? onError,
  });

  /// Pauses current playback.
  Future<void> pause();

  /// Resumes playback.
  Future<void> resume();

  /// Stops playback.
  Future<void> stop();

  /// Disposes provider resources.
  void dispose();
}
