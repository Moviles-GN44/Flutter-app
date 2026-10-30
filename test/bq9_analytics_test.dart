import 'package:flutter_test/flutter_test.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/models/restaurant_filters.dart';
import 'package:uniandes_food/repositories/campus_restaurants_repository.dart';
import 'package:uniandes_food/services/bq9_analytics_service.dart';
import 'package:uniandes_food/services/location/building_location_strategy.dart';
import 'package:uniandes_food/services/location/user_location_tracker.dart';
import 'package:uniandes_food/services/telemetry_service.dart';
import 'package:uniandes_food/viewmodels/explore_view_model.dart';

class _FakeRestaurants implements CampusRestaurantsRepository {
  @override
  Stream<List<Restaurant>> watchRestaurants() => Stream.value(const []);
}

class _FakeTelemetry extends TelemetryService {
  final events = <String>[];
  final applyIds = <String>{};

  @override
  Future<void> trackFilterApplied({
    required String filterType,
    required String value,
    required String applyId,
    required int filtersCount,
    String? userId,
  }) async {
    events.add('$filterType:$value:$filtersCount');
    applyIds.add(applyId);
  }
}

ExploreViewModel _viewModel(_FakeTelemetry telemetry) => ExploreViewModel(
  repository: _FakeRestaurants(),
  telemetryService: telemetry,
  locationTracker: UserLocationTracker(
    gpsStrategy: const BuildingLocationStrategy('ML'),
  ),
);

Map<String, dynamic> _event(String type, String value, String applyId) => {
  'eventName': 'filter_applied',
  'params': {'filterType': type, 'value': value, 'applyId': applyId},
};

void main() {
  test('Active filters are listed the way analytics stores them', () {
    const filters = RestaurantFilters(
      category: 'Fast Food',
      maxWalkingMinutes: 5,
      maxPrice: 25000,
      dietary: {DietaryOption.vegan, DietaryOption.glutenFree},
      paymentMethods: {'Nequi'},
    );

    expect(filters.activeFilters, [
      (type: 'category', value: 'Fast Food'),
      (type: 'walking_time', value: '5'),
      (type: 'price', value: '0-25000'),
      (type: 'dietary', value: 'vegan'),
      (type: 'dietary', value: 'gluten_free'),
      (type: 'payment', value: 'Nequi'),
    ]);
  });

  test('Applying filters sends one event per filter of the same search', () {
    final telemetry = _FakeTelemetry();
    final viewModel = _viewModel(telemetry)
      ..toggleDietary(DietaryOption.vegan)
      ..selectWalkingTime(10);

    viewModel.applyFilters();

    expect(telemetry.events, ['walking_time:10:2', 'dietary:vegan:2']);
    expect(telemetry.applyIds, hasLength(1));
  });

  test('A search without filters is tracked as none', () {
    final telemetry = _FakeTelemetry();

    _viewModel(telemetry).applyFilters();

    expect(telemetry.events, ['none:none:0']);
  });

  test('BQ9 compares dietary filters against the others', () {
    final result = BQ9AnalyticsService.aggregate([
      _event('dietary', 'vegan', 'a'),
      _event('price', '0-25000', 'a'),
      _event('dietary', 'vegan', 'b'),
      _event('dietary', 'gluten_free', 'b'),
      _event('walking_time', '5', 'c'),
      _event('none', 'none', 'd'),
    ]);

    expect(result.totalFilterUses, 5);
    expect(result.countsByType['dietary'], 3);
    expect(result.dietaryShare, 60);
    expect(result.searches, 4);
    expect(result.searchesWithDietary, 2);
    expect(result.searchesWithDietaryShare, 50);
    expect(result.mostUsedFilterType, 'dietary');
    expect(result.mostSelectedRestriction, 'vegan');
  });

  test('Without events there is no answer yet', () {
    final result = BQ9AnalyticsService.aggregate(const []);

    expect(result.totalFilterUses, 0);
    expect(result.dietaryShare, 0);
    expect(result.mostUsedFilterType, isNull);
    expect(result.mostSelectedRestriction, isNull);
  });
}
