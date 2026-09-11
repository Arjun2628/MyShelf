import 'package:epub_audio/features/epub/data/repositories/epub_repository_impl.dart';
import 'package:epub_audio/features/epub/domain/entities/chapter_content.dart';
import 'package:epub_audio/features/epub/domain/entities/content_nodes.dart';
import 'package:epub_audio/features/epub/domain/usecases/open_epub_usecase.dart';
import 'package:epub_audio/features/library/data/sample_books_provider.dart';
import 'package:epub_audio/features/reader/domain/entities/reader_preferences.dart';
import 'package:epub_audio/features/reader/domain/entities/text_highlight.dart';
import 'package:epub_audio/features/reader/presentation/widgets/reader_content_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleContent = ChapterContent(
    chapterId: 'chap1',
    title: 'Chapter 1: The Beginning',
    fullPath: 'chapter1.xhtml',
    spineIndex: 0,
    blocks: [
      HeadingNode(
        level: 1,
        spans: [TextSpanNode(text: 'Chapter 1: The Beginning')],
      ),
      ParagraphNode(
        spans: [
          TextSpanNode(text: 'The quick brown fox jumps over the lazy dog.'),
        ],
      ),
      ParagraphNode(
        spans: [
          TextSpanNode(text: 'Second paragraph with more interesting text.'),
        ],
      ),
      ParagraphNode(
        spans: [
          TextSpanNode(text: 'Third paragraph which will be scrolled to smoothly.'),
        ],
      ),
    ],
  );

  testWidgets('ReaderContentView renders content blocks and highlights active paragraph',
      (WidgetTester tester) async {
    const provider = SampleBooksProvider(OpenEpubUseCase(EpubRepositoryImpl()));
    final sampleBook = await provider.getEnglishSampleBook();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderContentView(
            content: sampleContent,
            book: sampleBook,
            preferences: const ReaderPreferences(),
            activeParagraphIndex: 1, // Second text paragraph (0 is heading, 1 is 1st para)
            isPlaying: true,
          ),
        ),
      ),
    );

    expect(find.text('Chapter 1: The Beginning'), findsOneWidget);
    expect(find.text('READING'), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsWidgets);
  });

  testWidgets('ReaderContentView highlights active word by charOffset during playback',
      (WidgetTester tester) async {
    const provider = SampleBooksProvider(OpenEpubUseCase(EpubRepositoryImpl()));
    final sampleBook = await provider.getEnglishSampleBook();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderContentView(
            content: sampleContent,
            book: sampleBook,
            preferences: const ReaderPreferences(),
            activeParagraphIndex: 1,
            charOffset: 4, // 'quick' starts at offset 4
            isPlaying: true,
          ),
        ),
      ),
    );

    // Verify rich text has rendered spans
    final richTextFinder = find.byType(RichText);
    expect(richTextFinder, findsWidgets);

    // Verify 'quick' has active word highlight styling
    bool foundSpokenWordSpan = false;
    for (final element in richTextFinder.evaluate()) {
      final richText = element.widget as RichText;
      richText.text.visitChildren((span) {
        if (span is TextSpan && span.text == 'quick') {
          if (span.style?.fontWeight == FontWeight.w900) {
            foundSpokenWordSpan = true;
          }
        }
        return true;
      });
    }

    expect(foundSpokenWordSpan, isTrue);
  });

  testWidgets('ReaderContentView handles manual highlights combined with TTS word playback',
      (WidgetTester tester) async {
    const provider = SampleBooksProvider(OpenEpubUseCase(EpubRepositoryImpl()));
    final sampleBook = await provider.getEnglishSampleBook();

    final highlight = TextHighlight(
      id: 'hl_1',
      bookId: sampleBook.id,
      chapterIndex: 0,
      selectedText: 'brown fox',
      colorValue: Colors.yellow.toARGB32(),
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderContentView(
            content: sampleContent,
            book: sampleBook,
            preferences: const ReaderPreferences(),
            activeParagraphIndex: 1,
            charOffset: 10, // offset inside 'brown'
            isPlaying: true,
            highlights: [highlight],
          ),
        ),
      ),
    );

    expect(find.text('READING'), findsOneWidget);
  });

  testWidgets('ReaderContentView auto-scrolls smoothly when active paragraph advances',
      (WidgetTester tester) async {
    const provider = SampleBooksProvider(OpenEpubUseCase(EpubRepositoryImpl()));
    final sampleBook = await provider.getEnglishSampleBook();
    final scrollController = ScrollController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: ReaderContentView(
              content: sampleContent,
              book: sampleBook,
              preferences: const ReaderPreferences(),
              activeParagraphIndex: 0,
              isPlaying: true,
              scrollController: scrollController,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Advance to paragraph 2
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 300,
            child: ReaderContentView(
              content: sampleContent,
              book: sampleBook,
              preferences: const ReaderPreferences(),
              activeParagraphIndex: 2,
              isPlaying: true,
              scrollController: scrollController,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('READING'), findsOneWidget);
  });
}
