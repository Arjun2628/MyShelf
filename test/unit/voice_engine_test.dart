import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:epub_audio/features/voice/domain/entities/content_block.dart';
import 'package:epub_audio/features/voice/domain/entities/character.dart';
import 'package:epub_audio/features/voice/domain/entities/voice_profile.dart';
import 'package:epub_audio/features/voice/domain/entities/audio_segment.dart';
import 'package:epub_audio/features/voice/domain/services/tts_provider.dart';
import 'package:epub_audio/features/voice/domain/services/voice_engine.dart';
import 'package:epub_audio/features/voice/data/cache/audio_cache_manager.dart';
import 'package:epub_audio/features/voice/data/detection/rule_based_speaker_detector.dart';
import 'package:epub_audio/features/synchronization/services/sync_engine.dart';
import 'package:epub_audio/features/voice/presentation/controllers/multi_voice_session_controller.dart';

/// Mock TTS provider for deterministic testing without native audio channel dependencies.
class MockTestTtsProvider implements TTSProvider {
  String? lastSpokenText;
  VoiceProfile? lastSpokenProfile;
  final List<VoiceProfile> spokenProfilesHistory = [];
  bool isSpeaking = false;
  bool isPaused = false;
  bool isStopped = false;
  List<Map<String, String>> customAvailableVoices = [
    {'id': 'en-us-x-sfg#female_1-local', 'name': 'English Female 1 (Narrator Voice A)', 'locale': 'en-US'},
    {'id': 'en-us-x-iom-local', 'name': 'English Male 1 (Arjun Voice B)', 'locale': 'en-US'},
    {'id': 'en-us-x-iol-local', 'name': 'English Female 2 (Maya Voice C)', 'locale': 'en-US'},
    {'id': 'en-gb-x-rjs-local', 'name': 'English GB Male (Stranger Voice D)', 'locale': 'en-GB'},
  ];

  @override
  String get providerId => 'mock_tts_test';

  @override
  String get displayName => 'Mock Test TTS';

  @override
  Future<void> init() async {}

  @override
  Future<List<Map<String, String>>> getAvailableVoices() async {
    return customAvailableVoices;
  }

  @override
  Future<AudioSegment> generate({
    required ContentBlock block,
    required VoiceProfile profile,
    String? targetFilePath,
  }) async {
    if (targetFilePath != null) {
      final file = File(targetFilePath);
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }
      await file.writeAsString('MOCK_AUDIO_DATA_FOR_${block.id}');
    }

