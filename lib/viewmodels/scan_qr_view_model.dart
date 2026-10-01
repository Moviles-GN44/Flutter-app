import 'package:flutter/foundation.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/repositories/restaurant_repository.dart';

enum ScanStatus { searching, verified }

class ScanQrViewModel extends ChangeNotifier {
  ScanQrViewModel({RestaurantRepository? repository})
    : _repository = repository ?? const RestaurantRepository();

  static const payloadPrefix = 'uniandesfood:';
  static const darkLux = 15;

  final RestaurantRepository _repository;

  ScanStatus _status = ScanStatus.searching;
  Restaurant? _restaurant;
  String? _errorMessage;
  bool _isDark = false;

  bool get isDark => _isDark;
  ScanStatus get status => _status;
  bool get isVerified => _status == ScanStatus.verified;
  Restaurant? get restaurant => _restaurant;
  String? get errorMessage => _errorMessage;

  List<Restaurant> get nearbyRestaurants => _repository.getNearbyRestaurants();

  bool onCodeDetected(String? rawValue) {
    if (isVerified || rawValue == null) return false;

    final restaurant = _restaurantFor(rawValue);
    if (restaurant == null) {
      _errorMessage = 'This QR code is not from a campus restaurant.';
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

  Restaurant? _restaurantFor(String rawValue) {
    final value = rawValue.trim();
    if (!value.startsWith(payloadPrefix)) return null;

    final id = value.substring(payloadPrefix.length);
    for (final restaurant in _repository.getAllRestaurants()) {
      if (restaurant.id == id) return restaurant;
    }
    return null;
  }
}
