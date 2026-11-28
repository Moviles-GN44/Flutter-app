import 'package:flutter/material.dart';

abstract final class AppNavigation {
  static final tab = ValueNotifier<int>(0);

  static void goToTab(BuildContext context, int index) {
    tab.value = index;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Index of the Explore tab in the bottom bar.
  static const exploreTab = 1;

  /// Changes every time a screen asks Explore to show its filters.
  static final filtersRequest = ValueNotifier<int>(0);

  /// Opens Explore on the filter menu (the filter button on the map).
  static void openFilters(BuildContext context) {
    filtersRequest.value++;
    goToTab(context, exploreTab);
  }
}
