import 'dart:async';
import 'package:epub_audio/core/utils/path_utils.dart';
import 'package:epub_audio/features/audio/data/services/flutter_tts_audio_engine.dart';
import 'package:epub_audio/features/audio/domain/entities/audio_playback_state.dart';
import 'package:epub_audio/features/audio/domain/services/audio_source_engine.dart';
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/epub/domain/entities/chapter_content.dart';
import 'package:epub_audio/features/epub/domain/entities/content_nodes.dart';
import 'package:epub_audio/features/epub/domain/usecases/parse_chapter_content_usecase.dart';
import 'package:epub_audio/features/reader/domain/entities/bookmark.dart';
import 'package:epub_audio/features/reader/domain/entities/reader_preferences.dart';
import 'package:epub_audio/features/session/domain/entities/book_position.dart';
import 'package:flutter/foundation.dart';

/// Unified session controller managing shared reading position, audio narration,
/// chapter navigation, preferences, and bookmarks.
class BookSessionController extends ChangeNotifier {
  final Book book;
  final AudioSourceEngine _audioEngine;
  final ParseChapterContentUseCase _parseChapterUseCase;

  BookPosition _currentPosition;
  ChapterContent? _currentChapterContent;
  List<String> _currentChapterParagraphs = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _showControls = true;

  ReaderPreferences _preferences = const ReaderPreferences();
  AudioPlaybackState _audioState;
  final List<Bookmark> _bookmarks = [];
  Timer? _sleepTimer;

  BookSessionController({
    required this.book,
    AudioSourceEngine? audioEngine,
    ParseChapterContentUseCase parseChapterUseCase =
        const ParseChapterContentUseCase(),
    int initialChapterIndex = 0,
    int initialParagraphIndex = 0,
  })  : _audioEngine = audioEngine ?? FlutterTtsAudioEngine(),
        _parseChapterUseCase = parseChapterUseCase,
        _currentPosition = BookPosition(
          chapterIndex: initialChapterIndex,
          paragraphIndex: initialParagraphIndex,
          timestamp: DateTime.now(),
        ),
        _audioState = AudioPlaybackState(
          position: BookPosition(
            chapterIndex: initialChapterIndex,
            paragraphIndex: initialParagraphIndex,
            timestamp: DateTime.now(),
          ),
        ) {
    _initAudioEngine();
    loadChapter(initialChapterIndex, paragraphIndex: initialParagraphIndex);
  }

  void _initAudioEngine() {
    _audioEngine.setOnCompletion(_onParagraphAudioFinished);
    _audioEngine.setOnError((msg) {
      _audioState = _audioState.copyWith(
        status: AudioPlaybackStatus.error,
        errorMessage: msg,
      );
      notifyListeners();
    });
  }

