import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../shared/models/connection_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../providers/connection_provider.dart';

class UserSearchScreen extends ConsumerStatefulWidget {
  const UserSearchScreen({super.key});

  @override
  ConsumerState<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends ConsumerState<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final currentUser = ref.read(currentFirebaseUserProvider);
    if (currentUser == null) return;

    setState(() => _isSearching = true);
    try {
      final results = await ref
          .read(connectionRepositoryProvider)
          .searchUsers(clean, currentUser.uid);
      if (mounted) setState(() => _searchResults = results);
    } catch (e) {
      if (mounted) context.showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final currentUser = ref.watch(currentUserModelStreamProvider).value;
    final receivedRequestsAsync = ref.watch(receivedRequestsStreamProvider);
    final sentRequestsAsync = ref.watch(sentRequestsStreamProvider);
    final connectedUsersAsync = ref.watch(connectedUsersStreamProvider);

    final receivedCount = receivedRequestsAsync.when(
      data: (list) => list.length,
      loading: () => 0,
      error: (_, _) => 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Find Collaborators',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.people_outline),
                tooltip: 'Connection Requests',
                onPressed: () => context.push(RoutePaths.connectionRequests),
              ),
              if (receivedCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$receivedCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search by name, username, or email...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                fillColor: isDark
                    ? AppColors.surfaceDark
                    : const Color(0xFFF1F5F9),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isSearching
          ? const AppLoader()
          : _searchController.text.trim().isNotEmpty
          ? _buildSearchResults(
              currentUser,
              isDark,
              sentRequestsAsync.value,
              connectedUsersAsync.value,
            )
          : _buildDefaultConnectionsView(
              connectedUsersAsync,
              isDark,
              currentUser,
            ),
    );
  }

  Widget _buildSearchResults(
    UserModel? currentUser,
    bool isDark,
    List<ConnectionRequestModel>? sentRequests,
    List<UserModel>? connectedUsers,
  ) {
    if (_searchResults.isEmpty) {
      return const AppEmptyView(
        icon: Icons.person_off_outlined,
        title: 'No Users Found',
        message:
            'Try searching with a different name, username, or email address.',
      );
    }

    final sentIds = (sentRequests ?? []).map((r) => r.receiverId).toSet();
    final connectedIds = (connectedUsers ?? []).map((u) => u.id).toSet();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (itemCtx, index) {
        final targetUser = _searchResults[index];
        final isSelf = targetUser.id == currentUser?.id;
        final isConnected = connectedIds.contains(targetUser.id);
        final isPending = sentIds.contains(targetUser.id);

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            if (isSelf) {
              context.push(RoutePaths.profile);
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                AppAvatar(
                  name: targetUser.fullName,
                  imageUrl: targetUser.photoUrl,
                  size: 46,
                  isOnline: targetUser.isOnline,
                  showOnlineIndicator: true,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              targetUser.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (isSelf) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'You',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '@${targetUser.username} • ${targetUser.designation ?? 'Tester'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 96,
                  child: isSelf
                      ? AppButton(
                          text: 'Profile',
                          variant: AppButtonVariant.outline,
                          height: 36,
                          width: 96,
                          onPressed: () => context.push(RoutePaths.profile),
                        )
                      : isConnected
                      ? AppButton(
                          text: 'Message',
                          variant: AppButtonVariant.primary,
                          height: 36,
                          width: 96,
                          onPressed: () async {
                            if (currentUser == null) return;
                            final chatId = await ref
                                .read(connectionRepositoryProvider)
                                .getOrCreateIndividualChat(
                                  currentUser.id,
                                  targetUser.id,
                                  currentUser.fullName,
                                  targetUser.fullName,
                                );
                            if (!mounted) return;
                            context.push(RoutePaths.chatDetailsPath(chatId));
                          },
                        )
                      : isPending
                      ? AppButton(
                          text: 'Pending',
                          variant: AppButtonVariant.outline,
                          height: 36,
                          width: 96,
                          onPressed: () {},
                        )
                      : AppButton(
                          text: 'Connect',
                          variant: AppButtonVariant.fox,
                          height: 36,
                          width: 96,
                          onPressed: () async {
                            if (currentUser == null) return;
                            final scaffold = ScaffoldMessenger.of(context);
                            await ref
                                .read(connectionRepositoryProvider)
                                .sendConnectionRequest(
                                  sender: currentUser,
                                  receiver: targetUser,
                                );
                            if (!mounted) return;
                            scaffold.showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Connection request sent to ${targetUser.fullName}',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultConnectionsView(
    AsyncValue<List<UserModel>> connectedUsersAsync,
    bool isDark,
    UserModel? currentUser,
  ) {
    return connectedUsersAsync.when(
      data: (users) {
        if (users.isEmpty) {
          return const AppEmptyView(
            icon: Icons.group_add_outlined,
            title: 'Expand Your Testing Network',
            message: 'Search for developers, testers, and product managers by email or username to connect and test together.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (itemCtx, index) {
            final user = users[index];
            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                if (currentUser == null) return;
                final chatId = await ref
                    .read(connectionRepositoryProvider)
                    .getOrCreateIndividualChat(
                      currentUser.id,
                      user.id,
                      currentUser.fullName,
                      user.fullName,
                    );
                if (!mounted) return;
                context.push(RoutePaths.chatDetailsPath(chatId));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    AppAvatar(
                      name: user.fullName,
                      imageUrl: user.photoUrl,
                      size: 46,
                      isOnline: user.isOnline,
                      showOnlineIndicator: true,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user.designation ?? '@${user.username}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 96,
                      child: AppButton(
                        text: 'Message',
                        variant: AppButtonVariant.outline,
                        height: 36,
                        width: 96,
                        onPressed: () async {
                          if (currentUser == null) return;
                          final chatId = await ref
                              .read(connectionRepositoryProvider)
                              .getOrCreateIndividualChat(
                                currentUser.id,
                                user.id,
                                currentUser.fullName,
                                user.fullName,
                              );
                          if (!mounted) return;
                          context.push(RoutePaths.chatDetailsPath(chatId));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const AppLoader(),
      error: (e, _) => const AppEmptyView(
        icon: Icons.group_add_outlined,
        title: 'Expand Your Testing Network',
        message: 'Search for developers, testers, and product managers by email or username to connect and test together.',
      ),
    );
  }
}
