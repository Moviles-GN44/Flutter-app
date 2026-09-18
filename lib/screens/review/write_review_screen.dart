import 'package:flutter/material.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/navigation/app_navigation.dart';
import 'package:uniandes_food/theme/app_colors.dart';
import 'package:uniandes_food/theme/app_text.dart';
import 'package:uniandes_food/widgets/app_bottom_nav.dart';
import 'package:uniandes_food/widgets/dashed_border_painter.dart';
import 'package:uniandes_food/widgets/food_image_placeholder.dart';
import 'package:uniandes_food/widgets/status_tag.dart';
import 'package:uniandes_food/widgets/wait_time_style.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({
    super.key,
    required this.restaurant,
    required this.verified,
  });

  final Restaurant restaurant;
  final bool verified;

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  static const _tagOptions = [
    'Good portion',
    'Good price',
    'Fast service',
    'Nice atmosphere',
    'Friendly staff',
    'Healthy',
  ];

  final _commentController = TextEditingController();
  final Set<String> _tags = {};
  int _rating = 0;
  WaitTime? _wait;
  bool _hasPhoto = false;
  bool _publishing = false;

  bool get _canPublish => _rating > 0 && _wait != null && !_publishing;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picked = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.shadowGrey,
              ),
              title: const Text('Take a photo', style: AppText.bodyStrong),
              subtitle: const Text(
                'A square guide helps you frame the dish',
                style: AppText.caption,
              ),
              onTap: () => Navigator.of(context).pop(true),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.shadowGrey,
              ),
              title: const Text(
                'Choose from gallery',
                style: AppText.bodyStrong,
              ),
              onTap: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == true && mounted) {
      setState(() => _hasPhoto = true);
    }
  }

  Future<void> _publish() async {
    setState(() => _publishing = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    navigator.popUntil((route) => route.isFirst);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          _hasPhoto
              ? 'Review published. Your photo is uploading in the background.'
              : 'Review published. Thanks for helping other students!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          children: [
            _Header(
              restaurant: widget.restaurant,
              verified: widget.verified,
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 56),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RatingPicker(
                    rating: _rating,
                    onChanged: (value) => setState(() => _rating = value),
                  ),
                  const SizedBox(height: 28),
                  const Text('Your review', style: AppText.h3),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _commentController,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 300,
                    textCapitalization: TextCapitalization.sentences,
                    style: AppText.body,
                    decoration: _inputDecoration(
                      'Tell other students about the food, price and service',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Dish photo', style: AppText.h3),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _hasPhoto
                        ? _AttachedPhoto(
                            key: const ValueKey('attached'),
                            icon: widget.restaurant.foodIcon,
                            onRemove: () => setState(() => _hasPhoto = false),
                          )
                        : _PhotoDropZone(
                            key: const ValueKey('empty'),
                            onTap: _pickPhoto,
                          ),
                  ),
                  const SizedBox(height: 28),
                  const Text('How long did you wait?', style: AppText.h3),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final wait in WaitTime.values)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: wait == WaitTime.values.last ? 0 : 8,
                            ),
                            child: _WaitOption(
                              wait: wait,
                              selected: _wait == wait,
                              onTap: () => setState(() => _wait = wait),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text('Tags', style: AppText.h3),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in _tagOptions)
                        _TagChip(
                          label: tag,
                          selected: _tags.contains(tag),
                          onTap: () => setState(() {
                            if (!_tags.remove(tag)) _tags.add(tag);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _canPublish ? _publish : null,
                      child: _publishing
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.shadowGrey,
                              ),
                            )
                          : const Text('Publish review'),
                    ),
                  ),
                  if (!_canPublish && !_publishing)
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Center(
                        child: Text(
                          'Add a rating and your wait time to publish.',
                          style: AppText.caption,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const ScanFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onSelect: (index) => AppNavigation.goToTab(context, index),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: AppText.body.copyWith(color: AppColors.textSecondary),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.all(14),
      counterStyle: AppText.caption,
      enabledBorder: border(AppColors.border, 1),
      focusedBorder: border(AppColors.shadowGrey, 1.5),
      border: border(AppColors.border, 1),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.restaurant, required this.verified});

  final Restaurant restaurant;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                tooltip: 'Back',
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.shadowGrey,
                ),
              ),
              const Spacer(),
              verified ? StatusTag.verifiedVisit() : StatusTag.unverifiedVisit(),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('New review', style: AppText.h1),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      restaurant.name,
                      style: AppText.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
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

