import 'package:cloud_firestore/cloud_firestore.dart';

/// Answer to BQ6: how long students spend setting filters (price, distance,
/// dietary preferences…) before selecting a restaurant.
class BQ6AnalyticsResult {
  const BQ6AnalyticsResult({
    required this.durationsSec,
    required this.withSuggestionSec,
    required this.withoutSuggestionSec,
    required this.averageFilterChanges,
  });

  /// Seconds each completed session took, shortest first.
  final List<double> durationsSec;
  final List<double> withSuggestionSec;
  final List<double> withoutSuggestionSec;

  /// Filter taps per session before choosing.
  final double averageFilterChanges;

  /// Labels of the time ranges used to group sessions.
  static const buckets = ['< 5 s', '5–10 s', '10–20 s', '> 20 s'];

  int get sessions => durationsSec.length;

  double get averageSec => _average(durationsSec);
  double get medianSec => _median(durationsSec);

  /// Average with and without the "Suggested for you" filters, to see
  /// whether the suggestion makes deciding faster.
  double get averageWithSuggestionSec => _average(withSuggestionSec);
  double get averageWithoutSuggestionSec => _average(withoutSuggestionSec);

  /// Sessions per time range, in the order of [buckets].
  Map<String, int> get distribution {
    final counts = {for (final bucket in buckets) bucket: 0};
    for (final seconds in durationsSec) {
      final bucket = seconds < 5
          ? buckets[0]
          : seconds < 10
          ? buckets[1]
          : seconds < 20
          ? buckets[2]
          : buckets[3];
      counts[bucket] = counts[bucket]! + 1;
    }
    return counts;
  }

  static double _average(List<double> values) => values.isEmpty
      ? 0
      : values.fold(0.0, (total, value) => total + value) / values.length;

  static double _median(List<double> sorted) {
    if (sorted.isEmpty) return 0;
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;
  }
}

class BQ6AnalyticsService {
  BQ6AnalyticsService({FirebaseFirestore? firestore}) : _injected = firestore;

  final FirebaseFirestore? _injected;

  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  /// Sessions longer than this were probably left open, not spent deciding.
  static const maxSessionSec = 600;

  Future<BQ6AnalyticsResult> getFilterSessionTimes() async {
    try {
      final snapshot = await _firestore
          .collection('telemetry_events')
          .where('eventName', isEqualTo: 'filter_session_completed')
          .get();
      return aggregate(snapshot.docs.map((document) => document.data()));
    } on FirebaseException {
      return aggregate(const []);
    }
  }

  /// Turns raw `filter_session_completed` events into the BQ6 answer.
  static BQ6AnalyticsResult aggregate(Iterable<Map<String, dynamic>> events) {
    final all = <double>[];
    final withSuggestion = <double>[];
    final withoutSuggestion = <double>[];
    var changes = 0;

    for (final event in events) {
      final params = event['params'];
      if (params is! Map) continue;
      final durationMs = params['durationMs'];
      if (durationMs is! num || durationMs < 0) continue;

      final seconds = durationMs / 1000;
      if (seconds > maxSessionSec) continue;

      all.add(seconds);
      (params['usedSuggestion'] == true ? withSuggestion : withoutSuggestion)
          .add(seconds);
      changes += (params['filterChanges'] as num?)?.toInt() ?? 0;
    }

    all.sort();
    return BQ6AnalyticsResult(
      durationsSec: all,
      withSuggestionSec: withSuggestion,
      withoutSuggestionSec: withoutSuggestion,
      averageFilterChanges: all.isEmpty ? 0 : changes / all.length,
    );
  }
}
