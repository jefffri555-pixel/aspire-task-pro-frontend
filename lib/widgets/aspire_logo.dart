import 'package:flutter/material.dart';
import '../config/colors.dart';

class AspireLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isDarkBackground;

  const AspireLogo({
    super.key,
    this.size = 40.0,
    this.showText = true,
    this.isDarkBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!showText) return const SizedBox.shrink();

    return Image.asset(
      'assets/images/logo.jpg',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
