import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:uniandes_food/data/campus.dart';
import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/services/location/building_location_strategy.dart';
import 'package:uniandes_food/services/location/gps_location_strategy.dart';
import 'package:uniandes_food/services/location/location_strategy.dart';

/// Knows where the student is and measures restaurants from there.
///
/// It is the context of the [LocationStrategy] pattern: it starts with the
/// GPS, falls back to a campus building when the GPS cannot be used, and lets
/// the student pick a building. One instance is shared by the map and the
/// Explore screen so both measure from the same place.
class UserLocationTracker extends ChangeNotifier {
  UserLocationTracker({
    LocationStrategy? gpsStrategy,
    LocationStrategy? fallbackStrategy,
  }) : _gpsStrategy = gpsStrategy ?? const GpsLocationStrategy(),
       _fallbackStrategy = fallbackStrategy ?? const BuildingLocationStrategy(),
       _strategy = fallbackStrategy ?? const BuildingLocationStrategy() {
    useGps();
  }

  /// The tracker the app screens share.
  static final shared = UserLocationTracker();

  // Walking pace and detour factor used to turn a straight-line distance into
  // minutes: paths on campus are rarely straight (stairs, corners).
  static const _walkingMetersPerMinute = 80.0;
  static const _detourFactor = 1.3;
  static const _distance = Distance();

  final LocationStrategy _gpsStrategy;
  final LocationStrategy _fallbackStrategy;
  LocationStrategy _strategy;
  StreamSubscription<LatLng>? _subscription;
  LatLng _location = defaultUserLocation;
  bool _gpsUnavailable = false;

  LatLng get location => _location;

  /// Short name of where the position comes from: `GPS`, `ML`, `SD`…
  String get label => _strategy.label;
  bool get isUsingGps => identical(_strategy, _gpsStrategy);

  /// True when the tracker fell back to a building because the GPS failed, as
  /// opposed to the student picking the building themselves.
  bool get gpsUnavailable => _gpsUnavailable;

  /// Tries the GPS again, e.g. after the student turns location on.
  void useGps() {
    _gpsUnavailable = false;
    _use(_gpsStrategy);
  }

  /// The student says which building they are in (e.g. in a basement where
  /// the GPS does not work).
  void useBuilding(String building) {
    _gpsUnavailable = false;
    _use(BuildingLocationStrategy(building));
  }

  /// Copies [restaurant] with its distance and walking time measured from the
  /// student's current position.
  Restaurant measure(Restaurant restaurant) {
    final meters = _distance(_location, restaurant.location).round();
    final minutes = (meters * _detourFactor / _walkingMetersPerMinute).ceil();
    final r = restaurant;
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
      isGlutenFree: r.isGlutenFree,
      isLactoseFree: r.isLactoseFree,
      averagePriceCop: r.averagePriceCop,
      hasPromo: r.hasPromo,
      address: r.address,
      schedule: r.schedule,
      phone: r.phone,
      paymentMethods: r.paymentMethods,
      menu: r.menu,
      reviews: r.reviews,
    );
  }

  void _use(LocationStrategy strategy) {
    _subscription?.cancel();
    _strategy = strategy;
    _subscription = strategy.watchLocation().listen(
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
    _location = location;
    notifyListeners();
  }

  void _fallBack() {
    if (identical(_strategy, _fallbackStrategy)) return;
    _gpsUnavailable = true;
    _use(_fallbackStrategy);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
