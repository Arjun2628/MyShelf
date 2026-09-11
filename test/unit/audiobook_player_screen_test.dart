import 'package:epub_audio/features/audio/presentation/screens/audiobook_player_screen.dart';
import 'package:epub_audio/features/epub/data/repositories/epub_repository_impl.dart';
import 'package:epub_audio/features/epub/domain/usecases/open_epub_usecase.dart';
import 'package:epub_audio/features/library/data/sample_books_provider.dart';
import 'package:epub_audio/features/session/presentation/controllers/book_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks/mock_audio_source_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AudiobookPlayerScreen renders with Live Text toggle and paragraph lyrics',
      (WidgetTester tester) async {
    const provider = SampleBooksProvider(OpenEpubUseCase(EpubRepositoryImpl()));
    final sampleBook = await provider.getEnglishSampleBook();
    final mockAudio = MockAudioSourceEngine();

    final session = BookSessionController(
      book: sampleBook,
      audioEngine: mockAudio,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AudiobookPlayerScreen(session: session),
      ),
    );

    // Verify mode switcher
    expect(find.text('Live Reading'), findsOneWidget);
    expect(find.text('Cover Art'), findsOneWidget);

    // Switch to Cover view
    await tester.tap(find.text('Cover Art'));
    await tester.pumpAndSettle();

    expect(find.byType(Slider), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    // Switch back to Live Reading
    await tester.tap(find.text('Live Reading'));
    await tester.pumpAndSettle();

    // Verify play button works
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();

    expect(session.audioState.isPlaying, isTrue);
  });
}
