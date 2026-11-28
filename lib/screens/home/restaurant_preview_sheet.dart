import 'package:flutter/material.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/screens/restaurant/restaurant_detail_screen.dart';
import 'package:uniandes_food/theme/app_colors.dart';
import 'package:uniandes_food/theme/app_text.dart';
import 'package:uniandes_food/widgets/food_image_placeholder.dart';
import 'package:uniandes_food/widgets/status_tag.dart';

/// Card with the selected restaurant, under the map.
///
/// It can be dragged by its handle: down to collapse it to the restaurant
/// summary (the map gets more room) and up to show the wait time notice and
/// the buttons again. Tapping the handle toggles it.
class RestaurantPreviewSheet extends StatefulWidget {
  const RestaurantPreviewSheet({
    super.key,
    required this.restaurant,
    required this.onSelectAlternative,
    required this.onViewMenu,
    required this.onViewWaitingTimeAlternative,
    this.alternative,
    this.reportedWait,
    this.reportCount = 0,
    this.reportsFromCache = false,
  });

  final Restaurant restaurant;
  final Restaurant? alternative;
  final WaitTime? reportedWait;
  final int reportCount;
  final bool reportsFromCache;
  final ValueChanged<Restaurant> onSelectAlternative;
  final VoidCallback onViewMenu;
  final VoidCallback onViewWaitingTimeAlternative;

  @override
  State<RestaurantPreviewSheet> createState() => _RestaurantPreviewSheetState();
}

class _RestaurantPreviewSheetState extends State<RestaurantPreviewSheet>
    with SingleTickerProviderStateMixin {
  static const _topPadding = 10.0;
  // Room for the scan button that is docked over the bottom of the card.
  static const _bottomPadding = 44.0;
  static const _snapVelocity = 600.0;

  final _contentKey = GlobalKey();
  final _headerKey = GlobalKey();

  /// 1 = open (everything visible), 0 = collapsed (only the summary).
  late final AnimationController _extent = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );

  double? _fullHeight;
  double? _collapsedHeight;

  @override
  void initState() {
    super.initState();
    _scheduleMeasure();
  }

  @override
  void didUpdateWidget(RestaurantPreviewSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new restaurant opens the card again; its content may have another
    // height (notice, alternative), so it is measured again.
    if (oldWidget.restaurant.id != widget.restaurant.id) _extent.value = 1;
    _scheduleMeasure();
  }

  @override
  void dispose() {
    _extent.dispose();
    super.dispose();
  }

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final content = _contentKey.currentContext?.findRenderObject();
      final header = _headerKey.currentContext?.findRenderObject();
      if (content is! RenderBox || header is! RenderBox) return;
      if (!content.hasSize || !header.hasSize) return;

      final full = content.size.height;
      final headerBottom =
          header.localToGlobal(Offset.zero, ancestor: content).dy +
          header.size.height;
      final collapsed = (headerBottom + _bottomPadding).clamp(0.0, full);
      if (full != _fullHeight || collapsed != _collapsedHeight) {
        setState(() {
          _fullHeight = full;
          _collapsedHeight = collapsed;
        });
      }
    });
  }

  double get _range {
    final full = _fullHeight;
    final collapsed = _collapsedHeight;
    if (full == null || collapsed == null) return 0;
    return full - collapsed;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final range = _range;
    if (range <= 0) return;
    _extent.value -= details.primaryDelta! / range;
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final open = velocity.abs() > _snapVelocity
        ? velocity < 0
        : _extent.value >= 0.5;
    _extent.animateTo(open ? 1 : 0, curve: Curves.easeOutCubic);
  }

  void _toggle() {
    _extent.animateTo(_extent.value < 0.5 ? 1 : 0, curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: DecoratedBox(
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
        child: AnimatedBuilder(
          animation: _extent,
          child: content,
          builder: (context, child) {
            final full = _fullHeight;
            final collapsed = _collapsedHeight;
            // Until it is measured, the card takes its natural height.
            if (full == null || collapsed == null) return child!;
            final height = collapsed + (full - collapsed) * _extent.value;
            return SizedBox(
              height: height,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: 0,
                  maxHeight: double.infinity,
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final restaurant = widget.restaurant;
    final alternative = widget.alternative;
    final reportedWait = widget.reportedWait;

    return Padding(
      key: _contentKey,
      padding: const EdgeInsets.fromLTRB(20, _topPadding, 20, _bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            key: _headerKey,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                button: true,
                label: 'Expand or collapse the restaurant card',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 6,
                    ),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _RestaurantSummary(
                  key: ValueKey(restaurant.id),
                  restaurant: restaurant,
                ),
              ),
            ],
          ),
          // Fades out while the card collapses, so nothing is left half
          // visible under the summary.
          FadeTransition(
            opacity: _extent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reportedWait != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.groups_rounded,
                        size: 18,
                        color: AppColors.tealDark,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${widget.reportsFromCache ? 'Saved reports' : 'Students report'} '
                          '${reportedWait.shortLabel} · '
                          '${widget.reportCount} '
                          '${widget.reportCount == 1 ? 'report' : 'reports'}'
                          '${widget.reportsFromCache ? ' (offline)' : ''}',
                          style: AppText.caption.copyWith(
                            color: AppColors.tealText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (alternative != null) ...[
                  const SizedBox(height: 16),
                  _CongestionNotice(
                    alternative: alternative,
                    onShow: () {
                      widget.onViewWaitingTimeAlternative();
                      widget.onSelectAlternative(alternative);
                    },
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          widget.onViewMenu();

                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => RestaurantDetailScreen(
                                restaurant: restaurant,
                              ),
                            ),
                          );
                        },
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
