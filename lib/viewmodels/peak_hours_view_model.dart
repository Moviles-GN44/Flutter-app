import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import 'package:uniandes_food/models/peak_hours.dart';
import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/repositories/peak_hours_repository.dart';

class PeakHoursViewModel extends ChangeNotifier {
  PeakHoursViewModel({
    required this.restaurant,
    PeakHoursRepository? repository,
    Connectivity? connectivity,
    DateTime Function()? now,
  }) : _repository = repository ?? PeakHoursRepository.instance,
       _now = now ?? DateTime.now {
    _connectivitySubscription = (connectivity ?? Connectivity())
        .onConnectivityChanged
        .listen(_onConnectivityChanged, onError: (Object _) {});
    unawaited(load());
  }

  final Restaurant restaurant;
  final PeakHoursRepository _repository;
  final DateTime Function() _now;
  late final StreamSubscription<List<ConnectivityResult>>
  _connectivitySubscription;

  PeakHours? _peakHours;
  DateTime? _savedAt;
  bool _isOffline = false;
  bool _isLoading = false;
  bool _disposed = false;

  PeakHours? get peakHours => _peakHours;
  DateTime? get savedAt => _savedAt;
  bool get isOffline => _isOffline;
  bool get isLoading => _isLoading;
  int get currentHour => _now().hour;
  HourSlot? get bestSlot => _peakHours?.bestFrom(currentHour);

  Future<void> load() async {
    if (_isLoading) return;

    final cached = _repository.cached(restaurant.id);
    if (cached != null) {
      _peakHours = cached;
      _savedAt = null;
      _isOffline = false;
      _notify();
      return;
    }

    _isLoading = true;
    _notify();

    final saved = await _repository.saved(restaurant.id);
    if (saved != null && _peakHours == null) {
      _peakHours = saved;
      _savedAt = saved.updatedAt;
      _notify();
    }

    final result = await _repository.fetch(restaurant.id);
    _isLoading = false;
    _isOffline = result.isFromCache;
    if (!result.isFromCache || saved == null) {
      _peakHours = result.peakHours;
      _savedAt = null;
    }
    _notify();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final online = results.any((result) => result != ConnectivityResult.none);
    if (online && _isOffline) unawaited(load());
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
