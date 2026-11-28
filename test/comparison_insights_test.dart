import 'package:flutter_test/flutter_test.dart';
import 'package:uniandes_food/services/comparison_insights_service.dart';

import 'comparison_view_model_test.dart' show restaurant;

void main() {
  final service = ComparisonInsightsService();

  final first = restaurant(
    'first',
    price: 15000,
    walkingMinutes: 5,
    rating: 4.5,
  );

  final second = restaurant(
    'second',
    price: 20000,
    walkingMinutes: 8,
    rating: 4.8,
  );

  final third = restaurant(
    'third',
    price: 10000,
    walkingMinutes: 3,
    rating: 4.0,
  );

  test('Restaurants are ranked by price', () async {
    final result = await service.calculate([first, second, third]);

    expect(result.priceRanks['third'], 1);
    expect(result.priceRanks['first'], 2);
    expect(result.priceRanks['second'], 3);
  });

  test('Restaurants are ranked by walking time', () async {
    final result = await service.calculate([first, second, third]);

    expect(result.walkingRanks['third'], 1);
    expect(result.walkingRanks['first'], 2);
    expect(result.walkingRanks['second'], 3);
  });

  test('Restaurants are ranked by highest rating', () async {
    final result = await service.calculate([first, second, third]);

    expect(result.ratingRanks['second'], 1);
    expect(result.ratingRanks['first'], 2);
    expect(result.ratingRanks['third'], 3);
  });

  test('Equal prices receive the same rank', () async {
    final fourth = restaurant('fourth', price: 15000);

    final result = await service.calculate([first, second, fourth]);

    expect(result.priceRanks['first'], 1);
    expect(result.priceRanks['fourth'], 1);
    expect(result.priceRanks['second'], 3);
  });

  test('Missing metrics are excluded from rankings', () {
    final result = calculateRestaurantRankings([
      (id: 'unknown', price: null, walkingMinutes: 5, rating: null),
      (id: 'known', price: 15000, walkingMinutes: 8, rating: 4.5),
    ]);

    expect(result.priceRanks.containsKey('unknown'), isFalse);
    expect(result.ratingRanks.containsKey('unknown'), isFalse);
    expect(result.priceRanks['known'], 1);
    expect(result.walkingRanks['unknown'], 1);
  });

  test('Empty restaurant data returns empty rankings', () async {
    final result = await service.calculate([]);

    expect(result.priceRanks, isEmpty);
    expect(result.walkingRanks, isEmpty);
    expect(result.ratingRanks, isEmpty);
  });

  test('Updated restaurant data produces updated rankings', () async {
    final original = await service.calculate([first, second]);

    final updatedSecond = restaurant('second', price: 8000);

    final updated = await service.calculate([first, updatedSecond]);

    expect(original.priceRanks['first'], 1);
    expect(updated.priceRanks['second'], 1);
    expect(updated.priceRanks['first'], 2);
  });

  test('Concurrent requests return independent results', () async {
    final results = await Future.wait([
      service.calculate([first, second]),
      service.calculate([second, third]),
    ]);

    expect(results[0].priceRanks['first'], 1);
    expect(results[1].priceRanks['third'], 1);

    expect(results[0].priceRanks.containsKey('third'), isFalse);

    expect(results[1].priceRanks.containsKey('first'), isFalse);
  });
}
