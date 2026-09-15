import 'dart:io';
import 'package:epub_audio/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:epub_audio/features/auth/domain/entities/auth_user.dart';
import 'package:epub_audio/features/auth/presentation/controllers/auth_controller.dart';
import 'package:epub_audio/features/auth/presentation/widgets/auth_modal.dart';
import 'package:epub_audio/features/library/data/datasources/hive_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late HiveStorageService storageService;
  late AuthRepositoryImpl authRepo;
  late AuthController authController;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('auth_test_');
    storageService = HiveStorageService();
    await storageService.init(tempDir.path);
    authRepo = AuthRepositoryImpl(storageService: storageService);
    authController = AuthController(repository: authRepo);
    await authController.init();
  });

  tearDown(() async {
    authController.dispose();
    await storageService.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AuthUser Domain Entity & Permissions Matrix', () {
    test('default AuthUser has expected member permissions', () {
      final user = AuthUser(
        id: 'usr_test',
        email: 'reader@scribbleverse.io',
        displayName: 'Test Reader',
        role: UserRole.user,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      expect(user.isUser, isTrue);
      expect(user.isGuest, isFalse);
      expect(user.isAdmin, isFalse);
      expect(user.roleBadge, '✨ MEMBER');
      expect(user.canManageCatalog, isFalse);
      expect(user.canEditShelves, isFalse);
    });

    test('guest user has restricted local permissions', () {
      final guest = AuthUser.guest();
      expect(guest.isGuest, isTrue);
      expect(guest.isAnonymous, isTrue);
      expect(guest.isAdmin, isFalse);
      expect(guest.roleBadge, '🌱 GUEST');
      expect(guest.canManageCatalog, isFalse);
    });

    test('admin user has full catalog curation permissions', () {
      final admin = AuthUser.admin(name: 'Curator Alice', email: 'alice@scribbleverse.io');
      expect(admin.isAdmin, isTrue);
      expect(admin.isGuest, isFalse);
      expect(admin.roleBadge, '👑 ADMIN');
      expect(admin.canManageCatalog, isTrue);
      expect(admin.canEditShelves, isTrue);
      expect(admin.canUploadPublicBooks, isTrue);
    });

    test('AuthUser serialization to/from JSON roundtrip', () {
      final admin = AuthUser.admin();
      final json = admin.toJson();
      final restored = AuthUser.fromJson(json);

      expect(restored.id, admin.id);
      expect(restored.displayName, admin.displayName);
      expect(restored.role, UserRole.admin);
      expect(restored.isAdmin, isTrue);
      expect(restored.canManageCatalog, isTrue);
    });
  });

  group('AuthRepositoryImpl Operations & Persistence', () {
    test('starts as initialized default user', () {
      expect(authRepo.currentUser.displayName, 'Arjun (Reader)');
      expect(authRepo.currentUser.role, UserRole.user);
    });

    test('sign in as guest creates anonymous session', () async {
      final guest = await authRepo.signInAsGuest();
      expect(guest.isGuest, isTrue);
      expect(authRepo.currentUser.isGuest, isTrue);
    });

    test('sign in with valid admin passkey grants admin privileges', () async {
      final admin = await authRepo.signInWithAdminPasskey(
        adminPasskey: 'admin123',
        adminName: 'Chief Curator',
      );
      expect(admin.isAdmin, isTrue);
      expect(admin.displayName, 'Chief Curator');
      expect(authRepo.currentUser.isAdmin, isTrue);
    });

    test('sign in with invalid admin passkey throws exception', () async {
      expect(
        () => authRepo.signInWithAdminPasskey(adminPasskey: 'wrong_secret'),
        throwsA(isA<Exception>()),
      );
    });

    test('sign up and sign in with email/password creates verified reader', () async {
      final user = await authRepo.signUpWithEmailPassword(
        email: 'maya@scribbleverse.io',
        password: 'securePassword123',
        displayName: 'Maya Reader',
      );

      expect(user.displayName, 'Maya Reader');
      expect(user.email, 'maya@scribbleverse.io');
      expect(user.role, UserRole.user);
      expect(user.isUser, isTrue);
    });

    test('persists session in HiveStorageService across re-initialization', () async {
      await authRepo.signInWithAdminPasskey(adminPasskey: 'scribble_admin');
      expect(authRepo.currentUser.isAdmin, isTrue);

      final freshRepo = AuthRepositoryImpl(storageService: storageService);
      await freshRepo.init();
      expect(freshRepo.currentUser.isAdmin, isTrue);
      expect(freshRepo.currentUser.roleBadge, '👑 ADMIN');
    });
  });

  group('AuthController State & Role Transitions', () {
    test('switchRole updates active state and notifies listeners', () async {
      int notifyCount = 0;
      authController.addListener(() => notifyCount++);

      await authController.switchRole(UserRole.guest);
      expect(authController.isGuest, isTrue);

      await authController.switchRole(UserRole.admin);
      expect(authController.isAdmin, isTrue);

      await authController.switchRole(UserRole.user);
      expect(authController.isUser, isTrue);

      expect(notifyCount, greaterThanOrEqualTo(3));
    });

    test('handles invalid email validation cleanly', () async {
      final success = await authController.signInWithEmailPassword(
        email: 'invalid-email',
        password: 'pass',
      );
      expect(success, isFalse);
      expect(authController.errorMessage, isNotNull);
      expect(authController.errorMessage, contains('valid email'));
    });
  });

  group('AuthModal & ProfileScreen Integration', () {
    testWidgets('AuthModal displays active role and switches tabs', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AuthModal(authController: authController),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Member Auth'), findsOneWidget);
      expect(find.text('Guest Mode'), findsOneWidget);
      expect(find.text('Admin Portal'), findsOneWidget);

      // Tap on Guest Mode tab
      await tester.tap(find.text('Guest Mode'));
      await tester.pumpAndSettle();

      expect(find.text('Local & Anonymous Reading'), findsOneWidget);
      expect(find.text('Continue as Guest Explorer 🌱'), findsOneWidget);

      // Tap on Admin Portal tab
      await tester.tap(find.text('Admin Portal'));
      await tester.pumpAndSettle();

      expect(find.text('Curator & Catalog Access'), findsOneWidget);
      expect(find.text('Unlock Admin Capabilities 👑'), findsOneWidget);
    });
  });
}
