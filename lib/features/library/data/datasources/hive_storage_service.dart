import 'dart:convert';
import 'dart:io';
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/epub/domain/usecases/open_epub_usecase.dart';
import 'package:epub_audio/features/pdf/domain/usecases/open_pdf_usecase.dart';
import 'package:epub_audio/features/reader/domain/entities/bookmark.dart';
import 'package:epub_audio/features/reader/domain/entities/text_highlight.dart';
import 'package:epub_audio/features/scan/data/parsers/scan_document_parser.dart';
import 'package:epub_audio/features/session/domain/entities/book_progress.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Manages local storage of imported EPUB files, PDFs, Scans, and reading/audiobook progress using Hive.
class HiveStorageService {
  static const String booksBoxName = 'imported_books_v1';
  static const String progressBoxName = 'reading_progress_v1';
  static const String highlightsBoxName = 'highlights_v1';
  static const String bookmarksBoxName = 'bookmarks_v1';
  static const String settingsBoxName = 'settings_v1';

  static final HiveStorageService _instance = HiveStorageService._internal();
  factory HiveStorageService() => _instance;
  HiveStorageService._internal();

  Box<dynamic>? _booksBox;
  Box<dynamic>? _progressBox;
  Box<dynamic>? _highlightsBox;
  Box<dynamic>? _bookmarksBox;
  Box<dynamic>? _settingsBox;
  bool _isInitialized = false;

  /// Initializes Hive and opens required boxes.
  Future<void> init([String? customPath]) async {
    if (_isInitialized) {
      if (_booksBox != null && _booksBox!.isOpen &&
          _progressBox != null && _progressBox!.isOpen &&
          _highlightsBox != null && _highlightsBox!.isOpen &&
          _bookmarksBox != null && _bookmarksBox!.isOpen &&
          _settingsBox != null && _settingsBox!.isOpen) {
        return;
      }
    }

    try {
      if (customPath != null) {
        Hive.init(customPath);
      } else {
        try {
          await Hive.initFlutter();
        } catch (_) {
          final tempDir = Directory.systemTemp.createTempSync('epub_hive_');
          Hive.init(tempDir.path);
        }
      }
      _booksBox = await Hive.openBox(booksBoxName);
      _progressBox = await Hive.openBox(progressBoxName);
      _highlightsBox = await Hive.openBox(highlightsBoxName);
      _bookmarksBox = await Hive.openBox(bookmarksBoxName);
      _settingsBox = await Hive.openBox(settingsBoxName);
      _isInitialized = true;
      debugPrint('[HiveStorage] Initialized successfully. Stored books: ${_booksBox?.length}');
    } catch (e) {
      debugPrint('[HiveStorage] Initialization error: $e');
    }
  }

  // ----------------- APP ONBOARDING / SETTINGS -----------------

  /// Checks whether the user has completed the first-launch onboarding/splash guide.
  bool hasSeenOnboarding() {
    if (_settingsBox == null || !_settingsBox!.isOpen) return false;
    return (_settingsBox?.get('has_seen_onboarding', defaultValue: false) as bool?) ?? false;
  }

  /// Sets whether the user has completed the first-launch onboarding/splash guide.
  Future<void> setHasSeenOnboarding([bool value = true]) async {
    await init();
    await _settingsBox?.put('has_seen_onboarding', value);
  }

  // ----------------- IMPORTED BOOKS PERSISTENCE -----------------

  /// Saves an imported EPUB or PDF file to device storage and indexes its metadata in Hive.
  Future<Book> saveImportedBook({
    required Uint8List bytes,
    required Book book,
    bool isPdf = false,
    bool isScan = false,
  }) async {
    await init();

    try {
      String basePath;
      try {
        final docDir = await getApplicationDocumentsDirectory();
        basePath = docDir.path;
      } catch (_) {
        basePath = Directory.systemTemp.path;
      }

      final booksDir = Directory('$basePath/books');
      if (!booksDir.existsSync()) {
        booksDir.createSync(recursive: true);
      }

      final isScannedDoc = isScan || book.isScan;
      final ext = isScannedDoc ? 'scan.json' : (isPdf || book.isPdf ? 'pdf' : 'epub');
      final sanitizedId = book.id.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final filePath = '${booksDir.path}/$sanitizedId.$ext';
      final file = File(filePath);

      if (isScannedDoc) {
        final parser = ScanDocumentParser();
        final jsonMap = parser.toJson(book);
        final jsonStr = jsonEncode(jsonMap);
        await file.writeAsString(jsonStr);
      } else {
        await file.writeAsBytes(bytes);
      }

      final bookRecord = {
        'id': book.id,
        'title': book.metadata.title,
        'author': book.metadata.author,
        'description': book.metadata.description,
        'language': book.metadata.language,
        'filePath': filePath,
        'coverBytes': book.coverImageBytes,
        'chapterCount': book.chapterCount,
        'isPdf': isPdf || book.isPdf,
        'isScan': isScannedDoc,
        'dateAdded': DateTime.now().toIso8601String(),
      };

      await _booksBox?.put(book.id, bookRecord);
      debugPrint('[HiveStorage] Saved book "${book.metadata.title}" to $filePath');
      return book;
    } catch (e) {
      debugPrint('[HiveStorage] Error saving book: $e');
      rethrow;
    }
  }

