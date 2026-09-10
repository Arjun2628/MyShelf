import 'package:epub_audio/core/utils/path_utils.dart';
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/epub/domain/entities/chapter_content.dart';
import 'package:epub_audio/features/epub/domain/entities/content_nodes.dart';
import 'package:epub_audio/features/epub/domain/usecases/parse_chapter_content_usecase.dart';
import 'package:epub_audio/features/reader/domain/entities/bookmark.dart';
import 'package:epub_audio/features/reader/domain/entities/reader_preferences.dart';
import 'package:flutter/foundation.dart';

/// Controller managing reader state, chapter navigation, preferences, and bookmarks.
class ReaderController extends ChangeNotifier {
  final Book book;
  final ParseChapterContentUseCase _parseChapterUseCase;

  int _currentChapterIndex = 0;
  ChapterContent? _currentChapterContent;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showControls = true;
  ReaderPreferences _preferences = const ReaderPreferences();
  final List<Bookmark> _bookmarks = [];

  ReaderController({
    required this.book,
    ParseChapterContentUseCase parseChapterUseCase =
        const ParseChapterContentUseCase(),
    int initialChapterIndex = 0,
  })  : _parseChapterUseCase = parseChapterUseCase,
        _currentChapterIndex = initialChapterIndex {
    loadChapter(_currentChapterIndex);
  }

  // Getters
  int get currentChapterIndex => _currentChapterIndex;
  ChapterContent? get currentChapterContent => _currentChapterContent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get showControls => _showControls;
  ReaderPreferences get preferences => _preferences;
  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);

  bool get hasPreviousChapter => _currentChapterIndex > 0;
  bool get hasNextChapter => _currentChapterIndex < book.chapterCount - 1;

  double get readingProgress =>
      book.chapterCount > 0 ? (_currentChapterIndex + 1) / book.chapterCount : 0.0;

  bool get isCurrentChapterBookmarked =>
      _bookmarks.any((b) => b.bookId == book.id && b.chapterIndex == _currentChapterIndex);

  /// Loads and parses the specified chapter by spine index.
  Future<void> loadChapter(int index, {String? targetAnchor}) async {
    if (index < 0 || index >= book.chapterCount) return;

    _isLoading = true;
    _errorMessage = null;
    _currentChapterIndex = index;
    notifyListeners();

    try {
      final rawChapter = book.getChapter(index);
      _currentChapterContent = _parseChapterUseCase.execute(rawChapter);
    } catch (e) {
      _errorMessage = 'Failed to load chapter: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Navigates to the next chapter if available.
  Future<void> nextChapter() async {
    if (hasNextChapter) {
      await loadChapter(_currentChapterIndex + 1);
    }
  }

  /// Navigates to the previous chapter if available.
  Future<void> previousChapter() async {
    if (hasPreviousChapter) {
      await loadChapter(_currentChapterIndex - 1);
    }
  }

  /// Toggles visibility of reader toolbars and navigation chrome.
  void toggleControls() {
    _showControls = !_showControls;
    notifyListeners();
  }

  /// Updates reader display preferences (theme, font, size, line spacing).
  void updatePreferences(ReaderPreferences newPrefs) {
    _preferences = newPrefs;
    notifyListeners();
  }

  /// Toggles bookmark on the current chapter.
  void toggleBookmark() {
    if (isCurrentChapterBookmarked) {
      _bookmarks.removeWhere(
        (b) => b.bookId == book.id && b.chapterIndex == _currentChapterIndex,
      );
    } else {
      final snippet = _currentChapterContent?.paragraphsAsText.firstOrNull ??
          _currentChapterContent?.title ??
          'Chapter ${_currentChapterIndex + 1}';

      final bookmark = Bookmark(
        id: 'bm_${DateTime.now().millisecondsSinceEpoch}',
        bookId: book.id,
        chapterIndex: _currentChapterIndex,
        chapterTitle: _currentChapterContent?.title ?? 'Chapter ${_currentChapterIndex + 1}',
        snippet: snippet.length > 120 ? '${snippet.substring(0, 120)}...' : snippet,
        createdAt: DateTime.now(),
      );
      _bookmarks.add(bookmark);
    }
    notifyListeners();
  }

  /// Deletes a specific bookmark.
  void deleteBookmark(Bookmark bookmark) {
    _bookmarks.removeWhere((b) => b.id == bookmark.id);
    notifyListeners();
  }

  /// Handles internal hyperlink taps to jump to other chapters or anchors.
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
}
