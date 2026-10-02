import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:uniandes_food/data/campus.dart';
import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/repositories/campus_restaurants_repository.dart';
import 'package:uniandes_food/services/location/building_location_strategy.dart';
import 'package:uniandes_food/services/location/gps_location_strategy.dart';
import 'package:uniandes_food/services/location/location_strategy.dart';

class CampusMapViewModel extends ChangeNotifier {
  CampusMapViewModel({
    CampusRestaurantsRepository? repository,
    LocationStrategy? gpsStrategy,
    LocationStrategy? fallbackStrategy,
  }) : _repository = repository ?? CampusRestaurantsRepository(),
       _gpsStrategy = gpsStrategy ?? const GpsLocationStrategy(),
       _fallbackStrategy = fallbackStrategy ?? const BuildingLocationStrategy(),
       _locationStrategy =
           fallbackStrategy ?? const BuildingLocationStrategy() {
    _subscription = _repository.watchRestaurants().listen(
      _onRestaurants,
      onError: _onError,
    );
    useGps();
  }

  final CampusRestaurantsRepository _repository;
  late final StreamSubscription<List<Restaurant>> _subscription;

  final LocationStrategy _gpsStrategy;
  final LocationStrategy _fallbackStrategy;
  LocationStrategy _locationStrategy;
  StreamSubscription<LatLng>? _locationSubscription;

  // Walking pace and detour factor used to turn a straight-line distance into
  // minutes: paths on campus are rarely straight (stairs, corners).
  static const _walkingMetersPerMinute = 80.0;
  static const _detourFactor = 1.3;
  static const _distance = Distance();

  List<Restaurant> _firestoreRestaurants = const [];
  List<Restaurant> _restaurants = const [];
  bool _isLoading = true;
  String? _errorMessage;
  LatLng _userLocation = defaultUserLocation;

  List<Restaurant> get restaurants => _restaurants;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  LatLng get userLocation => _userLocation;
  String get locationLabel => _locationStrategy.label;
  bool get isUsingGps => identical(_locationStrategy, _gpsStrategy);

  /// True when the map fell back to a building because the GPS failed, as
  /// opposed to the student picking the building themselves.
  bool get gpsUnavailable => _gpsUnavailable;
  bool _gpsUnavailable = false;

  /// Tries the GPS again, e.g. after the student turns location on.
  void useGps() {
    _gpsUnavailable = false;
    _useLocationStrategy(_gpsStrategy);
  }

  /// The student says which building they are in (e.g. in a basement where
  /// the GPS does not work).
  void useBuilding(String building) {
    _gpsUnavailable = false;
    _useLocationStrategy(BuildingLocationStrategy(building));
  }

  //stategy
  void _useLocationStrategy(LocationStrategy strategy) {
    _locationSubscription?.cancel();
    _locationStrategy = strategy;
    _locationSubscription = strategy.watchLocation().listen(
      _onLocation,
      onError: (Object _) => _fallBack(),
    );
    notifyListeners();
  }

  void _onLocation(LatLng location) {
    // The app only covers the campus: a fix outside it (or an emulator's
    // default position) would leave the student's dot off the map.
    if (!campusBounds.contains(location)) {
      _fallBack();
      return;
    }
    _userLocation = location;
    _restaurants = _measuredFromUser(_firestoreRestaurants);
    notifyListeners();
  }

  /// Copies each restaurant with its distance and walking time measured from
  /// wherever the current strategy places the student.
  List<Restaurant> _measuredFromUser(List<Restaurant> restaurants) {
    return [
      for (final r in restaurants)
        _withDistance(r, _distance(_userLocation, r.location).round()),
    ];
  }

  static Restaurant _withDistance(Restaurant r, int meters) {
    final minutes = (meters * _detourFactor / _walkingMetersPerMinute).ceil();
    return Restaurant(
      id: r.id,
      name: r.name,
      category: r.category,
      priceRange: r.priceRange,
      distanceMeters: meters,
      walkingMinutes: minutes < 1 ? 1 : minutes,
      rating: r.rating,
      reviewCount: r.reviewCount,
      waitTime: r.waitTime,
      isOpen: r.isOpen,
      foodIcon: r.foodIcon,
      location: r.location,
      imageAsset: r.imageAsset,
      isVegan: r.isVegan,
      hasPromo: r.hasPromo,
      address: r.address,
      schedule: r.schedule,
      phone: r.phone,
      paymentMethods: r.paymentMethods,
      menu: r.menu,
      reviews: r.reviews,
    );
  }

  void _fallBack() {
    if (identical(_locationStrategy, _fallbackStrategy)) return;
    _gpsUnavailable = true;
    _useLocationStrategy(_fallbackStrategy);
  }

  void _onRestaurants(List<Restaurant> restaurants) {
    _firestoreRestaurants = restaurants;
    _restaurants = _measuredFromUser(restaurants);
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
    _locationSubscription?.cancel();
    _subscription.cancel();
    super.dispose();
  }
}
