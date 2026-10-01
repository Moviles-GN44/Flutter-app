import 'package:flutter/foundation.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/repositories/restaurant_repository.dart';
import 'package:uniandes_food/services/telemetry_service.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    RestaurantRepository? repository,
    TelemetryService? telemetryService,
    Restaurant? initialRestaurant,
  }) : _repository = repository ?? const RestaurantRepository(),
       _telemetryService = telemetryService ?? TelemetryService(),
       _selectedRestaurant =
           initialRestaurant ??
           (repository ?? const RestaurantRepository())
               .getAllRestaurants()
               .first;

  final RestaurantRepository _repository;
  final TelemetryService _telemetryService;

  Restaurant _selectedRestaurant;

  Restaurant get selectedRestaurant => _selectedRestaurant;

  List<Restaurant> get restaurants =>
      _repository.getAllRestaurants();

  Restaurant? get fasterAlternative {
    if (_selectedRestaurant.waitTime != WaitTime.over15) {
      return null;
    }

    return _repository.getFasterAlternative(_selectedRestaurant);
  }

  void selectRestaurant(Restaurant restaurant) {
    if (_selectedRestaurant.id == restaurant.id) {
      return;
    }

    _selectedRestaurant = restaurant;
    notifyListeners();
  }

  Future<void> trackComparisonCriterion(String criterion) async {
    await _telemetryService.trackComparisonCriterion(
      criterion: criterion,
      restaurantId: _selectedRestaurant.id,
    );
  }
}