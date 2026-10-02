import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:uniandes_food/data/campus.dart';
import 'package:uniandes_food/utils/currency.dart';

enum WaitTime {
  under5('UNDER 5 MIN', '< 5 min', 'Wait time under 5 minutes'),
  fiveTo15('5–15 MIN', '5–15 min', 'Wait time between 5 and 15 minutes'),
  over15('OVER 15 MIN', '> 15 min', 'Wait time over 15 minutes');

  const WaitTime(this.label, this.shortLabel, this.spokenLabel);

  final String label;
  final String shortLabel;
  final String spokenLabel;
}

class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.category,
    required this.priceRange,
    required this.distanceMeters,
    required this.walkingMinutes,
    required this.rating,
    required this.reviewCount,
    required this.waitTime,
    required this.isOpen,
    required this.foodIcon,
    required this.location,
    this.imageAsset,
    this.isVegan = false,
    this.hasPromo = false,
    this.address = '',
    this.schedule = '',
    this.phone = '',
    this.paymentMethods = const <String>[],
    this.menu = const <MenuSection>[],
    this.reviews = const <RestaurantReview>[],
  });

  factory Restaurant.fromFirestore(String id, Map<String, dynamic> data) {
    final category = data['category'] as String? ?? '';
    final averagePrice = (data['averagePriceCOP'] as num?)?.toInt();
    final latitude = (data['latitude'] as num?)?.toDouble();
    final longitude = (data['longitude'] as num?)?.toDouble();
    final location = latitude == null || longitude == null
        ? null
        : LatLng(latitude, longitude);
    final walks = data['walkDistancesFromBuilding'];
    final waitTime = switch (data['waitTimeCategory']) {
      'FAST' => WaitTime.under5,
      'LONG' => WaitTime.over15,
      _ => WaitTime.fiveTo15,
    };

    return Restaurant(
      id: id,
      name: data['name'] as String? ?? id,
      category: category,
      priceRange: averagePrice == null ? '' : formatCop(averagePrice),
      distanceMeters: location == null
          ? 0
          : _distance(defaultUserLocation, location).round(),
      walkingMinutes: walks is Map
          ? (walks[defaultUserBuilding] as num?)?.toInt() ?? 0
          : 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
      waitTime: waitTime,
      // Firestore has no opening hours yet.
      isOpen: true,
      foodIcon: _iconFor(category),
      location: location ?? campusCenter,
      isVegan: data['isVeganFriendly'] as bool? ?? false,
      paymentMethods: [
        for (final method in data['paymentMethods'] as List? ?? const [])
          '$method',
      ],
      menu: _menuFrom(data['menu'], waitTime),
    );
  }

  static const _distance = Distance();

  static IconData _iconFor(String category) {
    return switch (category) {
      'Fast Food' => Icons.lunch_dining_outlined,
      'Executive Lunch' => Icons.rice_bowl_outlined,
      _ => Icons.restaurant_outlined,
    };
  }

  static List<MenuSection> _menuFrom(Object? menu, WaitTime waitTime) {
    if (menu is! List || menu.isEmpty) return const [];

    return [
      MenuSection(
        title: 'Menu',
        items: [
          for (final dish in menu.whereType<Map>())
            MenuItem(
              name: dish['name'] as String? ?? '',
              description: dish['description'] as String? ?? '',
              priceCop: (dish['priceCOP'] as num?)?.toInt() ?? 0,
              waitTime: waitTime,
              dietaryTags: [
                if (dish['isVegan'] == true) 'Vegan',
                if (dish['isGlutenFree'] == true) 'Gluten-Free',
                if (dish['isLactoseFree'] == true) 'Lactose-Free',
              ],
            ),
        ],
      ),
    ];
  }

  final String id;
  final String name;
  final String category;
  final String priceRange;
  final int distanceMeters;
  final int walkingMinutes;
  final double rating;
  final int reviewCount;
  final WaitTime waitTime;
  final bool isOpen;
  final IconData foodIcon;
  final LatLng location;
  final String? imageAsset;
  final bool isVegan;
  final bool hasPromo;
  final String address;
  final String schedule;
  final String phone;
  final List<String> paymentMethods;
  final List<MenuSection> menu;
  final List<RestaurantReview> reviews;
}

class MenuItem {
  const MenuItem({
    required this.name,
    required this.description,
    required this.priceCop,
    required this.waitTime,
    this.imageAsset,
    this.hasPromo = false,
    this.dietaryTags = const <String>[],
  });

  final String name;
  final String description;
  final int priceCop;
  final WaitTime waitTime;
  final String? imageAsset;
  final bool hasPromo;
  final List<String> dietaryTags;
}

class MenuSection {
  const MenuSection({required this.title, required this.items});

  final String title;
  final List<MenuItem> items;
}

class RestaurantReview {
  const RestaurantReview({
    required this.author,
    required this.comment,
    this.verified = false,
  });

  final String author;
  final String comment;
  final bool verified;
}

class Review {
  const Review({
    required this.restaurantId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.waitTime,
    required this.tags,
    required this.verified,
    this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> data, {DateTime? createdAt}) {
    return Review(
      restaurantId: data['restaurantId'] as String,
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      rating: data['rating'] as int,
      comment: data['comment'] as String,
      waitTime: WaitTime.values.byName(data['waitTime'] as String),
      tags: List<String>.from(data['tags'] as List),
      verified: data['verified'] as bool,
      createdAt: createdAt,
    );
  }

  final String restaurantId;
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final WaitTime waitTime;
  final List<String> tags;
  final bool verified;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return {
      'restaurantId': restaurantId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'waitTime': waitTime.name,
      'tags': tags,
      'verified': verified,
      'platform': 'Flutter',
    };
  }
}
