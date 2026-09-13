import 'package:flutter/foundation.dart';
import '../entities/content_block.dart';
import '../entities/character.dart';
import '../entities/voice_profile.dart';
import '../entities/audio_segment.dart';
import '../../data/cache/audio_cache_manager.dart';
import 'tts_provider.dart';

/// Central Voice Engine managing character voice mappings, profile settings, audio generation, and caching.
class VoiceEngine {
  final TTSProvider _ttsProvider;
  final AudioCacheManager _cacheManager;

  final Map<String, Character> _characters = {};
  final Map<String, VoiceProfile> _voiceProfiles = {};

  VoiceEngine({
    required TTSProvider ttsProvider,
    AudioCacheManager? cacheManager,
  })  : _ttsProvider = ttsProvider,
        _cacheManager = cacheManager ?? AudioCacheManager() {
    _initializeDefaultProfilesAndCharacters();
  }

  TTSProvider get ttsProvider => _ttsProvider;
  AudioCacheManager get cacheManager => _cacheManager;

  void _initializeDefaultProfilesAndCharacters() {
    // 1. Narrator Profile (Voice ID A - Clear, standard narrator)
    final narratorProfile = const VoiceProfile(
      id: 'voice_narrator',
      name: 'Narrator (Studio Clear)',
      provider: 'device_tts',
      providerVoiceId: 'en-us-x-sfg#female_1-local',
      language: 'en-US',
      speed: 1.0,
      pitch: 1.0,
      volume: 1.0,
      emotion: 'neutral',
    );

    // 2. Arjun Profile (Voice ID B - Distinct Masculine Voice Model)
    final arjunProfile = const VoiceProfile(
      id: 'voice_arjun',
      name: 'Arjun (Resonant Male)',
      provider: 'device_tts',
      providerVoiceId: 'en-us-x-iom-local',
      language: 'en-US',
      speed: 1.0,
      pitch: 1.0,
      volume: 1.0,
      emotion: 'composed',
    );

    // 3. Maya Profile (Voice ID C - Distinct Female Voice Model)
    final mayaProfile = const VoiceProfile(
      id: 'voice_maya',
      name: 'Maya (Expressive Female)',
      provider: 'device_tts',
      providerVoiceId: 'en-us-x-iol-local',
      language: 'en-US',
      speed: 1.0,
      pitch: 1.0,
      volume: 1.0,
      emotion: 'expressive',
    );

    // 4. Stranger / Unknown Profile (Voice ID D - Distinct British / Deep Alternate Voice Model)
    final strangerProfile = const VoiceProfile(
      id: 'voice_stranger',
      name: 'Stranger (British / Deep Male)',
      provider: 'device_tts',
      providerVoiceId: 'en-gb-x-rjs-local',
      language: 'en-GB',
      speed: 1.0,
      pitch: 1.0,
      volume: 1.0,
      emotion: 'whisper',
    );

    _voiceProfiles[narratorProfile.id] = narratorProfile;
    _voiceProfiles[arjunProfile.id] = arjunProfile;
    _voiceProfiles[mayaProfile.id] = mayaProfile;
    _voiceProfiles[strangerProfile.id] = strangerProfile;

    _characters['narrator'] = const Character(
      id: 'narrator',
      name: 'Narrator',
      description: 'Main omniscient narrator',
      voiceProfileId: 'voice_narrator',
      colorHex: '#6366F1',
    );

    _characters['arjun'] = const Character(
      id: 'arjun',
      name: 'Arjun',
      description: 'Protagonist, composed and calm',
      voiceProfileId: 'voice_arjun',
      colorHex: '#3B82F6',
    );

    _characters['maya'] = const Character(
      id: 'maya',
      name: 'Maya',
      description: 'Energetic and inquisitive character',
      voiceProfileId: 'voice_maya',
      colorHex: '#EC4899',
    );

    _characters['stranger'] = const Character(
      id: 'stranger',
      name: 'Mystery Figure',
      description: 'Unknown entity or stranger',
      voiceProfileId: 'voice_stranger',
      colorHex: '#8B5CF6',
    );

    _characters['unknown'] = const Character(
      id: 'unknown',
      name: 'Unknown Speaker',
      description: 'Unidentified speaker',
      voiceProfileId: 'voice_stranger',
      colorHex: '#8B5CF6',
    );
  }

