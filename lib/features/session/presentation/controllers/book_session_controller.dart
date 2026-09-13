import 'dart:async';
import 'package:epub_audio/core/utils/path_utils.dart';
import 'package:epub_audio/features/audio/data/services/audio_notification_service.dart';
import 'package:epub_audio/features/audio/data/services/flutter_tts_audio_engine.dart';
import 'package:epub_audio/features/audio/domain/entities/audio_playback_state.dart';
import 'package:epub_audio/features/audio/domain/services/audio_source_engine.dart';
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/epub/domain/entities/chapter_content.dart';
import 'package:epub_audio/features/epub/domain/entities/content_nodes.dart';
import 'package:epub_audio/features/epub/domain/usecases/parse_chapter_content_usecase.dart';
import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:epub_audio/features/reader/data/services/translation_service.dart';
import 'package:epub_audio/features/reader/domain/entities/bookmark.dart';
import 'package:epub_audio/features/reader/domain/entities/reader_preferences.dart';
import 'package:epub_audio/features/session/domain/entities/book_position.dart';
import 'package:flutter/foundation.dart';

/// Unified session controller managing shared reading position, audio narration,
/// chapter navigation, preferences, and bookmarks with persistent progress.
class BookSessionController extends ChangeNotifier {
  /// Global active session tracker for Home Screen player and notification sync.
  static BookSessionController? activeSession;
  static final ValueNotifier<BookSessionController?> activeSessionNotifier =
      ValueNotifier<BookSessionController?>(null);

  final Book book;
  final AudioSourceEngine _audioEngine;
  final ParseChapterContentUseCase _parseChapterUseCase;

  BookPosition _currentPosition;
  ChapterContent? _currentChapterContent;
  List<String> _currentChapterParagraphs = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _showControls = true;

  ReaderPreferences _preferences = HiveStorageService().getReaderPreferences();
  AudioPlaybackState _audioState;
  final List<Bookmark> _bookmarks = [];
  Timer? _sleepTimer;

  // Translation state and caching
  String? _activeTranslationLanguage;
  final Map<int, ChapterContent> _originalChapters = {};
  final Map<String, Map<int, ChapterContent>> _translatedChaptersCache = {};
  final TranslationService _translationService = TranslationService();

  BookSessionController({
    required this.book,
    AudioSourceEngine? audioEngine,
    ParseChapterContentUseCase parseChapterUseCase =
        const ParseChapterContentUseCase(),
    int? initialChapterIndex,
    int? initialParagraphIndex,
    int? initialCharOffset,
  })  : _audioEngine = audioEngine ?? FlutterTtsAudioEngine(),
        _parseChapterUseCase = parseChapterUseCase,
        _currentPosition = _computeInitialPosition(
          book,
          initialChapterIndex,
          initialParagraphIndex,
          initialCharOffset,
        ),
        _audioState = AudioPlaybackState(
          position: _computeInitialPosition(
            book,
            initialChapterIndex,
            initialParagraphIndex,
            initialCharOffset,
          ),
        ) {
    activeSession = this;
    activeSessionNotifier.value = this;
    _setupNotificationHandlers();
    _initAudioEngine();
    _initInitialChapter(_currentPosition.chapterIndex, _currentPosition.paragraphIndex);
    _loadBookmarks();
  }

  void _setupNotificationHandlers() {
    final notif = AudioNotificationService();
    notif.onPlayPressed = () {
      if (activeSession == this) {
        playAudio();
      }
    };
    notif.onPausePressed = () {
      if (activeSession == this) {
        pauseAudio();
      }
    };
    notif.onNextPressed = () {
      if (activeSession == this) {
        nextAudioParagraph();
      }
    };
    notif.onPrevPressed = () {
      if (activeSession == this) {
        previousAudioParagraph();
      }
    };
    notif.onStopPressed = () {
      if (activeSession == this) {
        stopAudio();
      }
    };
  }

