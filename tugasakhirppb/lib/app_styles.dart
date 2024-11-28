import 'package:flutter/material.dart';

class AppStyles {
  // Text Styles
  static const TextStyle rankTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle titleTextStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subtitleTextStyle = TextStyle(
    fontSize: 12,
  );

  static const TextStyle errorTextStyle = TextStyle(
    fontSize: 16,
    color: Colors.red,
  );

  // Padding
  static const EdgeInsets cardPadding = EdgeInsets.all(12.0);
  static const EdgeInsets cardMargin = EdgeInsets.all(8);

  // Decorations
  static BoxDecoration cardDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(10),
    color: Colors.white,
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.2),
        spreadRadius: 2,
        blurRadius: 5,
      ),
    ],
  );

  // Icon size
  static const double iconSize = 50;
  static const double smallIconSize = 24;
  static const double unitIconSize = 36;
  static const double unitIconBorderWidth = 3;
}
