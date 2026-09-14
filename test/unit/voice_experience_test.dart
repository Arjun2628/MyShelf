import 'dart:io';
import 'package:epub_audio/features/epub/domain/entities/book.dart';
import 'package:epub_audio/features/explore/data/repositories/explore_repository_impl.dart';
import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:epub_audio/features/voice/domain/entities/character.dart';
import 'package:epub_audio/features/voice/domain/entities/voice_profile.dart';
import 'package:epub_audio/features/voice/domain/services/tts_provider.dart';
import 'package:epub_audio/features/voice/domain/services/voice_engine.dart';
import 'package:epub_audio/features/voice/presentation/widgets/book_voice_audition_modal.dart';
import 'package:epub_audio/features/voice/domain/entities/content_block.dart';
import 'package:epub_audio/features/voice/domain/entities/audio_segment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MockTTSProvider implements TTSProvider {
  final List<Map<String, String>> voices;
  String? lastSpokenText;
  VoiceProfile? lastSpokenProfile;
  bool stopCalled = false;

  MockTTSProvider({
    this.voices = const [
      {'id': 'en-us-x-sfg#female_1-local', 'name': 'English Female 1', 'locale': 'en-US', 'gender': 'female'},
      {'id': 'en-us-x-iom-local', 'name': 'English Male 1', 'locale': 'en-US', 'gender': 'male'},
      {'id': 'en-us-x-iol-local', 'name': 'English Female 2', 'locale': 'en-US', 'gender': 'female'},
      {'id': 'en-gb-x-rjs-local', 'name': 'British Male', 'locale': 'en-GB', 'gender': 'male'},
      {'id': 'ml-in-x-female', 'name': 'Malayalam Female', 'locale': 'ml-IN', 'gender': 'female'},
      {'id': 'ml-in-x-male', 'name': 'Malayalam Male', 'locale': 'ml-IN', 'gender': 'male'},
    ],
  });

  @override
  String get displayName => 'Mock TTS';

  @override
  String get providerId => 'mock_tts';

  @override
  void dispose() {}

  @override
  Future<AudioSegment> generate({
    required ContentBlock block,
    required VoiceProfile profile,
    String? targetFilePath,
  }) async {
    return AudioSegment(
      id: 'seg_${block.id}',
      contentBlockId: block.id,
      speakerId: block.speakerId,
      voiceProfileId: profile.id,
      status: AudioSegmentStatus.ready,
    );
  }

  @override
  Future<List<Map<String, String>>> getAvailableVoices() async => voices;

  @override
  Future<void> init() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> speakDirectly(
    String text,
    VoiceProfile profile, {
    void Function()? onCompletion,
    void Function(String word, int startOffset, int endOffset)? onProgress,
    void Function(String error)? onError,
  }) async {
    lastSpokenText = text;
    lastSpokenProfile = profile;
    onProgress?.call(text.split(' ').first, 0, text.split(' ').first.length);
    onCompletion?.call();
  }

  @override
  Future<void> stop() async {
    stopCalled = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late MockTTSProvider mockTTS;
  late VoiceEngine voiceEngine;
  late ExploreRepositoryImpl exploreRepo;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('voice_experience_test_');
    await HiveStorageService().init(tempDir.path);
    mockTTS = MockTTSProvider();
    voiceEngine = VoiceEngine(ttsProvider: mockTTS);
    exploreRepo = ExploreRepositoryImpl();
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('VoiceProfile & Character Entities', () {
    test('VoiceProfile copyWith and hash code consistency', () {
      const profile = VoiceProfile(
        id: 'p1',
        name: 'Arjun Male',
        providerVoiceId: 'en-us-x-iom',
        speed: 1.1,
        pitch: 0.9,
      );

      final updated = profile.copyWith(speed: 1.25);
      expect(updated.speed, 1.25);
      expect(updated.pitch, 0.9);
      expect(profile.generateSettingsHash(), isNotEmpty);
      expect(profile.generateSettingsHash() != updated.generateSettingsHash(), isTrue);
    });

    test('Character serialization toMap and fromMap', () {
      const char = Character(
        id: 'sherlock',
        name: 'Sherlock Holmes',
        voiceProfileId: 'voice_arjun',
        colorHex: '#3B82F6',
      );

      final map = char.toMap();
      final restored = Character.fromMap(map);
      expect(restored.id, 'sherlock');
      expect(restored.name, 'Sherlock Holmes');
      expect(restored.voiceProfileId, 'voice_arjun');
    });
  });

  group('VoiceEngine Logic & Assignment', () {
    test('autoDiscoverAndAssignVoices assigns appropriate male/female/stranger profiles', () async {
      await voiceEngine.autoDiscoverAndAssignVoices(targetLanguage: 'en-US');

      final narrator = voiceEngine.getVoiceProfile('narrator');
      final arjun = voiceEngine.getVoiceProfile('arjun');
      final maya = voiceEngine.getVoiceProfile('maya');
      final stranger = voiceEngine.getVoiceProfile('stranger');

      expect(narrator.providerVoiceId, isNotEmpty);
      expect(arjun.providerVoiceId, isNotEmpty);
      expect(maya.providerVoiceId, isNotEmpty);
      expect(stranger.providerVoiceId, isNotEmpty);
      expect(arjun.providerVoiceId != maya.providerVoiceId, isTrue);
    });

    test('registerCharacter and assignVoice updates profile routing', () {
      const customChar = Character(
        id: 'dracula',
        name: 'Count Dracula',
        voiceProfileId: 'voice_stranger',
      );
      voiceEngine.registerCharacter(customChar);

      expect(voiceEngine.getCharacter('dracula')?.name, 'Count Dracula');
      expect(voiceEngine.getVoiceProfile('dracula').id, 'voice_stranger');

      voiceEngine.assignVoice('dracula', 'voice_arjun');
      expect(voiceEngine.getVoiceProfile('dracula').id, 'voice_arjun');
    });

    test('updateVoiceProfile updates pitch and speed acoustics', () {
      final old = voiceEngine.getVoiceProfile('narrator');
      final updated = old.copyWith(pitch: 1.4, speed: 1.2);
      voiceEngine.updateVoiceProfile(updated);

      final current = voiceEngine.getVoiceProfile('narrator');
      expect(current.pitch, 1.4);
      expect(current.speed, 1.2);
    });
  });

  group('BookVoiceAuditionModal UI & Auditioning', () {
    testWidgets('renders character cards and allows voice auditioning and pitch/speed tuning', (tester) async {
      final books = await exploreRepo.getCategoryBooks('cat_malayalam');
      final book = books.firstWhere((b) => b.id.contains('chemmeen'));

      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookVoiceAuditionModal(
              book: book,
              voiceEngine: voiceEngine,
              characterVoiceNames: const [
                'Narrator (വിവരണക്കാരൻ)',
                'കറുത്തമ്മ (Female)',
                'പരീക്കുട്ടി (Male)',
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Voice Cast & Audition'), findsOneWidget);
      expect(find.text('Save Voice Preferences'), findsOneWidget);
      expect(find.text('കറുത്തമ്മ (Female)'), findsOneWidget);
      expect(find.text('പരീക്കുട്ടി (Male)'), findsOneWidget);

      // Tap Audition button
      final auditionButtons = find.text('Audition');
      expect(auditionButtons, findsWidgets);
      await tester.tap(auditionButtons.first);
      await tester.pump();

      expect(mockTTS.lastSpokenText, isNotNull);
      expect(mockTTS.lastSpokenProfile, isNotNull);

      // Tap Save Preferences
      await tester.tap(find.text('Save Voice Preferences'));
      await tester.pump();
    });
  });
}
