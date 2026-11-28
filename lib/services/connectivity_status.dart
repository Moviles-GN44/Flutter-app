import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Whether the phone has a network connection, shared by every screen.
///
/// One listener for the whole app, so the screens that only need to show the
/// offline notice do not each open their own subscription.
class ConnectivityStatus extends ChangeNotifier {
  ConnectivityStatus._(Connectivity connectivity) {
    connectivity.onConnectivityChanged.listen(_update, onError: (Object _) {});
    connectivity.checkConnectivity().then(_update).catchError((Object _) {});
  }

  static final ConnectivityStatus instance = ConnectivityStatus._(
    Connectivity(),
  );

  /// How long the "Back online" notice stays after reconnecting.
  static const backOnlineDuration = Duration(seconds: 3);

  bool _isOnline = true;
  bool _justReconnected = false;
  Timer? _backOnlineTimer;

  bool get isOnline => _isOnline;

  /// True for a few seconds after the connection comes back.
  bool get justReconnected => _justReconnected;

  void _update(List<ConnectivityResult> results) {
    final online = results.any((result) => result != ConnectivityResult.none);
    if (online == _isOnline) return;

    _isOnline = online;
    _backOnlineTimer?.cancel();
    _justReconnected = online;
    if (online) {
      _backOnlineTimer = Timer(backOnlineDuration, () {
        _justReconnected = false;
        notifyListeners();
      });
    }
    notifyListeners();
  }
}
