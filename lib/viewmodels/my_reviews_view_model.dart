import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'package:uniandes_food/models/my_review.dart';
import 'package:uniandes_food/repositories/my_reviews_repository.dart';
import 'package:uniandes_food/services/telemetry_service.dart';

/// State of the My Reviews view.
///
/// 1. Shows the list saved on the phone (SQLite) right away.
/// 2. Listens to Firestore. Offline it receives the cached documents, and
///    reviews written offline come marked as pending.
/// 3. When the server confirms the list, it replaces the saved copy.
class MyReviewsViewModel extends ChangeNotifier {
  MyReviewsViewModel({
    required this.uid,
    MyReviewsRepository? repository,
    Connectivity? connectivity,
    TelemetryService? telemetryService,
    DateTime Function()? now,
  }) : _repository = repository ?? MyReviewsRepository.instance,
       _connectivity = connectivity ?? Connectivity(),
       _now = now ?? DateTime.now {
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
    unawaited(_loadSaved());
    _reviewsSubscription = _repository
        .watch(uid)
        .listen(_onSnapshot, onError: _onError);
  }

  final String uid;
  final MyReviewsRepository _repository;
  final Connectivity _connectivity;
  final DateTime Function() _now;

  late final StreamSubscription<List<ConnectivityResult>>
  _connectivitySubscription;
  late final StreamSubscription<MyReviewsSnapshot> _reviewsSubscription;

  MyReviewsSummary? _summary;
  DateTime? _savedAt;
  bool _isOnline = true;
  bool _isFromCache = false;
  bool _hasSnapshot = false;
  bool _showingSaved = false;
  String? _errorMessage;
  int _version = 0;
  bool _disposed = false;

  /// Null until there is something to show.
  MyReviewsSummary? get summary => _summary;

  /// When the list shown was last confirmed by the server, if known.
  DateTime? get savedAt => _savedAt;

  bool get isOffline => !_isOnline;

  /// True while the data comes from the phone and not from the server.
  bool get isShowingSavedData => _isFromCache || _showingSaved;

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

  Future<void> _loadSaved() async {
    final saved = await _repository.store.load(uid);
    // A Firestore snapshot may have arrived while the database was opening.
    if (_disposed || saved.rows.isEmpty || _summary != null) return;
    final summary = await _repository.summarize(saved.rows, const {});
    if (_disposed || _summary != null) return;
    _summary = summary;
    _savedAt = saved.syncedAt;
    _showingSaved = true;
    _notify();
  }

  Future<void> _onSnapshot(MyReviewsSnapshot snapshot) async {
    final version = ++_version;
    _hasSnapshot = true;
    _isFromCache = snapshot.isFromCache;
    _errorMessage = null;

    // Offline with an empty Firestore cache: keep the list saved on the
    // phone instead of showing an empty screen.
    if (snapshot.isFromCache && snapshot.rows.isEmpty) {
      final saved = await _repository.store.load(uid);
      if (_disposed || version != _version) return;
      if (saved.rows.isNotEmpty) {
        _summary = await _repository.summarize(saved.rows, const {});
        if (_disposed || version != _version) return;
        _savedAt = saved.syncedAt;
        _showingSaved = true;
        _notify();
        return;
      }
    }

    final ids = {
      for (final row in snapshot.rows)
        if (row['restaurantId'] case final String id when id.isNotEmpty) id,
    };
    final names = await _repository.restaurantNames(ids);
    if (_disposed || version != _version) return;

    final summary = await _repository.summarize(snapshot.rows, names);
    if (_disposed || version != _version) return;

    _summary = summary;
    _showingSaved = false;
    if (!snapshot.isFromCache) {
      _savedAt = _now();
      unawaited(_repository.store.replace(uid, summary.reviews, _savedAt!));
    }
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
