import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6B4CE6); // Purple
  static const Color primaryLight = Color(0xFF9B7FED);
  static const Color primaryDark = Color(0xFF4A2FB8);

  // Secondary Colors
  static const Color secondary = Color(0xFF34D399); // Green
  static const Color secondaryLight = Color(0xFF6EE7B7);
  static const Color secondaryDark = Color(0xFF10B981);

  // Neutral Colors
  static const Color background = Color(0xFFF9FAFB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF3F4F6);

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Health Score Status Colors
  static const Color radiant = Color(0xFFF59E0B); // Gold
  static const Color thriving = Color(0xFF10B981); // Green
  static const Color balanced = Color(0xFF3B82F6); // Blue
  static const Color rebuilding = Color(0xFFF97316); // Orange
  static const Color needsSupport = Color(0xFFEF4444); // Red

  // Domain Colors
  static const Color physicalDomain = Color(0xFFEC4899); // Pink
  static const Color mentalDomain = Color(0xFF8B5CF6); // Purple
  static const Color lifestyleDomain = Color(0xFF10B981); // Green
  static const Color socialDomain = Color(0xFF3B82F6); // Blue

  // Borders
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFFD1D5DB);

  // Shadows
  static const Color shadow = Color(0x1A000000);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient scoreGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Get color for health score status
  static Color getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RADIANT':
        return radiant;
      case 'THRIVING':
        return thriving;
      case 'BALANCED':
        return balanced;
      case 'REBUILDING':
        return rebuilding;
      case 'NEEDS_SUPPORT':
        return needsSupport;
      default:
        return textSecondary;
    }
  }

  // Get color for domain
  static Color getDomainColor(String domain) {
    switch (domain.toLowerCase()) {
      case 'physical':
        return physicalDomain;
      case 'mental':
        return mentalDomain;
      case 'lifestyle':
        return lifestyleDomain;
      case 'social':
        return socialDomain;
      default:
        return textSecondary;
    }
  }
}
