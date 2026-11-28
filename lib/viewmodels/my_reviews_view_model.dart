import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:uniandes_food/models/my_review.dart';
import 'package:uniandes_food/repositories/my_reviews_repository.dart';
import 'package:uniandes_food/services/telemetry_service.dart';

/// State of the My Reviews view.
class MyReviewsViewModel extends ChangeNotifier {
  MyReviewsViewModel({
    required this.uid,
    MyReviewsRepository? repository,
    TelemetryService? telemetryService,
  }) : _repository = repository ?? MyReviewsRepository.instance {
    unawaited(
      (telemetryService ?? TelemetryService()).trackFeatureOpened(
        feature: 'my_reviews',
        userId: uid,
      ),
    );
    _reviewsSubscription = _repository
        .watch(uid)
        .listen(_onSnapshot, onError: _onError);
  }

  final String uid;
  final MyReviewsRepository _repository;

  late final StreamSubscription<MyReviewsSnapshot> _reviewsSubscription;

  MyReviewsSummary? _summary;
  bool _hasSnapshot = false;
  String? _errorMessage;
  int _version = 0;
  bool _disposed = false;

  /// Null until there is something to show.
  MyReviewsSummary? get summary => _summary;

  bool get isLoading => _summary == null && !_hasSnapshot;
  String? get errorMessage => _errorMessage;

  Future<void> _onSnapshot(MyReviewsSnapshot snapshot) async {
    final version = ++_version;
    _hasSnapshot = true;
    _errorMessage = null;

    final ids = {
      for (final row in snapshot.rows)
        if (row['restaurantId'] case final String id when id.isNotEmpty) id,
    };
    final names = await _repository.restaurantNames(ids);
    if (_disposed || version != _version) return;

    final summary = await _repository.summarize(snapshot.rows, names);
    if (_disposed || version != _version) return;

    _summary = summary;
    _notify();
  }

  void _onError(Object error) {
    _hasSnapshot = true;
    _errorMessage = 'We could not load your reviews.';
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _reviewsSubscription.cancel();
    super.dispose();
  }
}
