import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../voice/domain/entities/content_block.dart';

/// Coordinates bi-directional synchronization between the visual Reading Position and Audio Playback.
class SyncEngine extends ChangeNotifier {
  List<ContentBlock> _contentBlocks = [];
  int _currentBlockIndex = 0;
  bool _isPlaying = false;
  String _currentSpokenWord = '';
  int _wordStartOffset = 0;
  int _wordEndOffset = 0;

  final StreamController<ContentBlock> _blockChangeController =
      StreamController<ContentBlock>.broadcast();

  final StreamController<void> _seekRequestController =
      StreamController<void>.broadcast();

  List<ContentBlock> get contentBlocks => List.unmodifiable(_contentBlocks);
  int get currentBlockIndex => _currentBlockIndex;
  bool get isPlaying => _isPlaying;
  String get currentSpokenWord => _currentSpokenWord;
  int get wordStartOffset => _wordStartOffset;
  int get wordEndOffset => _wordEndOffset;

  ContentBlock? get currentBlock =>
      (_currentBlockIndex >= 0 && _currentBlockIndex < _contentBlocks.length)
          ? _contentBlocks[_currentBlockIndex]
          : null;

  Stream<ContentBlock> get onBlockChanged => _blockChangeController.stream;
  Stream<void> get onSeekRequested => _seekRequestController.stream;

  /// Loads the structured content blocks for the active chapter or document.
  void setContentBlocks(List<ContentBlock> blocks, {int initialIndex = 0}) {
    _contentBlocks = List.from(blocks);
    _currentBlockIndex = initialIndex.clamp(0, (_contentBlocks.isEmpty ? 0 : _contentBlocks.length - 1));
    notifyListeners();
    if (currentBlock != null) {
      _blockChangeController.add(currentBlock!);
    }
  }

  /// Called when the audio engine advances to or begins playing a new [ContentBlock].
  void updateAudioPosition(int blockIndex) {
    if (blockIndex >= 0 && blockIndex < _contentBlocks.length) {
      _currentBlockIndex = blockIndex;
      _currentSpokenWord = '';
      notifyListeners();
      _blockChangeController.add(_contentBlocks[blockIndex]);
    }
  }

  /// Called when user taps a specific block in the reading UI to jump playback.
  void seekToBlockIndex(int index) {
    if (index >= 0 && index < _contentBlocks.length) {
      _currentBlockIndex = index;
      _currentSpokenWord = '';
      notifyListeners();
      _blockChangeController.add(_contentBlocks[index]);
      _seekRequestController.add(null);
    }
  }

  /// Seeks to a block matching a given [blockId].
  void seekToBlockId(String blockId) {
    final index = _contentBlocks.indexWhere((b) => b.id == blockId);
    if (index != -1) {
      seekToBlockIndex(index);
    }
  }

  /// Updates real-time word boundary offset during speech synthesis.
  void updateWordProgress(String word, int start, int end) {
    _currentSpokenWord = word;
    _wordStartOffset = start;
    _wordEndOffset = end;
    notifyListeners();
  }

  /// Updates play/pause state.
  void setPlaying(bool playing) {
    if (_isPlaying != playing) {
      _isPlaying = playing;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _blockChangeController.close();
    _seekRequestController.close();
    super.dispose();
  }
}
