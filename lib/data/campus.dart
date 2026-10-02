import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';


const campusCenter = LatLng(4.6020, -74.0655);


const campusBuildings = <String, LatLng>{
  'ML': LatLng(4.6029, -74.0650),
  'SD': LatLng(4.6046, -74.0655),
  'RGD': LatLng(4.6025, -74.0667),
  'Franco': LatLng(4.6015, -74.0666),
  'W': LatLng(4.6021, -74.0646),
  'C': LatLng(4.6012, -74.0656),
};

const campusBuildingNames = <String, String>{
  'ML': 'Mario Laserna (ML)',
  'SD': 'Santo Domingo (SD)',
  'RGD': 'RGD',
  'Franco': 'Franco',
  'W': 'Building W',
  'C': 'Building C',
};

// Mario Laserna (ML), used as the user location when GPS is not available.
const defaultUserBuilding = 'ML';
const defaultUserLocation = LatLng(4.6029, -74.0650);

final campusBounds = LatLngBounds(
  const LatLng(4.5975, -74.0705),
  const LatLng(4.6070, -74.0610),
);
