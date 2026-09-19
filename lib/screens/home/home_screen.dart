import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:uniandes_food/data/sample_restaurants.dart';
import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/screens/home/campus_map.dart';
import 'package:uniandes_food/screens/home/restaurant_preview_sheet.dart';
import 'package:uniandes_food/theme/app_colors.dart';
import 'package:uniandes_food/theme/app_text.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final Restaurant selected;
  final ValueChanged<Restaurant> onSelect;

  @override
  Widget build(BuildContext context) {
    final alternative = selected.waitTime == WaitTime.over15
        ? fasterAlternativeTo(selected)
        : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: AppColors.mapLand,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CampusMap(
                      restaurants: sampleRestaurants,
                      selected: selected,
                      onSelect: onSelect,
                    ),
                  ),
                  const Positioned(
                    left: 16,
                    right: 16,
                    top: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: _SearchRow(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            RestaurantPreviewSheet(
              restaurant: selected,
              alternative: alternative,
              onSelectAlternative: onSelect,
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  const _SearchRow();

  static final _floatingDecoration = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: const [
      BoxShadow(
        color: Color(0x1F1E232A),
        blurRadius: 16,
        offset: Offset(0, 6),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: _floatingDecoration,
            child: TextField(
              textInputAction: TextInputAction.search,
              style: AppText.body,
              decoration: InputDecoration(
                hintText: 'Search for a restaurant or dish',
                hintStyle: AppText.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.shadowGrey,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 52,
          height: 52,
          decoration: _floatingDecoration,
          child: IconButton(
            onPressed: () {},
            tooltip: 'Filters',
            icon: const Icon(Icons.tune_rounded, color: AppColors.shadowGrey),
          ),
        ),
      ],
    );
  }
}
