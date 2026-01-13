import 'package:flutter/material.dart';
import 'package:niemyetdientu/screens/danh_muc_thu_tuc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const DanhMucThuTucPage(),
    );
  }
}
