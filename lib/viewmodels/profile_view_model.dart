import 'package:flutter/foundation.dart';

import 'package:uniandes_food/models/app_user.dart';
import 'package:uniandes_food/repositories/user_profile_repository.dart';

/// State of the Profile screen for the signed-in student.
class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({required this.user, UserProfileRepository? repository})
    : _repository = repository ?? UserProfileRepository() {
    _loadReviewCount();
  }

  final AppUser user;
  final UserProfileRepository _repository;

  int? _reviewCount;
  bool _disposed = false;

  /// Null while it loads or when it could not be read.
  int? get reviewCount => _reviewCount;

  /// The name from the account, or the part of the email before the `@`
  /// when the account has no name.
  String get displayName {
    if (user.name.trim().isNotEmpty) return user.name.trim();
    final at = user.email.indexOf('@');
    return at > 0 ? user.email.substring(0, at) : user.email;
  }

  /// Up to two initials, e.g. `JO` for "Juan Ortiz".
  String get initials {
    final words = displayName.split(RegExp(r'[\s._-]+'))
      ..removeWhere((word) => word.isEmpty);
    if (words.isEmpty) return '?';
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }

  Future<void> _loadReviewCount() async {
    final count = await _repository.countReviews(user.uid);
    if (_disposed) return;
    _reviewCount = count;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