  /// Auto-discovers physical device voice models from TTS provider and binds distinct voice models
  /// to Narrator, Arjun (Male), Maya (Female), and Stranger (Alternate) based on the target language.
  Future<void> autoDiscoverAndAssignVoices({String targetLanguage = 'en-US'}) async {
    try {
      final voices = await _ttsProvider.getAvailableVoices();
      if (voices.isEmpty) return;

      final langPrefix = targetLanguage.split(RegExp(r'[-_]')).first.toLowerCase();

      // Filter voices for the current language
      var matchingVoices = voices.where((v) {
        final loc = (v['locale'] ?? '').toLowerCase();
        final id = (v['id'] ?? '').toLowerCase();
        final name = (v['name'] ?? '').toLowerCase();
        return loc.startsWith(langPrefix) || id.startsWith(langPrefix) || name.startsWith(langPrefix);
      }).toList();

      if (matchingVoices.isEmpty) {
        matchingVoices = voices;
      }

      if (matchingVoices.isNotEmpty) {
        final List<Map<String, String>> distinctVoices = [];
        final Set<String> seenIds = {};

        for (final v in matchingVoices) {
          final id = v['id'] ?? v['name'] ?? '';
          if (id.isNotEmpty && !seenIds.contains(id)) {
            seenIds.add(id);
            distinctVoices.add(v);
          }
        }

        // Separate into Male, Female, and Alternate voice pools
        final List<Map<String, String>> malePool = [];
        final List<Map<String, String>> femalePool = [];
        final List<Map<String, String>> otherPool = [];

        for (final v in distinctVoices) {
          final id = (v['id'] ?? '').toLowerCase();
          final name = (v['name'] ?? '').toLowerCase();
          final gender = (v['gender'] ?? '').toLowerCase();

          final isMale = gender == 'male' ||
              id.contains('#male') ||
              id.contains('-male') ||
              id.contains('_male') ||
              name.contains('male') ||
              id.contains('iom') ||
              id.contains('iob') ||
              id.contains('tpd') ||
              id.contains('tpc') ||
              id.contains('rjs') ||
              id.contains('gbb') ||
              id.contains('aud') ||
              id.contains('enc') ||
              id.contains('alex') ||
              id.contains('daniel') ||
              id.contains('oliver') ||
              id.contains('fred') ||
              id.contains('george') ||
              id.contains('rishi') ||
              id.contains('standard-b') ||
              id.contains('standard-d') ||
              id.contains('wavenet-b') ||
              id.contains('wavenet-d');

          final isFemale = gender == 'female' ||
              id.contains('#female') ||
              id.contains('-female') ||
              id.contains('_female') ||
              name.contains('female') ||
              id.contains('sfg') ||
              id.contains('iol') ||
              id.contains('tpf') ||
              id.contains('gba') ||
              id.contains('gbd') ||
              id.contains('aub') ||
              id.contains('cxx') ||
              id.contains('end') ||
              id.contains('samantha') ||
              id.contains('karen') ||
              id.contains('moira') ||
              id.contains('victoria') ||
              id.contains('tessa') ||
              id.contains('ava') ||
              id.contains('serena') ||
              id.contains('standard-a') ||
              id.contains('standard-c') ||
              id.contains('standard-e') ||
              id.contains('wavenet-a') ||
              id.contains('wavenet-c') ||
              id.contains('wavenet-e');

          if (isMale && !isFemale) {
            malePool.add(v);
          } else if (isFemale && !isMale) {
            femalePool.add(v);
          } else {
            otherPool.add(v);
          }
        }

        // Categorize specifically for each character role
        Map<String, String>? narratorVoice;
        Map<String, String>? maleVoice;
        Map<String, String>? femaleVoice;
        Map<String, String>? strangerVoice;

        // Arjun -> strictly Male voice
        if (malePool.isNotEmpty) {
          maleVoice = malePool.first;
        } else if (otherPool.isNotEmpty) {
          maleVoice = otherPool.first;
        } else {
          maleVoice = distinctVoices.length > 1 ? distinctVoices[1] : distinctVoices[0];
        }

        // Maya -> strictly Female voice
        if (femalePool.isNotEmpty) {
          femaleVoice = femalePool.first;
        } else if (otherPool.length > 1) {
          femaleVoice = otherPool[1];
        } else {
          femaleVoice = distinctVoices.length > 2 ? distinctVoices[2] : (distinctVoices.isNotEmpty ? distinctVoices[0] : null);
        }

        // Narrator -> Clear Female or Primary Narrator voice
        if (femalePool.length > 1) {
          narratorVoice = femalePool[1];
        } else if (otherPool.isNotEmpty && otherPool.first != maleVoice) {
          narratorVoice = otherPool.first;
        } else {
          narratorVoice = distinctVoices.isNotEmpty ? distinctVoices[0] : null;
        }

        // Stranger -> Alternate Male / British accent / Deep voice
        if (malePool.length > 1) {
          strangerVoice = malePool[1];
        } else {
          final gbOrAccent = distinctVoices.firstWhere(
            (v) => (v['locale'] ?? '').toLowerCase().contains('gb') ||
                (v['id'] ?? '').toLowerCase().contains('rjs') ||
                (v != maleVoice && v != femaleVoice && v != narratorVoice),
            orElse: () => distinctVoices.length > 3 ? distinctVoices[3] : (maleVoice ?? distinctVoices[0]),
          );
          strangerVoice = gbOrAccent;
        }

        if (narratorVoice != null && _voiceProfiles.containsKey('voice_narrator')) {
          _voiceProfiles['voice_narrator'] = _voiceProfiles['voice_narrator']!.copyWith(
            providerVoiceId: narratorVoice['id'] ?? narratorVoice['name'],
            language: narratorVoice['locale'] ?? targetLanguage,
            pitch: 1.0,
            speed: 1.0,
          );
        }
        if (_voiceProfiles.containsKey('voice_arjun')) {
          _voiceProfiles['voice_arjun'] = _voiceProfiles['voice_arjun']!.copyWith(
            providerVoiceId: maleVoice['id'] ?? maleVoice['name'],
            language: maleVoice['locale'] ?? targetLanguage,
            pitch: 1.0,
            speed: 1.0,
          );
        }
        if (femaleVoice != null && _voiceProfiles.containsKey('voice_maya')) {
          _voiceProfiles['voice_maya'] = _voiceProfiles['voice_maya']!.copyWith(
            providerVoiceId: femaleVoice['id'] ?? femaleVoice['name'],
            language: femaleVoice['locale'] ?? targetLanguage,
            pitch: 1.0,
            speed: 1.0,
          );
        }
        if (_voiceProfiles.containsKey('voice_stranger')) {
          _voiceProfiles['voice_stranger'] = _voiceProfiles['voice_stranger']!.copyWith(
            providerVoiceId: strangerVoice['id'] ?? strangerVoice['name'],
            language: strangerVoice['locale'] ?? targetLanguage,
            pitch: 1.0,
            speed: 1.0,
          );
        }

        debugPrint('[VoiceEngine] Assigned distinct voice models with natural pitch for $targetLanguage: '
            'Narrator=${_voiceProfiles['voice_narrator']?.providerVoiceId}, '
            'Arjun(Male)=${_voiceProfiles['voice_arjun']?.providerVoiceId}, '
            'Maya(Female)=${_voiceProfiles['voice_maya']?.providerVoiceId}, '
            'Stranger=${_voiceProfiles['voice_stranger']?.providerVoiceId}');
      }
    } catch (e) {
      debugPrint('[VoiceEngine] Auto-discovery error: $e');
    }
  }

