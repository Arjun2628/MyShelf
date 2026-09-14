import 'dart:io';
import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:epub_audio/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:epub_audio/features/profile/domain/entities/reading_stats.dart';
import 'package:epub_audio/features/profile/domain/entities/user_profile.dart';
import 'package:epub_audio/features/profile/presentation/screens/profile_screen.dart';
import 'package:epub_audio/features/profile/presentation/widgets/avatar_picker_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late ProfileRepositoryImpl profileRepo;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('profile_identity_test_');
    await HiveStorageService().init(tempDir.path);
    profileRepo = ProfileRepositoryImpl();
    await profileRepo.saveUserProfile(const UserProfile());
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('UserProfile Domain Entity', () {
    test('default UserProfile has expected initial values', () {
      const profile = UserProfile();
      expect(profile.displayName, 'Arjun (Reader)');
      expect(profile.avatarEmoji, '🦉');
      expect(profile.currentStreakDays, 5);
      expect(profile.dailyGoalMinutes, 30);
      expect(profile.booksCompletedCount, 4);
    });

    test('UserProfile serialization toMap and fromMap', () {
      const profile = UserProfile(
        id: 'user_123',
        displayName: 'Aria Stark',
        email: 'aria@winterfell.io',
        avatarEmoji: '🐺',
        avatarGradientStart: '0xFF6366F1',
        avatarGradientEnd: '0xFF4338CA',
        readerTier: 'MASTER READER',
        dailyGoalMinutes: 45,
        currentStreakDays: 12,
        longestStreakDays: 30,
        booksCompletedCount: 15,
      );

      final map = profile.toMap();
      final restored = UserProfile.fromMap(map);
      expect(restored.id, 'user_123');
      expect(restored.displayName, 'Aria Stark');
      expect(restored.avatarEmoji, '🐺');
      expect(restored.readerTier, 'MASTER READER');
      expect(restored.dailyGoalMinutes, 45);
      expect(restored.currentStreakDays, 12);
    });
  });

  group('ReadingStats & DayActivity Domain Entities', () {
    test('computes totalHoursRead, totalHoursListened, and dailyGoalProgress', () {
      const stats = ReadingStats(
        totalMinutesRead: 300,
        totalMinutesListened: 180,
        dailyGoalMinutes: 60,
        todayMinutesCompleted: 45,
      );

      expect(stats.totalHoursRead, 5.0);
      expect(stats.totalHoursListened, 3.0);
      expect(stats.dailyGoalProgress, 0.75);
    });

    test('DayActivity serialization', () {
      const day = DayActivity(dayName: 'Wed', minutes: 40, completed: true);
      final map = day.toMap();
      final restored = DayActivity.fromMap(map);
      expect(restored.dayName, 'Wed');
      expect(restored.minutes, 40);
      expect(restored.completed, isTrue);
    });
  });

  group('ProfileRepositoryImpl', () {
    test('loads default profile if none saved, and saves updated profile', () async {
      final initial = await profileRepo.getUserProfile();
      expect(initial.displayName, 'Arjun (Reader)');

      final custom = initial.copyWith(
        displayName: 'Elena Gilbert',
        avatarEmoji: '✨',
        currentStreakDays: 9,
      );

      await profileRepo.saveUserProfile(custom);
      final loaded = await profileRepo.getUserProfile();
      expect(loaded.displayName, 'Elena Gilbert');
      expect(loaded.avatarEmoji, '✨');
      expect(loaded.currentStreakDays, 9);
    });

    test('recordActivity increments read or listen minutes', () async {
      final initial = await profileRepo.getUserProfile();
      final initialRead = initial.totalMinutesRead;

      await profileRepo.recordActivity(minutes: 30, isAudio: false);
      final updated = await profileRepo.getUserProfile();
      expect(updated.totalMinutesRead, initialRead + 30);
    });

    test('getReadingStats returns consistent metrics', () async {
      final stats = await profileRepo.getReadingStats();
      expect(stats.currentStreakDays, greaterThanOrEqualTo(0));
      expect(stats.weeklyActivity.length, 7);
      expect(stats.totalHoursRead, greaterThanOrEqualTo(0));
    });
  });

  group('Profile & Avatar UI Components', () {
    testWidgets('AvatarPickerModal allows selecting emoji, editing name, and saving', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      UserProfile? updatedResult;
      const initial = UserProfile();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AvatarPickerModal(
              currentProfile: initial,
              onProfileUpdated: (p) => updatedResult = p,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Customize Avatar & Identity'), findsOneWidget);
      expect(find.text('Reader Moniker'), findsOneWidget);
      expect(find.text('Save Profile Identity'), findsOneWidget);

      // Tap on dragon emoji '🐉'
      final dragon = find.text('🐉');
      if (dragon.evaluate().isNotEmpty) {
        await tester.tap(dragon);
        await tester.pump();
      }

      // Ensure Save button is visible and tap
      final saveFinder = find.text('Save Profile Identity');
      await tester.ensureVisible(saveFinder);
      await tester.tap(saveFinder);
      await tester.pump();

      expect(updatedResult, isNotNull);
      expect(updatedResult!.avatarEmoji, '🐉');
    });

    testWidgets('ProfileScreen renders user details, streak, goals, and stat cards', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(repository: profileRepo),
        ),
      );

      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Profile & Identity'), findsOneWidget);
      expect(find.text('Arjun (Reader)'), findsOneWidget);
      expect(find.text('Daily Reading Goal'), findsOneWidget);
      expect(find.text('5 Day Reading Streak'), findsOneWidget);
      expect(find.text('Appearance Theme'), findsOneWidget);
      expect(find.text('Multi-Voice Narration'), findsOneWidget);
    });
  });
}
