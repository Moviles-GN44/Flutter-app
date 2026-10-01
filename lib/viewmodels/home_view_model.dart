import 'package:flutter/foundation.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/repositories/restaurant_repository.dart';
import 'package:uniandes_food/repositories/review_repository.dart';
import 'package:uniandes_food/services/telemetry_service.dart';

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({
    RestaurantRepository? repository,
    TelemetryService? telemetryService,
    ReviewRepository? reviewRepository,
    Restaurant? initialRestaurant,
  }) : _repository = repository ?? const RestaurantRepository(),
       _telemetryService = telemetryService ?? TelemetryService(),
       _reviewRepository = reviewRepository ?? ReviewRepository(),
       _selectedRestaurant =
           initialRestaurant ??
           (repository ?? const RestaurantRepository())
               .getAllRestaurants()
               .first {
    loadReportedWait();
  }

  static const _reportMinutes = {
    WaitTime.under5: 3,
    WaitTime.fiveTo15: 10,
    WaitTime.over15: 20,
  };

  final RestaurantRepository _repository;
  final TelemetryService _telemetryService;
  final ReviewRepository _reviewRepository;

  Restaurant _selectedRestaurant;
  WaitTime? _reportedWait;
  int _reportCount = 0;

  Restaurant get selectedRestaurant => _selectedRestaurant;
  WaitTime? get reportedWait => _reportedWait;
  int get reportCount => _reportCount;

  List<Restaurant> get restaurants =>
      _repository.getAllRestaurants();

  Restaurant? get fasterAlternative {
    if (_selectedRestaurant.waitTime != WaitTime.over15) {
      return null;
    }

    return _repository.getFasterAlternative(_selectedRestaurant);
  }

  void selectRestaurant(Restaurant restaurant) {
    if (_selectedRestaurant.id == restaurant.id) {
      return;
    }

    _selectedRestaurant = restaurant;
    _reportedWait = null;
    _reportCount = 0;
    notifyListeners();
    loadReportedWait();
  }

  Future<void> loadReportedWait() async {
    final restaurantId = _selectedRestaurant.id;
    final reviews = await _reviewRepository.getReviews(restaurantId);
    if (restaurantId != _selectedRestaurant.id) return;

    final now = DateTime.now();
    var weightedMinutes = 0.0;
    var totalWeight = 0.0;
    var count = 0;
    for (final review in reviews) {
      final weight = _reportWeight(review, now);
      if (weight == 0) continue;
      weightedMinutes += _reportMinutes[review.waitTime]! * weight;
      totalWeight += weight;
      count++;
    }

    _reportCount = count;
    _reportedWait = totalWeight == 0
        ? null
        : _waitTimeFor(weightedMinutes / totalWeight);
    notifyListeners();
  }

  double _reportWeight(Review review, DateTime now) {
    final createdAt = review.createdAt ?? now;
    final age = now.difference(createdAt);
    final sameTimeOfDay = (createdAt.hour - now.hour).abs() <= 1;
    final recency = age.inMinutes <= 60
        ? 3.0
        : (age.inDays <= 14 && sameTimeOfDay ? 1.0 : 0.0);
    return review.verified ? recency * 2 : recency;
  }

  WaitTime _waitTimeFor(double minutes) {
    if (minutes < 5) return WaitTime.under5;
    if (minutes <= 15) return WaitTime.fiveTo15;
    return WaitTime.over15;
  }

  Future<void> trackComparisonCriterion(String criterion) async {
    await _telemetryService.trackComparisonCriterion(
      criterion: criterion,
      restaurantId: _selectedRestaurant.id,
    );
  }
}