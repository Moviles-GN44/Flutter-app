import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:uniandes_food/models/restaurant.dart';

class ReviewException implements Exception {
  const ReviewException(this.message);

  final String message;
}

typedef ReviewList = ({List<Review> reviews, bool isFromCache});

typedef RestaurantReviewList = ({
  List<RestaurantReview> reviews,
  bool isFromCache,
});

typedef RestaurantStats = ({double rating, int reviewCount});

class ReviewRepository {
  ReviewRepository({FirebaseFirestore? firestore}) : _injected = firestore;

  static const _serverTimeout = Duration(seconds: 8);
  static final _published = StreamController<String>.broadcast();

  static Stream<String> get published => _published.stream;

  final FirebaseFirestore? _injected;

  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  Future<ReviewList> getReviews(String restaurantId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();
      final reviews = Timeline.timeSync(
        'ReviewRepository.parseReviews',
        () => [
          for (final doc in snapshot.docs)
            if (doc.data() case final data
                when WaitTime.names.containsKey(data['waitTime']))
              Review.fromMap(
                data,
                createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
              ),
        ],
      );
      return (reviews: reviews, isFromCache: snapshot.metadata.isFromCache);
    } on FirebaseException {
      return (reviews: const <Review>[], isFromCache: false);
    }
  }

  /// Reviews of the restaurant, pending first and then newest first.
  ///
  /// With metadata changes, a review written offline shows up right away
  /// marked as pending, and again when the server confirms it.
  Stream<RestaurantReviewList> watchReviews(String restaurantId) {
    try {
      return _firestore
          .collection('reviews')
          .where('restaurantId', isEqualTo: restaurantId)
          .snapshots(includeMetadataChanges: true)
          .map(
            (snapshot) => (
              reviews: [
                for (final doc in snapshot.docs)
                  _review(doc.data(), doc.metadata.hasPendingWrites),
              ]..sort(_newestFirst),
              isFromCache: snapshot.metadata.isFromCache,
            ),
          );
    } on FirebaseException catch (error) {
      return Stream<RestaurantReviewList>.error(error);
    }
  }

  /// Rating and review count from the restaurant document. They change when
  /// a new review reaches the server. Null when the document does not exist.
  Stream<RestaurantStats?> watchStats(String restaurantId) {
    try {
      return _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .snapshots()
          .map((doc) {
            final data = doc.data();
            if (data == null) return null;
            return (
              rating: (data['rating'] as num?)?.toDouble() ?? 0,
              reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
            );
          });
    } on FirebaseException catch (error) {
      return Stream<RestaurantStats?>.error(error);
    }
  }

  static RestaurantReview _review(Map<String, dynamic> data, bool isPending) {
    final author = data['userName'];
    final comment = data['comment'];
    final createdAt = data['createdAt'];
    return RestaurantReview(
      author: author is String && author.trim().isNotEmpty
          ? author.trim()
          : 'Student',
      comment: comment is String ? comment : '',
      verified: data['verified'] == true,
      rating: (data['rating'] as num?)?.round(),
      createdAt: switch (createdAt) {
        Timestamp() => createdAt.toDate(),
        int() => DateTime.fromMillisecondsSinceEpoch(createdAt),
        _ => null,
      },
      isPending: isPending,
    );
  }

  static int _newestFirst(RestaurantReview a, RestaurantReview b) {
    final aDate = a.createdAt;
    final bDate = b.createdAt;
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return -1;
    if (bDate == null) return 1;
    return bDate.compareTo(aDate);
  }

  Future<bool> addReview(Review review) async {
    final saved = _firestore.collection('reviews').add({
      ...review.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    unawaited(
      saved.then(
        (_) => _updateRestaurantRating(review),
        onError: (Object _) {},
      ),
    );

    try {
      await saved.timeout(_serverTimeout);
      _published.add(review.restaurantId);
      return true;
    } on TimeoutException {
      _published.add(review.restaurantId);
      return false;
    } on FirebaseException catch (error) {
      throw ReviewException(
        error.code == 'permission-denied'
            ? 'You do not have permission to publish reviews.'
            : 'We could not publish your review. Try again.',
      );
    }
  }

  static double newAverage(double rating, int count, int newRating) {
    final average = (rating * count + newRating) / (count + 1);
    return (average * 10).round() / 10;
  }

  Future<void> _updateRestaurantRating(Review review) async {
    final restaurant = _firestore
        .collection('restaurants')
        .doc(review.restaurantId);
    try {
      await _firestore
          .runTransaction((transaction) async {
            final data = (await transaction.get(restaurant)).data();
            if (data == null) return;
            final count = (data['reviewCount'] as num?)?.toInt() ?? 0;
            final rating = (data['rating'] as num?)?.toDouble() ?? 0;
            transaction.update(restaurant, {
              'rating': newAverage(rating, count, review.rating),
              'reviewCount': count + 1,
            });
          })
          .timeout(_serverTimeout);
    } on Exception {
      return;
    }
  }
}
