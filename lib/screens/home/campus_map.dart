import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/theme/app_colors.dart';
import 'package:uniandes_food/theme/app_text.dart';

class CampusMap extends StatelessWidget {
  const CampusMap({
    super.key,
    required this.restaurants,
    required this.selected,
    required this.onSelect,
  });

  final List<Restaurant> restaurants;
  final Restaurant selected;
  final ValueChanged<Restaurant> onSelect;

  static const _mapAsset = 'assets/images/campus_map.png';
  static const _mapSize = Size(804, 840);
  static const _focus = Offset(0.52, 0.52);
  static const _zoom = 1.3;
  static const _userLocation = Offset(0.26, 0.45);
  static const _pinBoxWidth = 160.0;
  static const _pinBoxHeight = 94.0;
  static const _pinSize = 44.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final scale =
            math.max(width / _mapSize.width, height / _mapSize.height) *
            _zoom;
        final drawnWidth = _mapSize.width * scale;
        final drawnHeight = _mapSize.height * scale;
        final originX = (width / 2 - _focus.dx * drawnWidth).clamp(
          width - drawnWidth,
          0.0,
        );
        final originY = (height / 2 - _focus.dy * drawnHeight).clamp(
          height - drawnHeight,
          0.0,
        );

        Offset toScreen(Offset fraction) => Offset(
          originX + fraction.dx * drawnWidth,
          originY + fraction.dy * drawnHeight,
        );

        final ordered = [
          ...restaurants.where((r) => r.id != selected.id),
          selected,
        ];
        final user = toScreen(_userLocation);

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: originX,
              top: originY,
              width: drawnWidth,
              height: drawnHeight,
              child: Image.asset(
                _mapAsset,
                fit: BoxFit.fill,
                semanticLabel:
                    'Illustrated map of the Universidad de los Andes campus',
              ),
            ),
            Positioned(
              left: user.dx - 14,
              top: user.dy - 14,
              child: const _UserLocationMarker(),
            ),
            for (final restaurant in ordered)
              Builder(
                builder: (context) {
                  final point = toScreen(restaurant.mapPosition);
                  return Positioned(
                    left: point.dx - _pinBoxWidth / 2,
                    top: point.dy - _pinBoxHeight + _pinSize / 2,
                    width: _pinBoxWidth,
                    height: _pinBoxHeight,
                    child: _RestaurantPin(
                      restaurant: restaurant,
                      selected: restaurant.id == selected.id,
                      size: _pinSize,
                      onTap: () => onSelect(restaurant),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _RestaurantPin extends StatelessWidget {
  const _RestaurantPin({
    required this.restaurant,
    required this.selected,
    required this.size,
    required this.onTap,
  });

  final Restaurant restaurant;
  final bool selected;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final markerSize = selected ? size : 36.0;
    return Semantics(
      button: true,
      selected: selected,
      label: '${restaurant.name}, ${restaurant.waitTime.spokenLabel}',
      excludeSemantics: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (selected) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.amber,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x291E232A),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                restaurant.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.tag.copyWith(
                  fontSize: 12,
                  color: AppColors.shadowGrey,
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: SizedBox.square(
              dimension: size,
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  width: markerSize,
                  height: markerSize,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.amber : AppColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.white : AppColors.shadowGrey,
                      width: selected ? 3 : 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x331E232A),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    restaurant.foodIcon,
                    size: selected ? 22 : 18,
                    color: AppColors.shadowGrey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserLocationMarker extends StatelessWidget {
  const _UserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Your location, next to Mario Laserna',
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.teal.withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.tealDark,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 3),
          ),
        ),
      ),
    );
  }
}
