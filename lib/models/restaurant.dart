import 'package:flutter/widgets.dart';

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
    required this.mapPosition,
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
  final Offset mapPosition;
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
  });

  final String restaurantId;
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final WaitTime waitTime;
  final List<String> tags;
  final bool verified;

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
