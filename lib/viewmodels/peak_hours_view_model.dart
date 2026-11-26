import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:uniandes_food/models/peak_hours.dart';
import 'package:uniandes_food/models/restaurant.dart';
import 'package:uniandes_food/repositories/peak_hours_repository.dart';

class PeakHoursViewModel extends ChangeNotifier {
  PeakHoursViewModel({
    required this.restaurant,
    PeakHoursRepository? repository,
    DateTime Function()? now,
  }) : _repository = repository ?? PeakHoursRepository.instance,
       _now = now ?? DateTime.now {
    unawaited(load());
  }

  final Restaurant restaurant;
  final PeakHoursRepository _repository;
  final DateTime Function() _now;

  PeakHours? _peakHours;
  bool _isLoading = false;
  bool _disposed = false;

  PeakHours? get peakHours => _peakHours;
  bool get isLoading => _isLoading;
  int get currentHour => _now().hour;
  HourSlot? get bestSlot => _peakHours?.bestFrom(currentHour);

  Future<void> load() async {
    if (_isLoading) return;

    _isLoading = true;
    _notify();

    _peakHours = await _repository.fetch(restaurant.id);
    _isLoading = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
