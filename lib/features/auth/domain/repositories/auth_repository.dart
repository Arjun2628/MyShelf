import 'dart:async';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  /// Stream emitting changes to the current authentication state.
  Stream<AuthUser> get authStateChanges;

  /// Returns the current active user synchronously.
  AuthUser get currentUser;

  /// Initializes the auth state from local persistence.
  Future<AuthUser> init();

  /// Signs in using email and password.
  Future<AuthUser> signInWithEmailPassword({
    required String email,
    required String password,
  });

  /// Signs up a new user with email and password.
  Future<AuthUser> signUpWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
  });

  /// Starts an unauthenticated guest session.
  Future<AuthUser> signInAsGuest();

  /// Validates an admin passkey to grant administrative privileges.
  Future<AuthUser> signInWithAdminPasskey({
    required String adminPasskey,
    String? adminName,
  });

  /// Switches active role directly (convenience for demo/testing).
  Future<AuthUser> switchRole(UserRole newRole);

  /// Updates profile data (name, avatar) on the current authenticated user.
  Future<AuthUser> updateAuthProfile({
    String? displayName,
    String? avatarEmoji,
  });

  /// Signs out and returns the user to Guest mode.
  Future<AuthUser> signOut();
}
