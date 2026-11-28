import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/repositories/review_repository.dart';

/// Live rating, review count and comments for the restaurant detail.
///
/// The detail used to show the copy of the restaurant it was opened with, so
/// a review written from it never appeared. Now it listens to Firestore:
/// - the `reviews` of this restaurant, so a new review shows up right away
///   (marked as pending while it is offline);
/// - the restaurant document, so the rating and the count change when the
///   server confirms the review.
class RestaurantReviewsViewModel extends ChangeNotifier {
  RestaurantReviewsViewModel({
    required this.restaurant,
    ReviewRepository? repository,
  }) {
    final source = repository ?? ReviewRepository();
    _reviewsSubscription = source
        .watchReviews(restaurant.id)
        .listen(_onReviews, onError: (Object _) {});
    _statsSubscription = source
        .watchStats(restaurant.id)
        .listen(_onStats, onError: (Object _) {});
  }

  /// The restaurant the detail was opened with.
  final Restaurant restaurant;

  late final StreamSubscription<RestaurantReviewList> _reviewsSubscription;
  late final StreamSubscription<RestaurantStats?> _statsSubscription;

  List<RestaurantReview>? _liveReviews;
  double? _rating;
  int? _reviewCount;
  bool _isFromCache = false;
  bool _disposed = false;

  double get rating => _rating ?? restaurant.rating;

  int get reviewCount => _reviewCount ?? restaurant.reviewCount;

  /// Firestore reviews when there are any; otherwise the ones bundled with
  /// the restaurant (sample data).
  List<RestaurantReview> get reviews {
    final live = _liveReviews;
    return live == null || live.isEmpty ? restaurant.reviews : live;
  }

  /// True while the reviews come from the copy saved on the phone.
  bool get isFromCache => _isFromCache;

  bool get hasPendingReviews => reviews.any((review) => review.isPending);

  void _onReviews(RestaurantReviewList list) {
    _liveReviews = list.reviews;
    _isFromCache = list.isFromCache;
    _notify();
  }

  void _onStats(RestaurantStats? stats) {
    if (stats == null) return;
    _rating = stats.rating;
    _reviewCount = stats.reviewCount;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _reviewsSubscription.cancel();
    _statsSubscription.cancel();
    super.dispose();
  }
}
