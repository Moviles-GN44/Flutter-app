import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/viewmodels/comparison_view_model.dart';

Restaurant restaurant(
  String id, {
  int price = 15000,
  int walkingMinutes = 5,
  double rating = 4.5,
}) {
  return Restaurant(
    id: id,
    name: 'Restaurant $id',
    category: 'Lunch',
    priceRange: '',
    distanceMeters: 300,
    walkingMinutes: walkingMinutes,
    rating: rating,
    reviewCount: 10,
    waitTime: WaitTime.under5,
    isOpen: true,
    foodIcon: Icons.restaurant_outlined,
    location: const LatLng(4.6025, -74.0667),
    averagePriceCop: price,
  );
}

void main() {
  late ComparisonViewModel viewModel;
  late Restaurant first;
  late Restaurant second;

  setUp(() {
    viewModel = ComparisonViewModel();

    first = restaurant('first');

    second = restaurant('second', price: 20000, walkingMinutes: 8, rating: 4.8);

    viewModel.updateRestaurants([first, second], isFromCache: false);
  });

  tearDown(() {
    viewModel.dispose();
  });

  test('Comparison starts without selected restaurants', () {
    expect(viewModel.firstRestaurant, isNull);
    expect(viewModel.secondRestaurant, isNull);
    expect(viewModel.canCompare, isFalse);
    expect(viewModel.comparison, isNull);
  });

  test('Two different restaurants can be compared', () {
    viewModel.selectFirstRestaurant(first);
    viewModel.selectSecondRestaurant(second);

    expect(viewModel.canCompare, isTrue);
    expect(viewModel.comparison, isNotNull);

    final comparison = viewModel.comparison!;

    expect(comparison.firstRestaurant.averagePriceCop, 15000);
    expect(comparison.secondRestaurant.averagePriceCop, 20000);

    expect(comparison.firstRestaurant.walkingMinutes, 5);
    expect(comparison.secondRestaurant.walkingMinutes, 8);

    expect(comparison.firstRestaurant.rating, 4.5);
    expect(comparison.secondRestaurant.rating, 4.8);
  });

  test('The same restaurant cannot occupy both selections', () {
    viewModel.selectFirstRestaurant(first);
    viewModel.selectSecondRestaurant(first);

    expect(viewModel.secondRestaurant, isNull);
    expect(viewModel.canCompare, isFalse);
  });

  test('Changing the first selection prevents duplicates', () {
    viewModel.selectFirstRestaurant(first);
    viewModel.selectSecondRestaurant(second);

    viewModel.selectFirstRestaurant(second);

    expect(viewModel.firstRestaurant?.id, second.id);
    expect(viewModel.secondRestaurant, isNull);
    expect(viewModel.canCompare, isFalse);
  });

  test('Removing a restaurant disables comparison', () {
    viewModel.selectFirstRestaurant(first);
    viewModel.selectSecondRestaurant(second);

    viewModel.removeFirstRestaurant();

    expect(viewModel.firstRestaurant, isNull);
    expect(viewModel.canCompare, isFalse);

    viewModel.selectFirstRestaurant(first);
    viewModel.removeSecondRestaurant();

    expect(viewModel.secondRestaurant, isNull);
    expect(viewModel.canCompare, isFalse);
  });

  test('Clearing comparison removes both selections', () {
    viewModel.selectFirstRestaurant(first);
    viewModel.selectSecondRestaurant(second);

    viewModel.clearSelection();

    expect(viewModel.firstRestaurant, isNull);
    expect(viewModel.secondRestaurant, isNull);
    expect(viewModel.comparison, isNull);
  });

  test('Cached restaurants remain available for comparison', () {
    viewModel.updateRestaurants([first, second], isFromCache: true);

    viewModel.selectFirstRestaurant(first);
    viewModel.selectSecondRestaurant(second);

    expect(viewModel.isFromCache, isTrue);
    expect(viewModel.canCompare, isTrue);
  });

  test('Fresh data updates prices and preserves selections', () {
    viewModel.updateRestaurants([first, second], isFromCache: true);

    viewModel.selectFirstRestaurant(first);
    viewModel.selectSecondRestaurant(second);

    final updatedFirst = restaurant('first', price: 18000, walkingMinutes: 7);

    viewModel.updateRestaurants([updatedFirst, second], isFromCache: false);

    expect(viewModel.isFromCache, isFalse);
    expect(viewModel.canCompare, isTrue);
    expect(viewModel.firstRestaurant?.id, first.id);
    expect(viewModel.secondRestaurant?.id, second.id);

    expect(viewModel.comparison?.firstRestaurant.averagePriceCop, 18000);

    expect(viewModel.comparison?.firstRestaurant.walkingMinutes, 7);
  });

  test('Unavailable restaurants are removed from selection', () {
    viewModel.selectFirstRestaurant(first);
    viewModel.selectSecondRestaurant(second);

    viewModel.updateRestaurants([first], isFromCache: false);

    expect(viewModel.firstRestaurant?.id, first.id);
    expect(viewModel.secondRestaurant, isNull);
    expect(viewModel.canCompare, isFalse);
  });

  test('External changes cannot modify available restaurants', () {
    final restaurants = viewModel.restaurants;

    expect(() => restaurants.clear(), throwsUnsupportedError);

    expect(viewModel.restaurants, hasLength(2));
  });
}
