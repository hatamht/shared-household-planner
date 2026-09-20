import 'package:flutter/material.dart';

class ProjectPalette {
  static const List<IconData> icons = [
    Icons.apartment_rounded,
    Icons.home_rounded,
    Icons.flight_takeoff_rounded,
    Icons.restaurant_rounded,
    Icons.celebration_rounded,
    Icons.school_rounded,
    Icons.work_rounded,
    Icons.shopping_bag_rounded,
  ];

  static const List<Color> colors = [
    Color(0xFF3F51B5), // Indigo
    Color(0xFF009688), // Teal
    Color(0xFFFF5722), // Deep Orange
    Color(0xFFFFB300), // Amber
    Color(0xFF9C27B0), // Purple
    Color(0xFF2196F3), // Blue
  ];

  static IconData getIcon(int index) {
    if (index >= 0 && index < icons.length) {
      return icons[index];
    }
    return icons[0];
  }

  static Color getColor(int index) {
    if (index >= 0 && index < colors.length) {
      return colors[index];
    }
    return colors[0];
  }
}
