import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../core/enums/app_status.dart';
import '../../core/extensions/date_extensions.dart';
import '../../core/utils/file_utils.dart';
import '../models/message_model.dart';
import 'app_avatar.dart';
import 'app_network_image.dart';

class ChatMessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isSender;
  final bool isGroup;
  final VoidCallback? onReply;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isSender,
    this.isGroup = false,
    this.onReply,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Handle System Message (e.g. "Ravi joined the group", "BUG-102 created")
    if (message.type == MessageType.system) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 24.0),
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.surfaceDark : Colors.black).withValues(
              alpha: isDark ? 0.6 : 0.06,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.content,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
      );
    }

    final bubbleBg = isSender
        ? (isDark
              ? AppColors.outgoingBubbleDark
              : AppColors.outgoingBubbleLight)
        : (isDark
              ? AppColors.incomingBubbleDark
              : AppColors.incomingBubbleLight);

    final textColor = isSender
        ? AppColors.outgoingBubbleText
        : (isDark
              ? AppColors.incomingBubbleTextDark
              : AppColors.incomingBubbleTextLight);

    final timeColor = isSender
        ? Colors.white.withValues(alpha: 0.7)
        : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 3.0),
      child: Row(
        mainAxisAlignment: isSender
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSender && isGroup) ...[
            AppAvatar(
              name: message.senderName,
              imageUrl: message.senderAvatar,
              size: 28,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              onLongPress: onLongPress,
              onSecondaryTap: onLongPress,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width > 640
                      ? 420.0
                      : MediaQuery.of(context).size.width * 0.76,
                ),
                decoration: BoxDecoration(
                  color: bubbleBg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isSender ? 16 : 4),
                    bottomRight: Radius.circular(isSender ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Group sender name
                      if (!isSender && isGroup) ...[
                        Text(
                          message.senderName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                      ],

                      // Reply preview
                      if (message.replyToPreview != null) ...[
                        Container(
                          padding: const EdgeInsets.all(6),
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            color: (isSender ? Colors.black : Colors.black)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: const Border(
                              left: BorderSide(
                                color: AppColors.accent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: Text(
                            message.replyToPreview!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: textColor.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],

                      // Media image (if any)
                      if (message.type == MessageType.image &&
                          message.mediaUrl != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 240),
                            child: AppNetworkImage(
                              url: message.mediaUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 160,
                                color: Colors.black12,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) =>
                                  const SizedBox(
                                    height: 80,
                                    child: Center(
                                      child: Icon(Icons.broken_image),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],

                      // Document attachment (if any)
                      if (message.type == MessageType.file &&
                          message.mediaUrl != null) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isSender ? Colors.white : Colors.black)
                                .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.insert_drive_file,
                                  color: AppColors.accent,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      message.mediaName ?? 'Document',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: textColor,
                                      ),
                                    ),
                                    if (message.mediaSize != null)
                                      Text(
                                        AppFileUtils.getFileSizeString(
                                          message.mediaSize!,
                                        ),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: textColor.withValues(
                                            alpha: 0.7,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],

                      // Message content or caption
                      if (message.content.isNotEmpty &&
                          message.content != 'Photo' &&
                          message.content != 'Image attachment' &&
                          message.content != message.mediaName)
                        Text(
                          message.content,
                          style: TextStyle(
                            fontSize: 14.5,
                            color: textColor,
                            height: 1.35,
                          ),
                        ),

                      const SizedBox(height: 4),

                      // Timestamp & Read Receipts
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            message.createdAt?.timeOnly ?? '',
                            style: TextStyle(fontSize: 10, color: timeColor),
                          ),
                          if (isSender) ...[
                            const SizedBox(width: 4),
                            Icon(
                              message.readBy.isNotEmpty
                                  ? Icons.done_all
                                  : Icons.done,
                              size: 14,
                              color: message.readBy.isNotEmpty
                                  ? Colors.lightBlueAccent
                                  : timeColor,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
