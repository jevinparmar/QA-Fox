import 'package:flutter/material.dart';

import '../../core/enums/bug_status.dart';
import '../../core/enums/bug_severity.dart';
import '../../core/enums/bug_priority.dart';

class AppBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;
  final IconData? icon;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const AppBadge({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.icon,
    this.fontSize = 11.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
  });

  factory AppBadge.status(BugStatus status) {
    return AppBadge(
      label: status.label,
      color: status.color,
      backgroundColor: status.backgroundColor,
    );
  }

  factory AppBadge.severity(BugSeverity severity) {
    return AppBadge(
      label: severity.label,
      color: severity.color,
      backgroundColor: severity.backgroundColor,
      icon: Icons.shield_outlined,
    );
  }

  factory AppBadge.priority(BugPriority priority) {
    return AppBadge(
      label: priority.label,
      color: priority.color,
      backgroundColor: priority.backgroundColor,
      icon: Icons.flag_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? color.withValues(alpha: 0.12);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 1, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
