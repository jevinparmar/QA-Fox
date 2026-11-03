import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../shared/models/app_notification_model.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../../shared/providers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = context.isDarkMode;
    final notificationsAsync = ref.watch(userNotificationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          ClipRect(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: IconButton(
                icon: const Icon(Icons.done_all_outlined),
                tooltip: 'Mark all as read',
                onPressed: () async {
                  final notifs = notificationsAsync.value ?? [];
                  final firestore = ref.read(firestoreServiceProvider);
                  final batch = firestore.batch();
                  for (final n in notifs.where((n) => !n.isRead)) {
                    batch.update(
                      firestore.doc('${FirestoreConstants.notifications}/${n.id}'),
                      {'isRead': true},
                    );
                  }
                  await batch.commit();
                },
              ),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const AppEmptyView(
              icon: Icons.notifications_none_outlined,
              title: 'All Caught Up!',
              message:
                  'You have no new notifications. You will be alerted when someone messages you, assigns a bug, or invites you to an organization.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _buildNotificationTile(context, ref, notif, isDark);
            },
          );
        },
        loading: () => const AppLoader(),
        error: (err, _) => Center(child: Text('Error loading notifications: $err')),
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    WidgetRef ref,
    AppNotificationModel notif,
    bool isDark,
  ) {
    IconData icon;
    Color iconColor;

    switch (notif.type) {
      case 'message':
        icon = Icons.chat_bubble_outline;
        iconColor = AppColors.primary;
        break;
      case 'connection_request':
        icon = Icons.person_add_alt_1_outlined;
        iconColor = AppColors.secondary;
        break;
      case 'bug':
        icon = Icons.pest_control_outlined;
        iconColor = AppColors.accent;
        break;
      default:
        icon = Icons.notifications_outlined;
        iconColor = Colors.grey;
    }

    return ListTile(
      tileColor: notif.isRead
          ? Colors.transparent
          : (isDark ? AppColors.primaryDark.withValues(alpha: 0.15) : AppColors.primaryLight.withValues(alpha: 0.08)),
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.15),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        notif.title,
        style: TextStyle(
          fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(notif.body, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            DateFormat('h:mm a • d MMM').format(notif.createdAt),
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
            ),
          ),
        ],
      ),
      onTap: () async {
        // Mark as read
        if (!notif.isRead) {
          try {
            await ref.read(firestoreServiceProvider).updateDoc(
              '${FirestoreConstants.notifications}/${notif.id}',
              {'isRead': true},
            );
          } catch (_) {}
        }

        // Navigate based on target
        if (!context.mounted) return;
        if (notif.type == 'connection_request') {
          context.push(RoutePaths.connectionRequests);
        } else if (notif.type == 'message' && notif.targetId != null) {
          context.push(RoutePaths.chatDetailsPath(notif.targetId!));
        } else if (notif.type == 'bug' && notif.targetId != null) {
          context.push(RoutePaths.bugDetailsPath(notif.targetId!));
        }
      },
    );
  }
}
