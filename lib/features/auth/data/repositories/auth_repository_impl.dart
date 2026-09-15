import 'dart:async';
import 'dart:convert';
import '../../../library/data/datasources/hive_storage_service.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final HiveStorageService _storageService;
  final StreamController<AuthUser> _authController = StreamController<AuthUser>.broadcast();

  static const String _authKey = 'auth_current_user';
  static const List<String> _validAdminPasskeys = [
    'admin123',
    'scribble_admin',
    'admin',
    'curator_2026',
  ];

  late AuthUser _currentUser;

  AuthRepositoryImpl({HiveStorageService? storageService})
      : _storageService = storageService ?? HiveStorageService() {
    _currentUser = _buildDefaultUser();
  }

  @override
  Stream<AuthUser> get authStateChanges => _authController.stream;

  @override
  AuthUser get currentUser => _currentUser;

  AuthUser _buildDefaultUser() {
    return AuthUser(
      id: 'usr_arjun_01',
      email: 'arjun@scribbleverse.io',
      displayName: 'Arjun (Reader)',
      role: UserRole.user,
      isAnonymous: false,
      createdAt: DateTime(2025, 6, 1),
      lastLoginAt: DateTime.now(),
      avatarEmoji: '🦉',
    );
  }

  @override
  Future<AuthUser> init() async {
    try {
      final savedData = _storageService.getCustomSetting<String>(_authKey);
      if (savedData != null && savedData.isNotEmpty) {
        final Map<String, dynamic> json = jsonDecode(savedData);
        _currentUser = AuthUser.fromJson(json);
      } else {
        _currentUser = _buildDefaultUser();
        await _saveUser(_currentUser);
      }
    } catch (_) {
      _currentUser = _buildDefaultUser();
    }
    _authController.add(_currentUser);
    return _currentUser;
  }

  Future<void> _saveUser(AuthUser user) async {
    try {
      final jsonStr = jsonEncode(user.toJson());
      await _storageService.setCustomSetting(_authKey, jsonStr);
    } catch (_) {}
  }

  @override
  Future<AuthUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || !email.contains('@')) {
      throw Exception('Please enter a valid email address.');
    }
    if (password.length < 4) {
      throw Exception('Password must be at least 4 characters.');
    }

    final nameFromEmail = email.split('@').first;
    final formattedName = nameFromEmail.isNotEmpty
        ? nameFromEmail[0].toUpperCase() + nameFromEmail.substring(1)
        : 'Reader';

    final updated = AuthUser(
      id: 'usr_${email.hashCode.abs()}',
      email: email.trim(),
      displayName: formattedName,
      role: UserRole.user,
      isAnonymous: false,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastLoginAt: DateTime.now(),
      avatarEmoji: '🦊',
      permissions: const ['read_public', 'sync_cloud', 'create_bookmarks'],
    );

    _currentUser = updated;
    await _saveUser(updated);
    _authController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<AuthUser> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    if (email.trim().isEmpty || !email.contains('@')) {
      throw Exception('Please enter a valid email address.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters long.');
    }
    if (displayName.trim().isEmpty) {
      throw Exception('Display name cannot be empty.');
    }

    final newUser = AuthUser(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim(),
      displayName: displayName.trim(),
      role: UserRole.user,
      isAnonymous: false,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      avatarEmoji: '✨',
      permissions: const ['read_public', 'sync_cloud', 'create_bookmarks'],
    );

    _currentUser = newUser;
    await _saveUser(newUser);
    _authController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<AuthUser> signInAsGuest() async {
    final guestUser = AuthUser.guest();
    _currentUser = guestUser;
    await _saveUser(guestUser);
    _authController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<AuthUser> signInWithAdminPasskey({
    required String adminPasskey,
    String? adminName,
  }) async {
    final cleanKey = adminPasskey.trim();
    if (!_validAdminPasskeys.contains(cleanKey)) {
      throw Exception('Invalid Admin Passkey. Access denied.');
    }

    final adminUser = AuthUser.admin(
      name: adminName?.isNotEmpty == true ? adminName : 'Master Curator',
      email: 'curator@scribbleverse.io',
    );

    _currentUser = adminUser;
    await _saveUser(adminUser);
    _authController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<AuthUser> switchRole(UserRole newRole) async {
    switch (newRole) {
      case UserRole.guest:
        return signInAsGuest();
      case UserRole.admin:
        return signInWithAdminPasskey(adminPasskey: 'admin123', adminName: 'Admin Curator');
      case UserRole.user:
        return signInWithEmailPassword(
          email: 'arjun@scribbleverse.io',
          password: 'password123',
        );
    }
  }

  @override
  Future<AuthUser> updateAuthProfile({
    String? displayName,
    String? avatarEmoji,
  }) async {
    _currentUser = _currentUser.copyWith(
      displayName: displayName,
      avatarEmoji: avatarEmoji,
    );
    await _saveUser(_currentUser);
    _authController.add(_currentUser);
    return _currentUser;
  }

  @override
  Future<AuthUser> signOut() async {
    return signInAsGuest();
  }

  void dispose() {
    _authController.close();
  }
}
