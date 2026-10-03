import 'package:cloud_firestore/cloud_firestore.dart';

class BQ3AnalyticsResult {
  const BQ3AnalyticsResult({
    required this.counts,
    required this.totalInteractions,
  });

  final Map<String, int> counts;
  final int totalInteractions;

  int countFor(String criterion) => counts[criterion] ?? 0;

  double percentageFor(String criterion) {
    if (totalInteractions == 0) return 0;

    return (countFor(criterion) / totalInteractions) * 100;
  }

  String? get mostConsultedCriterion {
    if (totalInteractions == 0) return null;

    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

class BQ3AnalyticsService {
  BQ3AnalyticsService({FirebaseFirestore? firestore}) : _injected = firestore;

  final FirebaseFirestore? _injected;

  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  static const List<String> criteria = [
    'price',
    'distance',
    'waiting_time',
    'menu',
    'dietary_preferences',
  ];

  Future<BQ3AnalyticsResult> getComparisonResults() async {
    final counts = <String, int>{
      for (final criterion in criteria) criterion: 0,
    };

    try {
      final snapshot = await _firestore
          .collection('telemetry_events')
          .where('eventName', isEqualTo: 'restaurant_comparison_criterion')
          .get();

      for (final document in snapshot.docs) {
        final data = document.data();
        final params = data['params'];

        if (params is! Map) continue;

        final criterion = params['criterion'];

        if (criterion is String && counts.containsKey(criterion)) {
          counts[criterion] = counts[criterion]! + 1;
        }
      }
    } on FirebaseException {
      return BQ3AnalyticsResult(counts: counts, totalInteractions: 0);
    }

    final totalInteractions = counts.values.fold<int>(
      0,
      (total, value) => total + value,
    );

    return BQ3AnalyticsResult(
      counts: counts,
      totalInteractions: totalInteractions,
    );
  }
}
