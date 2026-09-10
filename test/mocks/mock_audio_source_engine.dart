import 'package:epub_audio/features/audio/domain/services/audio_source_engine.dart';
import 'package:flutter/foundation.dart';

/// Mock implementation of [AudioSourceEngine] for deterministic unit and widget testing.
class MockAudioSourceEngine implements AudioSourceEngine {
  VoidCallback? _onCompletion;
  void Function(String message)? _onError;
  void Function(String text, int startOffset, int endOffset, String word)? _onProgress;

  final List<String> spokenParagraphs = [];
  bool isPlaying = false;
  double speechRate = 1.0;
  double pitch = 1.0;
  double volume = 1.0;

  @override
  Future<void> init() async {}

  @override
  Future<void> speakParagraph(String text, {String? language}) async {
    spokenParagraphs.add(text);
    isPlaying = true;
  }

  @override
  Future<void> pause() async {
    isPlaying = false;
  }

  @override
  Future<void> resume() async {
    isPlaying = true;
  }

  @override
  Future<void> stop() async {
    isPlaying = false;
  }

  @override
  Future<void> setRate(double rate) async {
    speechRate = rate;
  }

  @override
  Future<void> setPitch(double p) async {
    pitch = p;
  }

  @override
  Future<void> setVolume(double v) async {
    volume = v;
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

  /// Manually trigger progress with character offset in tests.
  void triggerProgress(String text, int startOffset, int endOffset, String word) {
    _onProgress?.call(text, startOffset, endOffset, word);
  }

  /// Manually trigger completion of current paragraph in tests.
  void triggerCompletion() {
    _onCompletion?.call();
  }

  /// Manually trigger error in tests.
  void triggerError(String error) {
    _onError?.call(error);
  }

  @override
  void dispose() {
    isPlaying = false;
    _onCompletion = null;
    _onProgress = null;
    _onError = null;
  }
}
