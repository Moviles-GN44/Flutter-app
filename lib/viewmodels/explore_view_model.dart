import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/models/restaurant_filters.dart';
import 'package:uniandes_food/repositories/campus_restaurants_repository.dart';
import 'package:uniandes_food/services/filter_suggestion_service.dart';
import 'package:uniandes_food/services/location/user_location_tracker.dart';
import 'package:uniandes_food/services/telemetry_service.dart';
import 'package:uniandes_food/viewmodels/auth_view_model.dart';

class ExploreViewModel extends ChangeNotifier {
  ExploreViewModel({
    CampusRestaurantsRepository? repository,
    UserLocationTracker? locationTracker,
    TelemetryService? telemetryService,
    FilterSuggestionService? suggestionService,
    AuthViewModel? auth,
  }) : _location = locationTracker ?? UserLocationTracker.shared,
       _telemetry = telemetryService ?? TelemetryService(),
       _suggestions = suggestionService ?? FilterSuggestionService(),
       _auth = auth {
    _subscription = (repository ?? CampusRestaurantsRepository())
        .watchRestaurants()
        .listen(_onRestaurants, onError: _onError);
    _location.addListener(notifyListeners);
    _auth?.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  static const walkingTimeOptions = [5, 10, 15];

  /// Payment methods as Firestore stores them.
  static const paymentOptions = ['Cash', 'Cards', 'Nequi'];

  final UserLocationTracker _location;
  final TelemetryService _telemetry;
  final FilterSuggestionService _suggestions;
  final AuthViewModel? _auth;
  late final StreamSubscription<List<Restaurant>> _subscription;

  List<Restaurant> _restaurants = const [];
  RestaurantFilters _filters = const RestaurantFilters();
  bool _showingResults = false;
  bool _isLoading = true;
  String? _errorMessage;
  String? _suggestionUserId;
  FilterSuggestion? _suggestion;
  bool _disposed = false;

  RestaurantFilters get filters => _filters;
  bool get showingResults => _showingResults;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// The filters this student usually applies, while they differ from the
  /// ones already selected. Null when signed out or without a habit yet.
  FilterSuggestion? get suggestion {
    final suggestion = _suggestion;
    if (suggestion == null) return null;
    final current = _filters.activeFilters.toSet();
    return current.containsAll(suggestion.filters.activeFilters)
        ? null
        : suggestion;
  }

  /// Applies the suggested filters in one tap.
  void useSuggestion() {
    final suggestion = _suggestion;
    if (suggestion == null) return;
    _filters = suggestion.filters;
    applyFilters();
  }

  /// Where walking times are measured from: `you` with GPS, else a building.
  String get measuredFrom => _location.isUsingGps ? 'you' : _location.label;

  /// Categories that exist in Firestore, in alphabetical order.
  List<String> get categories => {
    for (final r in _restaurants) r.category,
  }.where((category) => category.isNotEmpty).toList()..sort();

  /// Restaurants that match the filters, measured from the student and
  /// closest first.
  List<Restaurant> get results {
    final measured = [for (final r in _restaurants) _location.measure(r)];
    return measured.where(_filters.matches).toList()
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
  }

  void selectCategory(String? category) => _update(category: () => category);

  /// Tapping the selected time again removes the limit.
  void selectWalkingTime(int minutes) => _update(
    maxWalkingMinutes: () =>
        _filters.maxWalkingMinutes == minutes ? null : minutes,
  );

  void setBudget(int min, int max) => _update(minPrice: min, maxPrice: max);

  void toggleDietary(DietaryOption option) =>
      _update(dietary: _toggled(_filters.dietary, option));

  void togglePayment(String method) =>
      _update(paymentMethods: _toggled(_filters.paymentMethods, method));

  void applyFilters() {
    _showingResults = true;
    notifyListeners();
    _trackAppliedFilters();
  }

  /// BQ9: sends one `filter_applied` event per active filter. A search with
  /// no filters is sent as `none`, so searches without filters are counted.
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
          userId: _auth?.currentUser?.uid,
        ),
      );
    }
  }

  void editFilters() {
    _showingResults = false;
    notifyListeners();
    // The search just made may have changed the student's habits.
    if (_suggestionUserId case final userId?) _loadSuggestion(userId);
  }

  void clearFilters() {
    _filters = const RestaurantFilters();
    _showingResults = false;
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
    notifyListeners();
  }

  static Set<T> _toggled<T>(Set<T> values, T value) => values.contains(value)
      ? ({...values}..remove(value))
      : {...values, value};

  void _onRestaurants(List<Restaurant> restaurants) {
    _restaurants = restaurants;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void _onError(Object error) {
    _isLoading = false;
    _errorMessage = 'Could not load restaurants.';
    notifyListeners();
  }

  void _onAuthChanged() {
    final userId = _auth?.currentUser?.uid;
    if (userId == _suggestionUserId) return;
    _suggestionUserId = userId;
    _suggestion = null;
    notifyListeners();
    if (userId != null) _loadSuggestion(userId);
  }

  Future<void> _loadSuggestion(String userId) async {
    final suggestion = await _suggestions.suggestFor(userId);
    if (_disposed || userId != _suggestionUserId) return;
    _suggestion = suggestion;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth?.removeListener(_onAuthChanged);
    _location.removeListener(notifyListeners);
    _subscription.cancel();
    super.dispose();
  }
}
