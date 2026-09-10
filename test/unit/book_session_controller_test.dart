import 'package:epub_audio/features/epub/data/repositories/epub_repository_impl.dart';
import 'package:epub_audio/features/epub/domain/usecases/open_epub_usecase.dart';
import 'package:epub_audio/features/library/data/sample_books_provider.dart';
import 'package:epub_audio/features/session/presentation/controllers/book_session_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/mock_audio_source_engine.dart';

void main() {
  group('BookSessionController & Audio Synchronization', () {
    late SampleBooksProvider provider;
    late MockAudioSourceEngine mockAudio;

    setUp(() {
      provider = const SampleBooksProvider(OpenEpubUseCase(EpubRepositoryImpl()));
      mockAudio = MockAudioSourceEngine();
    });

    test('initializes and synchronizes reading and audio position', () async {
      final book = await provider.getMalayalamSampleBook();
      final session = BookSessionController(
        book: book,
        audioEngine: mockAudio,
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(session.currentChapterIndex, 0);
      expect(session.currentParagraphIndex, 0);
      expect(session.currentChapterParagraphs.isNotEmpty, isTrue);
      expect(session.audioState.isStopped, isTrue);

      // Start audio
      await session.playAudio();

      expect(session.audioState.isPlaying, isTrue);
      expect(mockAudio.spokenParagraphs.length, 1);
      expect(mockAudio.spokenParagraphs[0], contains('അദ്ധ്യായം ഒന്ന്'));

      // Simulate paragraph finished speaking -> auto advance to next paragraph
      mockAudio.triggerCompletion();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(session.currentParagraphIndex, 1);
      expect(mockAudio.spokenParagraphs.length, 2);
      expect(mockAudio.spokenParagraphs[1], contains('കടൽ ഇളകിമറിയുകയാണ്'));
    });

    test('bidirectional sync: seeking in reader immediately updates audio', () async {
      final book = await provider.getEnglishSampleBook();
      final session = BookSessionController(
        book: book,
        audioEngine: mockAudio,
      );

      await Future.delayed(const Duration(milliseconds: 50));

      // User seeks to paragraph 2 in reader
      await session.seekToParagraph(2);

      expect(session.currentPosition.paragraphIndex, 2);
      expect(session.audioState.position.paragraphIndex, 2);

      // Starting audio now speaks from paragraph 2
      await session.playAudio();
      expect(mockAudio.spokenParagraphs.last, contains('White Rabbit'));
    });

    test('pausing and resuming continues from the exact paragraph where paused', () async {
      final book = await provider.getMalayalamSampleBook();
      final session = BookSessionController(
        book: book,
        audioEngine: mockAudio,
      );

      await Future.delayed(const Duration(milliseconds: 50));

      // Seek to paragraph 2 and play
      await session.seekToParagraph(2);
      expect(session.currentParagraphIndex, 2);
      expect(session.audioState.isPlaying, isTrue);

      // Pause audio
      await session.pauseAudio();
      expect(session.audioState.isPaused, isTrue);
      expect(session.currentParagraphIndex, 2);

      // Play audio again -> must still be on paragraph 2 and speak paragraph 2
      await session.playAudio();
      expect(session.audioState.isPlaying, isTrue);
      expect(session.currentParagraphIndex, 2);
      expect(mockAudio.spokenParagraphs.last, contains('തീരത്ത് വള്ളങ്ങൾ'));
    });

    test('supports speed adjustment and sleep timer', () async {
      final book = await provider.getEnglishSampleBook();
      final session = BookSessionController(
        book: book,
        audioEngine: mockAudio,
      );

      await session.setAudioSpeed(1.5);
      expect(session.audioState.speechRate, 1.5);
      expect(mockAudio.speechRate, 1.5);

      // Sleep timer
      session.setSleepTimer(const Duration(minutes: 15));
      expect(session.audioState.sleepTimerRemaining?.inMinutes, 15);

      session.setSleepTimer(null);
      expect(session.audioState.sleepTimerRemaining, isNull);
    });
  });
}
