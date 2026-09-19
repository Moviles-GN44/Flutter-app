import 'package:flutter/material.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/screens/restaurant/restaurant_detail_screen.dart';
import 'package:uniandes_food/theme/app_colors.dart';
import 'package:uniandes_food/theme/app_text.dart';
import 'package:uniandes_food/widgets/food_image_placeholder.dart';
import 'package:uniandes_food/widgets/status_tag.dart';

class RestaurantPreviewSheet extends StatelessWidget {
  const RestaurantPreviewSheet({
    super.key,
    required this.restaurant,
    required this.onSelectAlternative,
    this.alternative,
  });

  final Restaurant restaurant;
  final Restaurant? alternative;
  final ValueChanged<Restaurant> onSelectAlternative;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 44),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _RestaurantSummary(
              key: ValueKey(restaurant.id),
              restaurant: restaurant,
            ),
          ),
          if (alternative != null) ...[
            const SizedBox(height: 16),
            _CongestionNotice(
              alternative: alternative!,
              onShow: () => onSelectAlternative(alternative!),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          RestaurantDetailScreen(restaurant: restaurant),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('View full menu'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _SaveButton(key: ValueKey('save-${restaurant.id}')),
            ],
          ),
        ],
      ),
    );
  }
}

class _RestaurantSummary extends StatelessWidget {
  const _RestaurantSummary({super.key, required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          child: RestaurantThumbnail(restaurant: restaurant),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      restaurant.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.h2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  RatingPill(rating: restaurant.rating),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${restaurant.category} · ${restaurant.priceRange} · '
                '${restaurant.reviewCount} reviews',
                style: AppText.caption,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.directions_walk_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${restaurant.distanceMeters} m · '
                      '${restaurant.walkingMinutes} min from ML',
                      style: AppText.caption,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  StatusTag.wait(restaurant.waitTime),
                  StatusTag.open(isOpen: restaurant.isOpen),
                  if (restaurant.isVegan) StatusTag.vegan(),
                  if (restaurant.hasPromo) StatusTag.promo(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CongestionNotice extends StatelessWidget {
  const _CongestionNotice({required this.alternative, required this.onShow});

  final Restaurant alternative;
  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        decoration: BoxDecoration(
          color: AppColors.waitSlowTint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.waitSlow.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.people_rounded,
              size: 20,
              color: AppColors.waitSlowText,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Long queue right now',
                    style: AppText.bodyStrong.copyWith(
                      fontSize: 13,
                      color: AppColors.waitSlowText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${alternative.name} is ${alternative.walkingMinutes} min '
                    'away with under 5 min of wait.',
                    style: AppText.caption.copyWith(
                      color: AppColors.shadowGrey,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onShow, child: const Text('Show')),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  const _SaveButton({super.key});

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 52,
      child: IconButton.outlined(
        onPressed: () => setState(() => _saved = !_saved),
        tooltip: _saved ? 'Remove from favorites' : 'Save to favorites',
        icon: Icon(
          _saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        ),
        style: IconButton.styleFrom(
          foregroundColor: AppColors.shadowGrey,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
