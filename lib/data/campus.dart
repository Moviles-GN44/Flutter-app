import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// Approximate coordinates of the Universidad de los Andes campus. They frame
// the map and stand in for the user's position until GPS is wired up.
const campusCenter = LatLng(4.6020, -74.0655);

// Mario Laserna (ML), used as the default user location.
const defaultUserBuilding = 'ML';
const defaultUserLocation = LatLng(4.6029, -74.0650);

final campusBounds = LatLngBounds(
  const LatLng(4.5975, -74.0705),
  const LatLng(4.6070, -74.0610),
);
