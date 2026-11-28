import 'package:flutter/material.dart';

import 'package:uniandes_food/models/my_review.dart';
import 'package:uniandes_food/theme/app_colors.dart';
import 'package:uniandes_food/theme/app_text.dart';
import 'package:uniandes_food/viewmodels/my_reviews_view_model.dart';

/// Every review the signed-in student wrote, with its sync state.
///
/// Opened from the My Reviews button in Profile. Mirrors the My Reviews view
/// of the Kotlin app.
class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key, required this.uid});

  final String uid;

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  late final MyReviewsViewModel _viewModel = MyReviewsViewModel(
    uid: widget.uid,
  );

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        title: const Text('My Reviews', style: AppText.h2),
      ),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) => _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final summary = _viewModel.summary;

    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final error = _viewModel.errorMessage;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(
          'Reviews you wrote in Uniandes Food',
          style: AppText.caption,
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(error, style: AppText.caption),
        ],
        const SizedBox(height: 16),
        _StatsRow(summary: summary ?? MyReviewsSummary.empty),
        const SizedBox(height: 16),
        if (summary == null || summary.isEmpty)
          if (error == null)
            const _EmptyState()
          else
            const SizedBox.shrink()
        else ...[
          for (final review in summary.reviews) ...[
            _ReviewCard(review: review),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.summary});

  final MyReviewsSummary summary;

  @override
  Widget build(BuildContext context) {
    final average = summary.average;
    return Row(
      children: [
        Expanded(
          child: _StatCard(value: '${summary.total}', label: 'Total'),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: average == null ? '–' : average.toStringAsFixed(1),
            label: 'Average',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(value: '${summary.pending}', label: 'Pending'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(value, style: AppText.h2),
            const SizedBox(height: 2),
            Text(label, style: AppText.caption),
          ],
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final MyReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(review.displayName, style: AppText.h3)),
              const SizedBox(width: 8),
              _SyncTag(isPending: review.isPending),
            ],
          ),
          const SizedBox(height: 6),
          _Stars(rating: review.rating),
          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(review.comment.trim(), style: AppText.body),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  review.createdAt == null
                      ? 'Waiting to sync'
                      : _formatDate(review.createdAt!),
                  style: AppText.caption,
                ),
              ),
              if (review.verified)
                Text(
                  'Verified visit',
                  style: AppText.caption.copyWith(
                    color: AppColors.tealText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Rating $rating out of 5',
      excludeSemantics: true,
      child: Row(
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 18,
              color: i <= rating ? AppColors.amber : AppColors.disabled,
            ),
          const SizedBox(width: 6),
          Text('$rating/5', style: AppText.caption),
        ],
      ),
    );
  }
}

class _SyncTag extends StatelessWidget {
  const _SyncTag({required this.isPending});

  final bool isPending;

  @override
  Widget build(BuildContext context) {
    final background = isPending
        ? AppColors.waitMediumTint
        : AppColors.waitFastTint;
    final foreground = isPending
        ? AppColors.waitMediumText
        : AppColors.waitFastText;

    return Semantics(
      label: isPending
          ? 'Pending, it will be sent when you are online'
          : 'Sent',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPending ? Icons.schedule_rounded : Icons.check_rounded,
              size: 13,
              color: foreground,
            ),
            const SizedBox(width: 4),
            Text(
              isPending ? 'Pending' : 'Sent',
              style: AppText.tag.copyWith(color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          const Icon(
            Icons.rate_review_outlined,
            size: 40,
            color: AppColors.disabled,
          ),
          const SizedBox(height: 10),
          const Text('No reviews yet', style: AppText.h3),
          const SizedBox(height: 4),
          Text(
            'Scan a restaurant QR code to write your first review.',
            style: AppText.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} '
      '${two(date.hour)}:${two(date.minute)}';
}
