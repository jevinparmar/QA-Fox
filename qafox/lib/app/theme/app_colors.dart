import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Brand Colors
  static const Color primary = Color(0xFF4C1D95); // Deep Purple
  static const Color primaryDark = Color(0xFF24104F);
  static const Color primaryLight = Color(0xFF6D28D9);
  static const Color secondary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFFFF7A30); // Fox Orange
  static const Color accentLight = Color(0xFFFF9554);
  static const Color accentDark = Color(0xFFDD5E18);

  // Background & Surfaces
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFFFFFFF);

  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color cardDark = Color(0xFF1E293B);
  static const Color surfaceElevatedDark = Color(0xFF243048);

  // Typography Colors
  static const Color textMainLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textMutedLight = Color(0xFF94A3B8);

  static const Color textMainDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Borders & Dividers
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);
  static const Color dividerLight = Color(0xFFF1F5F9);
  static const Color dividerDark = Color(0xFF1E293B);

  // State & Feedback Colors
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF0284C7);
  static const Color infoLight = Color(0xFFE0F2FE);

  // Chat Bubble Colors
  static const Color outgoingBubbleLight = Color(0xFF4C1D95);
  static const Color outgoingBubbleText = Colors.white;
  static const Color incomingBubbleLight = Color(0xFFF1F5F9);
  static const Color incomingBubbleTextLight = Color(0xFF111827);

  static const Color outgoingBubbleDark = Color(0xFF6D28D9);
  static const Color incomingBubbleDark = Color(0xFF334155);
  static const Color incomingBubbleTextDark = Color(0xFFF8FAFC);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient foxGradient = LinearGradient(
    colors: [accent, Color(0xFFFF9E66)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
