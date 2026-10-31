import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:uniandes_food/data/sample_restaurants.dart';
import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/repositories/campus_restaurants_repository.dart';
import 'package:uniandes_food/services/location/building_location_strategy.dart';
import 'package:uniandes_food/services/location/user_location_tracker.dart';
import 'package:uniandes_food/services/telemetry_service.dart';
import 'package:uniandes_food/viewmodels/campus_map_view_model.dart';

class _FakeRestaurantsRepository implements CampusRestaurantsRepository {
  _FakeRestaurantsRepository(this.controller);

  final StreamController<RestaurantsSnapshot> controller;

  @override
  Stream<RestaurantsSnapshot> watchRestaurantsWithMetadata() =>
      controller.stream;

  @override
  Stream<List<Restaurant>> watchRestaurants() =>
      controller.stream.map((snapshot) => snapshot.restaurants);
}

class _FakeTelemetryService implements TelemetryService {
  final List<(String, int, bool?)> loads = [];

  @override
  Future<void> trackMapLoad({
    required String eventName,
    required int durationMs,
    bool? fromCache,
  }) async => loads.add((eventName, durationMs, fromCache));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _restaurant = sampleRestaurants.first;

void main() {
  late StreamController<RestaurantsSnapshot> controller;
  late _FakeTelemetryService telemetry;
  late DateTime now;
  late CampusMapViewModel viewModel;

  setUp(() {
    controller = StreamController<RestaurantsSnapshot>.broadcast(sync: true);
    telemetry = _FakeTelemetryService();
    now = DateTime(2026, 10, 30, 12);
    viewModel = CampusMapViewModel(
      repository: _FakeRestaurantsRepository(controller),
      locationTracker: UserLocationTracker(
        gpsStrategy: const BuildingLocationStrategy('ML'),
      ),
      telemetryService: telemetry,
      now: () => now,
    );
  });

  tearDown(() async {
    viewModel.dispose();
    await controller.close();
  });

  test('The first restaurants shown record the load time', () {
    now = now.add(const Duration(milliseconds: 1500));
    controller.add(
      RestaurantsSnapshot(restaurants: [_restaurant], isFromCache: false),
    );

    expect(telemetry.loads, [('map_load_completed', 1500, false)]);
  });

  test('Restaurants saved on the phone count as loaded from cache', () {
    now = now.add(const Duration(milliseconds: 200));
    controller.add(
      RestaurantsSnapshot(restaurants: [_restaurant], isFromCache: true),
    );

    expect(telemetry.loads, [('map_load_completed', 200, true)]);
  });

  test('Later updates do not record another load', () {
    controller.add(
      RestaurantsSnapshot(restaurants: [_restaurant], isFromCache: true),
    );
    controller.add(
      RestaurantsSnapshot(restaurants: [_restaurant], isFromCache: false),
    );

    expect(telemetry.loads, hasLength(1));
  });

  test('An empty cache keeps the map loading until the server answers', () {
    controller.add(
      const RestaurantsSnapshot(restaurants: [], isFromCache: true),
    );
    expect(telemetry.loads, isEmpty);

    now = now.add(const Duration(seconds: 3));
    controller.add(
      RestaurantsSnapshot(restaurants: [_restaurant], isFromCache: false),
    );

    expect(telemetry.loads, [('map_load_completed', 3000, false)]);
  });

  test('Leaving the app while the map loads records an abandonment', () {
    now = now.add(const Duration(seconds: 4));
    viewModel.onAppHidden();

    expect(telemetry.loads, [('map_load_abandoned', 4000, null)]);
  });

  test('Leaving the app after the map loaded is not an abandonment', () {
    controller.add(
      RestaurantsSnapshot(restaurants: [_restaurant], isFromCache: false),
    );
    viewModel.onAppHidden();

    expect(telemetry.loads.single.$1, 'map_load_completed');
  });

  test('An abandoned load is not recorded again when it finishes', () {
    viewModel.onAppHidden();
    controller.add(
      RestaurantsSnapshot(restaurants: [_restaurant], isFromCache: false),
    );

    expect(telemetry.loads.single.$1, 'map_load_abandoned');
  });
}
