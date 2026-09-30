import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:uniandes_food/models/app_user.dart';
import 'package:uniandes_food/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({AuthRepository? repository})
    : _repository = repository ?? AuthRepository.instance {
    _currentUser = _repository.currentUser;
    _subscription = _repository.authStateChanges().listen(_onAuthChanged);
  }

  static const _institutionalDomain = '@uniandes.edu.co';
  static const _minPasswordLength = 6;

  final AuthRepository _repository;
  late final StreamSubscription<AppUser?> _subscription;

  AppUser? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> signIn({required String email, required String password}) async {
    final error =
        _validateEmail(email) ??
        (password.isEmpty ? 'Enter your password.' : null);
    if (error != null) {
      _setError(error);
      return;
    }

    await _run(
      () => _repository.signIn(email: _normalize(email), password: password),
    );
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final error =
        (name.trim().isEmpty ? 'Enter your name.' : null) ??
        _validateEmail(email) ??
        _validatePassword(password, confirmPassword);
    if (error != null) {
      _setError(error);
      return;
    }

    await _run(
      () => _repository.signUp(
        name: name.trim(),
        email: _normalize(email),
        password: password,
      ),
    );
  }

  Future<void> signOut() => _repository.signOut();

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  String? _validateEmail(String email) {
    final normalized = _normalize(email);
    if (normalized.isEmpty) return 'Enter your email.';
    if (!normalized.endsWith(_institutionalDomain)) {
      return 'Use your $_institutionalDomain email.';
    }
    return null;
  }

  String? _validatePassword(String password, String confirmPassword) {
    if (password.length < _minPasswordLength) {
      return 'Password must have at least $_minPasswordLength characters.';
    }
    if (password != confirmPassword) return 'Passwords do not match.';
    return null;
  }

  String _normalize(String email) => email.trim().toLowerCase();

  Future<void> _run(Future<AppUser> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await action();
    } on AuthException catch (error) {
      _errorMessage = error.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _onAuthChanged(AppUser? user) {
    _currentUser = user;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
