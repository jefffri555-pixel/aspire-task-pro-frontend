import 'package:flutter/material.dart';

class AppStyles {
  // Soft, diffuse shadow for cards and list items
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: 2,
        ),
      ];

  // Stronger shadow for floating elements (like FAB or bottom nav)
  static List<BoxShadow> get floatShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 32,
          offset: const Offset(0, 12),
          spreadRadius: 4,
        ),
      ];
}
