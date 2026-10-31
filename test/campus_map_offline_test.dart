import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:uniandes_food/data/sample_restaurants.dart';
import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/repositories/campus_restaurants_repository.dart';
import 'package:uniandes_food/services/location/building_location_strategy.dart';
import 'package:uniandes_food/services/location/user_location_tracker.dart';
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

final _restaurant = sampleRestaurants.first;

void main() {
  late StreamController<RestaurantsSnapshot> controller;
  late CampusMapViewModel viewModel;

  setUp(() {
    controller = StreamController<RestaurantsSnapshot>.broadcast(sync: true);
    viewModel = CampusMapViewModel(
      repository: _FakeRestaurantsRepository(controller),
      locationTracker: UserLocationTracker(
        gpsStrategy: const BuildingLocationStrategy('ML'),
      ),
    );
  });

  tearDown(() async {
    viewModel.dispose();
    await controller.close();
  });

  test('Offline, the map shows the restaurants saved on the phone', () {
    controller.add(
      RestaurantsSnapshot(restaurants: [_restaurant], isFromCache: true),
    );

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.isFromCache, isTrue);
    expect(viewModel.restaurants.single.id, _restaurant.id);
    expect(viewModel.hasNoCachedRestaurants, isFalse);
  });

  test('Offline without saved restaurants, the map says so', () {
    controller.add(
      const RestaurantsSnapshot(restaurants: [], isFromCache: true),
    );

    expect(viewModel.hasNoCachedRestaurants, isTrue);
  });

  test('When the connection is back, the server data replaces the cache', () {
    controller.add(
      RestaurantsSnapshot(restaurants: [_restaurant], isFromCache: true),
    );
    controller.add(
      RestaurantsSnapshot(restaurants: [_restaurant], isFromCache: false),
    );

    expect(viewModel.isFromCache, isFalse);
    expect(viewModel.hasNoCachedRestaurants, isFalse);
  });
}
