import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/models/restaurant_filters.dart';
import 'package:uniandes_food/repositories/campus_restaurants_repository.dart';
import 'package:uniandes_food/services/bq6_analytics_service.dart';
import 'package:uniandes_food/services/location/building_location_strategy.dart';
import 'package:uniandes_food/services/location/user_location_tracker.dart';
import 'package:uniandes_food/services/telemetry_service.dart';
import 'package:uniandes_food/viewmodels/explore_view_model.dart';

const _restaurant = Restaurant(
  id: 'el_toro_rgd',
  name: 'El Toro - RGD',
  category: 'Executive Lunch',
  priceRange: '',
  distanceMeters: 0,
  walkingMinutes: 0,
  rating: 5,
  reviewCount: 0,
  waitTime: WaitTime.under5,
  isOpen: true,
  foodIcon: Icons.restaurant_outlined,
  location: LatLng(4.6025, -74.0667),
);

class _FakeRestaurants implements CampusRestaurantsRepository {
  @override
  Stream<List<Restaurant>> watchRestaurants() => Stream.value(const []);
}

class _FakeTelemetry extends TelemetryService {
  final sessions = <Map<String, Object>>[];

  @override
  Future<void> trackFilterApplied({
    required String filterType,
    required String value,
    required String applyId,
    required int filtersCount,
    String? userId,
  }) async {}

  @override
  Future<void> trackFilterSession({
    required int durationMs,
    required int filtersCount,
    required int filterChanges,
    required int searches,
    required bool usedSuggestion,
    required String restaurantId,
    String? userId,
  }) async {
    sessions.add({
      'durationMs': durationMs,
      'filtersCount': filtersCount,
      'filterChanges': filterChanges,
      'searches': searches,
      'usedSuggestion': usedSuggestion,
      'restaurantId': restaurantId,
    });
  }
}

Map<String, dynamic> _session(int ms, {bool suggestion = false}) => {
  'eventName': 'filter_session_completed',
  'params': {
    'durationMs': ms,
    'filterChanges': 2,
    'usedSuggestion': suggestion,
  },
};

void main() {
  test('A session runs from the first filter until a restaurant opens', () {
    var now = DateTime(2026, 10, 3, 12);
    final telemetry = _FakeTelemetry();
    final viewModel = ExploreViewModel(
      repository: _FakeRestaurants(),
      telemetryService: telemetry,
      locationTracker: UserLocationTracker(
        gpsStrategy: const BuildingLocationStrategy('ML'),
      ),
      clock: () => now,
    );

    viewModel.toggleDietary(DietaryOption.vegan);
    now = now.add(const Duration(seconds: 4));
    viewModel.setBudget(0, 20000);
    viewModel.setBudget(0, 25000);
    viewModel.selectWalkingTime(10);
    viewModel.applyFilters();
    now = now.add(const Duration(seconds: 8));
    viewModel.openRestaurant(_restaurant);

    expect(telemetry.sessions, [
      {
        'durationMs': 12000,
        'filtersCount': 3,
        // Vegan, walking time and one budget adjustment.
        'filterChanges': 3,
        'searches': 1,
        'usedSuggestion': false,
        'restaurantId': 'el_toro_rgd',
      },
    ]);

    // Opening another restaurant without touching filters is not a session.
    viewModel.openRestaurant(_restaurant);
    expect(telemetry.sessions, hasLength(1));
  });

  test('BQ6 summarizes how long students take to decide', () {
    final result = BQ6AnalyticsService.aggregate([
      _session(3000),
      _session(8000),
      _session(12000, suggestion: true),
      _session(30000),
      _session(4000, suggestion: true),
      _session(900000), // left open for 15 minutes: ignored
    ]);

    expect(result.sessions, 5);
    expect(result.averageSec, closeTo(11.4, 0.001));
    expect(result.medianSec, 8);
    expect(result.distribution, {
      '< 5 s': 2,
      '5–10 s': 1,
      '10–20 s': 1,
      '> 20 s': 1,
    });
    expect(result.averageWithSuggestionSec, 8);
    expect(result.averageWithoutSuggestionSec, closeTo(13.667, 0.001));
    expect(result.averageFilterChanges, 2);
  });

  test('Without sessions there is no answer yet', () {
    final result = BQ6AnalyticsService.aggregate(const []);

    expect(result.sessions, 0);
    expect(result.averageSec, 0);
    expect(result.medianSec, 0);
  });
}
