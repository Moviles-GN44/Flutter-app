import 'package:cloud_firestore/cloud_firestore.dart';

class TelemetryService {
  TelemetryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> trackComparisonCriterion({
    required String criterion,
    required String restaurantId,
    String? userId,
  }) async {
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
  }
}