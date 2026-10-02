import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:uniandes_food/models/restaurant.dart';

class ReviewException implements Exception {
  const ReviewException(this.message);

  final String message;
}

class ReviewRepository {
  ReviewRepository({FirebaseFirestore? firestore}) : _injected = firestore;

  static const _serverTimeout = Duration(seconds: 8);
  static final _published = StreamController<String>.broadcast();

  static Stream<String> get published => _published.stream;

  final FirebaseFirestore? _injected;

  FirebaseFirestore get _firestore => _injected ?? FirebaseFirestore.instance;

  Future<List<Review>> getReviews(String restaurantId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();
      return snapshot.docs.map((doc) {
        final createdAt = doc.data()['createdAt'] as Timestamp?;
        return Review.fromMap(doc.data(), createdAt: createdAt?.toDate());
      }).toList();
    } on FirebaseException {
      return const [];
    }
  }

  Future<bool> addReview(Review review) async {
    try {
      await _firestore
          .collection('reviews')
          .add({...review.toMap(), 'createdAt': FieldValue.serverTimestamp()})
          .timeout(_serverTimeout);
      unawaited(_updateRestaurantRating(review));
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
