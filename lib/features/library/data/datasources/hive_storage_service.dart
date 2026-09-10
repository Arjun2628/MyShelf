import 'dart:io';
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/epub/domain/usecases/open_epub_usecase.dart';
import 'package:epub_audio/features/session/domain/entities/book_progress.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Manages local storage of imported EPUB files and reading/audiobook progress using Hive.
class HiveStorageService {
  static const String booksBoxName = 'imported_books_v1';
  static const String progressBoxName = 'reading_progress_v1';

  static final HiveStorageService _instance = HiveStorageService._internal();
  factory HiveStorageService() => _instance;
  HiveStorageService._internal();

  Box<dynamic>? _booksBox;
  Box<dynamic>? _progressBox;
  bool _isInitialized = false;

  /// Initializes Hive and opens required boxes.
  Future<void> init([String? customPath]) async {
    if (_isInitialized) return;

    try {
      if (customPath != null) {
        Hive.init(customPath);
      } else {
        try {
          await Hive.initFlutter();
        } catch (_) {
          // Fallback for tests or environments without native platform channel
          final tempDir = Directory.systemTemp.createTempSync('epub_hive_');
          Hive.init(tempDir.path);
        }
      }
      _booksBox = await Hive.openBox(booksBoxName);
      _progressBox = await Hive.openBox(progressBoxName);
      _isInitialized = true;
      debugPrint('[HiveStorage] Initialized successfully. Stored books: ${_booksBox?.length}');
    } catch (e) {
      debugPrint('[HiveStorage] Initialization error: $e');
    }
  }

  // ----------------- IMPORTED BOOKS PERSISTENCE -----------------

  /// Saves an imported EPUB file to device storage and indexes its metadata in Hive.
  Future<Book> saveImportedEpub({
    required Uint8List bytes,
    required Book book,
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

      final epubsDir = Directory('$basePath/epubs');
      if (!epubsDir.existsSync()) {
        epubsDir.createSync(recursive: true);
      }

      final sanitizedId = book.id.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
      final filePath = '${epubsDir.path}/$sanitizedId.epub';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      final bookRecord = {
        'id': book.id,
        'title': book.metadata.title,
        'author': book.metadata.author,
        'description': book.metadata.description,
        'language': book.metadata.language,
        'filePath': filePath,
        'coverBytes': book.coverImageBytes,
        'chapterCount': book.chapterCount,
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

  /// Loads all stored imported books from disk.
  Future<List<Book>> loadAllImportedBooks(OpenEpubUseCase openUseCase) async {
    await init();
    final List<Book> loadedBooks = [];
    if (_booksBox == null) return loadedBooks;

    for (final key in _booksBox!.keys) {
      try {
        final data = _booksBox!.get(key);
        if (data is Map) {
          final filePath = data['filePath'] as String?;
          if (filePath != null) {
            final file = File(filePath);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              final book = await openUseCase.fromBytes(bytes, bookId: key.toString());
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
}
