import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'package:uniandes_food/models/my_review.dart';
import 'package:uniandes_food/repositories/my_reviews_repository.dart';
import 'package:uniandes_food/services/telemetry_service.dart';

/// State of the My Reviews view.
///
/// Listens to Firestore with metadata changes. Offline it receives the cached
/// documents, and reviews written offline come marked as pending until they
/// reach the server. Connectivity changes update the offline notice.
class MyReviewsViewModel extends ChangeNotifier {
  MyReviewsViewModel({
    required this.uid,
    MyReviewsRepository? repository,
    Connectivity? connectivity,
    TelemetryService? telemetryService,
  }) : _repository = repository ?? MyReviewsRepository.instance,
       _connectivity = connectivity ?? Connectivity() {
    unawaited(
      (telemetryService ?? TelemetryService()).trackFeatureOpened(
        feature: 'my_reviews',
        userId: uid,
      ),
    );
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (Object _) {},
    );
    unawaited(_checkConnectivity());
    _reviewsSubscription = _repository
        .watch(uid)
        .listen(_onSnapshot, onError: _onError);
  }

  final String uid;
  final MyReviewsRepository _repository;
  final Connectivity _connectivity;

  late final StreamSubscription<List<ConnectivityResult>>
  _connectivitySubscription;
  late final StreamSubscription<MyReviewsSnapshot> _reviewsSubscription;

  MyReviewsSummary? _summary;
  bool _isOnline = true;
  bool _isFromCache = false;
  bool _hasSnapshot = false;
  String? _errorMessage;
  int _version = 0;
  bool _disposed = false;

  /// Null until there is something to show.
  MyReviewsSummary? get summary => _summary;

  bool get isOffline => !_isOnline;

  /// True while the data comes from the phone and not from the server.
  bool get isShowingSavedData => _isFromCache;

  bool get isLoading => _summary == null && !_hasSnapshot;
  String? get errorMessage => _errorMessage;

  /// Offline and the phone never downloaded the student's reviews.
  bool get neverLoaded =>
      _hasSnapshot && isShowingSavedData && (_summary?.isEmpty ?? true);

  Future<void> _checkConnectivity() async {
    try {
      _onConnectivityChanged(await _connectivity.checkConnectivity());
    } on Exception {
      return;
    }
  }

  Future<void> _onSnapshot(MyReviewsSnapshot snapshot) async {
    final version = ++_version;
    _hasSnapshot = true;
    _isFromCache = snapshot.isFromCache;
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

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final online = results.any((result) => result != ConnectivityResult.none);
    if (online == _isOnline) return;
    _isOnline = online;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _connectivitySubscription.cancel();
    _reviewsSubscription.cancel();
    super.dispose();
  }
}
