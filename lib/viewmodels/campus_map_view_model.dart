import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:uniandes_food/data/campus.dart';
import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/repositories/campus_restaurants_repository.dart';
import 'package:uniandes_food/services/location/user_location_tracker.dart';

class CampusMapViewModel extends ChangeNotifier {
  CampusMapViewModel({
    CampusRestaurantsRepository? repository,
    UserLocationTracker? locationTracker,
  }) : _repository = repository ?? CampusRestaurantsRepository(),
       _location = locationTracker ?? UserLocationTracker.shared {
    _subscription = _repository.watchRestaurants().listen(
      _onRestaurants,
      onError: _onError,
    );
    _location.addListener(_onLocationChanged);
  }

  final CampusRestaurantsRepository _repository;

  // Where the student is (GPS or a building). The location Strategy lives
  // in UserLocationTracker, shared with the Explore screen.
  final UserLocationTracker _location;
  late final StreamSubscription<List<Restaurant>> _subscription;

  // "Near you" means reachable on foot in this many minutes, and "in a
  // building" means within this many meters of its entrance.
  static const nearbyMinutes = 3;
  static const _buildingRadiusMeters = 120.0;
  static const _distance = Distance();

  List<Restaurant> _firestoreRestaurants = const [];
  List<Restaurant> _restaurants = const [];
  bool _isLoading = true;
  String? _errorMessage;

  /// Restaurants from Firestore, measured from the student's position.
  List<Restaurant> get restaurants => _restaurants;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  LatLng get userLocation => _location.location;
  String get locationLabel => _location.label;
  bool get isUsingGps => _location.isUsingGps;
  bool get gpsUnavailable => _location.gpsUnavailable;

  void useGps() => _location.useGps();
  void useBuilding(String building) => _location.useBuilding(building);

  /// The campus building the student is in or next to, or null when they are
  /// between buildings. Follows the GPS as they walk.
  String? get currentBuilding {
    if (!isUsingGps) return locationLabel;

    String? closest;
    var closestMeters = double.infinity;
    for (final entry in campusBuildings.entries) {
      final meters = _distance(userLocation, entry.value);
      if (meters < closestMeters) {
        closest = entry.key;
        closestMeters = meters;
      }
    }
    return closestMeters <= _buildingRadiusMeters ? closest : null;
  }

  /// Restaurants within [nearbyMinutes] of the student, closest first.
  List<Restaurant> get nearbyRestaurants {
    return [
      for (final r in _restaurants)
        if (r.walkingMinutes <= nearbyMinutes) r,
    ]..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
  }

  /// The restaurant closest to the student, nearby or not.
  Restaurant? get closestRestaurant {
    if (_restaurants.isEmpty) return null;
    return _restaurants.reduce(
      (a, b) => a.distanceMeters <= b.distanceMeters ? a : b,
    );
  }

  bool isNearby(Restaurant restaurant) =>
      restaurant.walkingMinutes <= nearbyMinutes;

  void _onLocationChanged() {
    _restaurants = [
      for (final r in _firestoreRestaurants) _location.measure(r),
    ];
    notifyListeners();
  }

  void _onRestaurants(List<Restaurant> restaurants) {
    _firestoreRestaurants = restaurants;
    _restaurants = [for (final r in restaurants) _location.measure(r)];
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void _onError(Object error) {
    _isLoading = false;
    _errorMessage = 'Could not load restaurants.';
    notifyListeners();
  }

  @override
  void dispose() {
    _location.removeListener(_onLocationChanged);
    _subscription.cancel();
    super.dispose();
  }
}
