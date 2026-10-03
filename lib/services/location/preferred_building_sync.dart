import 'package:flutter/foundation.dart';

import 'package:uniandes_food/data/campus.dart';
import 'package:uniandes_food/repositories/user_profile_repository.dart';
import 'package:uniandes_food/services/location/user_location_tracker.dart';
import 'package:uniandes_food/viewmodels/auth_view_model.dart';

/// Keeps the student's preferred building in their account.
///
/// After signing in, the building saved in `users/{uid}` becomes the place
/// the map falls back to when the GPS cannot be used. The student changes it
/// on the Profile screen, and it follows them to other devices and to the
/// Kotlin app, which reads the same field.
class PreferredBuildingSync extends ChangeNotifier {
  PreferredBuildingSync({
    required AuthViewModel auth,
    UserLocationTracker? tracker,
    UserProfileRepository? repository,
  }) : _auth = auth,
       _tracker = tracker ?? UserLocationTracker.shared,
       _repository = repository ?? UserProfileRepository() {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  final AuthViewModel _auth;
  final UserLocationTracker _tracker;
  final UserProfileRepository _repository;

  String? _uid;
  String? _preferredBuilding;

  /// Building code (`ML`, `SD`…) saved in the account, if any.
  String? get preferredBuilding => _preferredBuilding;

  Future<void> _onAuthChanged() async {
    final user = _auth.currentUser;
    if (user?.uid == _uid) return;
    _uid = user?.uid;

    if (user == null) {
      _preferredBuilding = null;
      _tracker.setFallbackBuilding(defaultUserBuilding);
      notifyListeners();
      return;
    }

    final building = await _repository.loadPreferredBuilding(user.uid);
    if (_uid != user.uid) return;
    _preferredBuilding = campusBuildings.containsKey(building)
        ? building
        : null;
    _tracker.setFallbackBuilding(_preferredBuilding ?? defaultUserBuilding);
    notifyListeners();
  }

  /// Saves the building the student chose on the Profile screen. It does not
  /// move the student there; it is only used when the GPS cannot be.
  void setPreferredBuilding(String building) {
    final user = _auth.currentUser;
    if (user == null) return;

    _preferredBuilding = building;
    _tracker.setFallbackBuilding(building);
    notifyListeners();
    _repository.savePreferredBuilding(user, building);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