  /// Saves a scanned photo document book directly to storage.
  Future<Book> saveScannedBook(Book book) {
    return saveImportedBook(
      bytes: Uint8List(0),
      book: book,
      isScan: true,
    );
  }

  /// Backward-compatible alias for saveImportedBook with EPUB files.
  Future<Book> saveImportedEpub({
    required Uint8List bytes,
    required Book book,
  }) {
    return saveImportedBook(bytes: bytes, book: book, isPdf: false);
  }

  /// Loads all stored imported EPUB, PDF, and Scanned books from disk.
  Future<List<Book>> loadAllImportedBooks(
    OpenEpubUseCase openUseCase, [
    OpenPdfUseCase? pdfUseCase,
    ScanDocumentParser? scanParser,
  ]) async {
    await init();
    final List<Book> loadedBooks = [];
    if (_booksBox == null) return loadedBooks;

    final actualPdfUseCase = pdfUseCase ?? OpenPdfUseCase();
    final actualScanParser = scanParser ?? ScanDocumentParser();

    for (final key in _booksBox!.keys) {
      try {
        final data = _booksBox!.get(key);
        if (data is Map) {
          final filePath = data['filePath'] as String?;
          final isScan = (data['isScan'] == true) ||
              (filePath != null && filePath.toLowerCase().endsWith('.scan.json'));
          final isPdf = (data['isPdf'] == true) ||
              (filePath != null && filePath.toLowerCase().endsWith('.pdf'));

          if (filePath != null) {
            final file = File(filePath);
            if (await file.exists()) {
              final Uint8List? coverBytes = data['coverBytes'] as Uint8List?;
              final Book book;

              if (isScan) {
                final jsonStr = await file.readAsString();
                final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
                book = actualScanParser.fromJson(jsonMap, coverBytes: coverBytes);
              } else if (isPdf) {
                final bytes = await file.readAsBytes();
                book = await actualPdfUseCase.fromBytes(
                  bytes,
                  bookId: key.toString(),
                  fallbackTitle: data['title'] as String?,
                );
              } else {
                final bytes = await file.readAsBytes();
                book = await openUseCase.fromBytes(bytes, bookId: key.toString());
              }
              loadedBooks.add(book);
            }
          }
        }
      } catch (e) {
        debugPrint('[HiveStorage] Failed to load book for key $key: $e');
      }
    }

    return loadedBooks;
  }

