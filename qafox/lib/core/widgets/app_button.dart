import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import 'app_loader.dart';

enum AppButtonVariant { primary, secondary, outline, text, danger, fox }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppDimensions.buttonHeight,
    this.borderRadius,
    this.padding,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius = borderRadius ?? AppDimensions.borderRadiusMd;
    final primaryAccent = isDark ? AppColors.secondary : AppColors.primary;
    final isCompact = height <= 38;
    final effectivePadding = padding ??
        (isCompact
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 0)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 0));
    final effectiveFontSize = fontSize ?? (isCompact ? 12.5 : 15.0);

    if (variant == AppButtonVariant.text) {
      return TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: primaryAccent,
          padding: effectivePadding,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: isLoading
            ? const AppLoader(size: 18)
            : (icon != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      icon!,
                      const SizedBox(width: 6),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            text,
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: effectiveFontSize,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      text,
                      maxLines: 1,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: effectiveFontSize,
                      ),
                    ),
                  )),
      );
    }

    if (variant == AppButtonVariant.outline) {
      return SizedBox(
        width: width,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryAccent,
            side: BorderSide(color: primaryAccent, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
            padding: effectivePadding,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          child: isLoading
              ? const AppLoader(size: 20)
              : (icon != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        icon!,
                        const SizedBox(width: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              text,
                              maxLines: 1,
                              style: TextStyle(
                                color: primaryAccent,
                                fontWeight: FontWeight.w600,
                                fontSize: effectiveFontSize,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        text,
                        maxLines: 1,
                        style: TextStyle(
                          color: primaryAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: effectiveFontSize,
                        ),
                      ),
                    )),
        ),
      );
    }

    Color bgColor = isDark ? AppColors.primaryLight : AppColors.primary;
    Color fgColor = Colors.white;

    switch (variant) {
      case AppButtonVariant.secondary:
        bgColor = AppColors.secondary;
        break;
      case AppButtonVariant.fox:
        bgColor = AppColors.accent;
        break;
      case AppButtonVariant.danger:
        bgColor = AppColors.error;
        break;
      case AppButtonVariant.primary:
      default:
        bgColor = isDark ? AppColors.primaryLight : AppColors.primary;
        break;
    }

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
          padding: effectivePadding,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: isLoading
            ? const AppLoader(size: 20, color: Colors.white)
            : (icon != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      icon!,
                      const SizedBox(width: 6),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            text,
                            maxLines: 1,
                            style: TextStyle(
                              color: fgColor,
                              fontSize: effectiveFontSize,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      text,
                      maxLines: 1,
                      style: TextStyle(
                        color: fgColor,
                        fontSize: effectiveFontSize,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  )),
      ),
    );
  }
}
