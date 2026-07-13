import 'dart:async';
import 'package:flutter/material.dart';
import 'package:niemyetdientu/screens/danh_muc_thu_tuc.dart';

class IdleManager {
  static Timer? _timer;

  /// 🔥 Navigator key global
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const Duration timeout = Duration(minutes: 5);

  static void start() {
    _timer?.cancel();

    _timer = Timer(timeout, () {
      debugPrint("⏰ Idle 5 phút → quay về trang chính");

      final navigator = navigatorKey.currentState;

      if (navigator != null) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DanhMucThuTucPage()),
          (route) => false,
        );
      } else {
        debugPrint("❌ Navigator null");
      }
    });
  }

  static void reset() {
    start();
  }

  static void stop() {
    _timer?.cancel();
  }
}
