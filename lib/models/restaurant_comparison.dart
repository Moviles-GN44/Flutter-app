import 'package:uniandes_food/models/restaurant.dart';

class RestaurantComparison {
  final Restaurant firstRestaurant;
  final Restaurant secondRestaurant;

  const RestaurantComparison({
    required this.firstRestaurant,
    required this.secondRestaurant,
  });

  bool get isValid => firstRestaurant.id != secondRestaurant.id;
}