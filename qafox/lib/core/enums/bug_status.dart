import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

enum BugStatus {
  open('Open'),
  assigned('Assigned'),
  inProgress('In Progress'),
  fixed('Fixed'),
  verified('Verified'),
  reopened('Reopened'),
  closed('Closed');

  final String label;
  const BugStatus(this.label);

  static BugStatus fromString(String? value) {
    return BugStatus.values.firstWhere(
      (e) =>
          e.name.toLowerCase() ==
          (value ?? '').replaceAll(' ', '').toLowerCase(),
      orElse: () => BugStatus.open,
    );
  }

  Color get color {
    switch (this) {
      case BugStatus.open:
        return const Color(0xFFEF4444); // Red
      case BugStatus.assigned:
        return const Color(0xFFF59E0B); // Amber
      case BugStatus.inProgress:
        return const Color(0xFF3B82F6); // Blue
      case BugStatus.fixed:
        return const Color(0xFF8B5CF6); // Purple
      case BugStatus.verified:
        return AppColors.success; // Green
      case BugStatus.reopened:
        return const Color(0xFFEC4899); // Pink
      case BugStatus.closed:
        return const Color(0xFF64748B); // Slate
    }
  }

  Color get backgroundColor {
    return color.withValues(alpha: 0.12);
  }

  bool get isOpen =>
      this == BugStatus.open ||
      this == BugStatus.assigned ||
      this == BugStatus.inProgress ||
      this == BugStatus.reopened;
  bool get isResolved =>
      this == BugStatus.fixed ||
      this == BugStatus.verified ||
      this == BugStatus.closed;
}
