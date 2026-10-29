import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/repositories/campus_restaurants_repository.dart';
import 'package:uniandes_food/services/location/building_location_strategy.dart';
import 'package:uniandes_food/services/location/user_location_tracker.dart';
import 'package:uniandes_food/viewmodels/explore_view_model.dart';

class _FakeRestaurantsRepository implements CampusRestaurantsRepository {
  _FakeRestaurantsRepository(this.controller);

  final StreamController<RestaurantsSnapshot> controller;

  @override
  Stream<RestaurantsSnapshot> watchRestaurantsWithMetadata() {
    return controller.stream;
  }

  @override
  Stream<List<Restaurant>> watchRestaurants() {
    return controller.stream.map((snapshot) => snapshot.restaurants);
  }
}

void main() {
  late StreamController<RestaurantsSnapshot> controller;
  late ExploreViewModel viewModel;

  setUp(() {
    controller = StreamController<RestaurantsSnapshot>.broadcast(sync: true);

    viewModel = ExploreViewModel(
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

  test('Explore starts in loading state', () {
    expect(viewModel.isLoading, isTrue);
    expect(viewModel.hasReceivedSnapshot, isFalse);
  });

  test('Explore identifies an empty Firestore cache', () {
    controller.add(
      const RestaurantsSnapshot(restaurants: [], isFromCache: true),
    );

    expect(viewModel.isLoading, isFalse);
    expect(viewModel.isFromCache, isTrue);
    expect(viewModel.hasReceivedSnapshot, isTrue);
    expect(viewModel.hasNoCachedRestaurants, isTrue);
  });

  test('Explore updates when server data is confirmed', () {
    controller.add(
      const RestaurantsSnapshot(restaurants: [], isFromCache: true),
    );

    expect(viewModel.isFromCache, isTrue);

    controller.add(
      const RestaurantsSnapshot(restaurants: [], isFromCache: false),
    );

    expect(viewModel.isFromCache, isFalse);
    expect(viewModel.hasNoCachedRestaurants, isFalse);
    expect(viewModel.isLoading, isFalse);
  });
}
