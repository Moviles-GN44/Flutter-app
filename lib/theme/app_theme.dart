import 'package:flutter/material.dart';

import 'package:uniandes_food/theme/app_colors.dart';
import 'package:uniandes_food/theme/app_text.dart';

ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.amber,
    onPrimary: AppColors.shadowGrey,
    secondary: AppColors.teal,
    onSecondary: AppColors.shadowGrey,
    surface: AppColors.white,
    onSurface: AppColors.shadowGrey,
    error: AppColors.waitSlowText,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: AppText.bodyFont,
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.shadowGrey,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.amber,
        foregroundColor: AppColors.shadowGrey,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.textSecondary,
        minimumSize: const Size(64, 52),
        textStyle: AppText.button,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.shadowGrey,
        textStyle: AppText.button,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.shadowGrey,
      contentTextStyle: AppText.body.copyWith(color: AppColors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
