import 'package:flutter/material.dart';

enum BugCategory {
  overall('Overall', Icons.layers_outlined),
  uiUx('UI / UX', Icons.palette_outlined),
  functional('Functional', Icons.build_circle_outlined),
  api('API', Icons.cloud_sync_outlined),
  performance('Performance', Icons.speed_outlined),
  validation('Validation', Icons.check_circle_outline),
  navigation('Navigation', Icons.navigation_outlined),
  crash('Crash', Icons.error_outline),
  compatibility('Compatibility', Icons.devices_other_outlined),
  other('Other', Icons.more_horiz);

  final String label;
  final IconData icon;
  const BugCategory(this.label, this.icon);

  static BugCategory fromString(String? value) {
    return BugCategory.values.firstWhere(
      (e) =>
          e.name.toLowerCase() == (value ?? '').toLowerCase() ||
          e.label.toLowerCase() == (value ?? '').toLowerCase(),
      orElse: () => BugCategory.other,
    );
  }
}
