import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryOrange = Color(0xFFFF6B35);
  static const Color secondaryOrange = Color(0xFFFF8C42);
  static const Color accentYellow = Color(0xFFFFC947);
  static const Color darkGreen = Color(0xFF2D6A4F);
  static const Color lightGreen = Color(0xFF52B788);
  static const Color backgroundColor = Color(0xFFFFF8E1);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textGrey = Color(0xFF6B7280);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color successGreen = Color(0xFF10B981);

  // Restaurant Dashboard Colors
  static const Color restaurantPrimary = Color(0xFF1E293B);
  static const Color restaurantAccent = Color(0xFFFF6B35);
  static const Color restaurantCard = Color(0xFF334155);

  // Status Colors
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusPreparing = Color(0xFF3B82F6);
  static const Color statusReady = Color(0xFF8B5CF6);
  static const Color statusDelivered = Color(0xFF10B981);
  static const Color statusCancelled = Color(0xFFEF4444);

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return statusPending;
      case 'preparing':
        return statusPreparing;
      case 'ready':
        return statusReady;
      case 'delivered':
        return statusDelivered;
      case 'cancelled':
        return statusCancelled;
      default:
        return textGrey;
    }
  }
}
