import 'dart:convert';

/// Represents a user's reading identity, customization settings, and lifetime stats.
class UserProfile {
  final String id;
  final String displayName;
  final String email;
  final String avatarEmoji;
  final String avatarGradientStart;
  final String avatarGradientEnd;
  final String readerTier;
  final int dailyGoalMinutes;
  final int currentStreakDays;
  final int longestStreakDays;
  final String? lastActiveDate;
  final int booksCompletedCount;
  final int totalMinutesRead;
  final int totalMinutesListened;
  final String preferredThemeMode; // 'system', 'light', 'dark'
  final List<String> favoriteCategories;

  const UserProfile({
    this.id = 'usr_default',
    this.displayName = 'Arjun (Reader)',
    this.email = 'reader@scribbleverse.io',
    this.avatarEmoji = '🦉',
    this.avatarGradientStart = '0xFFD4A373',
    this.avatarGradientEnd = '0xFFA8764B',
    this.readerTier = 'READER • TIER 1',
    this.dailyGoalMinutes = 30,
    this.currentStreakDays = 5,
    this.longestStreakDays = 14,
    this.lastActiveDate,
    this.booksCompletedCount = 4,
    this.totalMinutesRead = 420,
    this.totalMinutesListened = 390,
    this.preferredThemeMode = 'system',
    this.favoriteCategories = const ['cat_malayalam', 'cat_mystery', 'cat_scifi'],
  });

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    String? avatarEmoji,
    String? avatarGradientStart,
    String? avatarGradientEnd,
    String? readerTier,
    int? dailyGoalMinutes,
    int? currentStreakDays,
    int? longestStreakDays,
    String? lastActiveDate,
    int? booksCompletedCount,
    int? totalMinutesRead,
    int? totalMinutesListened,
    String? preferredThemeMode,
    List<String>? favoriteCategories,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      avatarGradientStart: avatarGradientStart ?? this.avatarGradientStart,
      avatarGradientEnd: avatarGradientEnd ?? this.avatarGradientEnd,
      readerTier: readerTier ?? this.readerTier,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      longestStreakDays: longestStreakDays ?? this.longestStreakDays,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      booksCompletedCount: booksCompletedCount ?? this.booksCompletedCount,
      totalMinutesRead: totalMinutesRead ?? this.totalMinutesRead,
      totalMinutesListened: totalMinutesListened ?? this.totalMinutesListened,
      preferredThemeMode: preferredThemeMode ?? this.preferredThemeMode,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'avatarEmoji': avatarEmoji,
      'avatarGradientStart': avatarGradientStart,
      'avatarGradientEnd': avatarGradientEnd,
      'readerTier': readerTier,
      'dailyGoalMinutes': dailyGoalMinutes,
      'currentStreakDays': currentStreakDays,
      'longestStreakDays': longestStreakDays,
      if (lastActiveDate != null) 'lastActiveDate': lastActiveDate,
      'booksCompletedCount': booksCompletedCount,
      'totalMinutesRead': totalMinutesRead,
      'totalMinutesListened': totalMinutesListened,
      'preferredThemeMode': preferredThemeMode,
      'favoriteCategories': favoriteCategories,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String? ?? 'usr_default',
      displayName: map['displayName'] as String? ?? 'Arjun (Reader)',
      email: map['email'] as String? ?? 'reader@scribbleverse.io',
      avatarEmoji: map['avatarEmoji'] as String? ?? '🦉',
      avatarGradientStart: map['avatarGradientStart'] as String? ?? '0xFFD4A373',
      avatarGradientEnd: map['avatarGradientEnd'] as String? ?? '0xFFA8764B',
      readerTier: map['readerTier'] as String? ?? 'READER • TIER 1',
      dailyGoalMinutes: (map['dailyGoalMinutes'] as num?)?.toInt() ?? 30,
      currentStreakDays: (map['currentStreakDays'] as num?)?.toInt() ?? 5,
      longestStreakDays: (map['longestStreakDays'] as num?)?.toInt() ?? 14,
      lastActiveDate: map['lastActiveDate'] as String?,
      booksCompletedCount: (map['booksCompletedCount'] as num?)?.toInt() ?? 4,
      totalMinutesRead: (map['totalMinutesRead'] as num?)?.toInt() ?? 420,
      totalMinutesListened: (map['totalMinutesListened'] as num?)?.toInt() ?? 390,
      preferredThemeMode: map['preferredThemeMode'] as String? ?? 'system',
      favoriteCategories: (map['favoriteCategories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['cat_malayalam', 'cat_mystery', 'cat_scifi'],
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(json.decode(source) as Map<String, dynamic>);
}
