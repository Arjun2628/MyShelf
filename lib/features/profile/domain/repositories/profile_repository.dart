import 'package:epub_audio/features/profile/domain/entities/reading_stats.dart';
import 'package:epub_audio/features/profile/domain/entities/user_profile.dart';

/// Contract for accessing, updating, and synchronizing reading identity and statistics.
abstract class ProfileRepository {
  Future<UserProfile> getUserProfile();
  Future<void> saveUserProfile(UserProfile profile);
  Future<ReadingStats> getReadingStats();
  Future<void> recordActivity({required int minutes, required bool isAudio});
  Future<void> resetStreak();
}