  // ----------------- GETTERS -----------------
  BookPosition get currentPosition => _currentPosition;
  int get currentChapterIndex => _currentPosition.chapterIndex;
  int get currentParagraphIndex => _currentPosition.paragraphIndex;
  ChapterContent? get currentChapterContent => _currentChapterContent;
  List<String> get currentChapterParagraphs => _currentChapterParagraphs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get showControls => _showControls;
  ReaderPreferences get preferences => _preferences;
  AudioPlaybackState get audioState => _audioState;
  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);

  bool get hasPreviousChapter => _currentPosition.chapterIndex > 0;
  bool get hasNextChapter =>
      _currentPosition.chapterIndex < book.chapterCount - 1;

  double get readingProgress => book.chapterCount > 0
      ? (_currentPosition.chapterIndex + 1) / book.chapterCount
      : 0.0;

  bool get isCurrentChapterBookmarked => _bookmarks.any(
        (b) =>
            b.bookId == book.id &&
            b.chapterIndex == _currentPosition.chapterIndex,
      );

  // ----------------- CHAPTER & POSITION -----------------

  /// Loads chapter content and sets initial paragraph index.
  Future<void> loadChapter(
    int index, {
    int paragraphIndex = 0,
    String? targetAnchor,
  }) async {
    if (index < 0 || index >= book.chapterCount) return;

    _isLoading = true;
    _errorMessage = null;

    final wasPlaying = _audioState.isPlaying;
    if (wasPlaying) {
      await _audioEngine.stop();
    }

    _currentPosition = _currentPosition.copyWith(
      chapterIndex: index,
      paragraphIndex: paragraphIndex,
      timestamp: DateTime.now(),
    );

    _audioState = _audioState.copyWith(
      position: _currentPosition,
      status: wasPlaying ? AudioPlaybackStatus.buffering : AudioPlaybackStatus.stopped,
    );
    notifyListeners();

    try {
      final rawChapter = book.getChapter(index);
      _currentChapterContent = _parseChapterUseCase.execute(rawChapter);
      _currentChapterParagraphs = _currentChapterContent!.paragraphsAsText;

      // If a target anchor is specified, find its block index
      if (targetAnchor != null) {
        final anchorIdx =
            _currentChapterContent!.findBlockIndexByAnchor(targetAnchor);
        if (anchorIdx != null) {
          paragraphIndex = anchorIdx.clamp(0, _currentChapterParagraphs.length - 1);
          _currentPosition = _currentPosition.copyWith(paragraphIndex: paragraphIndex);
        }
      }

      _audioState = _audioState.copyWith(
        position: _currentPosition,
        totalParagraphsInChapter: _currentChapterParagraphs.length,
        currentText: _currentChapterParagraphs.isNotEmpty &&
                paragraphIndex < _currentChapterParagraphs.length
            ? _currentChapterParagraphs[paragraphIndex]
            : null,
      );

      if (wasPlaying && _currentChapterParagraphs.isNotEmpty) {
        await _speakCurrentParagraph();
      }
    } catch (e) {
      _errorMessage = 'Failed to load chapter: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> nextChapter() async {
    if (hasNextChapter) {
      await loadChapter(_currentPosition.chapterIndex + 1);
    }
  }

  Future<void> previousChapter() async {
    if (hasPreviousChapter) {
      await loadChapter(_currentPosition.chapterIndex - 1);
    }
  }

  /// Jumps to a specific paragraph within the current chapter (syncs both reader highlight and audio).
  Future<void> seekToParagraph(int paragraphIndex) async {
    if (_currentChapterParagraphs.isEmpty) return;

    final clampedIdx = paragraphIndex.clamp(0, _currentChapterParagraphs.length - 1);
    _currentPosition = _currentPosition.copyWith(
      paragraphIndex: clampedIdx,
      timestamp: DateTime.now(),
    );

    final currentText = _currentChapterParagraphs[clampedIdx];
    _audioState = _audioState.copyWith(
      position: _currentPosition,
      currentText: currentText,
    );
    notifyListeners();

    if (_audioState.isPlaying) {
      await _speakCurrentParagraph();
    }
  }

  // ----------------- AUDIO PLAYBACK CONTROLS -----------------

  /// Starts or resumes audio playback from the current position.
  Future<void> playAudio() async {
    if (_currentChapterParagraphs.isEmpty) {
      if (_currentChapterContent == null) {
        await loadChapter(_currentPosition.chapterIndex);
      }
      if (_currentChapterParagraphs.isEmpty) return;
    }

    _audioState = _audioState.copyWith(status: AudioPlaybackStatus.playing);
    notifyListeners();

    await _speakCurrentParagraph();
  }

  /// Pauses audio playback.
  Future<void> pauseAudio() async {
    await _audioEngine.pause();
    await _audioEngine.stop();
    _audioState = _audioState.copyWith(status: AudioPlaybackStatus.paused);
    notifyListeners();
  }

  /// Toggles between Play and Pause.
  Future<void> toggleAudioPlayPause() async {
    if (_audioState.isPlaying) {
      await pauseAudio();
    } else {
      await playAudio();
    }
  }

  /// Stops audio playback and resets to start of chapter.
  Future<void> stopAudio() async {
    await _audioEngine.stop();
    _audioState = _audioState.copyWith(status: AudioPlaybackStatus.stopped);
    notifyListeners();
  }

  /// Skips to next paragraph in audio playback.
  Future<void> nextAudioParagraph() async {
    if (_currentPosition.paragraphIndex < _currentChapterParagraphs.length - 1) {
      await seekToParagraph(_currentPosition.paragraphIndex + 1);
    } else if (hasNextChapter) {
      // Advance to next chapter
      await loadChapter(_currentPosition.chapterIndex + 1, paragraphIndex: 0);
      if (_audioState.isPlaying) {
        await _speakCurrentParagraph();
      }
    } else {
      await stopAudio();
    }
  }

  /// Skips to previous paragraph in audio playback.
  Future<void> previousAudioParagraph() async {
    if (_currentPosition.paragraphIndex > 0) {
      await seekToParagraph(_currentPosition.paragraphIndex - 1);
    } else if (hasPreviousChapter) {
      await loadChapter(_currentPosition.chapterIndex - 1);
    }
  }

  /// Sets audio playback speed (0.75x, 1.0x, 1.25x, 1.5x, 2.0x).
  Future<void> setAudioSpeed(double speed) async {
    _audioState = _audioState.copyWith(speechRate: speed);
    await _audioEngine.setRate(speed);
    notifyListeners();
  }

  /// Sets sleep timer duration (or null to cancel).
  void setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    _sleepTimer = null;

    if (duration == null) {
      _audioState = _audioState.copyWith(clearSleepTimer: true);
      notifyListeners();
      return;
    }

    _audioState = _audioState.copyWith(sleepTimerRemaining: duration);
    notifyListeners();

    _sleepTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentRemaining = _audioState.sleepTimerRemaining;
      if (currentRemaining == null || currentRemaining.inSeconds <= 1) {
        timer.cancel();
        pauseAudio();
        _audioState = _audioState.copyWith(clearSleepTimer: true);
        notifyListeners();
      } else {
        _audioState = _audioState.copyWith(
          sleepTimerRemaining: currentRemaining - const Duration(seconds: 1),
        );
        notifyListeners();
      }
    });
  }

  Future<void> _speakCurrentParagraph() async {
    if (_currentChapterParagraphs.isEmpty) return;

    final pIdx = _currentPosition.paragraphIndex.clamp(
      0,
      _currentChapterParagraphs.length - 1,
    );
    final text = _currentChapterParagraphs[pIdx];

    _audioState = _audioState.copyWith(
      status: AudioPlaybackStatus.playing,
      currentText: text,
      position: _currentPosition.copyWith(paragraphIndex: pIdx),
    );
    notifyListeners();

    await _audioEngine.speakParagraph(text, language: book.metadata.language);
  }

  void _onParagraphAudioFinished() {
    if (!_audioState.isPlaying) return;

    if (_currentPosition.paragraphIndex < _currentChapterParagraphs.length - 1) {
      // Advance to next paragraph
      seekToParagraph(_currentPosition.paragraphIndex + 1);
    } else if (hasNextChapter) {
      // Auto-advance to next chapter
      loadChapter(_currentPosition.chapterIndex + 1, paragraphIndex: 0).then((_) {
        if (_audioState.isPlaying) {
          _speakCurrentParagraph();
        }
      });
    } else {
      // Reached the very end of the book
      stopAudio();
    }
  }

  // ----------------- READER CONTROLS -----------------

  void toggleControls() {
    _showControls = !_showControls;
    notifyListeners();
  }

  void updatePreferences(ReaderPreferences newPrefs) {
    _preferences = newPrefs;
    notifyListeners();
  }

  void toggleBookmark() {
    if (isCurrentChapterBookmarked) {
      _bookmarks.removeWhere(
        (b) =>
            b.bookId == book.id &&
            b.chapterIndex == _currentPosition.chapterIndex,
      );
    } else {
      final snippet = _currentChapterParagraphs.isNotEmpty
          ? _currentChapterParagraphs[_currentPosition.paragraphIndex.clamp(0, _currentChapterParagraphs.length - 1)]
          : _currentChapterContent?.title ?? 'Chapter ${_currentPosition.chapterIndex + 1}';

      final bookmark = Bookmark(
        id: 'bm_${DateTime.now().millisecondsSinceEpoch}',
        bookId: book.id,
        chapterIndex: _currentPosition.chapterIndex,
        chapterTitle: _currentChapterContent?.title ??
            'Chapter ${_currentPosition.chapterIndex + 1}',
        snippet: snippet.length > 120 ? '${snippet.substring(0, 120)}...' : snippet,
        createdAt: DateTime.now(),
      );
      _bookmarks.add(bookmark);
    }
    notifyListeners();
  }

  void deleteBookmark(Bookmark bookmark) {
    _bookmarks.removeWhere((b) => b.id == bookmark.id);
    notifyListeners();
  }

  void handleLink(LinkSpanNode link) {
    if (link.targetPath != null) {
      final targetNormalized = EpubPathUtils.normalize(link.targetPath!);
      for (int i = 0; i < book.spine.length; i++) {
        if (EpubPathUtils.normalize(book.spine[i].fullPath) == targetNormalized) {
          loadChapter(i, targetAnchor: link.anchor);
          return;
        }
      }
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _audioEngine.dispose();
    super.dispose();
  }
}
