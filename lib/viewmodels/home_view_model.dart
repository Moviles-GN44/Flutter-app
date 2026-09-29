import 'package:flutter/foundation.dart';

import 'package:uniandes_food/data/sample_restaurants.dart';
import 'package:uniandes_food/models/restaurant.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    Restaurant? initialRestaurant,
  }) : _selectedRestaurant =
            initialRestaurant ?? sampleRestaurants.first;

  Restaurant _selectedRestaurant;

  Restaurant get selectedRestaurant => _selectedRestaurant;

  List<Restaurant> get restaurants => sampleRestaurants;

  Restaurant? get fasterAlternative {
    if (_selectedRestaurant.waitTime != WaitTime.over15) {
      return null;
    }

    return fasterAlternativeTo(_selectedRestaurant);
  }

  void selectRestaurant(Restaurant restaurant) {
    if (_selectedRestaurant.id == restaurant.id) {
      return;
    }

    _selectedRestaurant = restaurant;
    notifyListeners();
  }
}