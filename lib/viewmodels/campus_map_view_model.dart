import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/repositories/campus_restaurants_repository.dart';

class CampusMapViewModel extends ChangeNotifier {
  CampusMapViewModel({CampusRestaurantsRepository? repository})
    : _repository = repository ?? CampusRestaurantsRepository() {
    _subscription = _repository.watchRestaurants().listen(
      _onRestaurants,
      onError: _onError,
    );
  }

  final CampusRestaurantsRepository _repository;
  late final StreamSubscription<List<Restaurant>> _subscription;

  List<Restaurant> _restaurants = const [];
  bool _isLoading = true;
  String? _errorMessage;

  List<Restaurant> get restaurants => _restaurants;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _onRestaurants(List<Restaurant> restaurants) {
    _restaurants = restaurants;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void _onError(Object error) {
    _isLoading = false;
    _errorMessage = 'Could not load restaurants.';
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
