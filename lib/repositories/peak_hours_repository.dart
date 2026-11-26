import 'dart:isolate';

import 'package:uniandes_food/models/peak_hours.dart';
import 'package:uniandes_food/repositories/review_repository.dart';

class PeakHoursRepository {
  PeakHoursRepository({
    ReviewRepository? reviewRepository,
    DateTime Function()? now,
  }) : _reviews = reviewRepository ?? ReviewRepository(),
       _now = now ?? DateTime.now;

  static final instance = PeakHoursRepository();

  final ReviewRepository _reviews;
  final DateTime Function() _now;

  Future<PeakHours> fetch(String restaurantId) async {
    final result = await _reviews.getReviews(restaurantId);
    final reviews = result.reviews;
    final now = _now();

    return Isolate.run(
      () => PeakHours.fromReviews(restaurantId, reviews, now),
    );
  }
}
