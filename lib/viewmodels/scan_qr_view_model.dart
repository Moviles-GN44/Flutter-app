import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/repositories/restaurant_repository.dart';

enum ScanStatus { searching, verified }

class ScanQrViewModel extends ChangeNotifier {
  ScanQrViewModel({
    RestaurantRepository? repository,
    Connectivity? connectivity,
  }) : _repository = repository ?? RestaurantRepository() {
    final source = connectivity ?? Connectivity();
    _connectivitySubscription = source.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (Object _) {},
    );
    source
        .checkConnectivity()
        .then(_onConnectivityChanged)
        .catchError((Object _) {});
  }

  static const darkLux = 15;
  static final _restaurantId = RegExp(r'^[A-Za-z0-9_-]{1,64}$');

  final RestaurantRepository _repository;
  late final StreamSubscription<List<ConnectivityResult>>
  _connectivitySubscription;

  ScanStatus _status = ScanStatus.searching;
  Restaurant? _restaurant;
  String? _errorMessage;
  bool _isDark = false;
  bool _isChecking = false;
  bool _isOnline = true;
  String? _pendingCode;

  bool get isDark => _isDark;
  ScanStatus get status => _status;
  bool get isVerified => _status == ScanStatus.verified;
  Restaurant? get restaurant => _restaurant;
  String? get errorMessage => _errorMessage;

  List<Restaurant> get nearbyRestaurants => _repository.getNearbyRestaurants();

  Future<bool> onCodeDetected(String? rawValue) async {
    final id = rawValue?.trim() ?? '';
    if (isVerified || _isChecking || id.isEmpty) return false;

    Restaurant? restaurant;
    if (_restaurantId.hasMatch(id)) {
      _isChecking = true;
      try {
        restaurant = await _repository.fetchRestaurantById(id);
      } finally {
        _isChecking = false;
      }
    }

    if (restaurant == null) {
      final waitForConnection = !_isOnline && _restaurantId.hasMatch(id);
      _pendingCode = waitForConnection ? id : null;
      _errorMessage = waitForConnection
          ? 'No connection. The code will be checked when you are back online.'
          : 'This QR code is not from a campus restaurant.';
      notifyListeners();
      return false;
    }

    _status = ScanStatus.verified;
    _restaurant = restaurant;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  void onLightChanged(int lux) {
    final isDark = lux >= 0 && lux < darkLux;
    if (isDark == _isDark) return;
    _isDark = isDark;
    notifyListeners();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _isOnline = results.any((result) => result != ConnectivityResult.none);
    final code = _pendingCode;
    if (!_isOnline || code == null) return;
    _pendingCode = null;
    unawaited(onCodeDetected(code));
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
