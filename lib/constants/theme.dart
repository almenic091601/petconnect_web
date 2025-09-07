import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF006D5B); // Dark Teal
  static const Color secondary = Color(0xFF00897B); // Lighter Teal
  static const Color background = Color(0xFFF5F6FA);
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color sidebarBackground = Color(0xFF004D40);

  static const TextStyle appBarTextStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );

  static const TextStyle sidebarTextStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
  );

  static const TextStyle sidebarTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle cardTitleStyle = TextStyle(
    fontSize: 14,
    color: textSecondary,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle cardValueStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
  );
}
