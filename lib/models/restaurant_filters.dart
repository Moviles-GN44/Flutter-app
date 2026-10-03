import 'package:uniandes_food/models/restaurant.dart';

enum DietaryOption {
  vegan('Vegan', 'vegan'),
  glutenFree('Gluten-Free', 'gluten_free'),
  lactoseFree('Lactose-Free', 'lactose_free');

  const DietaryOption(this.label, this.key);

  final String label;

  /// Stable name stored in analytics events.
  final String key;

  bool isOfferedBy(Restaurant restaurant) => switch (this) {
    DietaryOption.vegan => restaurant.isVegan,
    DietaryOption.glutenFree => restaurant.isGlutenFree,
    DietaryOption.lactoseFree => restaurant.isLactoseFree,
  };
}

/// What the student asked for on the Explore screen. An empty value means
/// "any": no category, no walking limit, the full budget range, and so on.
class RestaurantFilters {
  const RestaurantFilters({
    this.category,
    this.maxWalkingMinutes,
    this.minPrice = minBudget,
    this.maxPrice = maxBudget,
    this.dietary = const {},
    this.paymentMethods = const {},
  });

  static const minBudget = 0;
  static const maxBudget = 50000;

  /// Null shows every category.
  final String? category;

  /// Null shows every distance.
  final int? maxWalkingMinutes;
  final int minPrice;
  final int maxPrice;

  /// The restaurant must offer all of these.
  final Set<DietaryOption> dietary;

  /// The restaurant must accept at least one of these (Firestore values such
  /// as `Cash`, `Cards`, `Nequi`).
  final Set<String> paymentMethods;

  bool get hasBudget => minPrice > minBudget || maxPrice < maxBudget;

  /// One entry per active filter, as analytics stores them (BQ9). The
  /// `type` groups filters (`dietary`, `price`…) and `value` says which one.
  List<({String type, String value})> get activeFilters => [
    if (category case final category?) (type: 'category', value: category),
    if (maxWalkingMinutes case final minutes?)
      (type: 'walking_time', value: '$minutes'),
    if (hasBudget) (type: 'price', value: '$minPrice-$maxPrice'),
    for (final option in dietary) (type: 'dietary', value: option.key),
    for (final method in paymentMethods) (type: 'payment', value: method),
  ];

  int get activeCount =>
      (category == null ? 0 : 1) +
      (maxWalkingMinutes == null ? 0 : 1) +
      (hasBudget ? 1 : 0) +
      dietary.length +
      paymentMethods.length;

  bool matches(Restaurant restaurant) {
    if (category != null && restaurant.category != category) return false;

    final limit = maxWalkingMinutes;
    if (limit != null && restaurant.walkingMinutes > limit) return false;

    // A restaurant without a known price is kept rather than hidden.
    final price = restaurant.averagePriceCop;
    if (hasBudget && price != null && (price < minPrice || price > maxPrice)) {
      return false;
    }

    if (!dietary.every((option) => option.isOfferedBy(restaurant))) {
      return false;
    }

    if (paymentMethods.isNotEmpty &&
        !restaurant.paymentMethods.any(paymentMethods.contains)) {
      return false;
    }

    return true;
  }
}
