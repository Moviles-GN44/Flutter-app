import 'package:flutter/material.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/navigation/app_navigation.dart';
import 'package:uniandes_food/screens/review/scan_qr_screen.dart';
import 'package:uniandes_food/screens/review/write_review_screen.dart';
import 'package:uniandes_food/theme/app_colors.dart';
import 'package:uniandes_food/theme/app_text.dart';
import 'package:uniandes_food/utils/currency.dart';
import 'package:uniandes_food/widgets/app_bottom_nav.dart';
import 'package:uniandes_food/widgets/food_image_placeholder.dart';
import 'package:uniandes_food/widgets/status_tag.dart';

enum _DetailTab { menu, info, reviews }

class RestaurantDetailScreen extends StatefulWidget {
  const RestaurantDetailScreen({super.key, required this.restaurant});

  final Restaurant restaurant;

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  _DetailTab _tab = _DetailTab.menu;
  bool _favorite = false;

  Restaurant get _restaurant => widget.restaurant;

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ScanQrScreen(restaurant: _restaurant),
      ),
    );
  }

  void _writeReview() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            WriteReviewScreen(restaurant: _restaurant, verified: false),
      ),
    );
  }

  void _share() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Sharing ${_restaurant.name}…')));
  }

  void _toggleFavorite() {
    setState(() => _favorite = !_favorite);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _favorite
                ? '${_restaurant.name} added to favorites'
                : '${_restaurant.name} removed from favorites',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeroImage(
                      restaurant: _restaurant,
                      favorite: _favorite,
                      onBack: () => Navigator.of(context).maybePop(),
                      onShare: _share,
                      onToggleFavorite: _toggleFavorite,
                    ),
                    _SummaryCard(
                      restaurant: _restaurant,
                      tab: _tab,
                      onTabChanged: (tab) => setState(() => _tab = tab),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: switch (_tab) {
                        _DetailTab.menu => _MenuTab(restaurant: _restaurant),
                        _DetailTab.info => _InfoTab(restaurant: _restaurant),
                        _DetailTab.reviews => _ReviewsTab(
                          restaurant: _restaurant,
                        ),
                      },
                    ),
                  ],
                ),
              ),
            ),
            _ActionBar(onReview: _writeReview, onScan: _openScanner),
          ],
        ),
      ),
      floatingActionButton: ScanFab(onPressed: _openScanner),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AppBottomNav(
        currentIndex: null,
        onSelect: (index) => AppNavigation.goToTab(context, index),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({
    required this.restaurant,
    required this.favorite,
    required this.onBack,
    required this.onShare,
    required this.onToggleFavorite,
  });

  final Restaurant restaurant;
  final bool favorite;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          child: RestaurantThumbnail(
            restaurant: restaurant,
            aspectRatio: 16 / 11,
            radius: 0,
            iconSize: 64,
          ),
        ),
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Row(
            children: [
              _HeroButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Go back',
                onPressed: onBack,
              ),
              const Spacer(),
              _HeroButton(
                icon: Icons.share_outlined,
                tooltip: 'Share ${restaurant.name}',
                onPressed: onShare,
              ),
              const SizedBox(width: 10),
              _HeroButton(
                icon: favorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                tooltip: favorite
                    ? 'Remove from favorites'
                    : 'Save to favorites',
                onPressed: onToggleFavorite,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 40,
      child: IconButton.filled(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, size: 20),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.shadowGrey.withValues(alpha: 0.72),
          foregroundColor: AppColors.white,
          padding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.restaurant,
    required this.tab,
    required this.onTabChanged,
  });

  final Restaurant restaurant;
  final _DetailTab tab;
  final ValueChanged<_DetailTab> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: const BoxDecoration(color: AppColors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(restaurant.name, style: AppText.h1)),
              const SizedBox(width: 12),
              StatusTag.open(isOpen: restaurant.isOpen),
            ],
          ),
          const SizedBox(height: 4),
          Text(restaurant.category, style: AppText.caption),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 18, color: AppColors.amber),
              const SizedBox(width: 4),
              Text(
                restaurant.rating.toStringAsFixed(1),
                style: AppText.bodyStrong,
              ),
              const SizedBox(width: 12),
              Text('${restaurant.reviewCount} reviews', style: AppText.caption),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${restaurant.distanceMeters}m · '
                  '${restaurant.walkingMinutes} min from ML',
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _TabBar(current: tab, onChanged: onTabChanged),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.current, required this.onChanged});

  final _DetailTab current;
  final ValueChanged<_DetailTab> onChanged;

  static const _labels = {
    _DetailTab.menu: 'Menu',
    _DetailTab.info: 'Info',
    _DetailTab.reviews: 'Reviews',
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final tab in _DetailTab.values)
          Expanded(
            child: _TabButton(
              label: _labels[tab]!,
              selected: tab == current,
              onTap: () => onChanged(tab),
            ),
          ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.amber : AppColors.textSecondary;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppText.h3.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 3,
                width: 44,
                decoration: BoxDecoration(
                  color: selected ? AppColors.amber : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTab extends StatelessWidget {
  const _MenuTab({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    if (restaurant.menu.isEmpty) {
      return const _EmptyState(message: 'This menu is not published yet.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in restaurant.menu) ...[
          Text(section.title, style: AppText.h2),
          const SizedBox(height: 12),
          for (final item in section.items) ...[
            _MenuItemCard(item: item, fallbackIcon: restaurant.foodIcon),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
        ],
        Text(
          restaurant.address,
          textAlign: TextAlign.center,
          style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        Text('Accepted payment methods', style: AppText.h2),
        const SizedBox(height: 6),
        Text(
          restaurant.paymentMethods.join(' · '),
          style: AppText.body.copyWith(color: AppColors.amber),
        ),
      ],
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.item, required this.fallbackIcon});

  final MenuItem item;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final asset = item.imageAsset;
    final thumbnail = asset == null
        ? FoodImagePlaceholder(icon: fallbackIcon, aspectRatio: 1, radius: 10)
        : ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stackTrace) =>
                  FoodImagePlaceholder(
                    icon: fallbackIcon,
                    aspectRatio: 1,
                    radius: 10,
                  ),
            ),
          );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox.square(dimension: 64, child: thumbnail),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(item.name, style: AppText.h3)),
                    const SizedBox(width: 8),
                    Text(
                      formatCop(item.priceCop),
                      style: AppText.price.copyWith(color: AppColors.amber),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatusTag.wait(item.waitTime),
                    if (item.hasPromo) StatusTag.promo(),
                    for (final tag in item.dietaryTags) StatusTag.dietary(tag),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Information', style: AppText.h2),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.place_outlined,
                label: 'Address',
                value: restaurant.address,
              ),
              _InfoRow(
                icon: Icons.schedule_rounded,
                label: 'Opening hours',
                value: restaurant.schedule,
              ),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: restaurant.phone,
              ),
              _InfoRow(
                icon: Icons.credit_card_rounded,
                label: 'Payment methods',
                value: restaurant.paymentMethods.join(' · '),
                last: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.amber),
            const SizedBox(width: 12),
            Expanded(child: Text(value, style: AppText.bodyStrong)),
          ],
        ),
      ),
    );
  }
}

