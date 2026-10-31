import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:uniandes_food/data/sample_restaurants.dart';
import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/strategies/restaurant_recommendation_strategy.dart';

class RestaurantRepository {
  RestaurantRepository({
    this.recommendationStrategy = const SmartRestaurantStrategy(),
    FirebaseFirestore? firestore,
    Future<Restaurant?> Function(String id)? loadRestaurant,
    DateTime Function()? now,
  }) : _injected = firestore,
       _loadRestaurant = loadRestaurant,
       _now = now ?? DateTime.now;

  final RestaurantRecommendationStrategy recommendationStrategy;
  final FirebaseFirestore? _injected;
  final Future<Restaurant?> Function(String id)? _loadRestaurant;
  final DateTime Function() _now;

  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  static const _cacheDuration = Duration(minutes: 5);

  final Map<String, Restaurant> _cache = {};
  final Map<String, DateTime> _cachedAt = {};

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

  Future<Restaurant?> fetchRestaurantById(String id) async {
    if (id.isEmpty || id.contains('/')) return null;

    final cachedRestaurant = _cache[id];
    final cachedTime = _cachedAt[id];

    if (cachedRestaurant != null && cachedTime != null) {
      if (_now().difference(cachedTime) < _cacheDuration) {
        return cachedRestaurant;
      }
    }

    _cache.remove(id);
    _cachedAt.remove(id);

    try {
      final restaurant = _loadRestaurant != null
          ? await _loadRestaurant(id)
          : await _fetchFromFirestore(id);

      if (restaurant == null) return null;

      _cache[id] = restaurant;
      _cachedAt[id] = _now();

      return restaurant;
    } on FirebaseException {
      return null;
    }
  }

  Future<Restaurant?> _fetchFromFirestore(String id) async {
    final doc = await _firestore.collection('restaurants').doc(id).get();

    final data = doc.data();

    return data == null ? null : Restaurant.fromFirestore(doc.id, data);
  }

  void clearCache() {
    _cache.clear();
    _cachedAt.clear();
  }
}
