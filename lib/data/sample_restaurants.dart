import 'package:flutter/material.dart';

import 'package:uniandes_food/models/restaurant.dart';

const sampleRestaurants = <Restaurant>[
  Restaurant(
    id: 'el-corral',
    name: 'El Corral Uniandes',
    category: 'Burgers',
    priceRange: r'$$',
    distanceMeters: 250,
    walkingMinutes: 3,
    rating: 4.2,
    reviewCount: 187,
    waitTime: WaitTime.fiveTo15,
    isOpen: true,
    foodIcon: Icons.lunch_dining_outlined,
    mapPosition: Offset(0.56, 0.43),
    imageAsset: 'assets/images/el_corral.png',
  ),
  Restaurant(
    id: 'verde-bowl',
    name: 'Verde Bowl',
    category: 'Healthy',
    priceRange: r'$$',
    distanceMeters: 180,
    walkingMinutes: 2,
    rating: 4.6,
    reviewCount: 94,
    waitTime: WaitTime.under5,
    isOpen: true,
    foodIcon: Icons.rice_bowl_outlined,
    mapPosition: Offset(0.45, 0.56),
    isVegan: true,
  ),
  Restaurant(
    id: 'sushi-nikkei',
    name: 'Sushi Nikkei',
    category: 'Japanese',
    priceRange: r'$$$',
    distanceMeters: 420,
    walkingMinutes: 6,
    rating: 4.4,
    reviewCount: 132,
    waitTime: WaitTime.over15,
    isOpen: true,
    foodIcon: Icons.set_meal_outlined,
    mapPosition: Offset(0.74, 0.50),
  ),
  Restaurant(
    id: 'wok',
    name: 'Wok',
    category: 'Asian',
    priceRange: r'$$',
    distanceMeters: 330,
    walkingMinutes: 5,
    rating: 4.1,
    reviewCount: 76,
    waitTime: WaitTime.fiveTo15,
    isOpen: true,
    foodIcon: Icons.ramen_dining_outlined,
    mapPosition: Offset(0.33, 0.63),
    hasPromo: true,
  ),
  Restaurant(
    id: 'arepas-seneca',
    name: 'Arepas Séneca',
    category: 'Colombian',
    priceRange: r'$',
    distanceMeters: 290,
    walkingMinutes: 4,
    rating: 4.3,
    reviewCount: 58,
    waitTime: WaitTime.under5,
    isOpen: false,
    foodIcon: Icons.bakery_dining_outlined,
    mapPosition: Offset(0.64, 0.69),
  ),
];

Restaurant? fasterAlternativeTo(Restaurant restaurant) {
  final candidates = sampleRestaurants
      .where(
        (r) =>
            r.id != restaurant.id &&
            r.isOpen &&
            r.waitTime == WaitTime.under5,
      )
      .toList()
    ..sort((a, b) => a.walkingMinutes.compareTo(b.walkingMinutes));
  return candidates.isEmpty ? null : candidates.first;
}

List<Restaurant> nearbyRestaurants({int limit = 4}) {
  final sorted = [...sampleRestaurants]
    ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
  return sorted.take(limit).toList();
}
