import 'dart:io';
import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:epub_audio/features/library/presentation/screens/library_screen.dart';
import 'package:epub_audio/features/reader/domain/entities/bookmark.dart';
import 'package:epub_audio/features/reader/domain/entities/text_highlight.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() async {
    final tempDir = Directory.systemTemp.createTempSync('widget_test_hive');
    await HiveStorageService().init(tempDir.path);
  });

  testWidgets('LibraryScreen loads and renders sample books with read & listen actions', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LibraryScreen()));
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('EPUB'), findsWidgets);
    expect(find.text('Import EPUB'), findsOneWidget);
    expect(find.textContaining('Chemmeen'), findsWidgets);
    expect(find.textContaining('Alice'), findsWidgets);
    expect(find.text('Read'), findsWidgets);
    expect(find.text('Listen'), findsWidgets);
  });

  testWidgets('LibraryScreen switches to Saved & Bookmarks tab and displays saved items', (WidgetTester tester) async {
    final storage = HiveStorageService();
    await storage.saveHighlight(
      TextHighlight(
        id: 'hl_sample_widget',
        bookId: 'sample_chemmeen',
        chapterIndex: 0,
        selectedText: 'കടപ്പുറത്ത് കാറ്റ് വീശുന്നു',
        colorValue: Colors.yellow.toARGB32(),
        createdAt: DateTime.now(),
        note: 'Wind at beach note',
      ),
    );
    await storage.saveBookmark(
      Bookmark(
        id: 'bm_sample_widget',
        bookId: 'sample_chemmeen',
        chapterIndex: 1,
        chapterTitle: 'Chapter 2',
        snippet: 'A memorable passage from chapter 2',
        createdAt: DateTime.now(),
      ),
    );

    await tester.pumpWidget(const MaterialApp(home: LibraryScreen()));
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Tap Saved Navigation Bar item
    await tester.tap(find.byIcon(Icons.bookmark_outline));
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Saved & Bookmarks'), findsOneWidget);
    expect(find.textContaining('All (2)'), findsOneWidget);
    expect(find.textContaining('Highlights (1)'), findsOneWidget);
    expect(find.textContaining('Bookmarks (1)'), findsOneWidget);
    expect(find.textContaining('കടപ്പുറത്ത് കാറ്റ് വീശുന്നു'), findsOneWidget);
    expect(find.textContaining('Wind at beach note'), findsOneWidget);
    expect(find.textContaining('A memorable passage from chapter 2'), findsOneWidget);
  });
}
