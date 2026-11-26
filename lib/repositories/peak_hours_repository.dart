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

  static const _memoryTtl = Duration(minutes: 10);

  final ReviewRepository _reviews;
  final DateTime Function() _now;
  final Map<String, PeakHours> _memory = {};

  PeakHours? cached(String restaurantId) {
    final peakHours = _memory[restaurantId];
    if (peakHours == null) return null;
    if (_now().difference(peakHours.updatedAt) > _memoryTtl) {
      _memory.remove(restaurantId);
      return null;
    }
    return peakHours;
  }

  Future<PeakHours> fetch(String restaurantId) async {
    final result = await _reviews.getReviews(restaurantId);
    final reviews = result.reviews;
    final now = _now();

    final peakHours = await Isolate.run(
      () => PeakHours.fromReviews(restaurantId, reviews, now),
    );

    if (!result.isFromCache && reviews.isNotEmpty) {
      _memory[restaurantId] = peakHours;
    }

    return peakHours;
  }
}
