import 'package:flutter/foundation.dart';
import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/models/restaurant_comparison.dart';
import 'package:uniandes_food/services/comparison_preferences_service.dart';

class ComparisonViewModel extends ChangeNotifier {
  ComparisonViewModel({ComparisonPreferencesService? preferencesService})
    : _preferencesService =
          preferencesService ?? ComparisonPreferencesService();

  final ComparisonPreferencesService _preferencesService;

  Restaurant? _firstRestaurant;
  Restaurant? _secondRestaurant;

  List<Restaurant> _restaurants = [];

  bool _isFromCache = false;
  bool _disposed = false;
  bool _selectionModified = false;

  String? _pendingFirstId;
  String? _pendingSecondId;

  Future<void> _saveQueue = Future<void>.value();

  Restaurant? get firstRestaurant => _firstRestaurant;
  Restaurant? get secondRestaurant => _secondRestaurant;

  List<Restaurant> get restaurants => List.unmodifiable(_restaurants);

  bool get isFromCache => _isFromCache;

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

  Future<void> restoreSelection() async {
    try {
      final saved = await _preferencesService.loadSelection();

      if (_disposed || _selectionModified) return;

      _pendingFirstId = saved.firstId;
      _pendingSecondId = saved.secondId;

      _restoreAvailableRestaurants();

      notifyListeners();
    } catch (error) {
      debugPrint('Could not restore restaurant comparison: $error');
    }
  }

  void _restoreAvailableRestaurants() {
    if (_pendingFirstId != null) {
      final restaurant = _findRestaurant(_pendingFirstId);

      if (restaurant != null) {
        _firstRestaurant = restaurant;
        _pendingFirstId = null;
      }
    }

    if (_pendingSecondId != null) {
      final restaurant = _findRestaurant(_pendingSecondId);

      if (restaurant != null && restaurant.id != _firstRestaurant?.id) {
        _secondRestaurant = restaurant;
        _pendingSecondId = null;
      }
    }
  }

  void _saveSelection() {
    _selectionModified = true;

    _pendingFirstId = null;
    _pendingSecondId = null;

    final firstId = _firstRestaurant?.id;
    final secondId = _secondRestaurant?.id;

    _saveQueue = _saveQueue.then((_) async {
      try {
        await _preferencesService.saveSelection(firstId, secondId);
      } catch (error) {
        debugPrint('Could not save restaurant comparison: $error');
      }
    });
  }

  Future<void> waitForPendingSaves() => _saveQueue;

  void updateRestaurants(
    List<Restaurant> restaurants, {
    required bool isFromCache,
  }) {
    _restaurants = List.of(restaurants);
    _isFromCache = isFromCache;

    _firstRestaurant = _findRestaurant(_firstRestaurant?.id);

    _secondRestaurant = _findRestaurant(_secondRestaurant?.id);

    _restoreAvailableRestaurants();

    notifyListeners();
  }

  Restaurant? _findRestaurant(String? id) {
    if (id == null) return null;

    for (final restaurant in _restaurants) {
      if (restaurant.id == id) {
        return restaurant;
      }
    }

    return null;
  }

  void selectFirstRestaurant(Restaurant restaurant) {
    if (_firstRestaurant?.id == restaurant.id) return;

    _firstRestaurant = restaurant;

    if (_secondRestaurant?.id == restaurant.id) {
      _secondRestaurant = null;
    }

    _saveSelection();
    notifyListeners();
  }

  void selectSecondRestaurant(Restaurant restaurant) {
    if (_firstRestaurant?.id == restaurant.id ||
        _secondRestaurant?.id == restaurant.id) {
      return;
    }

    _secondRestaurant = restaurant;

    _saveSelection();
    notifyListeners();
  }

  void removeFirstRestaurant() {
    _firstRestaurant = null;

    _saveSelection();
    notifyListeners();
  }

  void removeSecondRestaurant() {
    _secondRestaurant = null;

    _saveSelection();
    notifyListeners();
  }

  void clearSelection() {
    _firstRestaurant = null;
    _secondRestaurant = null;

    _saveSelection();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
