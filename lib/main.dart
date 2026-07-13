import 'dart:io';

import 'package:flutter/material.dart';
import 'package:niemyetdientu/screens/danh_muc_thu_tuc.dart';
import 'package:niemyetdientu/utils/idle_manager.dart';

/// ✅ Bypass SSL cho server nội bộ/self-signed
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        return true;
      };
  }
}

void main() {
  /// ✅ enable bypass SSL
  HttpOverrides.global = MyHttpOverrides();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,

      /// 🔥 reset timer toàn app
      onPointerDown: (_) => IdleManager.reset(),
      onPointerMove: (_) => IdleManager.reset(),

      child: MaterialApp(
        navigatorKey: IdleManager.navigatorKey,
        debugShowCheckedModeBanner: false,

        theme: ThemeData(primarySwatch: Colors.deepPurple),

        home: const DanhMucThuTucPage(),
      ),
    );
  }
}
