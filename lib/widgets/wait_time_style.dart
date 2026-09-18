import 'package:flutter/material.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/theme/app_colors.dart';

class WaitTimeStyle {
  const WaitTimeStyle({
    required this.icon,
    required this.accent,
    required this.tint,
    required this.text,
  });

  final IconData icon;
  final Color accent;
  final Color tint;
  final Color text;

  static WaitTimeStyle of(WaitTime wait) => switch (wait) {
    WaitTime.under5 => const WaitTimeStyle(
      icon: Icons.bolt_rounded,
      accent: AppColors.waitFast,
      tint: AppColors.waitFastTint,
      text: AppColors.waitFastText,
    ),
    WaitTime.fiveTo15 => const WaitTimeStyle(
      icon: Icons.hourglass_bottom_rounded,
      accent: AppColors.waitMedium,
      tint: AppColors.waitMediumTint,
      text: AppColors.waitMediumText,
    ),
    WaitTime.over15 => const WaitTimeStyle(
      icon: Icons.people_rounded,
      accent: AppColors.waitSlow,
      tint: AppColors.waitSlowTint,
      text: AppColors.waitSlowText,
    ),
  };
}
