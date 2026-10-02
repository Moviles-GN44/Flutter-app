import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:uniandes_food/data/sample_restaurants.dart';
import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/strategies/restaurant_recommendation_strategy.dart';

class RestaurantRepository {
  const RestaurantRepository({
    this.recommendationStrategy = const FasterRestaurantStrategy(),
  });

  final RestaurantRecommendationStrategy recommendationStrategy;

  List<Restaurant> getAllRestaurants() {
    return sampleRestaurants;
  }

  Restaurant? getRestaurantByName(String name) {
    return restaurantByName(name);
  }

  Restaurant? getFasterAlternative(Restaurant restaurant) {
    return recommendationStrategy.recommend(
      currentRestaurant: restaurant,
      restaurants: sampleRestaurants,
    );
  }

  List<Restaurant> getNearbyRestaurants({int limit = 4}) {
    return nearbyRestaurants(limit: limit);
  }

  Future<Restaurant?> fetchRestaurantById(String id) async {
    if (id.isEmpty || id.contains('/')) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(id)
          .get();

      final data = doc.data();

      return data == null
          ? null
          : Restaurant.fromFirestore(doc.id, data);
    } on FirebaseException {
      return null;
    }
  }
}