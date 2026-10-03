import 'package:cloud_firestore/cloud_firestore.dart';

/// Answer to BQ9: how often students use the allergen and dietary filters
/// compared to the other filters, and which restrictions they pick the most.
class BQ9AnalyticsResult {
  const BQ9AnalyticsResult({
    required this.countsByType,
    required this.dietaryCounts,
    required this.searches,
    required this.searchesWithDietary,
  });

  /// Times each kind of filter was applied: `category`, `walking_time`,
  /// `price`, `dietary`, `payment`.
  final Map<String, int> countsByType;

  /// Times each restriction was applied: `vegan`, `gluten_free`,
  /// `lactose_free`.
  final Map<String, int> dietaryCounts;

  /// Taps on "Apply Filters", including searches without filters.
  final int searches;

  /// Searches that used at least one dietary filter.
  final int searchesWithDietary;

  int get totalFilterUses =>
      countsByType.values.fold(0, (total, uses) => total + uses);

  /// Share of all filter uses that were dietary filters, from 0 to 100.
  double get dietaryShare => totalFilterUses == 0
      ? 0
      : (countsByType['dietary'] ?? 0) / totalFilterUses * 100;

  /// Share of searches that used a dietary filter, from 0 to 100.
  double get searchesWithDietaryShare =>
      searches == 0 ? 0 : searchesWithDietary / searches * 100;

  String? get mostUsedFilterType => _top(countsByType);
  String? get mostSelectedRestriction => _top(dietaryCounts);

  static String? _top(Map<String, int> counts) {
    final used = counts.entries.where((entry) => entry.value > 0);
    if (used.isEmpty) return null;
    return used.reduce((a, b) => a.value >= b.value ? a : b).key;
  }
}

class BQ9AnalyticsService {
  BQ9AnalyticsService({FirebaseFirestore? firestore}) : _injected = firestore;

  final FirebaseFirestore? _injected;

  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  static const filterTypes = [
    'category',
    'walking_time',
    'price',
    'dietary',
    'payment',
  ];

  static const restrictions = ['vegan', 'gluten_free', 'lactose_free'];

  Future<BQ9AnalyticsResult> getFilterUsage() async {
    try {
      final snapshot = await _firestore
          .collection('telemetry_events')
          .where('eventName', isEqualTo: 'filter_applied')
          .get();
      return aggregate(snapshot.docs.map((document) => document.data()));
    } on FirebaseException {
      return aggregate(const []);
    }
  }

  /// Turns raw `filter_applied` events into the BQ9 answer.
  static BQ9AnalyticsResult aggregate(Iterable<Map<String, dynamic>> events) {
    final countsByType = {for (final type in filterTypes) type: 0};
    final dietaryCounts = {for (final r in restrictions) r: 0};
    final searches = <String>{};
    final searchesWithDietary = <String>{};

    for (final event in events) {
      final params = event['params'];
      if (params is! Map) continue;

      final type = params['filterType'];
      final value = params['value'];
      final applyId = params['applyId'];
      if (applyId is String) searches.add(applyId);

      if (type is String && countsByType.containsKey(type)) {
        countsByType[type] = countsByType[type]! + 1;
      }
      if (type == 'dietary' && value is String) {
        if (dietaryCounts.containsKey(value)) {
          dietaryCounts[value] = dietaryCounts[value]! + 1;
        }
        if (applyId is String) searchesWithDietary.add(applyId);
      }
    }

    return BQ9AnalyticsResult(
      countsByType: countsByType,
      dietaryCounts: dietaryCounts,
      searches: searches.length,
      searchesWithDietary: searchesWithDietary.length,
    );
  }
}
