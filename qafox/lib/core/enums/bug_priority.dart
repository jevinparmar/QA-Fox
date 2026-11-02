import 'package:flutter/material.dart';

enum BugPriority {
  urgent('Urgent', Color(0xFFE11D48)),
  high('High', Color(0xFFF97316)),
  medium('Medium', Color(0xFFFBBF24)),
  low('Low', Color(0xFF10B981));

  final String label;
  final Color color;
  const BugPriority(this.label, this.color);

  static BugPriority fromString(String? value) {
    return BugPriority.values.firstWhere(
      (e) => e.name.toLowerCase() == (value ?? '').toLowerCase(),
      orElse: () => BugPriority.medium,
    );
  }

  Color get backgroundColor => color.withValues(alpha: 0.12);
}
