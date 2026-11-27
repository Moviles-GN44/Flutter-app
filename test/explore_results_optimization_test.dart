import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/models/restaurant_filters.dart';
import 'package:uniandes_food/repositories/campus_restaurants_repository.dart';
import 'package:uniandes_food/services/filter_preferences_service.dart';
import 'package:uniandes_food/services/location/building_location_strategy.dart';
import 'package:uniandes_food/services/location/user_location_tracker.dart';
import 'package:uniandes_food/viewmodels/explore_view_model.dart';

class _FakeRepository implements CampusRestaurantsRepository {
  final controller = StreamController<RestaurantsSnapshot>.broadcast(
    sync: true,
  );

  @override
  Stream<RestaurantsSnapshot> watchRestaurantsWithMetadata() =>
      controller.stream;

  @override
  Stream<List<Restaurant>> watchRestaurants() =>
      controller.stream.map((snapshot) => snapshot.restaurants);

  void emit(List<Restaurant> restaurants, {bool isFromCache = false}) {
    controller.add(
      RestaurantsSnapshot(restaurants: restaurants, isFromCache: isFromCache),
    );
  }
}

class _CountingLocationTracker extends UserLocationTracker {
  _CountingLocationTracker()
    : super(gpsStrategy: const BuildingLocationStrategy('ML'));

  int measurements = 0;

  @override
  Restaurant measure(Restaurant restaurant) {
    measurements++;
    return super.measure(restaurant);
  }
}

class _FakePreferences extends FilterPreferencesService {
  @override
  Future<RestaurantFilters> loadFilters() async => const RestaurantFilters();

  @override
  Future<void> saveFilters(RestaurantFilters filters) async {}
}

Restaurant _restaurant(int index) {
  return Restaurant(
    id: 'restaurant_$index',
    name: 'Restaurant $index',
    category: index.isEven ? 'Lunch' : 'Cafe',
    priceRange: '',
    distanceMeters: 0,
    walkingMinutes: 0,
    rating: 5,
    reviewCount: 0,
    waitTime: WaitTime.under5,
    isOpen: true,
    foodIcon: Icons.restaurant_outlined,
    location: LatLng(4.6025 + (index % 10) * 0.00001, -74.0667),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeRepository repository;
  late _CountingLocationTracker location;
  late ExploreViewModel viewModel;
  late List<Restaurant> restaurants;

  setUp(() async {
    repository = _FakeRepository();
    location = _CountingLocationTracker();

    viewModel = ExploreViewModel(
      repository: repository,
      locationTracker: location,
      preferencesService: _FakePreferences(),
    );

    await Future<void>.delayed(Duration.zero);

    restaurants = List.generate(20, _restaurant);
    repository.emit(restaurants);
  });

  tearDown(() async {
    viewModel.dispose();
    location.dispose();
    await repository.controller.close();
  });

  test('Repeated reads reuse processed results', () {
    final first = viewModel.results;
    final measurements = location.measurements;

    final second = viewModel.results;

    expect(second.map((r) => r.id), first.map((r) => r.id));
    expect(location.measurements, measurements);
  });

  test('Changing filters invalidates cached results', () {
    expect(viewModel.results, hasLength(20));
    final measurements = location.measurements;

    viewModel.selectCategory('Lunch');

    expect(viewModel.results, hasLength(10));
    expect(location.measurements, greaterThan(measurements));
  });

  test('Clearing filters refreshes results', () {
    viewModel.selectCategory('Cafe');
    expect(viewModel.results, hasLength(10));

    viewModel.clearFilters();

    expect(viewModel.results, hasLength(20));
  });

  test('Location changes invalidate cached results', () async {
    viewModel.results;
    final measurements = location.measurements;

    location.useBuilding('SD');
    await Future<void>.delayed(Duration.zero);

    viewModel.results;

    expect(location.measurements, greaterThan(measurements));
  });

  test('Server updates refresh cached restaurant data', () {
    repository.emit(restaurants, isFromCache: true);

    expect(viewModel.results, hasLength(20));
    expect(viewModel.isFromCache, isTrue);

    repository.emit(restaurants.take(10).toList());

    expect(viewModel.results, hasLength(10));
    expect(viewModel.isFromCache, isFalse);
  });

  test('External list changes do not modify cached results', () {
    final results = viewModel.results;
    results.clear();

    expect(viewModel.results, hasLength(20));
  });

  test('Benchmark repeated restaurant results processing', () {
    repository.emit(List.generate(20, _restaurant));

    const iterations = 10000;

    for (var i = 0; i < 1000; i++) {
      viewModel.results;
    }

    final measurementsBefore = location.measurements;
    final stopwatch = Stopwatch()..start();

    var totalResults = 0;

    for (var i = 0; i < iterations; i++) {
      totalResults += viewModel.results.length;
    }

    stopwatch.stop();

    final elapsed = stopwatch.elapsedMicroseconds;
    final average = elapsed / iterations;
    final measurements = location.measurements - measurementsBefore;

    debugPrint('--- Explore Results Benchmark ---');
    debugPrint('Restaurants: 20');
    debugPrint('Iterations: $iterations');
    debugPrint('Total time: $elapsed us');
    debugPrint('Average time: ${average.toStringAsFixed(3)} us');
    debugPrint('Distance calculations: $measurements');
    debugPrint('---------------------------------');

    expect(totalResults, iterations * 20);
  });
}