  /// Deletes an imported book and its progress from storage.
  Future<void> deleteBook(String bookId) async {
    await init();
    try {
      final data = _booksBox?.get(bookId);
      if (data is Map) {
        final filePath = data['filePath'] as String?;
        if (filePath != null) {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }
        }
      }
      await _booksBox?.delete(bookId);
      await _progressBox?.delete(bookId);
      debugPrint('[HiveStorage] Deleted book $bookId');
    } catch (e) {
      debugPrint('[HiveStorage] Error deleting book $bookId: $e');
    }
  }

  // ----------------- PROGRESS PERSISTENCE -----------------

  /// Saves the current reading and audio progress for a book.
  Future<void> saveProgress({
    required String bookId,
    required int chapterIndex,
    required int paragraphIndex,
    int charOffset = 0,
  }) async {
    await init();
    if (bookId.isEmpty) return;

    final progress = BookProgress(
      bookId: bookId,
      chapterIndex: chapterIndex,
      paragraphIndex: paragraphIndex,
      charOffset: charOffset,
      lastUpdated: DateTime.now(),
    );

    await _progressBox?.put(bookId, progress.toMap());
  }

  /// Retrieves the saved progress for a book, if any.
  BookProgress? getProgress(String bookId) {
    if (_progressBox == null || !_progressBox!.containsKey(bookId)) {
      return null;
    }

    try {
      final data = _progressBox!.get(bookId);
      if (data is Map) {
        return BookProgress.fromMap(data);
      }
    } catch (e) {
      debugPrint('[HiveStorage] Error reading progress for $bookId: $e');
    }
    return null;
  }

  /// Retrieves all saved progress records mapped by bookId.
  Map<String, BookProgress> getAllProgress() {
    final Map<String, BookProgress> result = {};
    if (_progressBox == null) return result;

    for (final key in _progressBox!.keys) {
      try {
        final data = _progressBox!.get(key);
        if (data is Map) {
          result[key.toString()] = BookProgress.fromMap(data);
        }
      } catch (_) {}
    }
    return result;
  }

  /// Retrieves all saved progress sorted by most recently updated.
  List<BookProgress> getRecentProgressList() {
    final map = getAllProgress();
    final list = map.values.toList();
    list.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    return list;
  }

  // ----------------- HIGHLIGHTS PERSISTENCE -----------------

  /// Saves or updates a text highlight in Hive.
  Future<void> saveHighlight(TextHighlight highlight) async {
    await init();
    await _highlightsBox?.put(highlight.id, highlight.toMap());
  }

  /// Deletes a highlight by ID.
  Future<void> deleteHighlight(String highlightId) async {
    await init();
    await _highlightsBox?.delete(highlightId);
  }

  /// Retrieves all highlights saved for a specific book.
  List<TextHighlight> getHighlightsForBook(String bookId) {
    final List<TextHighlight> result = [];
    if (_highlightsBox == null) return result;

    for (final key in _highlightsBox!.keys) {
      try {
        final data = _highlightsBox!.get(key);
        if (data is Map) {
          final h = TextHighlight.fromMap(data);
          if (h.bookId == bookId) {
            result.add(h);
          }
        }
      } catch (_) {}
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  /// Retrieves all highlights across all books.
  List<TextHighlight> getAllHighlights() {
    final List<TextHighlight> result = [];
    if (_highlightsBox == null) return result;

    for (final key in _highlightsBox!.keys) {
      try {
        final data = _highlightsBox!.get(key);
        if (data is Map) {
          final h = TextHighlight.fromMap(data);
          result.add(h);
        }
      } catch (_) {}
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  /// Retrieves all highlights for a specific book and chapter.
  List<TextHighlight> getHighlightsForChapter(String bookId, int chapterIndex) {
    final all = getHighlightsForBook(bookId);
    return all.where((h) => h.chapterIndex == chapterIndex).toList();
  }

  // ----------------- BOOKMARKS PERSISTENCE -----------------

  /// Saves or updates a bookmark in Hive.
  Future<void> saveBookmark(Bookmark bookmark) async {
    await init();
    await _bookmarksBox?.put(bookmark.id, bookmark.toJson());
  }

  /// Deletes a bookmark by ID.
  Future<void> deleteBookmark(String bookmarkId) async {
    await init();
    await _bookmarksBox?.delete(bookmarkId);
  }

  /// Retrieves all bookmarks for a specific book.
  List<Bookmark> getBookmarksForBook(String bookId) {
    final List<Bookmark> result = [];
    if (_bookmarksBox == null) return result;

    for (final key in _bookmarksBox!.keys) {
      try {
        final data = _bookmarksBox!.get(key);
        if (data is Map) {
          final bm = Bookmark.fromJson(Map<String, dynamic>.from(data));
          if (bm.bookId == bookId) {
            result.add(bm);
          }
        }
      } catch (e) {
        debugPrint('[HiveStorage] Error reading bookmark $key: $e');
      }
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  /// Retrieves all bookmarks across all books.
  List<Bookmark> getAllBookmarks() {
    final List<Bookmark> result = [];
    if (_bookmarksBox == null) return result;

    for (final key in _bookmarksBox!.keys) {
      try {
        final data = _bookmarksBox!.get(key);
        if (data is Map) {
          final bm = Bookmark.fromJson(Map<String, dynamic>.from(data));
          result.add(bm);
        }
      } catch (e) {
        debugPrint('[HiveStorage] Error reading bookmark $key: $e');
      }
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }
}
