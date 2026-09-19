import 'package:flutter/material.dart';

abstract final class AppNavigation {
  static final tab = ValueNotifier<int>(0);

  static void goToTab(BuildContext context, int index) {
    tab.value = index;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
