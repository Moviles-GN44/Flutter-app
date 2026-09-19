import 'package:flutter/material.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/theme/app_colors.dart';
import 'package:uniandes_food/theme/app_text.dart';
import 'package:uniandes_food/widgets/wait_time_style.dart';

class StatusTag extends StatelessWidget {
  const StatusTag({
    super.key,
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    this.borderColor,
    this.semanticLabel,
  });

  factory StatusTag.wait(WaitTime wait) {
    final style = WaitTimeStyle.of(wait);
    return StatusTag(
      label: wait.label,
      icon: style.icon,
      background: style.tint,
      foreground: style.text,
      borderColor: style.accent.withValues(alpha: 0.4),
      semanticLabel: wait.spokenLabel,
    );
  }

  factory StatusTag.open({required bool isOpen}) => isOpen
      ? const StatusTag(
          label: 'OPEN',
          icon: Icons.storefront_rounded,
          background: AppColors.tealDark,
          foreground: AppColors.white,
          semanticLabel: 'Open now',
        )
      : const StatusTag(
          label: 'CLOSED',
          icon: Icons.storefront_outlined,
          background: AppColors.border,
          foreground: AppColors.textSecondary,
          semanticLabel: 'Closed now',
        );

  factory StatusTag.vegan() => const StatusTag(
    label: 'VEGAN',
    icon: Icons.eco_rounded,
    background: AppColors.tealTint,
    foreground: AppColors.tealText,
    semanticLabel: 'Vegan options available',
  );

  factory StatusTag.promo() => const StatusTag(
    label: 'PROMO',
    icon: Icons.sell_rounded,
    background: AppColors.amber,
    foreground: AppColors.shadowGrey,
    semanticLabel: 'Promotion available',
  );

  /// Outlined tag used for dietary claims on menu items ("NUT-FREE", …).
  factory StatusTag.dietary(String label) => StatusTag(
    label: label.toUpperCase(),
    icon: Icons.error_outline_rounded,
    background: AppColors.white,
    foreground: AppColors.dietary,
    borderColor: AppColors.dietary.withValues(alpha: 0.5),
    semanticLabel: '$label dish',
  );

  factory StatusTag.verifiedVisit() => const StatusTag(
    label: 'VERIFIED VISIT',
    icon: Icons.verified_rounded,
    background: AppColors.tealDark,
    foreground: AppColors.white,
    semanticLabel: 'Visit verified with the restaurant QR code',
  );

  factory StatusTag.unverifiedVisit() => const StatusTag(
    label: 'NOT VERIFIED',
    icon: Icons.info_outline_rounded,
    background: AppColors.border,
    foreground: AppColors.textSecondary,
    semanticLabel: 'Visit not verified',
  );

  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: borderColor == null ? null : Border.all(color: borderColor!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
            Text(label, style: AppText.tag.copyWith(color: foreground)),
          ],
        ),
      ),
    );
  }
}

class RatingPill extends StatelessWidget {
  const RatingPill({super.key, required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final value = rating.toStringAsFixed(1);
    return Semantics(
      label: 'Rated $value out of 5',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.amber,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              size: 14,
              color: AppColors.shadowGrey,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: AppText.tag.copyWith(
                fontSize: 12,
                color: AppColors.shadowGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
