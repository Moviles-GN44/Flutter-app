import 'package:cloud_firestore/cloud_firestore.dart';

class TelemetryService {
  TelemetryService({FirebaseFirestore? firestore}) : _injected = firestore;

  final FirebaseFirestore? _injected;

  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  Future<void> trackComparisonCriterion({
    required String criterion,
    required String restaurantId,
    String? userId,
  }) async {
    try {
      final document = _firestore.collection('telemetry_events').doc();

      await document.set({
        'eventId': document.id,
        'eventName': 'restaurant_comparison_criterion',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'platform': 'Flutter',
        'params': {
          'criterion': criterion,
          'restaurantId': restaurantId,
          'userId': ?userId,
        },
      });
    } on FirebaseException {
      return;
    }
  }

  Future<void> trackReviewEvent({
    required String eventName,
    required String method,
    required String restaurantId,
  }) async {
    try {
      final document = _firestore.collection('telemetry_events').doc();

      await document.set({
        'eventId': document.id,
        'eventName': eventName,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'platform': 'Flutter',
        'params': {'method': method, 'restaurantId': restaurantId},
      });
    } on FirebaseException {
      return;
    }
  }

  /// BQ9: one event per filter the student applies on the Explore screen.
  /// Events from the same tap on "Apply Filters" share [applyId], and
  /// [filtersCount] says how many filters that search used.
  Future<void> trackFilterApplied({
    required String filterType,
    required String value,
    required String applyId,
    required int filtersCount,
  }) async {
    try {
      final document = _firestore.collection('telemetry_events').doc();

      await document.set({
        'eventId': document.id,
        'eventName': 'filter_applied',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'platform': 'Flutter',
        'params': {
          'filterType': filterType,
          'value': value,
          'applyId': applyId,
          'filtersCount': filtersCount,
        },
      });
    } on FirebaseException {
      return;
    }
  }
}
