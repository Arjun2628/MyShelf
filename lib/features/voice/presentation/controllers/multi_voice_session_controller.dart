import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/content_block.dart';
import '../../domain/entities/voice_profile.dart';
import '../../domain/services/voice_engine.dart';
import '../../domain/services/speaker_detection_engine.dart';
import '../../data/detection/rule_based_speaker_detector.dart';
import '../../../synchronization/services/sync_engine.dart';

/// Controller coordinating multi-voice playback, speaker assignment, on-demand speech generation, and reading sync.
class MultiVoiceSessionController extends ChangeNotifier {
  final VoiceEngine _voiceEngine;
  final SpeakerDetectionEngine _speakerDetector;
  final SyncEngine _syncEngine;

  bool _isMultiVoiceEnabled = true;
  bool _isLoading = false;
  String? _errorMessage;
  String _activeBookId = 'book_default';
  String _activeChapterId = 'ch_01';

  StreamSubscription? _seekSubscription;

  MultiVoiceSessionController({
    required VoiceEngine voiceEngine,
    SpeakerDetectionEngine? speakerDetector,
    SyncEngine? syncEngine,
  })  : _voiceEngine = voiceEngine,
        _speakerDetector = speakerDetector ?? RuleBasedSpeakerDetector(),
        _syncEngine = syncEngine ?? SyncEngine() {
    _initListeners();
  }

  VoiceEngine get voiceEngine => _voiceEngine;
  SpeakerDetectionEngine get speakerDetector => _speakerDetector;
  SyncEngine get syncEngine => _syncEngine;
  bool get isMultiVoiceEnabled => _isMultiVoiceEnabled;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get activeBookId => _activeBookId;
  String get activeChapterId => _activeChapterId;

  bool get isPlaying => _syncEngine.isPlaying;
  int get currentBlockIndex => _syncEngine.currentBlockIndex;
  List<ContentBlock> get contentBlocks => _syncEngine.contentBlocks;
  ContentBlock? get currentBlock => _syncEngine.currentBlock;

  void _initListeners() {
    _seekSubscription = _syncEngine.onSeekRequested.listen((_) {
      if (isPlaying) {
        _playCurrentBlock();
      }
    });
  }

  /// Parses raw document or chapter text into structured multi-character [ContentBlock] sequence.
  Future<void> loadRawContent({
    required String rawText,
    required String bookId,
    required String chapterId,
    int initialBlockIndex = 0,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _activeBookId = bookId;
    _activeChapterId = chapterId;
    notifyListeners();

    try {
      final characters = _voiceEngine.getCharacters();
      final blocks = await _speakerDetector.detect(
        rawText: rawText,
        knownCharacters: characters,
        chapterId: chapterId,
      );

      _syncEngine.setContentBlocks(blocks, initialIndex: initialBlockIndex);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to analyze text content: $e';
      notifyListeners();
    }
  }

  /// Toggles multi-voice mode on/off.
  void setMultiVoiceEnabled(bool enabled) {
    if (_isMultiVoiceEnabled != enabled) {
      _isMultiVoiceEnabled = enabled;
      notifyListeners();
    }
  }

  /// Starts or resumes playback from current block.
  Future<void> play() async {
    if (contentBlocks.isEmpty) return;
    _syncEngine.setPlaying(true);
    await _playCurrentBlock();
  }

  /// Pauses playback.
  Future<void> pause() async {
    _syncEngine.setPlaying(false);
    await _voiceEngine.ttsProvider.pause();
    notifyListeners();
  }

  /// Toggles between play and pause.
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Stops playback and resets position to beginning.
  Future<void> stop() async {
    _syncEngine.setPlaying(false);
    await _voiceEngine.ttsProvider.stop();
    _syncEngine.seekToBlockIndex(0);
    notifyListeners();
  }

  /// Skips forward to the next content block.
  Future<void> next() async {
    if (currentBlockIndex < contentBlocks.length - 1) {
      _syncEngine.seekToBlockIndex(currentBlockIndex + 1);
    } else {
      await stop();
    }
  }

  /// Skips back to previous content block.
  Future<void> previous() async {
    if (currentBlockIndex > 0) {
      _syncEngine.seekToBlockIndex(currentBlockIndex - 1);
    }
  }

  /// Seeks to a specific content block by index and immediately starts playing if active.
  Future<void> seekToBlock(int index) async {
    _syncEngine.seekToBlockIndex(index);
  }

  /// Plays the current block using either character voice or narrator fallback.
  Future<void> _playCurrentBlock() async {
    final block = currentBlock;
    if (block == null) {
      _syncEngine.setPlaying(false);
      return;
    }

    // Determine voice profile to use
    final speakerId = _isMultiVoiceEnabled ? block.speakerId : 'narrator';
    final profile = _voiceEngine.getVoiceProfile(speakerId);

    try {
      await _voiceEngine.ttsProvider.speakDirectly(
        block.text,
        profile,
        onCompletion: () {
          if (isPlaying) {
            next();
          }
        },
        onProgress: (word, start, end) {
          _syncEngine.updateWordProgress(word, start, end);
        },
        onError: (err) {
          debugPrint('[MultiVoiceSession] Playback error: $err');
          if (isPlaying) {
            next(); // Auto advance on error to prevent stuck state
          }
        },
      );
    } catch (e) {
      debugPrint('[MultiVoiceSession] Exception during speak: $e');
    }
  }

  /// Reassigns a character to a different voice profile.
  void assignCharacterVoice(String characterId, String voiceProfileId) {
    _voiceEngine.assignVoice(characterId, voiceProfileId);
    notifyListeners();
  }

  /// Updates pitch, speed, or volume for a voice profile.
  void updateVoiceProfile(VoiceProfile profile) {
    _voiceEngine.updateVoiceProfile(profile);
    notifyListeners();
  }

  /// Speaks a test sample with the given profile for instant UI auditioning.
  Future<void> previewVoice(VoiceProfile profile, {String? sampleText}) async {
    final text = sampleText ?? 'Hello! This is a preview of my voice for the story.';
    await _voiceEngine.ttsProvider.speakDirectly(text, profile);
  }

  @override
  void dispose() {
    _seekSubscription?.cancel();
    super.dispose();
  }
}
