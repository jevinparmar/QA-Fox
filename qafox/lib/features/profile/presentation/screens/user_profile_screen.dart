import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../shared/models/connection_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../providers/connection_provider.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  final UserModel? initialUser;

  const UserProfileScreen({
    super.key,
    required this.userId,
    this.initialUser,
  });

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  UserModel? _user;
  bool _isLoading = false;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    _user = widget.initialUser;
    if (_user == null) {
      _fetchUser();
    }
  }

  Future<void> _fetchUser() async {
    setState(() => _isLoading = true);
    try {
      final firestore = ref.read(firestoreServiceProvider);
      final doc = await firestore.getDoc('${FirestoreConstants.users}/${widget.userId}');
      if (doc.exists && doc.data() != null) {
        if (mounted) {
          setState(() {
            _user = UserModel.fromMap(doc.data()!, doc.id);
          });
        }
      }
    } catch (e) {
      if (mounted) context.showSnackBar('Error loading profile: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final currentUser = ref.watch(currentUserModelStreamProvider).value;
    final receivedRequests = ref.watch(receivedRequestsStreamProvider).value ?? [];
    final sentRequests = ref.watch(sentRequestsStreamProvider).value ?? [];
    final connectedUsers = ref.watch(connectedUsersStreamProvider).value ?? [];

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Profile')),
        body: const AppLoader(),
      );
    }

    final targetUser = _user;
    if (targetUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_off_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('User not found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.pop(), child: const Text('Go Back')),
            ],
          ),
        ),
      );
    }

    final isSelf = currentUser?.id == targetUser.id;
    final isConnected = connectedUsers.any((u) => u.id == targetUser.id);
    final pendingSent = sentRequests.firstWhere(
      (r) => r.receiverId == targetUser.id,
      orElse: () => ConnectionRequestModel.empty(),
    );
    final pendingReceived = receivedRequests.firstWhere(
      (r) => r.senderId == targetUser.id,
      orElse: () => ConnectionRequestModel.empty(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          targetUser.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            // Avatar & Online Badge
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AppAvatar(
                    name: targetUser.fullName,
                    imageUrl: targetUser.photoUrl,
                    size: 104,
                    isOnline: targetUser.isOnline,
                    showOnlineIndicator: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Name & Username
            Text(
              targetUser.fullName,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '@${targetUser.username}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            // Designation / Role Chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                targetUser.designation ?? 'Tester / Collaborator',
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Dynamic Action Button Bar
            _buildActionButtons(
              context: context,
              isSelf: isSelf,
              isConnected: isConnected,
              hasPendingSent: pendingSent.id.isNotEmpty,
              hasPendingReceived: pendingReceived.id.isNotEmpty,
              pendingSentId: pendingSent.id,
              pendingReceivedRequest: pendingReceived,
              currentUser: currentUser,
              targetUser: targetUser,
            ),
            const SizedBox(height: 28),

            // Details Card (Protected according to connection & privacy status)
            if (!isSelf && !isConnected)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: (isDark ? AppColors.secondary : AppColors.primary)
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.lock_outline,
                            size: 28,
                            color: isDark ? AppColors.secondary : AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Profile Information Hidden',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          pendingSent.id.isNotEmpty
                              ? 'Your connection request is pending. Information will be shared once accepted.'
                              : 'Connect with ${targetUser.fullName.split(' ').first} to view their collaboration details.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About Collaborator',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      // Only visible to the user viewing their own profile
                      if (isSelf) ...[
                        _buildInfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: targetUser.email,
                          isDark: isDark,
                        ),
                        if (targetUser.phoneNumber != null && targetUser.phoneNumber!.isNotEmpty) ...[
                          const Divider(height: 24),
                          _buildInfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: targetUser.phoneNumber!,
                            isDark: isDark,
                          ),
                        ],
                        const Divider(height: 24),
                      ],
                      // Bio (shown when connected or self)
                      if (targetUser.bio != null && targetUser.bio!.isNotEmpty) ...[
                        _buildInfoRow(
                          icon: Icons.article_outlined,
                          label: 'Bio',
                          value: targetUser.bio!,
                          isDark: isDark,
                        ),
                        const Divider(height: 24),
                      ],
                      if (!isSelf) ...[
                        _buildInfoRow(
                          icon: Icons.mark_chat_unread_outlined,
                          label: 'Direct Messaging',
                          value: 'Connected in QA Fox',
                          isDark: isDark,
                        ),
                        const Divider(height: 24),
                      ],
                      _buildInfoRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Member Since',
                        value: DateFormat('MMMM yyyy').format(targetUser.createdAt ?? DateTime.now()),
                        isDark: isDark,
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        icon: Icons.circle,
                        iconColor: targetUser.isOnline ? Colors.green : Colors.grey,
                        label: 'Status',
                        value: targetUser.isOnline ? 'Online now' : 'Offline',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons({
    required BuildContext context,
    required bool isSelf,
    required bool isConnected,
    required bool hasPendingSent,
    required bool hasPendingReceived,
    required String pendingSentId,
    required ConnectionRequestModel pendingReceivedRequest,
    required UserModel? currentUser,
    required UserModel targetUser,
  }) {
    if (isSelf) {
      return AppButton(
        text: 'Edit My Profile',
        icon: const Icon(Icons.edit_outlined, size: 18),
        onPressed: () => context.push(RoutePaths.editProfile),
        variant: AppButtonVariant.outline,
      );
    }

    if (isConnected) {
      return Row(
        children: [
          Expanded(
            child: AppButton(
              text: 'Message',
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              isLoading: _isActionLoading,
              onPressed: () async {
                if (currentUser == null) return;
                setState(() => _isActionLoading = true);
                try {
                  final chatId = await ref
                      .read(connectionRepositoryProvider)
                      .getOrCreateIndividualChat(
                        currentUser.id,
                        targetUser.id,
                        currentUser.fullName,
                        targetUser.fullName,
                      );
                  if (context.mounted) {
                    context.push(RoutePaths.chatDetailsPath(chatId));
                  }
                } catch (e) {
                  if (context.mounted) context.showSnackBar('Error opening chat: $e', isError: true);
                } finally {
                  if (mounted) setState(() => _isActionLoading = false);
                }
              },
              variant: AppButtonVariant.primary,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
            ),
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 18),
                  SizedBox(width: 6),
                  Text('Connected', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (hasPendingReceived) {
      return Row(
        children: [
          Expanded(
            child: AppButton(
              text: 'Accept Request',
              icon: const Icon(Icons.check, size: 18),
              isLoading: _isActionLoading,
              variant: AppButtonVariant.primary,
              onPressed: () async {
                setState(() => _isActionLoading = true);
                try {
                  await ref
                      .read(connectionRepositoryProvider)
                      .acceptConnectionRequest(pendingReceivedRequest);
                  if (context.mounted) {
                    context.showSuccessSnackBar('Connected with ${targetUser.fullName}!');
                  }
                } catch (e) {
                  if (context.mounted) context.showSnackBar('Failed to accept: $e', isError: true);
                } finally {
                  if (mounted) setState(() => _isActionLoading = false);
                }
              },
            ),
          ),
          const SizedBox(width: 12),
          AppButton(
            text: 'Decline',
            variant: AppButtonVariant.outline,
            width: 100,
            onPressed: () async {
              try {
                await ref
                    .read(connectionRepositoryProvider)
                    .declineConnectionRequest(pendingReceivedRequest.id);
                if (context.mounted) context.showSnackBar('Declined connection request.');
              } catch (e) {
                if (context.mounted) context.showSnackBar('Error: $e', isError: true);
              }
            },
          ),
        ],
      );
    }

    if (hasPendingSent) {
      return Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.access_time, color: AppColors.accent, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Invitation Pending',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          AppButton(
            text: 'Cancel',
            variant: AppButtonVariant.outline,
            width: 90,
            onPressed: () async {
              try {
                await ref.read(connectionRepositoryProvider).cancelSentRequest(pendingSentId);
                if (context.mounted) context.showSnackBar('Request cancelled.');
              } catch (e) {
                if (context.mounted) context.showSnackBar('Error: $e', isError: true);
              }
            },
          ),
        ],
      );
    }

    // Default: Not connected -> Send connection request
    return AppButton(
      text: 'Connect with ${targetUser.fullName.split(' ').first}',
      icon: const Icon(Icons.person_add_outlined, size: 18),
      isLoading: _isActionLoading,
      variant: AppButtonVariant.primary,
      onPressed: () async {
        if (currentUser == null) return;
        setState(() => _isActionLoading = true);
        try {
          await ref.read(connectionRepositoryProvider).sendConnectionRequest(
                sender: currentUser,
                receiver: targetUser,
              );
          if (context.mounted) {
            context.showSuccessSnackBar('Connection request sent to ${targetUser.fullName}!');
          }
        } catch (e) {
          if (context.mounted) context.showSnackBar('Failed to send request: $e', isError: true);
        } finally {
          if (mounted) setState(() => _isActionLoading = false);
        }
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    Color? iconColor,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor ?? (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
