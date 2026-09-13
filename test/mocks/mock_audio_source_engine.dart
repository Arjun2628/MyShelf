import 'package:epub_audio/features/audio/domain/services/audio_source_engine.dart';
import 'package:flutter/foundation.dart';

/// Mock implementation of [AudioSourceEngine] for deterministic unit and widget testing.
class MockAudioSourceEngine implements AudioSourceEngine {
  VoidCallback? _onCompletion;
  void Function(String message)? _onError;
  void Function(String text, int startOffset, int endOffset, String word)? _onProgress;

  final List<String> spokenParagraphs = [];
  final List<String?> spokenLanguages = [];
  bool isPlaying = false;
  double speechRate = 1.0;
  double pitch = 1.0;
  double volume = 1.0;

  @override
  Future<void> init() async {}

  @override
  Future<void> speakParagraph(String text, {String? language}) async {
    spokenParagraphs.add(text);
    spokenLanguages.add(language);
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

  String? currentVoice;
  String? currentVoiceLocale;
  final List<String> setVoicesHistory = [];

  @override
  Future<void> setVoice(String voiceName, {String? locale}) async {
    currentVoice = voiceName;
    currentVoiceLocale = locale;
    setVoicesHistory.add(voiceName);
  }

  @override
  Future<List<Map<String, String>>> getAvailableVoices() async {
    return [
      {'id': 'en-us-x-sfg#female_1-local', 'name': 'English Female 1 (Narrator Voice A)', 'locale': 'en-US'},
      {'id': 'en-us-x-iom-local', 'name': 'English Male 1 (Arjun Voice B)', 'locale': 'en-US'},
      {'id': 'en-us-x-iol-local', 'name': 'English Female 2 (Maya Voice C)', 'locale': 'en-US'},
      {'id': 'en-gb-x-rjs-local', 'name': 'English GB Male (Stranger Voice D)', 'locale': 'en-GB'},
    ];
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
