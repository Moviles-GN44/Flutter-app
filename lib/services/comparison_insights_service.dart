import 'dart:isolate';

import 'package:uniandes_food/models/restaurant.dart';

typedef RestaurantMetrics = ({
  String id,
  int? price,
  int walkingMinutes,
  double? rating,
});

class ComparisonInsights {
  final Map<String, int> priceRanks;
  final Map<String, int> walkingRanks;
  final Map<String, int> ratingRanks;

  const ComparisonInsights({
    required this.priceRanks,
    required this.walkingRanks,
    required this.ratingRanks,
  });
}

class ComparisonInsightsService {
  Future<ComparisonInsights> calculate(List<Restaurant> restaurants) async {
    final metrics = restaurants.map((restaurant) {
      return (
        id: restaurant.id,
        price: restaurant.averagePriceCop,
        walkingMinutes: restaurant.walkingMinutes,
        rating: restaurant.reviewCount > 0 ? restaurant.rating : null,
      );
    }).toList();

    return Isolate.run(() => calculateRestaurantRankings(metrics));
  }
}

ComparisonInsights calculateRestaurantRankings(
  List<RestaurantMetrics> restaurants,
) {
  final priceRanks = _rankRestaurants(
    restaurants,
    (restaurant) => restaurant.price,
  );

  final walkingRanks = _rankRestaurants(
    restaurants,
    (restaurant) => restaurant.walkingMinutes,
  );

  final ratingRanks = _rankRestaurants(
    restaurants,
    (restaurant) => restaurant.rating,
    descending: true,
  );

  return ComparisonInsights(
    priceRanks: priceRanks,
    walkingRanks: walkingRanks,
    ratingRanks: ratingRanks,
  );
}

Map<String, int> _rankRestaurants(
  List<RestaurantMetrics> restaurants,
  num? Function(RestaurantMetrics) metric, {
  bool descending = false,
}) {
  final available = restaurants
      .where((restaurant) => metric(restaurant) != null)
      .toList();

  available.sort((first, second) {
    final comparison = metric(first)!.compareTo(metric(second)!);

    return descending ? -comparison : comparison;
  });

  final ranks = <String, int>{};

  num? previousValue;
  int currentRank = 0;

  for (var index = 0; index < available.length; index++) {
    final restaurant = available[index];
    final value = metric(restaurant)!;

    if (index == 0 || value != previousValue) {
      currentRank = index + 1;
    }

    ranks[restaurant.id] = currentRank;
    previousValue = value;
  }

  return ranks;
}
