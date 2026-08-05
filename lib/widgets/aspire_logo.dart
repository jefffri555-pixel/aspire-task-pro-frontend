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
    final logoColor = isDarkBackground ? Colors.white : AspireColors.primary;

    if (!showText) return const SizedBox.shrink();

    return Text(
      'ASPIRE',
      style: TextStyle(
        color: logoColor,
        fontWeight: FontWeight.w700,
        fontSize: size > 24 ? size * 0.6 : 18,
        letterSpacing: 2.0,
      ),
    );
  }
}
