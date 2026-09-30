import 'package:firebase_auth/firebase_auth.dart';

import 'package:uniandes_food/models/app_user.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}

class AuthRepository {
  AuthRepository._();

  static final AuthRepository instance = AuthRepository._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().map(_toAppUser);
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _toAppUser(credential.user)!;
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageFor(error.code));
    }
  }

  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user!.updateDisplayName(name);
      await credential.user!.reload();
      return _toAppUser(_auth.currentUser)!;
    } on FirebaseAuthException catch (error) {
      throw AuthException(_messageFor(error.code));
    }
  }

  Future<void> signOut() => _auth.signOut();

  AppUser? _toAppUser(User? user) {
    if (user == null) return null;

    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      name: user.displayName ?? '',
    );
  }

  String _messageFor(String code) {
    return switch (code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Incorrect email or password.',
      'email-already-in-use' => 'An account with this email already exists.',
      'weak-password' => 'Password must have at least 6 characters.',
      'invalid-email' => 'Enter a valid email.',
      'too-many-requests' => 'Too many attempts. Try again later.',
      'network-request-failed' => 'Check your internet connection.',
      _ => 'Something went wrong. Try again.',
    };
  }
}
