import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Tracks whether the device currently has a network connection.
/// Used to show the "offline" banner and to block writes while offline.
class ConnectivityController {
  ConnectivityController._();
  static final ConnectivityController instance = ConnectivityController._();

  final ValueNotifier<bool> online = ValueNotifier<bool>(true);
  StreamSubscription<dynamic>? _sub;

  Future<void> start() async {
    try {
      final res = await Connectivity().checkConnectivity();
      online.value = _isOnline(res);
      _sub = Connectivity().onConnectivityChanged.listen((res) {
        online.value = _isOnline(res);
      });
    } catch (_) {
      // If the plugin can't report, assume online so we don't block the user.
      online.value = true;
    }
  }

  // Handles both connectivity_plus v6 (List<ConnectivityResult>) and older
  // single-value APIs.
  bool _isOnline(dynamic res) {
    if (res is List) {
      return res.any((r) => r != ConnectivityResult.none);
    }
    return res != ConnectivityResult.none;
  }
}
