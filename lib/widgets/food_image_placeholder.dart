import 'package:flutter/material.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/theme/app_colors.dart';

class RestaurantThumbnail extends StatelessWidget {
  const RestaurantThumbnail({
    super.key,
    required this.restaurant,
    this.aspectRatio = 4 / 3,
    this.radius = 12,
    this.iconSize = 32,
  });

  final Restaurant restaurant;
  final double aspectRatio;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final placeholder = FoodImagePlaceholder(
      icon: restaurant.foodIcon,
      aspectRatio: aspectRatio,
      radius: radius,
      iconSize: iconSize,
    );
    final asset = restaurant.imageAsset;
    if (asset == null) return placeholder;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          asset,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
          errorBuilder: (context, error, stackTrace) => placeholder,
        ),
      ),
    );
  }
}

class FoodImagePlaceholder extends StatelessWidget {
  const FoodImagePlaceholder({
    super.key,
    required this.icon,
    this.aspectRatio = 4 / 3,
    this.radius = 12,
    this.iconSize = 32,
  });

  final IconData icon;
  final double aspectRatio;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.blush,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Center(
          child: Icon(icon, size: iconSize, color: AppColors.placeholderIcon),
        ),
      ),
    );
  }
}
