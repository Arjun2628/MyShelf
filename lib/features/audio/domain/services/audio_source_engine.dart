import 'package:flutter/foundation.dart';

/// Contract for audio source engines (TTS, pre-recorded audio, neural AI speech).
abstract class AudioSourceEngine {
  /// Initializes the audio engine.
  Future<void> init();

  /// Speaks or streams a given text segment.
  Future<void> speakParagraph(String text, {String? language});

  /// Pauses current playback.
  Future<void> pause();

  /// Resumes playback from paused position.
  Future<void> resume();

  /// Stops playback completely.
  Future<void> stop();

  /// Sets playback / speech rate (0.5x to 2.0x).
  Future<void> setRate(double rate);

  /// Sets voice pitch (0.5 to 2.0).
  Future<void> setPitch(double pitch);

  /// Sets volume (0.0 to 1.0).
  Future<void> setVolume(double volume);

  /// Sets completion callback for when the current paragraph finishes playing.
  void setOnCompletion(VoidCallback callback);

  /// Sets progress callback with word and character offset tracking.
  void setOnProgress(void Function(String text, int startOffset, int endOffset, String word) callback);

  /// Sets error callback.
  void setOnError(void Function(String message) callback);

  /// Disposes audio resources.
  void dispose();
}