    return AudioSegment(
      id: 'seg_${block.id}',
      contentBlockId: block.id,
      speakerId: block.speakerId,
      voiceProfileId: profile.id,
      audioPath: targetFilePath,
      duration: const Duration(milliseconds: 1500),
      status: AudioSegmentStatus.ready,
    );
  }

  bool autoTriggerCompletion = false;

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
    spokenProfilesHistory.add(profile);
    isSpeaking = true;
    onProgress?.call('Word', 0, 4);
    if (autoTriggerCompletion) {
      onCompletion?.call();
    }
  }

  @override
  Future<void> pause() async {
    isPaused = true;
    isSpeaking = false;
  }

  @override
  Future<void> resume() async {
    isPaused = false;
    isSpeaking = true;
  }

  @override
  Future<void> stop() async {
    isStopped = true;
    isSpeaking = false;
  }

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. ContentBlock & Entity Serialization Tests', () {
    test('ContentBlock correctly serializes to and from JSON', () {
      const block = ContentBlock(
        id: 'blk_001',
        type: ContentBlockType.dialogue,
        text: 'Who is there?',
        speakerId: 'arjun',
        order: 1,
      );

      final jsonString = block.toJson();
      final restored = ContentBlock.fromJson(jsonString);

      expect(restored.id, equals('blk_001'));
      expect(restored.type, equals(ContentBlockType.dialogue));
      expect(restored.text, equals('Who is there?'));
      expect(restored.speakerId, equals('arjun'));
      expect(restored.order, equals(1));
    });

    test('Character model serializes properly', () {
      const character = Character(
        id: 'maya',
        name: 'Maya',
        description: 'Adventurer',
        voiceProfileId: 'voice_maya',
        colorHex: '#EC4899',
      );

      final map = character.toMap();
      final fromMap = Character.fromMap(map);

      expect(fromMap.id, equals('maya'));
      expect(fromMap.name, equals('Maya'));
      expect(fromMap.voiceProfileId, equals('voice_maya'));
      expect(fromMap.colorHex, equals('#EC4899'));
    });

    test('VoiceProfile generates consistent deterministic settings hash', () {
      const profile1 = VoiceProfile(
        id: 'voice_arjun',
        name: 'Arjun Voice',
        providerVoiceId: 'voice_02',
        speed: 1.0,
        pitch: 0.85,
        volume: 1.0,
      );

      const profile2 = VoiceProfile(
        id: 'voice_arjun',
        name: 'Arjun Voice',
        providerVoiceId: 'voice_02',
        speed: 1.0,
        pitch: 0.85,
        volume: 1.0,
      );

      final modified = profile1.copyWith(pitch: 1.2);

      expect(profile1.generateSettingsHash(), equals(profile2.generateSettingsHash()));
      expect(profile1.generateSettingsHash(), isNot(equals(modified.generateSettingsHash())));
    });
  });

  group('2. Speaker Detection Engine Tests', () {
    late RuleBasedSpeakerDetector detector;
    late List<Character> characters;

    setUp(() {
      detector = RuleBasedSpeakerDetector();
      characters = const [
        Character(id: 'narrator', name: 'Narrator', voiceProfileId: 'voice_narrator'),
        Character(id: 'arjun', name: 'Arjun', voiceProfileId: 'voice_arjun'),
        Character(id: 'maya', name: 'Maya', voiceProfileId: 'voice_maya'),
      ];
    });

    test('Parses narrative and dialogue with speaker attribution tags', () async {
      const storyText = '''
The room suddenly became silent.
"Who is there?" Arjun asked.
"Don't move!" Maya replied.
He slowly turned around.
''';

      final blocks = await detector.detect(
        rawText: storyText,
        knownCharacters: characters,
        chapterId: 'ch1',
      );

      expect(blocks.length, greaterThanOrEqualTo(4));

      // Block 1: Narration
      expect(blocks[0].type, equals(ContentBlockType.narration));
      expect(blocks[0].speakerId, equals('narrator'));
      expect(blocks[0].text, contains('The room suddenly became silent.'));

      // Block 2: Arjun dialogue
      final arjunBlock = blocks.firstWhere((b) => b.text.contains('Who is there?'));
      expect(arjunBlock.type, equals(ContentBlockType.dialogue));
      expect(arjunBlock.speakerId, equals('arjun'));

      // Block 3: Maya dialogue
      final mayaBlock = blocks.firstWhere((b) => b.text.contains("Don't move!"));
      expect(mayaBlock.type, equals(ContentBlockType.dialogue));
      expect(mayaBlock.speakerId, equals('maya'));

      // Block 4: Trailing narration
      final finalNarration = blocks.last;
      expect(finalNarration.type, equals(ContentBlockType.narration));
      expect(finalNarration.speakerId, equals('narrator'));
    });

    test('Parses script style dialogue format (Maya: Text)', () async {
      const scriptText = '''
Maya: Stop right there!
Arjun: I cannot wait any longer.
''';

      final blocks = await detector.detect(
        rawText: scriptText,
        knownCharacters: characters,
      );

      expect(blocks.length, equals(2));
      expect(blocks[0].speakerId, equals('maya'));
      expect(blocks[0].text, equals('Stop right there!'));
      expect(blocks[1].speakerId, equals('arjun'));
      expect(blocks[1].text, equals('I cannot wait any longer.'));
    });

    test('Accurately parses and attributes multi-character dialogue in "The Door at Midnight"', () async {
      const demoStory = '''
# The Door at Midnight

The old clock on the wall struck twelve.

Rain tapped gently against the windows, and the entire house was silent. Arjun sat alone in the living room, staring at the book in his hands.

Suddenly, there was a knock at the door.

Arjun looked up.

"Who could possibly be outside at this hour?" he whispered.

Another knock came.

This time, it was louder.

Arjun slowly stood up and walked toward the door.

"Don't open it."

The voice came from behind him.

Arjun turned around quickly. Maya was standing at the entrance of the hallway.

"Maya? I thought you were asleep."

"I was," she replied. "Then I heard the knocking."

The house became completely silent again.

Then a man's voice came from the other side of the door.

"Arjun... open the door."
''';

      final blocks = await detector.detect(
        rawText: demoStory,
        knownCharacters: characters,
      );

      // Check speaker assignments for each dialogue:
      final arjunWhisper = blocks.firstWhere((b) => b.text.contains('Who could possibly be outside'));
      expect(arjunWhisper.speakerId, equals('arjun'));

      final mayaWarning = blocks.firstWhere((b) => b.text.contains("Don't open it."));
      expect(mayaWarning.speakerId, equals('maya'));

      final arjunQuestion = blocks.firstWhere((b) => b.text.contains('I thought you were asleep'));
      expect(arjunQuestion.speakerId, equals('arjun'));

      final mayaReply = blocks.firstWhere((b) => b.text.contains('Then I heard the knocking'));
      expect(mayaReply.speakerId, equals('maya'));

      final strangerKnock = blocks.firstWhere((b) => b.text.contains('open the door'));
      expect(['stranger', 'arjun', 'maya'], contains(strangerKnock.speakerId));
    });
  });

  group('3. VoiceEngine & AudioCacheManager Tests', () {
    late Directory tempCacheDir;
    late AudioCacheManager cacheManager;
    late MockTestTtsProvider mockTts;
    late VoiceEngine voiceEngine;

    setUp(() async {
      tempCacheDir = await Directory.systemTemp.createTemp('voice_cache_test_');
      cacheManager = AudioCacheManager(customCacheDirectory: tempCacheDir.path);
      mockTts = MockTestTtsProvider();
      voiceEngine = VoiceEngine(ttsProvider: mockTts, cacheManager: cacheManager);
    });

    tearDown(() async {
      if (tempCacheDir.existsSync()) {
        tempCacheDir.deleteSync(recursive: true);
      }
    });

    test('Retrieves default profiles and characters', () {
      final characters = voiceEngine.getCharacters();
      expect(characters.map((c) => c.id), containsAll(['narrator', 'arjun', 'maya']));

      final arjunProfile = voiceEngine.getVoiceProfile('arjun');
      expect(arjunProfile.id, equals('voice_arjun'));
      expect(arjunProfile.providerVoiceId, equals('en-us-x-iom-local'));
    });

    test('Generates audio segment on demand and stores in cache', () async {
      const block = ContentBlock(
        id: 'blk_test_01',
        type: ContentBlockType.dialogue,
        text: 'Testing audio generation pipeline',
        speakerId: 'arjun',
        order: 1,
      );

      // 1. Initial generation (cache miss -> generates via provider)
      final segment1 = await voiceEngine.generateAudio(
        block: block,
        bookId: 'book_01',
        chapterId: 'ch_01',
      );

      expect(segment1.status, equals(AudioSegmentStatus.ready));
      expect(segment1.audioPath, isNotNull);
      expect(File(segment1.audioPath!).existsSync(), isTrue);

      // 2. Second request (cache hit -> returns directly from cache)
      final segment2 = await voiceEngine.generateAudio(
        block: block,
        bookId: 'book_01',
        chapterId: 'ch_01',
      );

      expect(segment2.audioPath, equals(segment1.audioPath));

      // 3. Cache clearing
      await voiceEngine.clearCache(bookId: 'book_01');
      final size = await cacheManager.getCacheSizeBytes();
      expect(size, equals(0));
    });

    test('Reassigning voice profile updates speaker voice mapping', () {
      voiceEngine.assignVoice('arjun', 'voice_maya');
      final newProfile = voiceEngine.getVoiceProfile('arjun');
      expect(newProfile.id, equals('voice_maya'));
    });
  });

  group('4. SyncEngine & MultiVoiceSessionController Tests', () {
    late MockTestTtsProvider mockTts;
    late VoiceEngine voiceEngine;
    late SyncEngine syncEngine;
    late MultiVoiceSessionController controller;

    setUp(() {
      mockTts = MockTestTtsProvider();
      voiceEngine = VoiceEngine(ttsProvider: mockTts);
      syncEngine = SyncEngine();
      controller = MultiVoiceSessionController(
        voiceEngine: voiceEngine,
        syncEngine: syncEngine,
      );
    });

    test('SyncEngine sets content blocks and updates position', () {
      final blocks = [
        const ContentBlock(id: 'b1', type: ContentBlockType.narration, text: 'Hello', speakerId: 'narrator', order: 1),
        const ContentBlock(id: 'b2', type: ContentBlockType.dialogue, text: 'Hi', speakerId: 'maya', order: 2),
      ];

      syncEngine.setContentBlocks(blocks);
      expect(syncEngine.contentBlocks.length, equals(2));
      expect(syncEngine.currentBlockIndex, equals(0));

      syncEngine.updateAudioPosition(1);
      expect(syncEngine.currentBlockIndex, equals(1));
      expect(syncEngine.currentBlock?.speakerId, equals('maya'));
    });

    test('Controller parses raw text, plays multi-voice blocks sequentially', () async {
      const rawText = '''
The night was cold and quiet.
"Where are we?" Arjun whispered.
"I don't know," Maya said.
''';

      await controller.loadRawContent(
        rawText: rawText,
        bookId: 'test_book',
        chapterId: 'ch_01',
      );

      expect(controller.contentBlocks.length, greaterThanOrEqualTo(3));

      // Play
      await controller.play();
      expect(mockTts.lastSpokenText, isNotNull);

      // Skip Next
      await controller.next();
      expect(controller.currentBlockIndex, equals(1));

      // Toggle multi-voice
      controller.setMultiVoiceEnabled(false);
      expect(controller.isMultiVoiceEnabled, isFalse);

      // Stop
      await controller.stop();
      expect(controller.isPlaying, isFalse);
    });
  });

  group('5. True Multi-Voice TTS & Provider Voice ID Tests', () {
    late Directory tempCacheDir;
    late AudioCacheManager cacheManager;
    late MockTestTtsProvider mockTts;
    late VoiceEngine voiceEngine;
    late MultiVoiceSessionController controller;

    setUp(() async {
      tempCacheDir = await Directory.systemTemp.createTemp('voice_test_5_');
      cacheManager = AudioCacheManager(customCacheDirectory: tempCacheDir.path);
      mockTts = MockTestTtsProvider();
      voiceEngine = VoiceEngine(ttsProvider: mockTts, cacheManager: cacheManager);
      controller = MultiVoiceSessionController(voiceEngine: voiceEngine);
    });

    tearDown(() async {
      if (tempCacheDir.existsSync()) {
        tempCacheDir.deleteSync(recursive: true);
      }
    });

    test('Each speaker is mapped to a genuinely separate provider voice identity', () {
      final narratorProfile = voiceEngine.getVoiceProfile('narrator');
      final arjunProfile = voiceEngine.getVoiceProfile('arjun');
      final mayaProfile = voiceEngine.getVoiceProfile('maya');
      final strangerProfile = voiceEngine.getVoiceProfile('stranger');

      // 1. Verify that all 4 characters have completely distinct providerVoiceId values
      final voiceIds = {
        narratorProfile.providerVoiceId,
        arjunProfile.providerVoiceId,
        mayaProfile.providerVoiceId,
        strangerProfile.providerVoiceId,
      };
      expect(voiceIds.length, equals(4),
          reason: 'Every speaker character MUST have a unique providerVoiceId voice model, not just pitch shifts');

      // 2. Verify specific model identifiers
      expect(narratorProfile.providerVoiceId, equals('en-us-x-sfg#female_1-local'));
      expect(arjunProfile.providerVoiceId, equals('en-us-x-iom-local'));
      expect(mayaProfile.providerVoiceId, equals('en-us-x-iol-local'));
      expect(strangerProfile.providerVoiceId, equals('en-gb-x-rjs-local'));
    });

    test('ContentBlock speakerId resolves end-to-end to TTSProvider generate with distinct providerVoiceId', () async {
      // Create ContentBlocks with speakerId
      const blockNarrator = ContentBlock(
        id: 'blk_1',
        type: ContentBlockType.narration,
        text: 'The night fell over the misty mountains.',
        speakerId: 'narrator',
        order: 1,
      );

      const blockArjun = ContentBlock(
        id: 'blk_2',
        type: ContentBlockType.dialogue,
        text: 'We must proceed through the pass immediately.',
        speakerId: 'arjun',
        order: 2,
      );

      const blockMaya = ContentBlock(
        id: 'blk_3',
        type: ContentBlockType.dialogue,
        text: 'Wait Arjun, look at the footprints on the ground!',
        speakerId: 'maya',
        order: 3,
      );

      // Generate audio segments
      final segNarrator = await voiceEngine.generateAudio(block: blockNarrator);
      final segArjun = await voiceEngine.generateAudio(block: blockArjun);
      final segMaya = await voiceEngine.generateAudio(block: blockMaya);

      expect(segNarrator.voiceProfileId, equals('voice_narrator'));
      expect(segArjun.voiceProfileId, equals('voice_arjun'));
      expect(segMaya.voiceProfileId, equals('voice_maya'));
    });

    test('MultiVoiceSession plays sequentially using distinct provider voice models for each speaker', () async {
      const dialogueText = '''
Arjun: Who could possibly be outside at this hour?
Maya: Don't open it.
Stranger: Arjun... open the door.
''';

      await controller.loadRawContent(
        rawText: dialogueText,
        bookId: 'test_book',
        chapterId: 'ch_01',
      );

      expect(controller.contentBlocks.length, equals(3));

      // Play Block 0 (Arjun)
      await controller.play();
      expect(mockTts.lastSpokenProfile?.providerVoiceId, equals('en-us-x-iom-local'));

      // Advance to Block 1 (Maya)
      await controller.next();
      expect(mockTts.lastSpokenProfile?.providerVoiceId, equals('en-us-x-iol-local'));

      // Advance to Block 2 (Stranger)
      await controller.next();
      expect(mockTts.lastSpokenProfile?.providerVoiceId, equals('en-gb-x-rjs-local'));

      // Verify that spoken profiles in history have distinct providerVoiceId values
      expect(mockTts.spokenProfilesHistory.length, equals(3));
      final p1 = mockTts.spokenProfilesHistory[0];
      final p2 = mockTts.spokenProfilesHistory[1];
      final p3 = mockTts.spokenProfilesHistory[2];
      expect(p1.providerVoiceId, isNot(equals(p2.providerVoiceId)),
          reason: 'Dialogue turns between Arjun and Maya MUST use different provider voice identities');
      expect(p2.providerVoiceId, isNot(equals(p3.providerVoiceId)),
          reason: 'Dialogue turns between Maya and Stranger MUST use different provider voice identities');
    });

    test('autoDiscoverAndAssignVoices dynamically maps 3+ real device voices to character profiles', () async {
      // Mock custom device voices discovered from device OS
      mockTts.customAvailableVoices = [
        {'id': 'com.apple.voice.samantha', 'name': 'Samantha (iOS Narrator)', 'locale': 'en-US'},
        {'id': 'com.apple.voice.alex', 'name': 'Alex (iOS Arjun)', 'locale': 'en-US'},
        {'id': 'com.apple.voice.karen', 'name': 'Karen (iOS Maya)', 'locale': 'en-US'},
        {'id': 'com.apple.voice.daniel', 'name': 'Daniel (iOS Stranger)', 'locale': 'en-GB'},
      ];

      await voiceEngine.autoDiscoverAndAssignVoices();

      final narratorProfile = voiceEngine.getVoiceProfile('narrator');
      final arjunProfile = voiceEngine.getVoiceProfile('arjun');
      final mayaProfile = voiceEngine.getVoiceProfile('maya');
      final strangerProfile = voiceEngine.getVoiceProfile('stranger');

      final distinctVoiceIds = {
        narratorProfile.providerVoiceId,
        arjunProfile.providerVoiceId,
        mayaProfile.providerVoiceId,
        strangerProfile.providerVoiceId,
      };
      expect(distinctVoiceIds.length, equals(4));
      expect(distinctVoiceIds, containsAll([
        'com.apple.voice.samantha',
        'com.apple.voice.alex',
        'com.apple.voice.karen',
        'com.apple.voice.daniel',
      ]));
    });
  });
}
