import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/models/restaurant_filters.dart';
import 'package:uniandes_food/repositories/campus_restaurants_repository.dart';
import 'package:uniandes_food/services/filter_preferences_service.dart';
import 'package:uniandes_food/services/location/user_location_tracker.dart';
import 'package:uniandes_food/services/telemetry_service.dart';

class ExploreViewModel extends ChangeNotifier {
  ExploreViewModel({
    CampusRestaurantsRepository? repository,
    UserLocationTracker? locationTracker,
    TelemetryService? telemetryService,
    FilterPreferencesService? preferencesService,
  }) : _location = locationTracker ?? UserLocationTracker.shared,
       _telemetry = telemetryService ?? TelemetryService(),
       _preferencesService = preferencesService ?? FilterPreferencesService() {
    _subscription = (repository ?? CampusRestaurantsRepository())
        .watchRestaurants()
        .listen(_onRestaurants, onError: _onError);

    _location.addListener(notifyListeners);

    // Sprint 3: restore filters saved on this device.
    unawaited(_loadSavedFilters());
  }

  static const walkingTimeOptions = [5, 10, 15];

  static const paymentOptions = ['Cash', 'Cards', 'Nequi'];

  final UserLocationTracker _location;
  final TelemetryService _telemetry;
  final FilterPreferencesService _preferencesService;

  late final StreamSubscription<List<Restaurant>> _subscription;

  List<Restaurant> _restaurants = const [];
  RestaurantFilters _filters = const RestaurantFilters();

  bool _showingResults = false;
  bool _isLoading = true;
  String? _errorMessage;

  // Sprint 3: local storage state.
  bool _filtersModified = false;
  bool _isDisposed = false;

  // Saves run in order, avoiding older writes replacing newer ones.
  Future<void> _saveQueue = Future<void>.value();

  RestaurantFilters get filters => _filters;
  bool get showingResults => _showingResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get measuredFrom => _location.isUsingGps ? 'you' : _location.label;

  List<String> get categories => {
    for (final r in _restaurants) r.category,
  }.where((category) => category.isNotEmpty).toList()..sort();

  List<Restaurant> get results {
    final measured = [
      for (final restaurant in _restaurants) _location.measure(restaurant),
    ];

    return measured.where(_filters.matches).toList()
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
  }

  // --------------------------------------------------
  // Sprint 3: LOCAL STORAGE
  // --------------------------------------------------

  Future<void> _loadSavedFilters() async {
    try {
      final savedFilters = await _preferencesService.loadFilters();

      if (_isDisposed || _filtersModified) return;

      _filters = savedFilters;
      notifyListeners();
    } catch (error) {
      debugPrint('Could not load saved filters: $error');
    }
  }

  void _saveCurrentFilters() {
    _filtersModified = true;

    // Capture the filters at the moment of the change.
    final filtersToSave = _filters;

    _saveQueue = _saveQueue.then((_) async {
      try {
        await _preferencesService.saveFilters(filtersToSave);
      } catch (error) {
        debugPrint('Could not save filters: $error');
      }
    });
  }

  // --------------------------------------------------
  // EXISTING FILTER FUNCTIONALITY
  // --------------------------------------------------

  void selectCategory(String? category) {
    _update(category: () => category);
  }

  void selectWalkingTime(int minutes) {
    _update(
      maxWalkingMinutes: () =>
          _filters.maxWalkingMinutes == minutes ? null : minutes,
    );
  }

  void setBudget(int min, int max) {
    _update(minPrice: min, maxPrice: max);
  }

  void toggleDietary(DietaryOption option) {
    _update(dietary: _toggled(_filters.dietary, option));
  }

  void togglePayment(String method) {
    _update(paymentMethods: _toggled(_filters.paymentMethods, method));
  }

  void applyFilters() {
    _showingResults = true;
    notifyListeners();

    // Existing BQ9 telemetry remains unchanged.
    _trackAppliedFilters();
  }

  void _trackAppliedFilters() {
    final applied = _filters.activeFilters;
    final applyId = '${DateTime.now().microsecondsSinceEpoch}';

    final events = applied.isEmpty ? [(type: 'none', value: 'none')] : applied;

    for (final filter in events) {
      unawaited(
        _telemetry.trackFilterApplied(
          filterType: filter.type,
          value: filter.value,
          applyId: applyId,
          filtersCount: applied.length,
        ),
      );
    }
  }

  void editFilters() {
    _showingResults = false;
    notifyListeners();
  }

  void clearFilters() {
    _filters = const RestaurantFilters();
    _showingResults = false;

    // Sprint 3: persist the reset as well.
    _saveCurrentFilters();

    notifyListeners();
  }

  void _update({
    String? Function()? category,
    int? Function()? maxWalkingMinutes,
    int? minPrice,
    int? maxPrice,
    Set<DietaryOption>? dietary,
    Set<String>? paymentMethods,
  }) {
    final f = _filters;

    _filters = RestaurantFilters(
      category: category != null ? category() : f.category,
      maxWalkingMinutes: maxWalkingMinutes != null
          ? maxWalkingMinutes()
          : f.maxWalkingMinutes,
      minPrice: minPrice ?? f.minPrice,
      maxPrice: maxPrice ?? f.maxPrice,
      dietary: dietary ?? f.dietary,
      paymentMethods: paymentMethods ?? f.paymentMethods,
    );

    // Sprint 3: save each change locally.
    _saveCurrentFilters();

    notifyListeners();
  }

  static Set<T> _toggled<T>(Set<T> values, T value) {
    return values.contains(value)
        ? ({...values}..remove(value))
        : {...values, value};
  }

  // --------------------------------------------------
  // EXISTING FIRESTORE FUNCTIONALITY
  // --------------------------------------------------

  void _onRestaurants(List<Restaurant> restaurants) {
    if (_isDisposed) return;

    _restaurants = restaurants;
    _isLoading = false;
    _errorMessage = null;

    notifyListeners();
  }

  void _onError(Object error) {
    if (_isDisposed) return;

    _isLoading = false;
    _errorMessage = 'Could not load restaurants.';

    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _location.removeListener(notifyListeners);
    _subscription.cancel();

    super.dispose();
  }
}
