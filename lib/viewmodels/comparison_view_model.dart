import 'package:flutter/foundation.dart';
import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/models/restaurant_comparison.dart';

class ComparisonViewModel extends ChangeNotifier {
  Restaurant? _firstRestaurant;
  Restaurant? _secondRestaurant;

  Restaurant? get firstRestaurant => _firstRestaurant;
  Restaurant? get secondRestaurant => _secondRestaurant;

  bool get canCompare =>
      _firstRestaurant != null &&
      _secondRestaurant != null &&
      _firstRestaurant!.id != _secondRestaurant!.id;

  RestaurantComparison? get comparison {
    if (!canCompare) return null;

    return RestaurantComparison(
      firstRestaurant: _firstRestaurant!,
      secondRestaurant: _secondRestaurant!,
    );
  }

  void selectFirstRestaurant(Restaurant restaurant) {
    if (_firstRestaurant?.id == restaurant.id) return;

    _firstRestaurant = restaurant;

    if (_secondRestaurant?.id == restaurant.id) {
      _secondRestaurant = null;
    }

    notifyListeners();
  }

  void selectSecondRestaurant(Restaurant restaurant) {
    if (_firstRestaurant?.id == restaurant.id ||
        _secondRestaurant?.id == restaurant.id) {
      return;
    }

    _secondRestaurant = restaurant;
    notifyListeners();
  }

  void removeFirstRestaurant() {
    _firstRestaurant = null;
    notifyListeners();
  }

  void removeSecondRestaurant() {
    _secondRestaurant = null;
    notifyListeners();
  }

  void clearSelection() {
    _firstRestaurant = null;
    _secondRestaurant = null;
    notifyListeners();
  }
}