  void _syncNotification() {
    final chTitle = _currentChapterContent?.title ??
        'Chapter ${_currentPosition.chapterIndex + 1}';

    AudioNotificationService().showOrUpdatePlaybackNotification(
      bookTitle: book.metadata.title,
      author: book.metadata.author,
      chapterTitle: chTitle,
      isPlaying: _audioState.isPlaying,
      coverImageBytes: book.coverImageBytes,
      currentParagraph: _currentPosition.paragraphIndex + 1,
      totalParagraphs: _currentChapterParagraphs.length,
    );
  }

  void _loadBookmarks() {
    _bookmarks.clear();
    _bookmarks.addAll(HiveStorageService().getBookmarksForBook(book.id));
  }

  int _currentParagraphSpeakingOffset = 0;

  static BookPosition _computeInitialPosition(
    Book book,
    int? chapterIdx,
    int? paraIdx, [
    int? charOffset,
  ]) {
    if (chapterIdx != null) {
      return BookPosition(
        chapterIndex: chapterIdx,
        paragraphIndex: paraIdx ?? 0,
        charOffset: charOffset ?? 0,
        timestamp: DateTime.now(),
      );
    }
    // Check saved progress from Hive
    final saved = HiveStorageService().getProgress(book.id);
    if (saved != null &&
        saved.chapterIndex >= 0 &&
        saved.chapterIndex < (book.chapterCount > 0 ? book.chapterCount : 1)) {
      return BookPosition(
        chapterIndex: saved.chapterIndex,
        paragraphIndex: saved.paragraphIndex,
        charOffset: saved.charOffset,
        timestamp: saved.lastUpdated,
      );
    }
    return BookPosition(
      chapterIndex: 0,
      paragraphIndex: 0,
      charOffset: 0,
      timestamp: DateTime.now(),
    );
  }

  void _persistProgress() {
    HiveStorageService().saveProgress(
      bookId: book.id,
      chapterIndex: _currentPosition.chapterIndex,
      paragraphIndex: _currentPosition.paragraphIndex,
      charOffset: _currentPosition.charOffset,
    );
  }

  void _initInitialChapter(int chapterIndex, int paragraphIndex) {
    if (book.chapterCount > 0 && chapterIndex >= 0 && chapterIndex < book.chapterCount) {
      try {
        final rawChapter = book.getChapter(chapterIndex);
        _currentChapterContent = _parseChapterUseCase.execute(rawChapter);
        _currentChapterParagraphs = _currentChapterContent!.paragraphsAsText;
        _audioState = _audioState.copyWith(
          position: _currentPosition,
          totalParagraphsInChapter: _currentChapterParagraphs.length,
          currentText: _currentChapterParagraphs.isNotEmpty &&
                  paragraphIndex < _currentChapterParagraphs.length
              ? _currentChapterParagraphs[paragraphIndex]
              : null,
        );
      } catch (e) {
        _errorMessage = 'Failed to load initial chapter: $e';
      }
    }
  }

  void _initAudioEngine() {
    _audioEngine.setOnCompletion(_onParagraphAudioFinished);
    _audioEngine.setOnProgress(_onAudioProgress);
    _audioEngine.setOnError((msg) {
      debugPrint('[SessionController] Audio error: $msg');
      _audioState = _audioState.copyWith(
        status: AudioPlaybackStatus.error,
        errorMessage: msg,
      );
      notifyListeners();
    });
  }

