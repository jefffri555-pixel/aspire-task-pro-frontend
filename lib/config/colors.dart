import 'package:flutter/material.dart';

class AspireColors {
  // Primary Brand Colors (Updated for premium mobile UI)
  static const Color primary = Color(0xFF5B3DF5); // Vibrant Purple
  static const Color primaryLight =
      Color(0xFF7A61FA); // Lighter purple for gradients
  static const Color secondary = Color(0xFF052550); // Dark Navy
  static const Color blue = Color(0xFF0A63FF); // Bright Blue
  static const Color accent = Color(0xFF22C55E); // Green
  static const Color warning = Color(0xFFF59E0B); // Orange

  // Light Mode Colors
  static const Color lightBg =
      Color(0xFFF8F9FE); // Very soft bluish white with purple hint
  static const Color lightCard = Colors.white;
  static const Color lightTextPrimary = Color(0xFF1E1E2D);
  static const Color lightTextSecondary = Color(0xFF7E8299);
  static const Color lightBorder = Color(0xFFF1F1F5);

  // Dark Mode Colors (Kept bright per user request - "Do NOT make the app dark. Keep it bright and elegant.")
  // Note: App will effectively ignore dark mode styling to force this aesthetic,
  // or use these slightly adjusted light theme colors if system triggers dark mode.
  static const Color darkBg = Color(0xFFF8F9FE);
  static const Color darkCard = Colors.white;
  static const Color darkTextPrimary = Color(0xFF1E1E2D);
  static const Color darkTextSecondary = Color(0xFF7E8299);
  static const Color darkBorder = Color(0xFFF1F1F5);

  // Status Indicator Colors
  static const Color statusPending = Color(0xFF8B5CF6);
  static const Color statusAssigned = Color(0xFF0A63FF);
  static const Color statusInProgress = Color(0xFFF59E0B);
  static const Color statusReview = Color(0xFF5B3DF5);
  static const Color statusCompleted = Color(0xFF22C55E);
  static const Color statusRejected = Color(0xFFEF4444);
  static const Color statusOverdue = Color(0xFFDC2626);

  // Get status color mapping
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'not_started':
        return statusPending;
      case 'assigned':
        return statusAssigned;
      case 'in_progress':
      case 'waiting_for_review':
        return statusInProgress;
      case 'under_review':
      case 'in_review':
        return statusReview;
      case 'completed':
        return statusCompleted;
      case 'rejected':
      case 'on_hold':
        return statusRejected;
      case 'overdue':
        return statusOverdue;
      default:
        return Colors.grey;
    }
  }

  // Get priority color mapping
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Color(0xFFEF4444);
      case 'medium':
        return warning;
      case 'low':
        return blue;
      default:
        return Colors.grey;
    }
  }
}
