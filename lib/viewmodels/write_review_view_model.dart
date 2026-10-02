import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/repositories/auth_repository.dart';
import 'package:uniandes_food/repositories/review_repository.dart';
import 'package:uniandes_food/services/telemetry_service.dart';

enum PublishOutcome { published, savedOffline, failed }

class WriteReviewViewModel extends ChangeNotifier {
  WriteReviewViewModel({
    required this.restaurant,
    required this.verified,
    ReviewRepository? repository,
    AuthRepository? authRepository,
    TelemetryService? telemetryService,
  }) : _repository = repository ?? ReviewRepository(),
       _authRepository = authRepository ?? AuthRepository.instance,
       _telemetryService = telemetryService ?? TelemetryService() {
    _track('review_started');
  }

  static const tagOptions = [
    'Good portion',
    'Good price',
    'Fast service',
    'Nice atmosphere',
    'Friendly staff',
    'Healthy',
  ];

  final Restaurant restaurant;
  final bool verified;
  final ReviewRepository _repository;
  final AuthRepository _authRepository;
  final TelemetryService _telemetryService;

  final Set<String> _tags = {};
  int _rating = 0;
  WaitTime? _waitTime;
  bool _isPublishing = false;
  String? _errorMessage;

  int get rating => _rating;
  WaitTime? get waitTime => _waitTime;
  Set<String> get tags => Set.unmodifiable(_tags);
  bool get isPublishing => _isPublishing;
  String? get errorMessage => _errorMessage;
  bool get canPublish => _rating > 0 && _waitTime != null && !_isPublishing;

  void setRating(int value) {
    _rating = value;
    notifyListeners();
  }

  void setWaitTime(WaitTime value) {
    _waitTime = value;
    notifyListeners();
  }

  void toggleTag(String tag) {
    if (!_tags.remove(tag)) _tags.add(tag);
    notifyListeners();
  }

  Future<PublishOutcome> publish(String comment) async {
    if (!canPublish) return PublishOutcome.failed;

    final user = _authRepository.currentUser;
    if (user == null) {
      _errorMessage = 'Sign in to publish your review.';
      notifyListeners();
      return PublishOutcome.failed;
    }

    _isPublishing = true;
    _errorMessage = null;
    notifyListeners();

    final review = Review(
      restaurantId: restaurant.id,
      userId: user.uid,
      userName: user.name,
      rating: _rating,
      comment: comment.trim(),
      waitTime: _waitTime!,
      tags: _tags.toList(),
      verified: verified,
    );

    try {
      final confirmed = await _repository.addReview(review);
      _track('review_published');
      return confirmed ? PublishOutcome.published : PublishOutcome.savedOffline;
    } on ReviewException catch (error) {
      _errorMessage = error.message;
      return PublishOutcome.failed;
    } finally {
      _isPublishing = false;
      notifyListeners();
    }
  }

  void _track(String eventName) {
    unawaited(
      _telemetryService.trackReviewEvent(
        eventName: eventName,
        method: verified ? 'qr' : 'manual',
        restaurantId: restaurant.id,
      ),
    );
  }
}
