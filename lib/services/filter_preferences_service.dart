
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uniandes_food/models/restaurant_filters.dart';

class FilterPreferencesService {
  FilterPreferencesService({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const String _storageKey = 'explore_saved_filters';

  final SharedPreferencesAsync _preferences;

  Future<void> saveFilters(RestaurantFilters filters) async {
    final data = {
      'category': filters.category,
      'maxWalkingMinutes': filters.maxWalkingMinutes,
      'minPrice': filters.minPrice,
      'maxPrice': filters.maxPrice,
      'dietary': filters.dietary.map((item) => item.key).toList(),
      'paymentMethods': filters.paymentMethods.toList(),
    };

    await _preferences.setString(_storageKey, jsonEncode(data));
  }

  Future<RestaurantFilters> loadFilters() async {
    final saved = await _preferences.getString(_storageKey);

    if (saved == null) {
      return const RestaurantFilters();
    }

    try {
      final decoded = jsonDecode(saved);

      if (decoded is! Map<String, dynamic>) {
        return const RestaurantFilters();
      }

      final rawMin = decoded['minPrice'];
      final rawMax = decoded['maxPrice'];
      final minPrice = rawMin is int
          ? rawMin.clamp(
              RestaurantFilters.minBudget,
              RestaurantFilters.maxBudget,
            ).toInt()
          : RestaurantFilters.minBudget;
      final maxPrice = rawMax is int
          ? rawMax.clamp(
              RestaurantFilters.minBudget,
              RestaurantFilters.maxBudget,
            ).toInt()
          : RestaurantFilters.maxBudget;

      final savedDietary = decoded['dietary'];
      final savedPayments = decoded['paymentMethods'];
      final savedWalkingTime = decoded['maxWalkingMinutes'];

      return RestaurantFilters(
        category: decoded['category'] is String
            ? decoded['category'] as String
            : null,
        maxWalkingMinutes:
            savedWalkingTime is int &&
                const [5, 10, 15].contains(savedWalkingTime)
            ? savedWalkingTime
            : null,
        minPrice: minPrice <= maxPrice
            ? minPrice
            : RestaurantFilters.minBudget,
        maxPrice: minPrice <= maxPrice
            ? maxPrice
            : RestaurantFilters.maxBudget,
        dietary: savedDietary is List
            ? DietaryOption.values
                .where((option) => savedDietary.contains(option.key))
                .toSet()
            : <DietaryOption>{},
        paymentMethods: savedPayments is List
            ? savedPayments
                .whereType<String>()
                .where(
                  (method) =>
                      const ['Cash', 'Cards', 'Nequi'].contains(method),
                )
                .toSet()
            : <String>{},
      );
    } on FormatException {
      return const RestaurantFilters();
    } on TypeError {
      return const RestaurantFilters();
    }
  }

  Future<void> clearFilters() async {
    await _preferences.remove(_storageKey);
  }
}
