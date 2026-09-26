import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Check current auth status on app start
class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

/// 1-Tap Google Sign-In
class SignInWithGoogleEvent extends AuthEvent {
  const SignInWithGoogleEvent();
}

/// Email & Password Sign-In
class SignInWithEmailEvent extends AuthEvent {
  final String email;
  final String password;

  const SignInWithEmailEvent({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

/// Email & Password Registration
class RegisterWithEmailEvent extends AuthEvent {
  final String email;
  final String password;
  final String? displayName;

  const RegisterWithEmailEvent({
    required this.email,
    required this.password,
    this.displayName,
  });

  @override
  List<Object?> get props => [email, password, displayName];
}

/// Sign out
class SignOutEvent extends AuthEvent {
  const SignOutEvent();
}

/// Internal/External event triggered when auth state changes in the repository
class AuthUserChangedEvent extends AuthEvent {
  final dynamic user;

  const AuthUserChangedEvent(this.user);

  @override
  List<Object?> get props => [user];
}