class _ReviewsTab extends StatelessWidget {
  const _ReviewsTab({required this.restaurant});

  final Restaurant restaurant;

  @override
  Widget build(BuildContext context) {
    final rounded = restaurant.rating.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reviews', style: AppText.h2),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(restaurant.rating.toStringAsFixed(1), style: AppText.h2),
                  const SizedBox(width: 8),
                  Semantics(
                    label:
                        'Rated ${restaurant.rating.toStringAsFixed(1)} '
                        'out of 5',
                    excludeSemantics: true,
                    child: Row(
                      children: [
                        for (var i = 1; i <= 5; i++)
                          Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: i <= rounded
                                ? AppColors.amber
                                : AppColors.border,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${restaurant.reviewCount} Reviews',
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption,
                    ),
                  ),
                ],
              ),
              if (restaurant.reviews.isEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'No comments yet. Be the first to leave one.',
                  style: AppText.caption,
                ),
              ],
              for (final review in restaurant.reviews) ...[
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(review.author, style: AppText.bodyStrong),
                    if (review.verified) StatusTag.verifiedVisit(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(review.comment, style: AppText.body),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(child: Text(message, style: AppText.caption)),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onReview, required this.onScan});

  final VoidCallback onReview;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: AppColors.background,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onReview,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.amber,
                side: const BorderSide(color: AppColors.amber, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Leave a review', style: AppText.button),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
              label: const Text('Scan QR', style: AppText.button),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.amber,
                foregroundColor: AppColors.shadowGrey,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
