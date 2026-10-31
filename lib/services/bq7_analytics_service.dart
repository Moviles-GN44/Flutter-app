import 'package:cloud_firestore/cloud_firestore.dart';

class BQ7AnalyticsResult {
  const BQ7AnalyticsResult({
    required this.counts,
    required this.totalInteractions,
  });

  final Map<String, int> counts;
  final int totalInteractions;

  int countFor(String feature) => counts[feature] ?? 0;

  double percentageFor(String feature) {
    if (totalInteractions == 0) return 0;
    return countFor(feature) / totalInteractions * 100;
  }

  String? get mostUsedFeature {
    if (totalInteractions == 0) return null;

    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  List<String> get leastUsedFeatures {
    if (totalInteractions == 0) return [];

    final minimum = counts.values.reduce((a, b) => a < b ? a : b);

    return counts.entries
        .where((entry) => entry.value == minimum)
        .map((entry) => entry.key)
        .toList();
  }
}

class BQ7AnalyticsService {
  BQ7AnalyticsService({FirebaseFirestore? firestore}) : _injected = firestore;

  final FirebaseFirestore? _injected;

  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  static const features = [
    'home',
    'explore',
    'favorites',
    'profile',
    'qr_scanner',
  ];

  Future<BQ7AnalyticsResult> getFeatureUsage() async {
    try {
      final snapshot = await _firestore
          .collection('telemetry_events')
          .where('eventName', isEqualTo: 'feature_opened')
          .get();

      final events = [for (final document in snapshot.docs) document.data()];

      return aggregate(events);
    } on FirebaseException {
      return aggregate(const []);
    }
  }

  static BQ7AnalyticsResult aggregate(Iterable<Map<String, dynamic>> events) {
    final counts = {for (final feature in features) feature: 0};

    for (final event in events) {
      if (event['eventName'] != 'feature_opened') {
        continue;
      }

      final params = event['params'];

      if (params is! Map) continue;

      final feature = params['feature'];

      if (feature is String && counts.containsKey(feature)) {
        counts[feature] = counts[feature]! + 1;
      }
    }

    final total = counts.values.fold<int>(0, (total, value) => total + value);

    return BQ7AnalyticsResult(counts: counts, totalInteractions: total);
  }
}
