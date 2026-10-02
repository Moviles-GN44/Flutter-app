import 'package:latlong2/latlong.dart';

import 'package:uniandes_food/data/campus.dart';
import 'package:uniandes_food/services/location/location_strategy.dart';

/// Places the student at the entrance of a campus building. Used when GPS is
/// off, denied, imprecise or reports a position outside the campus.
class BuildingLocationStrategy implements LocationStrategy {
  const BuildingLocationStrategy([this.building = defaultUserBuilding]);

  /// A key of [campusBuildings], e.g. `ML` or `RGD`.
  final String building;

  @override
  String get label => building;

  @override
  Stream<LatLng> watchLocation() {
    return Stream.value(campusBuildings[building] ?? defaultUserLocation);
  }
}
