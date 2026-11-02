import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/asset_constants.dart';
import '../../../../core/enums/app_status.dart';
import '../../../../core/extensions/date_extensions.dart';
import '../../../../core/widgets/app_animated_item.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../shared/models/chat_model.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../providers/chat_provider.dart';

class ChatsDashboardScreen extends ConsumerStatefulWidget {
  const ChatsDashboardScreen({super.key});

  @override
  ConsumerState<ChatsDashboardScreen> createState() =>
      _ChatsDashboardScreenState();
}

class _ChatsDashboardScreenState extends ConsumerState<ChatsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedChatIds = {};

  bool get _isSelectionMode => _selectedChatIds.isNotEmpty;

  void _clearSelection() {
    setState(() {
      _selectedChatIds.clear();
    });
  }

  void _toggleChatSelection(String chatId) {
    setState(() {
      if (_selectedChatIds.contains(chatId)) {
        _selectedChatIds.remove(chatId);
      } else {
        _selectedChatIds.add(chatId);
      }
    });
  }

  Future<void> _confirmDeleteSelected(String userId) async {
    final count = _selectedChatIds.length;
    if (count == 0 || userId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${count == 1 ? 'chat' : '$count chats'}?'),
        content: Text(
          count == 1
              ? 'This conversation will be removed from your chat list. Other participants will not be affected.'
              : 'These $count conversations will be removed from your chat list. Other participants will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    final chatIdsToDelete = _selectedChatIds.toList();
    _clearSelection();

    final scaffold = ScaffoldMessenger.of(context);
    try {
      final chatRepo = ref.read(chatRepositoryProvider);
      await chatRepo.deleteMultipleChatsForUser(chatIdsToDelete, userId);
      if (!mounted) return;
      scaffold.showSnackBar(
        SnackBar(
          content: Text(
            '${chatIdsToDelete.length} ${chatIdsToDelete.length == 1 ? 'chat' : 'chats'} deleted',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      scaffold.showSnackBar(
        const SnackBar(
          content: Text('Unable to delete conversation. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserModelStreamProvider).value;
    final allChatsAsync = ref.watch(userChatsStreamProvider);
    final groupChatsAsync = ref.watch(userGroupChatsStreamProvider);

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSelectionMode) {
          _clearSelection();
        }
      },
      child: Scaffold(
        appBar: _isSelectionMode
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancel selection',
                  onPressed: _clearSelection,
                ),
                title: Text(
                  '${_selectedChatIds.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete for me',
                    onPressed: () =>
                        _confirmDeleteSelected(currentUser?.id ?? ''),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppColors.primary,
                    indicatorWeight: 3,
                    labelColor: isDark ? Colors.white : AppColors.primary,
                    unselectedLabelColor: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textSecondaryLight,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    tabs: const [
                      Tab(text: 'Chats'),
                      Tab(text: 'Project Groups'),
                    ],
                  ),
                ),
              )
            : AppBar(
                titleSpacing: 16,
                title: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFF1F5F9),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          AssetConstants.logoPath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.pest_control,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : AppColors.textMainLight,
                          letterSpacing: -0.2,
                        ),
                        children: const [
                          TextSpan(text: 'QA '),
                          TextSpan(
                            text: 'Fox',
                            style: TextStyle(color: AppColors.accent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none_outlined),
                    tooltip: 'Notifications',
                    onPressed: () => context.push(RoutePaths.notifications),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0, left: 4.0),
                    child: GestureDetector(
                      onTap: () => context.push(RoutePaths.profile),
                      child: AppAvatar(
                        name: currentUser?.fullName ?? 'User',
                        imageUrl: currentUser?.photoUrl,
                        size: 34,
                      ),
                    ),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(104),
                  child: Column(
                    children: [
                      // Search Input Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(
                            () => _searchQuery = val.trim().toLowerCase(),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search chats, bugs, or groups...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
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
                      TabBar(
                        controller: _tabController,
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 3,
                        labelColor: isDark ? Colors.white : AppColors.primary,
                        unselectedLabelColor: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textSecondaryLight,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        tabs: const [
                          Tab(text: 'Chats'),
                          Tab(text: 'Project Groups'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab A: All Chats
            allChatsAsync.when(
              data: (chats) {
                final filteredChats = chats.where((c) {
                  if (_searchQuery.isEmpty) return true;
                  return c.name.toLowerCase().contains(_searchQuery) ||
                      (c.lastMessage?.toLowerCase().contains(_searchQuery) ??
                          false);
                }).toList();

                if (filteredChats.isEmpty) {
                  return AppEmptyView(
                    icon: Icons.chat_bubble_outline,
                    title: 'No Conversations Yet',
                    message: 'Connect with team members or create a project to start collaborating on testing.',
                    buttonText: 'Find Teammates',
                    onButtonPressed: () => context.push(RoutePaths.search),
                  );
                }

                return ListView.separated(
                  itemCount: filteredChats.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    indent: 72,
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                  itemBuilder: (context, index) {
                    final chat = filteredChats[index];
                    return AppAnimatedItem(
                      index: index,
                      child: _buildChatTile(chat, currentUser?.id ?? '', isDark),
                    );
                  },
                );
              },
              loading: () => const AppLoader(),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),

            // Tab B: Project Groups
            groupChatsAsync.when(
              data: (groups) {
                final filteredGroups = groups.where((g) {
                  if (_searchQuery.isEmpty) return true;
                  return g.name.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filteredGroups.isEmpty) {
                  return AppEmptyView(
                    icon: Icons.group_work_outlined,
                    title: 'No Project Groups',
                    message: 'Create a project in your organization to automatically set up its testing group chat.',
                    buttonText: 'Create Project',
                    onButtonPressed: () =>
                        context.push(RoutePaths.createProject),
                  );
                }

                return ListView.separated(
                  itemCount: filteredGroups.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    indent: 72,
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                  itemBuilder: (context, index) {
                    final group = filteredGroups[index];
                    return AppAnimatedItem(
                      index: index,
                      child: _buildChatTile(
                        group,
                        currentUser?.id ?? '',
                        isDark,
                        isGroupTab: true,
                      ),
                    );
                  },
                );
              },
              loading: () => const AppLoader(),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ],
        ),
        floatingActionButton: _isSelectionMode
            ? null
            : FloatingActionButton(
                heroTag: 'chats_dashboard_fab',
                onPressed: () {
                  _showChatActionMenu(context);
                },
                backgroundColor: AppColors.accent,
                elevation: 3,
                child: const Icon(
                  Icons.add_comment_rounded,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildChatTile(
    ChatModel chat,
    String currentUserId,
    bool isDark, {
    bool isGroupTab = false,
  }) {
    final unread = chat.unreadCounts[currentUserId] ?? 0;
    final isGroup = chat.type == ChatType.projectGroup;
    final isSelected = _selectedChatIds.contains(chat.id);

    return Material(
      color: isSelected
          ? (isDark
                ? AppColors.primary.withValues(alpha: 0.25)
                : AppColors.primary.withValues(alpha: 0.12))
          : Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        onTap: () {
          if (_isSelectionMode) {
            _toggleChatSelection(chat.id);
          } else {
            context.push(RoutePaths.chatDetailsPath(chat.id));
          }
        },
        onLongPress: () {
          _toggleChatSelection(chat.id);
        },
        leading: Stack(
          children: [
            AppAvatar(
              name: chat.name,
              imageUrl: chat.iconUrl,
              size: 52,
              backgroundColor: isGroup
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : null,
            ),
            if (isGroup)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.group, size: 10, color: Colors.white),
                ),
              ),
            if (isSelected)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.85),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 26),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                chat.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w600,
                  color: isDark
                      ? AppColors.textMainDark
                      : AppColors.textMainLight,
                ),
              ),
            ),
            if (chat.lastMessageAt != null)
              Text(
                chat.lastMessageAt!.chatTimestamp,
                style: TextStyle(
                  fontSize: 11.5,
                  color: unread > 0
                      ? AppColors.primary
                      : (isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight),
                  fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  chat.lastMessage ??
                      (isGroup ? 'Project testing channel' : 'Tap to chat'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: unread > 0
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                    fontWeight: unread > 0
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (chat.isPinned) ...[
                const SizedBox(width: 4),
                Icon(Icons.push_pin, size: 14, color: AppColors.accent),
              ],
              if (unread > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unread.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showChatActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceDark
              : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_alt_1,
                  color: AppColors.primary,
                ),
              ),
              title: const Text(
                'Find & Connect with Teammates',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Search users to start individual testing chats',
              ),
              onTap: () {
                Navigator.pop(ctx);
                context.push(RoutePaths.search);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_shared_outlined,
                  color: AppColors.accent,
                ),
              ),
              title: const Text(
                'Create New Project',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Set up a project with its dedicated testing group chat',
              ),
              onTap: () {
                Navigator.pop(ctx);
                context.push(RoutePaths.createProject);
              },
            ),
          ],
        ),
      ),
    );
  }
}
