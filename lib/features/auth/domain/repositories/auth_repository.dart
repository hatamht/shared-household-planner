import '../entities/auth_user.dart';

/// Abstract contract for authentication repository
abstract class AuthRepository {
  /// Stream of authentication state changes
  Stream<AuthUser?> get authStateChanges;

  /// Current authenticated user or null if guest / offline
  AuthUser? get currentUser;

  /// Whether a user is currently signed in
  bool get isAuthenticated => currentUser != null && !currentUser!.isAnonymous;

  /// Sign in with Google (1-Tap)
  Future<AuthUser> signInWithGoogle();

  /// Sign in with Email and Password
  Future<AuthUser> signInWithEmailPassword(String email, String password);

  /// Register a new account with Email and Password
  Future<AuthUser> registerWithEmailPassword(
    String email,
    String password, {
    String? displayName,
  });

  /// Sign out current user
  Future<void> signOut();
}
