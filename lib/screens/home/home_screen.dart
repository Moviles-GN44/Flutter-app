import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:uniandes_food/screens/home/campus_map.dart';
import 'package:uniandes_food/screens/home/restaurant_preview_sheet.dart';
import 'package:uniandes_food/theme/app_colors.dart';
import 'package:uniandes_food/theme/app_text.dart';
import 'package:uniandes_food/viewmodels/home_view_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.viewModel,
  });

  final HomeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
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
                      restaurants: viewModel.restaurants,
                      selected: viewModel.selectedRestaurant,
                      onSelect: (restaurant) {
                        viewModel.selectRestaurant(restaurant);
                        viewModel.trackComparisonCriterion('distance');
                      },
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
            if (viewModel.selectedRestaurant case final selected?)
              RestaurantPreviewSheet(
                restaurant: selected,
                alternative: viewModel.fasterAlternative,
                reportedWait: viewModel.reportedWait,
                reportCount: viewModel.reportCount,
                onSelectAlternative: viewModel.selectRestaurant,
                onViewMenu: () {
                  viewModel.trackComparisonCriterion('menu');
                },
                onViewWaitingTimeAlternative: () {
                  viewModel.trackComparisonCriterion('waiting_time');
                },
              )
            else
              const _NoSelectionSheet(),
          ],
        ),
      ),
    );
  }
}

/// Shown until the student picks a restaurant on the map.
class _NoSelectionSheet extends StatelessWidget {
  const _NoSelectionSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 44),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F1E232A),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.tealTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.touch_app_rounded,
              color: AppColors.tealDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Pick a restaurant', style: AppText.h2),
                const SizedBox(height: 2),
                Text(
                  'Tap a pin on the map to see its menu, wait time and '
                  'distance.',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
        ],
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
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15,
                ),
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
            icon: const Icon(
              Icons.tune_rounded,
              color: AppColors.shadowGrey,
            ),
          ),
        ),
      ],
    );
  }
}