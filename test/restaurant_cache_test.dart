import 'package:flutter_test/flutter_test.dart';

import 'package:uniandes_food/data/sample_restaurants.dart';
import 'package:uniandes_food/repositories/restaurant_repository.dart';

void main() {
  final restaurant = sampleRestaurants.first;

  test('First request loads the restaurant', () async {
    var requests = 0;

    final repository = RestaurantRepository(
      loadRestaurant: (id) async {
        requests++;
        return restaurant;
      },
    );

    final result = await repository.fetchRestaurantById(restaurant.id);

    expect(result, same(restaurant));
    expect(requests, 1);
  });

  test('Repeated requests use the cache', () async {
    var requests = 0;

    final repository = RestaurantRepository(
      loadRestaurant: (id) async {
        requests++;
        return restaurant;
      },
    );

    await repository.fetchRestaurantById(restaurant.id);
    await repository.fetchRestaurantById(restaurant.id);

    expect(requests, 1);
  });

  test('Clearing the cache causes another request', () async {
    var requests = 0;

    final repository = RestaurantRepository(
      loadRestaurant: (id) async {
        requests++;
        return restaurant;
      },
    );

    await repository.fetchRestaurantById(restaurant.id);

    repository.clearCache();

    await repository.fetchRestaurantById(restaurant.id);

    expect(requests, 2);
  });

  test('Expired cache causes another request', () async {
    var requests = 0;
    var currentTime = DateTime(2026, 10, 30, 12);

    final repository = RestaurantRepository(
      now: () => currentTime,
      loadRestaurant: (id) async {
        requests++;
        return restaurant;
      },
    );

    await repository.fetchRestaurantById(restaurant.id);

    currentTime = currentTime.add(const Duration(minutes: 6));

    await repository.fetchRestaurantById(restaurant.id);

    expect(requests, 2);
  });
}
