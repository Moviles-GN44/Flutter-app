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
          ..sort(
            (a, b) =>
                a.walkingMinutes.compareTo(b.walkingMinutes),
          );

    return candidates.isEmpty ? null : candidates.first;
  }
}