import 'package:epub_audio/features/epub/data/repositories/epub_repository_impl.dart';
import 'package:epub_audio/features/epub/domain/usecases/open_epub_usecase.dart';
import 'package:epub_audio/features/library/data/sample_books_provider.dart';
import 'package:epub_audio/features/reader/domain/entities/reader_preferences.dart';
import 'package:epub_audio/features/reader/presentation/controllers/reader_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReaderController', () {
    late SampleBooksProvider provider;

    setUp(() {
      provider = const SampleBooksProvider(OpenEpubUseCase(EpubRepositoryImpl()));
    });

    test('initializes with first chapter and navigates forwards and backwards', () async {
      final book = await provider.getEnglishSampleBook();
      final controller = ReaderController(book: book);

      // Wait for initial chapter load
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.currentChapterIndex, 0);
      expect(controller.currentChapterContent?.title, contains('Chapter I'));
      expect(controller.hasPreviousChapter, isFalse);
      expect(controller.hasNextChapter, isTrue);

      // Go to next chapter
      await controller.nextChapter();
      expect(controller.currentChapterIndex, 1);
      expect(controller.currentChapterContent?.title, contains('Chapter II'));
      expect(controller.hasPreviousChapter, isTrue);
      expect(controller.hasNextChapter, isFalse);

      // Go back
      await controller.previousChapter();
      expect(controller.currentChapterIndex, 0);
    });

    test('manages bookmark creation, toggling, and deletion', () async {
      final book = await provider.getMalayalamSampleBook();
      final controller = ReaderController(book: book);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.isCurrentChapterBookmarked, isFalse);
      expect(controller.bookmarks.isEmpty, isTrue);

      controller.toggleBookmark();
      expect(controller.isCurrentChapterBookmarked, isTrue);
      expect(controller.bookmarks.length, 1);
      expect(controller.bookmarks[0].chapterTitle, contains('അദ്ധ്യായം 1'));

      // Toggling again removes the bookmark
      controller.toggleBookmark();
      expect(controller.isCurrentChapterBookmarked, isFalse);
      expect(controller.bookmarks.isEmpty, isTrue);
    });

    test('updates preferences and changes theme', () async {
      final book = await provider.getEnglishSampleBook();
      final controller = ReaderController(book: book);

      expect(controller.preferences.themeMode, ReaderThemeMode.light);

      controller.updatePreferences(
        controller.preferences.copyWith(
          themeMode: ReaderThemeMode.sepia,
          fontSize: 22.0,
        ),
      );

      expect(controller.preferences.themeMode, ReaderThemeMode.sepia);
      expect(controller.preferences.fontSize, 22.0);
    });
  });
}
