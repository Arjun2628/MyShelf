import 'dart:io';
import 'package:epub_audio/features/epub/data/repositories/epub_repository_impl.dart';
import 'package:epub_audio/features/epub/domain/usecases/open_epub_usecase.dart';
import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:epub_audio/features/library/data/sample_books_provider.dart';
import 'package:epub_audio/features/library/presentation/screens/library_screen.dart';
import 'package:epub_audio/features/reader/domain/entities/bookmark.dart';
import 'package:epub_audio/features/reader/domain/entities/text_highlight.dart';
import 'package:epub_audio/features/session/presentation/controllers/book_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mocks/mock_audio_source_engine.dart';

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

  testWidgets('LibraryScreen displays active audio player tile when an audiobook session is active', (WidgetTester tester) async {
    const provider = SampleBooksProvider(OpenEpubUseCase(EpubRepositoryImpl()));
    final book = await provider.getEnglishSampleBook();
    final mockAudio = MockAudioSourceEngine();
    final session = BookSessionController(
      book: book,
      audioEngine: mockAudio,
    );

    await tester.runAsync(() async {
      await session.seekToParagraph(0, autoPlay: true);
    });

    await tester.pumpWidget(const MaterialApp(home: LibraryScreen()));
    for (int i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Verify floating audio playing tile is rendered on Home Screen
    expect(find.byIcon(Icons.graphic_eq_rounded), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsWidgets);
    expect(find.byIcon(Icons.skip_next_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // Stop audio
    await tester.tap(find.byIcon(Icons.close_rounded), warnIfMissed: false);
    for (int i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  });
}
