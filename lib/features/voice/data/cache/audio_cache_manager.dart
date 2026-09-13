import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../domain/entities/voice_profile.dart';
import '../../domain/entities/audio_segment.dart';

/// Manages structured persistent audio caching for multi-voice book segments.
class AudioCacheManager {
  final String? _customCacheDirectory;

  AudioCacheManager({String? customCacheDirectory})
      : _customCacheDirectory = customCacheDirectory;

  Future<Directory> _getBaseCacheDir() async {
    final customDir = _customCacheDirectory;
    if (customDir != null) {
      final dir = Directory(customDir);
      if (!dir.existsSync()) dir.createSync(recursive: true);
      return dir;
    }
    final appDocDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory(p.join(appDocDir.path, 'voice_cache'));
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
    return cacheDir;
  }

  /// Builds a deterministic unique cache key for a specific block & voice profile configuration.
  String buildCacheFileName({
    required String blockId,
    required VoiceProfile voiceProfile,
  }) {
    final settingsHash = voiceProfile.generateSettingsHash();
    return '${blockId}_${voiceProfile.id}_$settingsHash.wav';
  }

  Future<File> getCacheTargetFile({
    required String bookId,
    required String chapterId,
    required String blockId,
    required VoiceProfile voiceProfile,
  }) async {
    final baseDir = await _getBaseCacheDir();
    final chapterDir = Directory(p.join(baseDir.path, bookId, chapterId));
    if (!chapterDir.existsSync()) {
      chapterDir.createSync(recursive: true);
    }
    final fileName = buildCacheFileName(blockId: blockId, voiceProfile: voiceProfile);
    return File(p.join(chapterDir.path, fileName));
  }

  /// Checks if a valid cached audio segment exists for the given block & voice profile.
  Future<AudioSegment?> getCachedSegment({
    required String bookId,
    required String chapterId,
    required String blockId,
    required String speakerId,
    required VoiceProfile voiceProfile,
  }) async {
    try {
      final file = await getCacheTargetFile(
        bookId: bookId,
        chapterId: chapterId,
        blockId: blockId,
        voiceProfile: voiceProfile,
      );

      if (await file.exists() && (await file.length()) > 0) {
        return AudioSegment(
          id: 'seg_$blockId',
          contentBlockId: blockId,
          speakerId: speakerId,
          voiceProfileId: voiceProfile.id,
          audioPath: file.path,
          status: AudioSegmentStatus.ready,
        );
      }
    } catch (e) {
      debugPrint('[AudioCacheManager] Error checking cache: $e');
    }
    return null;
  }

  /// Clears cache for a specific book.
  Future<void> clearBookCache(String bookId) async {
    try {
      final baseDir = await _getBaseCacheDir();
      final bookDir = Directory(p.join(baseDir.path, bookId));
      if (await bookDir.exists()) {
        await bookDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('[AudioCacheManager] Error clearing book cache: $e');
    }
  }

  /// Clears the entire audio cache.
  Future<void> clearAllCache() async {
    try {
      final baseDir = await _getBaseCacheDir();
      if (await baseDir.exists()) {
        await baseDir.delete(recursive: true);
        await baseDir.create(recursive: true);
      }
    } catch (e) {
      debugPrint('[AudioCacheManager] Error clearing all cache: $e');
    }
  }

  /// Calculates total audio cache size in bytes.
  Future<int> getCacheSizeBytes() async {
    try {
      final baseDir = await _getBaseCacheDir();
      if (!await baseDir.exists()) return 0;

      int total = 0;
      await for (final entity in baseDir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return total;
    } catch (e) {
      debugPrint('[AudioCacheManager] Error computing cache size: $e');
      return 0;
    }
  }
}
