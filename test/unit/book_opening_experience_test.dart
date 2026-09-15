import 'dart:io';
import 'package:epub_audio/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:epub_audio/features/explore/domain/entities/category_experience_config.dart';
import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:epub_audio/features/opening_experience/data/repositories/book_opening_repository_impl.dart';
import 'package:epub_audio/features/opening_experience/domain/entities/book_opening_config.dart';
import 'package:epub_audio/features/opening_experience/presentation/screens/book_opening_experience_screen.dart';
import 'package:epub_audio/features/opening_experience/presentation/widgets/atmosphere_particles_painter.dart';
import 'package:epub_audio/features/opening_experience/presentation/widgets/book_cover_3d_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late ExploreRepositoryImpl exploreRepo;
  late BookOpeningRepositoryImpl openingRepo;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('book_opening_test_');
    await HiveStorageService().init(tempDir.path);
    exploreRepo = ExploreRepositoryImpl();
    openingRepo = BookOpeningRepositoryImpl(exploreRepository: exploreRepo);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BookOpeningConfig Domain Entity', () {
    test('defaultConfig has expected properties', () {
      const config = BookOpeningConfig.defaultConfig;
      expect(config.themeId, 'obsidian');
      expect(config.typographyId, 'modern');
      expect(config.accentColorHex, '0xFFD4A373');
      expect(config.atmosphereEffectId, 'golden_glow');
      expect(config.animationType, 'perspective_tilt');
      expect(config.characterVoiceNames, contains('Narrator'));
    });

    test('fromCategoryConfig inherits category properties', () {
      const catConfig = CategoryExperienceConfig(
        id: 'exp_mystery',
        themeId: 'noir_investigation',
        gradientHexColors: ['0xFF1C140E', '0xFF0E0B08'],
        typographyId: 'serif_classic',
        accentColorHex: '0xFFD97706',
        atmosphereEffectId: 'shadow_mist',
        ambientAudioId: 'rain_on_cobblestone',
        introAudioId: 'noir_cello',
      );

      final config = BookOpeningConfig.fromCategoryConfig(
        categoryConfig: catConfig,
        characterVoices: ['Sherlock Holmes', 'Dr. Watson'],
      );

      expect(config.themeId, 'noir_investigation');
      expect(config.accentColorHex, '0xFFD97706');
      expect(config.atmosphereEffectId, 'shadow_mist');
      expect(config.ambientAudioId, 'rain_on_cobblestone');
      expect(config.characterVoiceNames, ['Sherlock Holmes', 'Dr. Watson']);
    });
  });

  group('BookOpeningRepositoryImpl', () {
    test('resolves book-specific override for Sherlock Holmes', () async {
      final books = await exploreRepo.getCategoryBooks('cat_mystery');
      final sherlock = books.firstWhere((b) => b.id.contains('sherlock'));

      final config = await openingRepo.resolveOpeningConfig(book: sherlock);
      expect(config.themeId, 'dark_mystery');
      expect(config.atmosphereEffectId, 'shadow_mist');
      expect(config.characterVoiceNames, contains('Sherlock Holmes (Analytical)'));
    });

    test('resolves book-specific override for Malayalam Chemmeen', () async {
      final books = await exploreRepo.getCategoryBooks('cat_malayalam');
      final chemmeen = books.firstWhere((b) => b.id.contains('chemmeen'));

      final config = await openingRepo.resolveOpeningConfig(book: chemmeen);
      expect(config.themeId, 'kerala_heritage');
      expect(config.characterVoiceNames, contains('കറുത്തമ്മ (Female)'));
      expect(config.characterVoiceNames, contains('പരീക്കുട്ടി (Male)'));
    });

    test('resolves Dracula gothic horror config', () async {
      final books = await exploreRepo.getCategoryBooks('cat_mystery');
      final dracula = books.firstWhere((b) => b.id.contains('dracula'));

      final config = await openingRepo.resolveOpeningConfig(book: dracula);
      expect(config.themeId, 'gothic_horror');
      expect(config.atmosphereEffectId, 'shadow_mist');
      expect(config.characterVoiceNames, contains('Count Dracula (Deep)'));
    });

    test('resolves config for SciFi time machine', () async {
      final books = await exploreRepo.getCategoryBooks('cat_scifi');
      final timeMachine = books.firstWhere((b) => b.id.contains('timemachine'));

      final config = await openingRepo.resolveOpeningConfig(
        book: timeMachine,
        categoryId: 'cat_scifi',
      );

      expect(config.themeId, 'cosmic_scifi');
      expect(config.atmosphereEffectId, 'cosmic_pulse');
    });

    test('resolves language fallback for Malayalam books', () async {
      final books = await exploreRepo.getCategoryBooks('cat_malayalam');
      final chemmeen = books.firstWhere((b) => b.id.contains('chemmeen'));

      final config = await openingRepo.resolveOpeningConfig(book: chemmeen);
      expect(config.themeId, 'kerala_heritage');
      expect(config.typographyId, 'classical');
    });
  });

  group('Book Opening Experience UI Components', () {
    testWidgets('AtmosphereParticlesOverlay renders with different effect IDs', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: const [
                AtmosphereParticlesOverlay(
                  effectId: 'starfield',
                  accentColor: Colors.blueAccent,
                ),
                AtmosphereParticlesOverlay(
                  effectId: 'magical_sparkles',
                  accentColor: Colors.purpleAccent,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(AtmosphereParticlesOverlay), findsNWidgets(2));
    });

    testWidgets('BookCover3DStage renders title, author, and handles interaction', (tester) async {
      final books = await exploreRepo.getCategoryBooks('cat_mystery');
      final book = books.firstWhere((b) => b.id.contains('sherlock'));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BookCover3DStage(
                book: book,
                accentColor: const Color(0xFFD4A373),
                animationType: 'perspective_tilt',
                isDark: true,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('The Adventures of Sherlock Holmes'), findsOneWidget);
      expect(find.byType(BookCover3DStage), findsOneWidget);

      // Drag to trigger perspective tilt
      await tester.drag(find.byType(BookCover3DStage), const Offset(20, -10));
      await tester.pump(const Duration(milliseconds: 50));
    });

    testWidgets('BookOpeningExperienceScreen renders book details, cast chips, and triggers Read/Listen', (tester) async {
      final books = await exploreRepo.getCategoryBooks('cat_malayalam');
      final book = books.firstWhere((b) => b.id.contains('chemmeen'));

      bool readTriggered = false;
      bool listenTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: BookOpeningExperienceScreen(
            book: book,
            repository: openingRepo,
            onReadNow: () => readTriggered = true,
            onListenNow: () => listenTriggered = true,
          ),
        ),
      );

      // Pump for async config resolution
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Read Book'), findsOneWidget);
      expect(find.text('Listen Audio'), findsOneWidget);

      // Cast voices chip verification
      expect(find.text('Voice & Narrator Cast'), findsOneWidget);
      expect(find.text('കറുത്തമ്മ (Female)'), findsOneWidget);
      expect(find.text('പരീക്കുട്ടി (Male)'), findsOneWidget);

      // Tap Read Now
      await tester.tap(find.text('Read Book'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(readTriggered, isTrue);

      // Tap Listen Now
      await tester.tap(find.text('Listen Audio'));
      await tester.pump(const Duration(milliseconds: 50));
      expect(listenTriggered, isTrue);
    });
  });
}
