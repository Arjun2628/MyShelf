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

  testWidgets('LibraryScreen loads and renders search bar, row shelves and sample books', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LibraryScreen()));
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('EPUB'), findsWidgets);
    expect(find.text('Import EPUB'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('Malayalam Literature'), findsOneWidget);
    expect(find.textContaining('Chemmeen'), findsWidgets);

    // Scroll down to reveal World Classics shelf
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('World Classics'), findsOneWidget);
    expect(find.textContaining('Alice'), findsWidgets);
    expect(find.text('Read'), findsWidgets);
    expect(find.text('Listen'), findsWidgets);
  });

  testWidgets('LibraryScreen search filters books by query', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LibraryScreen()));
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Enter query 'Alice'
    await tester.enterText(find.byType(TextField), 'Alice');
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('Search Results'), findsOneWidget);
    expect(find.textContaining('Alice'), findsWidgets);

    // Clear search
    await tester.tap(find.byIcon(Icons.clear_rounded));
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.textContaining('Malayalam Literature'), findsOneWidget);
  });

  testWidgets('LibraryScreen displays Continue Reading shelf when progress exists', (WidgetTester tester) async {
    final storage = HiveStorageService();
    await tester.runAsync(() async {
      await storage.saveProgress(
        bookId: 'sample_chemmeen',
        chapterIndex: 1,
        paragraphIndex: 3,
        charOffset: 20,
      );
    });

    await tester.pumpWidget(const MaterialApp(home: LibraryScreen()));
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.textContaining('Continue Reading'), findsOneWidget);
    expect(find.textContaining('Chapter 2 of'), findsOneWidget);
  });

  testWidgets('LibraryScreen switches to Saved & Bookmarks tab and displays saved items', (WidgetTester tester) async {
    final storage = HiveStorageService();
    await tester.runAsync(() async {
      await storage.saveHighlight(
        TextHighlight(
          id: 'hl_sample_widget',
          bookId: 'sample_chemmeen',
          chapterIndex: 0,
          selectedText: 'കടപ്പുറത്ത് കാറ്റ് വീശുന്നു',
          colorValue: 0xFFFDE047,
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
    });

    await tester.pumpWidget(const MaterialApp(home: LibraryScreen()));
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Tap Saved Navigation Bar item
    await tester.tap(find.byIcon(Icons.bookmarks_outlined));
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