  void _onAudioProgress(String text, int startOffset, int endOffset, String word) {
    if (!_audioState.isPlaying) return;

    final absoluteCharOffset = _currentParagraphSpeakingOffset + startOffset;
    _currentPosition = _currentPosition.copyWith(charOffset: absoluteCharOffset);
    _audioState = _audioState.copyWith(position: _currentPosition);
    notifyListeners();
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

  String? get activeTranslationLanguage => _activeTranslationLanguage;
  bool get isTranslated => _activeTranslationLanguage != null;
  String get activeTranslationLanguageName =>
      _activeTranslationLanguage != null
          ? _translationService.getLanguageName(_activeTranslationLanguage!)
          : '';
  String get activeTranslationLanguageFlag =>
      _activeTranslationLanguage != null
          ? _translationService.getLanguageFlag(_activeTranslationLanguage!)
          : '';

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

    _currentParagraphSpeakingOffset = 0;
    _currentPosition = _currentPosition.copyWith(
      chapterIndex: index,
      paragraphIndex: paragraphIndex,
      charOffset: 0,
      timestamp: DateTime.now(),
    );

    _audioState = _audioState.copyWith(
      position: _currentPosition,
      status: wasPlaying ? AudioPlaybackStatus.buffering : AudioPlaybackStatus.stopped,
    );
    notifyListeners();

    try {
      ChapterContent loadedContent;
      if (!_originalChapters.containsKey(index)) {
        final rawChapter = book.getChapter(index);
        _originalChapters[index] = _parseChapterUseCase.execute(rawChapter);
      }
      final original = _originalChapters[index]!;

      if (_activeTranslationLanguage != null) {
        final cached = _translatedChaptersCache[_activeTranslationLanguage!]?[index];
        if (cached != null) {
          loadedContent = cached;
        } else {
          loadedContent = await _translationService.translateChapter(
            original,
            targetLanguage: _activeTranslationLanguage!,
          );
          _translatedChaptersCache.putIfAbsent(_activeTranslationLanguage!, () => {})[index] = loadedContent;
        }
      } else {
        loadedContent = original;
      }

      _currentChapterContent = loadedContent;
      _currentChapterParagraphs = _currentChapterContent!.paragraphsAsText;

      // If a target anchor is specified, find its block index
      if (targetAnchor != null) {
        final anchorIdx =
            _currentChapterContent!.findBlockIndexByAnchor(targetAnchor);
        if (anchorIdx != null && _currentChapterParagraphs.isNotEmpty) {
          paragraphIndex = anchorIdx.clamp(0, _currentChapterParagraphs.length - 1);
          _currentPosition = _currentPosition.copyWith(
            paragraphIndex: paragraphIndex,
            charOffset: 0,
          );
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
        await _speakCurrentParagraph(fromCharOffset: false);
      }
    } catch (e) {
      _errorMessage = 'Failed to load chapter: $e';
    } finally {
      _isLoading = false;
      _persistProgress();
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
  Future<void> seekToParagraph(int paragraphIndex, {bool autoPlay = true}) async {
    if (_currentChapterParagraphs.isEmpty) {
      if (_currentChapterContent == null) {
        await loadChapter(
          _currentPosition.chapterIndex,
          paragraphIndex: paragraphIndex,
        );
      }
      if (_currentChapterParagraphs.isEmpty) return;
    }

    final clampedIdx =
        paragraphIndex.clamp(0, _currentChapterParagraphs.length - 1);
    _currentParagraphSpeakingOffset = 0;
    _currentPosition = _currentPosition.copyWith(
      paragraphIndex: clampedIdx,
      charOffset: 0,
      timestamp: DateTime.now(),
    );

    final currentText = _currentChapterParagraphs[clampedIdx];
    final shouldPlay = autoPlay || _audioState.isPlaying;

    _audioState = _audioState.copyWith(
      position: _currentPosition,
      currentText: currentText,
      status: shouldPlay ? AudioPlaybackStatus.playing : AudioPlaybackStatus.paused,
    );
    _persistProgress();
    notifyListeners();

    if (shouldPlay) {
      await _speakCurrentParagraph(fromCharOffset: false);
    }
  }

  // ----------------- AUDIO PLAYBACK CONTROLS -----------------

  /// Starts or resumes audio playback from the current position and paused word offset.
  Future<void> playAudio() async {
    if (_currentChapterParagraphs.isEmpty) {
      if (_currentChapterContent == null) {
        await loadChapter(
          _currentPosition.chapterIndex,
          paragraphIndex: _currentPosition.paragraphIndex,
        );
      }
      if (_currentChapterParagraphs.isEmpty) return;
    }

    final pIdx = _currentPosition.paragraphIndex
        .clamp(0, _currentChapterParagraphs.length - 1);
    _currentPosition = _currentPosition.copyWith(paragraphIndex: pIdx);

    _audioState = _audioState.copyWith(
      status: AudioPlaybackStatus.playing,
      position: _currentPosition,
      currentText: _currentChapterParagraphs.isNotEmpty
          ? _currentChapterParagraphs[pIdx]
          : null,
    );
    _persistProgress();
    notifyListeners();

    await _speakCurrentParagraph(fromCharOffset: true);
  }

  /// Pauses audio playback without losing the current paragraph or word position.
  Future<void> pauseAudio() async {
    _audioState = _audioState.copyWith(
      status: AudioPlaybackStatus.paused,
      position: _currentPosition,
    );
    _persistProgress();
    notifyListeners();
    _syncNotification();

    await _audioEngine.stop();
  }

  /// Toggles between Play and Pause.
  Future<void> toggleAudioPlayPause() async {
    if (_audioState.isPlaying) {
      await pauseAudio();
    } else {
      await playAudio();
    }
  }

  /// Stops audio playback.
  Future<void> stopAudio() async {
    _currentPosition = _currentPosition.copyWith(charOffset: 0);
    _currentParagraphSpeakingOffset = 0;
    _audioState = _audioState.copyWith(
      status: AudioPlaybackStatus.stopped,
      position: _currentPosition,
    );
    _persistProgress();
    notifyListeners();
    AudioNotificationService().cancelNotification();

    await _audioEngine.stop();
  }

  /// Skips to next paragraph in audio playback.
  Future<void> nextAudioParagraph() async {
    if (_currentPosition.paragraphIndex < _currentChapterParagraphs.length - 1) {
      await seekToParagraph(_currentPosition.paragraphIndex + 1);
    } else if (hasNextChapter) {
      await loadChapter(_currentPosition.chapterIndex + 1, paragraphIndex: 0);
      if (_audioState.isPlaying) {
        await _speakCurrentParagraph(fromCharOffset: false);
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

  Future<void> _speakCurrentParagraph({bool fromCharOffset = false}) async {
    if (_currentChapterParagraphs.isEmpty) return;

    final pIdx = _currentPosition.paragraphIndex.clamp(
      0,
      _currentChapterParagraphs.length - 1,
    );
    final fullText = _currentChapterParagraphs[pIdx];

    int startOffset = 0;
    if (fromCharOffset &&
        _currentPosition.charOffset > 0 &&
        _currentPosition.charOffset < fullText.length) {
      startOffset = _currentPosition.charOffset;
      // Skip leading spaces to start cleanly on the word
      while (startOffset < fullText.length && fullText[startOffset] == ' ') {
        startOffset++;
      }
    }

    _currentParagraphSpeakingOffset = startOffset;
    final textToSpeak = (startOffset > 0 && startOffset < fullText.length)
        ? fullText.substring(startOffset)
        : fullText;

    if (textToSpeak.trim().isEmpty) {
      _onParagraphAudioFinished();
      return;
    }

    _audioState = _audioState.copyWith(
      status: AudioPlaybackStatus.playing,
      currentText: fullText,
      position: _currentPosition.copyWith(paragraphIndex: pIdx),
    );
    _persistProgress();
    notifyListeners();
    _syncNotification();

    await _audioEngine.speakParagraph(
      textToSpeak,
      language: _activeTranslationLanguage ?? book.metadata.language,
    );
  }

  void _onParagraphAudioFinished() {
    if (!_audioState.isPlaying) return;

    _currentPosition = _currentPosition.copyWith(charOffset: 0);
    _currentParagraphSpeakingOffset = 0;

    if (_currentPosition.paragraphIndex < _currentChapterParagraphs.length - 1) {
      seekToParagraph(_currentPosition.paragraphIndex + 1);
    } else if (hasNextChapter) {
      loadChapter(_currentPosition.chapterIndex + 1, paragraphIndex: 0).then((_) {
        if (_audioState.isPlaying) {
          _speakCurrentParagraph(fromCharOffset: false);
        }
      });
    } else {
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
    HiveStorageService().saveReaderPreferences(newPrefs);
    notifyListeners();
  }

  /// Synchronizes reader appearance mode with application theme brightness.
  void syncWithAppBrightness(bool isDark) {
    if (isDark && _preferences.themeMode == ReaderThemeMode.light) {
      _preferences = _preferences.copyWith(themeMode: ReaderThemeMode.night);
      HiveStorageService().saveReaderPreferences(_preferences);
      notifyListeners();
    } else if (!isDark && _preferences.themeMode == ReaderThemeMode.night) {
      _preferences = _preferences.copyWith(themeMode: ReaderThemeMode.light);
      HiveStorageService().saveReaderPreferences(_preferences);
      notifyListeners();
    }
  }

  void toggleBookmark() {
    if (isCurrentChapterBookmarked) {
      final toRemove = _bookmarks.where(
        (b) =>
            b.bookId == book.id &&
            b.chapterIndex == _currentPosition.chapterIndex,
      ).toList();
      for (final bm in toRemove) {
        HiveStorageService().deleteBookmark(bm.id);
      }
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
      HiveStorageService().saveBookmark(bookmark);
    }
    notifyListeners();
  }

  void deleteBookmark(Bookmark bookmark) {
    _bookmarks.removeWhere((b) => b.id == bookmark.id);
    HiveStorageService().deleteBookmark(bookmark.id);
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

  /// Speaks ad-hoc custom text snippet (e.g. for translation or pronunciation)
  Future<void> speakCustomText(String text, {String? language}) async {
    await _audioEngine.speakParagraph(
      text,
      language: language ?? _activeTranslationLanguage ?? book.metadata.language,
    );
  }

  // ----------------- TRANSLATION CONTROLS -----------------

  /// Translates the currently active chapter into [targetLanguage], updates reader view,
  /// and automatically routes TTS narration voice to the target language.
  Future<void> translateCurrentChapter(
    String targetLanguage, {
    void Function(double progress, String status)? onProgress,
  }) async {
    final chapterIdx = _currentPosition.chapterIndex;
    if (chapterIdx < 0 || chapterIdx >= book.chapterCount) return;

    final wasPlaying = _audioState.isPlaying;
    if (wasPlaying) {
      await _audioEngine.stop();
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!_originalChapters.containsKey(chapterIdx)) {
        final rawChapter = book.getChapter(chapterIdx);
        _originalChapters[chapterIdx] = _parseChapterUseCase.execute(rawChapter);
      }
      final original = _originalChapters[chapterIdx]!;

      onProgress?.call(
        0.1,
        'Translating chapter to ${_translationService.getLanguageName(targetLanguage)}...',
      );

      final translated = await _translationService.translateChapter(
        original,
        targetLanguage: targetLanguage,
        onProgress: onProgress,
      );

      _translatedChaptersCache.putIfAbsent(targetLanguage, () => {})[chapterIdx] = translated;
      _activeTranslationLanguage = targetLanguage;
      _currentChapterContent = translated;
      _currentChapterParagraphs = translated.paragraphsAsText;

      final pIdx = _currentPosition.paragraphIndex.clamp(
        0,
        _currentChapterParagraphs.isNotEmpty ? _currentChapterParagraphs.length - 1 : 0,
      );
      _currentPosition = _currentPosition.copyWith(
        paragraphIndex: pIdx,
        charOffset: 0,
      );

      _audioState = _audioState.copyWith(
        position: _currentPosition,
        totalParagraphsInChapter: _currentChapterParagraphs.length,
        currentText: _currentChapterParagraphs.isNotEmpty ? _currentChapterParagraphs[pIdx] : null,
        status: wasPlaying ? AudioPlaybackStatus.playing : AudioPlaybackStatus.stopped,
      );

      if (wasPlaying && _currentChapterParagraphs.isNotEmpty) {
        await _speakCurrentParagraph(fromCharOffset: false);
      }
    } catch (e) {
      debugPrint('[SessionController] Error translating chapter: $e');
      _errorMessage = 'Failed to translate chapter: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Translates all chapters in the book sequentially with progress reporting.
  Future<void> translateEntireBook(
    String targetLanguage, {
    void Function(double progress, String status)? onProgress,
  }) async {
    final total = book.chapterCount;
    if (total == 0) return;

    final wasPlaying = _audioState.isPlaying;
    if (wasPlaying) {
      await _audioEngine.stop();
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      for (int i = 0; i < total; i++) {
        final overallProg = i / total;
        onProgress?.call(
          overallProg,
          'Translating chapter ${i + 1} of $total to ${_translationService.getLanguageName(targetLanguage)}...',
        );

        if (!_originalChapters.containsKey(i)) {
          final rawChapter = book.getChapter(i);
          _originalChapters[i] = _parseChapterUseCase.execute(rawChapter);
        }
        final original = _originalChapters[i]!;

        final translated = await _translationService.translateChapter(
          original,
          targetLanguage: targetLanguage,
        );
        _translatedChaptersCache.putIfAbsent(targetLanguage, () => {})[i] = translated;
      }

      _activeTranslationLanguage = targetLanguage;
      final curIdx = _currentPosition.chapterIndex;
      final currentTranslated = _translatedChaptersCache[targetLanguage]?[curIdx];
      if (currentTranslated != null) {
        _currentChapterContent = currentTranslated;
        _currentChapterParagraphs = currentTranslated.paragraphsAsText;
      }

      onProgress?.call(1.0, 'Book translated successfully!');
      if (wasPlaying && _currentChapterParagraphs.isNotEmpty) {
        await _speakCurrentParagraph(fromCharOffset: false);
      }
    } catch (e) {
      debugPrint('[SessionController] Error translating entire book: $e');
      _errorMessage = 'Failed to translate book: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reverts the reader and audio voice back to the original book language.
  Future<void> revertToOriginalLanguage() async {
    if (_activeTranslationLanguage == null) return;

    final wasPlaying = _audioState.isPlaying;
    if (wasPlaying) {
      await _audioEngine.stop();
    }

    _activeTranslationLanguage = null;
    final curIdx = _currentPosition.chapterIndex;
    if (_originalChapters.containsKey(curIdx)) {
      _currentChapterContent = _originalChapters[curIdx];
    } else {
      final rawChapter = book.getChapter(curIdx);
      _currentChapterContent = _parseChapterUseCase.execute(rawChapter);
      _originalChapters[curIdx] = _currentChapterContent!;
    }
    _currentChapterParagraphs = _currentChapterContent!.paragraphsAsText;

    final pIdx = _currentPosition.paragraphIndex.clamp(
      0,
      _currentChapterParagraphs.isNotEmpty ? _currentChapterParagraphs.length - 1 : 0,
    );
    _currentPosition = _currentPosition.copyWith(
      paragraphIndex: pIdx,
      charOffset: 0,
    );

    _audioState = _audioState.copyWith(
      position: _currentPosition,
      totalParagraphsInChapter: _currentChapterParagraphs.length,
      currentText: _currentChapterParagraphs.isNotEmpty ? _currentChapterParagraphs[pIdx] : null,
      status: wasPlaying ? AudioPlaybackStatus.playing : AudioPlaybackStatus.stopped,
    );
    notifyListeners();

    if (wasPlaying && _currentChapterParagraphs.isNotEmpty) {
      await _speakCurrentParagraph(fromCharOffset: false);
    }
  }

  @override
  void dispose() {
    _persistProgress();
    _sleepTimer?.cancel();
    _audioEngine.dispose();
    super.dispose();
  }
}
