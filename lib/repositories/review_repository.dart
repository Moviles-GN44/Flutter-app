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
      return true;
    } on TimeoutException {
      return false;
    } on FirebaseException catch (error) {
      throw ReviewException(
        error.code == 'permission-denied'
            ? 'You do not have permission to publish reviews.'
            : 'We could not publish your review. Try again.',
      );
    }
  }
}
