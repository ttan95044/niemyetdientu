import 'package:flutter/material.dart';

class ResponsiveText extends StatelessWidget {
  final String text;

  const ResponsiveText({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    double fontSize = screenWidth < 360 ? 10 : (screenWidth < 480 ? 24 : 24);

    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      softWrap: true,
    );
  }
}
