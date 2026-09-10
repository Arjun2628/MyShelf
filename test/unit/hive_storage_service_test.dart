import 'dart:io';
import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:epub_audio/features/reader/domain/entities/bookmark.dart';
import 'package:epub_audio/features/reader/domain/entities/text_highlight.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late HiveStorageService storage;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_storage_test_');
    storage = HiveStorageService();
    await storage.init(tempDir.path);
  });

  group('HiveStorageService Bookmarks & Highlights Persistence', () {
    test('saves, retrieves, and deletes bookmarks', () async {
      final now = DateTime(2026, 9, 10, 10, 0);
      final bookmark = Bookmark(
        id: 'bm_test_1',
        bookId: 'book_chemmeen',
        chapterIndex: 3,
        chapterTitle: 'Chapter 4: The Sea',
        snippet: 'The waves rolled softly along the shore.',
        createdAt: now,
      );

      await storage.saveBookmark(bookmark);

      final bookBookmarks = storage.getBookmarksForBook('book_chemmeen');
      expect(bookBookmarks.length, equals(1));
      expect(bookBookmarks.first.id, equals('bm_test_1'));
      expect(bookBookmarks.first.chapterTitle, equals('Chapter 4: The Sea'));

      final allBookmarks = storage.getAllBookmarks();
      expect(allBookmarks.length, equals(1));

      await storage.deleteBookmark('bm_test_1');
      expect(storage.getBookmarksForBook('book_chemmeen').isEmpty, isTrue);
      expect(storage.getAllBookmarks().isEmpty, isTrue);
    });

    test('saves, retrieves, and deletes highlights across chapters and books', () async {
      final now = DateTime(2026, 9, 10, 10, 30);
      final hl1 = TextHighlight(
        id: 'hl_test_1',
        bookId: 'book_chemmeen',
        chapterIndex: 1,
        selectedText: 'കടപ്പുറവും കാറ്റും',
        colorValue: Colors.yellow.toARGB32(),
        createdAt: now,
        note: 'Setting description',
      );
      final hl2 = TextHighlight(
        id: 'hl_test_2',
        bookId: 'book_alice',
        chapterIndex: 0,
        selectedText: 'Down the rabbit hole',
        colorValue: Colors.pink.toARGB32(),
        createdAt: now.add(const Duration(minutes: 5)),
      );

      await storage.saveHighlight(hl1);
      await storage.saveHighlight(hl2);

      final chemmeenHighlights = storage.getHighlightsForBook('book_chemmeen');
      expect(chemmeenHighlights.length, equals(1));
      expect(chemmeenHighlights.first.selectedText, equals('കടപ്പുറവും കാറ്റും'));

      final allHighlights = storage.getAllHighlights();
      expect(allHighlights.length, equals(2));

      await storage.deleteHighlight('hl_test_1');
      expect(storage.getAllHighlights().length, equals(1));
      expect(storage.getAllHighlights().first.id, equals('hl_test_2'));
    });
  });
}
