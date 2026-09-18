import 'package:flutter/material.dart';

import 'package:uniandes_food/theme/app_colors.dart';

abstract final class AppText {
  static const headingFont = 'PlusJakartaSans';
  static const bodyFont = 'Inter';

  static const h1 = TextStyle(
    fontFamily: headingFont,
    fontSize: 26,
    fontWeight: FontWeight.w800,
    height: 32 / 26,
    color: AppColors.shadowGrey,
  );

  static const h2 = TextStyle(
    fontFamily: headingFont,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 24 / 18,
    color: AppColors.shadowGrey,
  );

  static const h3 = TextStyle(
    fontFamily: headingFont,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 20 / 15,
    color: AppColors.shadowGrey,
  );

  static const body = TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 21 / 14,
    color: AppColors.shadowGrey,
  );

  static const bodyStrong = TextStyle(
    fontFamily: bodyFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 20 / 14,
    color: AppColors.shadowGrey,
  );

  static const price = TextStyle(
    fontFamily: bodyFont,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 20 / 16,
    color: AppColors.shadowGrey,
  );

  static const caption = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    color: AppColors.textSecondary,
  );

  static const overline = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 16 / 12,
    letterSpacing: 1.2,
    color: AppColors.textSecondary,
  );

  static const tag = TextStyle(
    fontFamily: bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 14 / 11,
    letterSpacing: 0.4,
  );

  static const button = TextStyle(
    fontFamily: headingFont,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 16 / 14,
  );

  static const navLabel = TextStyle(
    fontFamily: bodyFont,
    fontSize: 12,
    height: 16 / 12,
  );
}