class _RatingPicker extends StatelessWidget {
  const _RatingPicker({required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int> onChanged;

  static const _labels = [
    'Tap a star to rate',
    'Poor',
    'Fair',
    'Good',
    'Very good',
    'Excellent',
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Text('RATE THE RESTAURANT', style: AppText.overline),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var star = 1; star <= 5; star++)
                IconButton(
                  onPressed: () => onChanged(star),
                  tooltip: '$star of 5 stars',
                  iconSize: 40,
                  padding: const EdgeInsets.all(4),
                  icon: _StarIcon(filled: star <= rating),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Semantics(
            liveRegion: true,
            child: Text(
              _labels[rating],
              style: AppText.bodyStrong.copyWith(
                color: rating == 0
                    ? AppColors.textSecondary
                    : AppColors.shadowGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StarIcon extends StatelessWidget {
  const _StarIcon({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (!filled) {
      return const Icon(
        Icons.star_outline_rounded,
        size: 40,
        color: AppColors.textSecondary,
      );
    }
    return const Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.star_rounded, size: 40, color: AppColors.amber),
        Icon(Icons.star_outline_rounded, size: 40, color: AppColors.shadowGrey),
      ],
    );
  }
}

class _PhotoDropZone extends StatelessWidget {
  const _PhotoDropZone({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Add a dish photo',
      excludeSemantics: true,
      child: Material(
        color: AppColors.photoDropTint,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: CustomPaint(
            painter: const DashedBorderPainter(
              color: AppColors.photoDropBorder,
            ),
            child: const SizedBox(
              width: double.infinity,
              height: 132,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_camera_outlined,
                    size: 28,
                    color: AppColors.shadowGrey,
                  ),
                  SizedBox(height: 8),
                  Text('Add a dish photo', style: AppText.bodyStrong),
                  SizedBox(height: 2),
                  Text('Square photos work best', style: AppText.caption),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachedPhoto extends StatelessWidget {
  const _AttachedPhoto({super.key, required this.icon, required this.onRemove});

  final IconData icon;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: FoodImagePlaceholder(
              icon: icon,
              aspectRatio: 1,
              iconSize: 28,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Photo added', style: AppText.bodyStrong),
                SizedBox(height: 2),
                Text(
                  'It will be resized to 1080 × 1080 and uploaded in the '
                  'background.',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove photo',
            icon: const Icon(Icons.close_rounded, color: AppColors.shadowGrey),
          ),
        ],
      ),
    );
  }
}

class _WaitOption extends StatelessWidget {
  const _WaitOption({
    required this.wait,
    required this.selected,
    required this.onTap,
  });

  final WaitTime wait;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = WaitTimeStyle.of(wait);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: selected ? style.text : AppColors.border,
        width: selected ? 2 : 1,
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: wait.spokenLabel,
      excludeSemantics: true,
      child: Material(
        color: selected ? style.tint : AppColors.background,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(
                  style.icon,
                  size: 20,
                  color: selected ? style.text : AppColors.textSecondary,
                ),
                const SizedBox(height: 4),
                Text(
                  wait.shortLabel,
                  style: AppText.tag.copyWith(
                    fontSize: 12,
                    color: selected ? style.text : AppColors.shadowGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = StadiumBorder(
      side: BorderSide(
        color: selected ? AppColors.amber : AppColors.border,
      ),
    );

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.amber : AppColors.background,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.shadowGrey,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: AppText.bodyStrong.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
