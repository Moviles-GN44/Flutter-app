import 'package:uniandes_food/data/sample_restaurants.dart';
import 'package:uniandes_food/models/restaurant.dart';

class RestaurantRepository {
  const RestaurantRepository();

  List<Restaurant> getAllRestaurants() {
    return sampleRestaurants;
  }

  Restaurant? getRestaurantByName(String name) {
    return restaurantByName(name);
  }

  Restaurant? getFasterAlternative(Restaurant restaurant) {
    return fasterAlternativeTo(restaurant);
  }

  List<Restaurant> getNearbyRestaurants({int limit = 4}) {
    return nearbyRestaurants(limit: limit);
  }
}