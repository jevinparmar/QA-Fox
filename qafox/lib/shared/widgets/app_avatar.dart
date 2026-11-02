import 'app_network_image.dart';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/extensions/string_extensions.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final bool isOnline;
  final bool showOnlineIndicator;
  final Color? backgroundColor;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 44.0,
    this.isOnline = false,
    this.showOnlineIndicator = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final initials = name.initials;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget avatarContent;
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      avatarContent = AppNetworkImage(
        url: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          color: (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          child: Center(
            child: SizedBox(
              width: size * 0.4,
              height: size * 0.4,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildInitials(initials, isDark),
      );
    } else {
      avatarContent = _buildInitials(initials, isDark);
    }

    final avatarWidget = ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        color:
            backgroundColor ?? AppColors.primaryLight.withValues(alpha: 0.15),
        child: avatarContent,
      ),
    );

    if (!showOnlineIndicator) {
      return avatarWidget;
    }

    final indicatorSize = size * 0.28;

    return Stack(
      children: [
        avatarWidget,
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: indicatorSize,
            height: indicatorSize,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.success : AppColors.textMutedLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitials(String initials, bool isDark) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: size * 0.4,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
