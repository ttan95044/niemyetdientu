import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ResponsiveIcon extends StatelessWidget {
  final String assetPath;
  final Color backgroundColor;

  const ResponsiveIcon({
    super.key,
    required this.assetPath,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Lấy kích thước màn hình
    final screenWidth = MediaQuery.of(context).size.width;

    // Điều chỉnh kích thước icon theo độ rộng màn hình
    double iconSize = screenWidth < 360 ? 26 : (screenWidth < 480 ? 28 : 36);
    double containerSize = screenWidth < 360
        ? 40
        : (screenWidth < 480 ? 70 : 60);

    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: backgroundColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Center(
        child: SvgPicture.asset(
          assetPath,
          width: iconSize,
          height: iconSize,
          fit: BoxFit.contain,
          // ignore: deprecated_member_use
          color: Colors.white,
        ),
      ),
    );
  }
}
