import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_dimensions.dart';
import '../../core/enums/bug_category.dart';
import '../../core/enums/bug_priority.dart';
import '../../core/enums/bug_severity.dart';
import '../../core/enums/bug_status.dart';
import '../../core/extensions/date_extensions.dart';
import '../models/message_model.dart';
import 'app_badge.dart';
import 'app_network_image.dart';

class BugReportMessageCard extends StatelessWidget {
  final MessageModel message;
  final VoidCallback onTap;
  final VoidCallback? onReply;
  final VoidCallback? onLongPress;
  final ValueChanged<BugStatus>? onStatusChange;
  final bool isSender;

  const BugReportMessageCard({
    super.key,
    required this.message,
    required this.onTap,
    this.onReply,
    this.onLongPress,
    this.onStatusChange,
    this.isSender = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bugData = message.bugData ?? {};

    final title = bugData['title'] as String? ?? message.content;
    final description = bugData['description'] as String? ?? '';
    final category = BugCategory.fromString(bugData['category'] as String?);
    final severity = BugSeverity.fromString(bugData['severity'] as String?);
    final priority = BugPriority.fromString(bugData['priority'] as String?);
    final status = BugStatus.fromString(bugData['status'] as String?);
    final attachments = List<String>.from(bugData['attachmentUrls'] ?? []);
    final reporterName = message.senderName;
    final timestamp = message.createdAt?.chatTimestamp ?? '';

    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth > 640 ? 360.0 : screenWidth * 0.82;

    return Align(
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: isDark ? const Color(0xFF181E2E) : const Color(0xFFFBF8FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isDark
                  ? AppColors.secondary.withValues(alpha: 0.35)
                  : const Color(0xFFDDD6FE),
              width: 1.1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            onSecondaryTap: onLongPress,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 10.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header: Category Badge & Status (Bug number removed as requested)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isDark ? AppColors.secondary : AppColors.primary)
                                  .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              category.icon,
                              size: 13,
                              color: isDark
                                  ? AppColors.secondary
                                  : AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              category.label,
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.secondary
                                    : AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      AppBadge.status(status),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textMainDark
                          : AppColors.textMainLight,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Description
                  if (description.isNotEmpty &&
                      description.trim() != title.trim()) ...[
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Attachments Preview (if any)
                  if (attachments.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: AppDimensions.borderRadiusMd,
                      child: Container(
                        height: 110,
                        width: double.infinity,
                        color: Colors.black12,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            AppNetworkImage(
                              url: attachments.first,
                              width: double.infinity,
                              height: 110,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Center(
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.grey,
                                    ),
                                  ),
                            ),
                            if (attachments.length > 1)
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '+${attachments.length - 1} more',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // Severity & Priority row
                  Row(
                    children: [
                      AppBadge.severity(severity),
                      const SizedBox(width: 6),
                      AppBadge.priority(priority),
                      const Spacer(),
                      Text(
                        timestamp,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Divider(height: 1),
                  const SizedBox(height: 6),

                  // Card Actions: Reporter, View Details, Reply
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          reporterName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      if (onReply != null) ...[
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onReply,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.reply,
                                  size: 14,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Reply',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onTap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Details',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.secondary
                                      : AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.arrow_forward_ios,
                                size: 10,
                                color: isDark
                                    ? AppColors.secondary
                                    : AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
