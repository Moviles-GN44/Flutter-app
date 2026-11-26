import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path_provider/path_provider.dart';

import 'package:uniandes_food/models/peak_hours.dart';
import 'package:uniandes_food/repositories/review_repository.dart';

typedef PeakHoursResult = ({PeakHours peakHours, bool isFromCache});

class PeakHoursRepository {
  PeakHoursRepository({
    ReviewRepository? reviewRepository,
    Future<Directory> Function()? directory,
    DateTime Function()? now,
  }) : _reviews = reviewRepository ?? ReviewRepository(),
       _directory = directory ?? getApplicationSupportDirectory,
       _now = now ?? DateTime.now;

  static final instance = PeakHoursRepository();

  static const _memoryTtl = Duration(minutes: 10);

  final ReviewRepository _reviews;
  final Future<Directory> Function() _directory;
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

  Future<PeakHours?> saved(String restaurantId) async {
    try {
      final file = await _file(restaurantId);
      if (!await file.exists()) return null;
      final json = jsonDecode(await file.readAsString());
      return PeakHours.fromJson(json as Map<String, dynamic>);
    } on Exception {
      return null;
    }
  }

  Future<PeakHoursResult> fetch(String restaurantId) async {
    final result = await _reviews.getReviews(restaurantId);
    final reviews = result.reviews;
    final now = _now();

    final peakHours = await Isolate.run(
      () => PeakHours.fromReviews(restaurantId, reviews, now),
    );

    if (!result.isFromCache && reviews.isNotEmpty) {
      _memory[restaurantId] = peakHours;
      await _save(peakHours);
    }

    return (peakHours: peakHours, isFromCache: result.isFromCache);
  }

  Future<void> _save(PeakHours peakHours) async {
    try {
      final file = await _file(peakHours.restaurantId);
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(peakHours.toJson()));
    } on Exception {
      return;
    }
  }

  Future<File> _file(String restaurantId) async {
    final directory = await _directory();
    return File('${directory.path}/peak_hours/$restaurantId.json');
  }
}
