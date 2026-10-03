import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:uniandes_food/models/restaurant_filters.dart';

/// Filters the student keeps using, learned from their own searches.
class FilterSuggestion {
  const FilterSuggestion({required this.filters, required this.basedOn});

  final RestaurantFilters filters;

  /// How many past searches the suggestion comes from.
  final int basedOn;
}

/// Smart feature: suggests the filters a student usually applies on the
/// Explore screen, so a repeated search takes one tap.
///
/// It reads the student's own `filter_applied` events (the BQ9 telemetry),
/// looks at their latest searches and keeps the filters that show up in at
/// least half of them.
class FilterSuggestionService {
  FilterSuggestionService({FirebaseFirestore? firestore})
    : _injected = firestore;

  final FirebaseFirestore? _injected;

  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  /// Only the latest searches count, so the suggestion follows habits that
  /// change over the semester.
  static const recentSearches = 10;

  /// Fewer searches than this are not a habit yet.
  static const minSearches = 2;

  Future<FilterSuggestion?> suggestFor(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('telemetry_events')
          .where('eventName', isEqualTo: 'filter_applied')
          .where('params.userId', isEqualTo: userId)
          .get();
      return suggest(snapshot.docs.map((document) => document.data()));
    } on FirebaseException {
      return null;
    }
  }

  /// Learns the suggestion from raw `filter_applied` events.
  static FilterSuggestion? suggest(Iterable<Map<String, dynamic>> events) {
    // Group the events of each tap on "Apply Filters".
    final searches = <String, _Search>{};
    for (final event in events) {
      final params = event['params'];
      if (params is! Map) continue;
      final applyId = params['applyId'];
      final type = params['filterType'];
      final value = params['value'];
      if (applyId is! String || type is! String || value is! String) continue;

      final search = searches.putIfAbsent(
        applyId,
        () => _Search((event['timestamp'] as num?)?.toInt() ?? 0),
      );
      if (type != 'none') search.filters.add((type: type, value: value));
    }

    final recent =
        searches.values.where((search) => search.filters.isNotEmpty).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final used = recent.take(recentSearches).toList();
    if (used.length < minSearches) return null;

    // How many of those searches used each filter.
    final counts = <({String type, String value}), int>{};
    for (final search in used) {
      for (final filter in search.filters) {
        counts[filter] = (counts[filter] ?? 0) + 1;
      }
    }
    final threshold = (used.length / 2).ceil();
    final habits =
        counts.entries
            .where((entry) => entry.value >= threshold && entry.value >= 2)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    String? top(String type) =>
        habits.where((entry) => entry.key.type == type).firstOrNull?.key.value;
    Iterable<String> all(String type) => habits
        .where((entry) => entry.key.type == type)
        .map((entry) => entry.key.value);

    final price = top('price')?.split('-').map(int.tryParse).toList();
    final filters = RestaurantFilters(
      category: top('category'),
      maxWalkingMinutes: int.tryParse(top('walking_time') ?? ''),
      minPrice: price?.first ?? RestaurantFilters.minBudget,
      maxPrice: price?.last ?? RestaurantFilters.maxBudget,
      dietary: {
        for (final key in all('dietary'))
          ...DietaryOption.values.where((option) => option.key == key),
      },
      paymentMethods: all('payment').toSet(),
    );

    if (filters.activeFilters.isEmpty) return null;
    return FilterSuggestion(filters: filters, basedOn: used.length);
  }
}

class _Search {
  _Search(this.timestamp);

  final int timestamp;
  final filters = <({String type, String value})>{};
}
