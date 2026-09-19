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
}
