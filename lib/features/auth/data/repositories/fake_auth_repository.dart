import 'dart:async';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Testable in-memory fake implementation of [AuthRepository]
class FakeAuthRepository implements AuthRepository {
  AuthUser? _currentUser;
  final StreamController<AuthUser?> _authStateController =
      StreamController<AuthUser?>.broadcast();

  bool shouldFail = false;
  String failureMessage = 'Authentication failed';
  Duration delay = Duration.zero;

  FakeAuthRepository({AuthUser? initialUser}) {
    _currentUser = initialUser;
  }

  @override
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  bool get isAuthenticated => _currentUser != null && !_currentUser!.isAnonymous;

  /// Helper to manually set user state in tests
  void emitUser(AuthUser? user) {
    _currentUser = user;
    _authStateController.add(user);
  }

  Future<void> _maybeDelayAndFail() async {
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }
    if (shouldFail) {
      throw Exception(failureMessage);
    }
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    await _maybeDelayAndFail();
    final user = AuthUser(
      uid: 'google-user-123',
      email: 'alex.google@example.com',
      displayName: 'Alex Rivers',
      photoUrl: 'https://example.com/avatar.png',
      isAnonymous: false,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      lastLoginAt: DateTime.now(),
    );
    emitUser(user);
    return user;
  }

  @override
  Future<AuthUser> signInWithEmailPassword(String email, String password) async {
    await _maybeDelayAndFail();
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw Exception('Email and password cannot be empty');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    final user = AuthUser(
      uid: 'email-user-${email.hashCode}',
      email: email.trim(),
      displayName: email.split('@').first,
      isAnonymous: false,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      lastLoginAt: DateTime.now(),
    );
    emitUser(user);
    return user;
  }

  @override
  Future<AuthUser> registerWithEmailPassword(
    String email,
    String password, {
    String? displayName,
  }) async {
    await _maybeDelayAndFail();
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw Exception('Email and password cannot be empty');
    }
    if (!email.contains('@')) {
      throw Exception('Invalid email format');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    final user = AuthUser(
      uid: 'registered-user-${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim(),
      displayName: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : email.split('@').first,
      isAnonymous: false,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    emitUser(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await _maybeDelayAndFail();
    emitUser(null);
  }

  void dispose() {
    _authStateController.close();
  }
}
