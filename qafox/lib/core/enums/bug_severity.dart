import 'package:flutter/material.dart';

enum BugSeverity {
  critical('Critical', Color(0xFFDC2626)), // Strong Red
  high('High', Color(0xFFEA580C)), // Deep Orange
  medium('Medium', Color(0xFFD97706)), // Amber
  low('Low', Color(0xFF2563EB)); // Blue

  final String label;
  final Color color;
  const BugSeverity(this.label, this.color);

  static BugSeverity fromString(String? value) {
    return BugSeverity.values.firstWhere(
      (e) => e.name.toLowerCase() == (value ?? '').toLowerCase(),
      orElse: () => BugSeverity.medium,
    );
  }

  Color get backgroundColor => color.withValues(alpha: 0.12);
}
