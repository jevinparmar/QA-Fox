import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class QAThemeExtension extends ThemeExtension<QAThemeExtension> {
  final Color foxAccent;
  final Color outgoingBubble;
  final Color incomingBubble;
  final Color outgoingText;
  final Color incomingText;
  final Color bugCardBackground;
  final Color bugCardBorder;

  const QAThemeExtension({
    required this.foxAccent,
    required this.outgoingBubble,
    required this.incomingBubble,
    required this.outgoingText,
    required this.incomingText,
    required this.bugCardBackground,
    required this.bugCardBorder,
  });

  static const light = QAThemeExtension(
    foxAccent: AppColors.accent,
    outgoingBubble: AppColors.outgoingBubbleLight,
    incomingBubble: AppColors.incomingBubbleLight,
    outgoingText: AppColors.outgoingBubbleText,
    incomingText: AppColors.incomingBubbleTextLight,
    bugCardBackground: Color(0xFFFBF8FF),
    bugCardBorder: Color(0xFFE9D5FF),
  );

  static const dark = QAThemeExtension(
    foxAccent: AppColors.accent,
    outgoingBubble: AppColors.outgoingBubbleDark,
    incomingBubble: AppColors.incomingBubbleDark,
    outgoingText: AppColors.outgoingBubbleText,
    incomingText: AppColors.incomingBubbleTextDark,
    bugCardBackground: Color(0xFF1E1B4B),
    bugCardBorder: Color(0xFF3B0764),
  );

  @override
  QAThemeExtension copyWith({
    Color? foxAccent,
    Color? outgoingBubble,
    Color? incomingBubble,
    Color? outgoingText,
    Color? incomingText,
    Color? bugCardBackground,
    Color? bugCardBorder,
  }) {
    return QAThemeExtension(
      foxAccent: foxAccent ?? this.foxAccent,
      outgoingBubble: outgoingBubble ?? this.outgoingBubble,
      incomingBubble: incomingBubble ?? this.incomingBubble,
      outgoingText: outgoingText ?? this.outgoingText,
      incomingText: incomingText ?? this.incomingText,
      bugCardBackground: bugCardBackground ?? this.bugCardBackground,
      bugCardBorder: bugCardBorder ?? this.bugCardBorder,
    );
  }

  @override
  QAThemeExtension lerp(ThemeExtension<QAThemeExtension>? other, double t) {
    if (other is! QAThemeExtension) return this;
    return QAThemeExtension(
      foxAccent: Color.lerp(foxAccent, other.foxAccent, t) ?? foxAccent,
      outgoingBubble:
          Color.lerp(outgoingBubble, other.outgoingBubble, t) ?? outgoingBubble,
      incomingBubble:
          Color.lerp(incomingBubble, other.incomingBubble, t) ?? incomingBubble,
      outgoingText:
          Color.lerp(outgoingText, other.outgoingText, t) ?? outgoingText,
      incomingText:
          Color.lerp(incomingText, other.incomingText, t) ?? incomingText,
      bugCardBackground:
          Color.lerp(bugCardBackground, other.bugCardBackground, t) ??
          bugCardBackground,
      bugCardBorder:
          Color.lerp(bugCardBorder, other.bugCardBorder, t) ?? bugCardBorder,
    );
  }
}
