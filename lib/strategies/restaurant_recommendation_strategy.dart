import 'package:uniandes_food/models/restaurant.dart';

abstract class RestaurantRecommendationStrategy {
  const RestaurantRecommendationStrategy();

  Restaurant? recommend({
    required Restaurant currentRestaurant,
    required List<Restaurant> restaurants,
  });
}

class FasterRestaurantStrategy implements RestaurantRecommendationStrategy {
  const FasterRestaurantStrategy();

  @override
  Restaurant? recommend({
    required Restaurant currentRestaurant,
    required List<Restaurant> restaurants,
  }) {
    final candidates =
        restaurants
            .where(
              (restaurant) =>
                  restaurant.id != currentRestaurant.id &&
                  restaurant.isOpen &&
                  restaurant.waitTime == WaitTime.under5,
            )
            .toList()
          ..sort((a, b) => a.walkingMinutes.compareTo(b.walkingMinutes));

    return candidates.isEmpty ? null : candidates.first;
  }
}

class SmartRestaurantStrategy implements RestaurantRecommendationStrategy {
  const SmartRestaurantStrategy();

  @override
  Restaurant? recommend({
    required Restaurant currentRestaurant,
    required List<Restaurant> restaurants,
  }) {
    final candidates = restaurants
        .where(
          (restaurant) =>
              restaurant.id != currentRestaurant.id && restaurant.isOpen,
        )
        .toList();

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => _score(b).compareTo(_score(a)));

    return candidates.first;
  }

  double _score(Restaurant restaurant) {
    final waitScore = switch (restaurant.waitTime) {
      WaitTime.under5 => 1.0,
      WaitTime.fiveTo15 => 0.5,
      WaitTime.over15 => 0.0,
    };

    final distanceScore = (1 - (restaurant.walkingMinutes / 15)).clamp(
      0.0,
      1.0,
    );

    final ratingScore = (restaurant.rating / 5).clamp(0.0, 1.0);

    final averagePrice = _averageMenuPrice(restaurant);

    final priceScore = averagePrice == 0
        ? 0.5
        : (1 - (averagePrice / 50000)).clamp(0.0, 1.0);

    return (waitScore * 0.40) +
        (distanceScore * 0.25) +
        (ratingScore * 0.20) +
        (priceScore * 0.15);
  }

  double _averageMenuPrice(Restaurant restaurant) {
    final prices = restaurant.menu
        .expand((section) => section.items)
        .map((item) => item.priceCop)
        .where((price) => price > 0)
        .toList();

    if (prices.isEmpty) return 0;

    return prices.reduce((a, b) => a + b) / prices.length;
  }
}