  /// Returns character details for a given speakerId.
  Character? getCharacter(String speakerId) {
    final lower = speakerId.toLowerCase().trim();
    if (lower == 'unknown' || lower == 'mystery') {
      return _characters['stranger'] ?? _characters['unknown'];
    }
    return _characters[lower];
  }

  /// Returns all registered characters.
  List<Character> getCharacters() {
    return _characters.values.toList();
  }

  /// Registers or updates a character.
  void registerCharacter(Character character) {
    _characters[character.id.toLowerCase()] = character;
  }

  /// Returns all available voice profiles.
  List<VoiceProfile> getAllProfiles() {
    return _voiceProfiles.values.toList();
  }

  /// Retrieves the assigned [VoiceProfile] for a speaker.
  VoiceProfile getVoiceProfile(String speakerId) {
    final lower = speakerId.toLowerCase().trim();
    final character = _characters[lower] ??
        ((lower == 'unknown' || lower == 'mystery') ? _characters['stranger'] : null);
    if (character != null) {
      final profile = _voiceProfiles[character.voiceProfileId];
      if (profile != null) return profile;
    }
    // Fallback to narrator voice profile
    return _voiceProfiles['voice_narrator'] ??
        const VoiceProfile(
          id: 'voice_narrator',
          name: 'Narrator',
          providerVoiceId: 'en-us-x-sfg#female_1-local',
        );
  }

  /// Reassigns a character's voice profile.
  void assignVoice(String speakerId, String voiceProfileId) {
    final normalizedId = speakerId.toLowerCase();
    final character = _characters[normalizedId];
    if (character != null) {
      _characters[normalizedId] = character.copyWith(voiceProfileId: voiceProfileId);
    }
  }

  /// Saves or updates the acoustic properties of a voice profile.
  void updateVoiceProfile(VoiceProfile updatedProfile) {
    _voiceProfiles[updatedProfile.id] = updatedProfile;
  }

  /// Synthesizes or retrieves cached audio for the given [ContentBlock].
  Future<AudioSegment> generateAudio({
    required ContentBlock block,
    String bookId = 'active_book',
    String chapterId = 'ch_01',
  }) async {
    final profile = getVoiceProfile(block.speakerId);

    // 1. Check persistent cache
    final cached = await _cacheManager.getCachedSegment(
      bookId: bookId,
      chapterId: chapterId,
      blockId: block.id,
      speakerId: block.speakerId,
      voiceProfile: profile,
    );

    if (cached != null) {
      return cached;
    }

    // 2. Generate on-demand via TTSProvider
    try {
      final targetFile = await _cacheManager.getCacheTargetFile(
        bookId: bookId,
        chapterId: chapterId,
        blockId: block.id,
        voiceProfile: profile,
      );

      final segment = await _ttsProvider.generate(
        block: block,
        profile: profile,
        targetFilePath: targetFile.path,
      );

      return segment;
    } catch (e) {
      debugPrint('[VoiceEngine] Generation error for block ${block.id}: $e');
      return AudioSegment(
        id: 'seg_${block.id}',
        contentBlockId: block.id,
        speakerId: block.speakerId,
        voiceProfileId: profile.id,
        status: AudioSegmentStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  /// Clears audio cache.
  Future<void> clearCache({String? bookId}) async {
    if (bookId != null) {
      await _cacheManager.clearBookCache(bookId);
    } else {
      await _cacheManager.clearAllCache();
    }
  }
}
