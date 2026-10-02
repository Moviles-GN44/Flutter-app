import 'package:latlong2/latlong.dart';

/// A way of knowing where the student is on campus.
///
/// The map does not care how the position is obtained: it asks the current
/// strategy and can swap it at runtime (GPS when it works, a campus building
/// when it does not).
abstract interface class LocationStrategy {
  /// Short name shown to the student, e.g. `GPS` or `ML`.
  String get label;

  /// Emits the student's position every time it changes. Emits an error when
  /// this strategy cannot provide a position.
  Stream<LatLng> watchLocation();
}
