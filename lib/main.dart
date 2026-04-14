import 'package:flutter/material.dart';
import 'package:niemyetdientu/screens/danh_muc_thu_tuc.dart';
import 'package:niemyetdientu/service/resolution_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize resolution detection at app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ResolutionHelper().initialize(context);
    });

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const DanhMucThuTucPage(),
    );
  }
}
