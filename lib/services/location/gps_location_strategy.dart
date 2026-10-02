import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:uniandes_food/services/location/location_strategy.dart';

class LocationUnavailableException implements Exception {
  const LocationUnavailableException(this.reason);

  final String reason;
}

/// Reads the phone's GPS sensor.
class GpsLocationStrategy implements LocationStrategy {
  const GpsLocationStrategy();

  // Fixes less precise than this (common inside concrete buildings) are
  // ignored instead of making the user's dot jump around the map.
  static const _maxAccuracyMeters = 50.0;

  static const _settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );

  @override
  String get label => 'GPS';

  @override
  Stream<LatLng> watchLocation() async* {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationUnavailableException('Location is turned off.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationUnavailableException('Location permission denied.');
    }

    yield* Geolocator.getPositionStream(locationSettings: _settings)
        .where((position) => position.accuracy <= _maxAccuracyMeters)
        .map((position) => LatLng(position.latitude, position.longitude));
  }
}
