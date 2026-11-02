import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../profile/presentation/providers/connection_provider.dart';
import '../providers/project_provider.dart';

class AddGroupMembersDialog extends ConsumerStatefulWidget {
  final String projectId;
  final String groupName;
  final List<String> existingMemberIds;

  const AddGroupMembersDialog({
    super.key,
    required this.projectId,
    required this.groupName,
    required this.existingMemberIds,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String projectId,
    required String groupName,
    required List<String> existingMemberIds,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AddGroupMembersDialog(
        projectId: projectId,
        groupName: groupName,
        existingMemberIds: existingMemberIds,
      ),
    );
  }

  @override
  ConsumerState<AddGroupMembersDialog> createState() =>
      _AddGroupMembersDialogState();
}

class _AddGroupMembersDialogState extends ConsumerState<AddGroupMembersDialog> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  List<UserModel> _allAvailableUsers = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAvailableUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableUsers() async {
    final currentUser = ref.read(currentFirebaseUserProvider);
    if (currentUser == null) return;

    try {
      final users = await ref
          .read(connectionRepositoryProvider)
          .getAllUsers(currentUser.uid);
      if (mounted) {
        setState(() {
          _allAvailableUsers = users
              .where((u) => !widget.existingMemberIds.contains(u.id))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleSelectAll(List<UserModel> filtered) {
    setState(() {
      final allFilteredSelected = filtered.every(
        (u) => _selectedUserIds.contains(u.id),
      );
      if (allFilteredSelected) {
        for (final u in filtered) {
          _selectedUserIds.remove(u.id);
        }
      } else {
        for (final u in filtered) {
          _selectedUserIds.add(u.id);
        }
      }
    });
  }

  Future<void> _submitAddMembers() async {
    if (_selectedUserIds.isEmpty) return;

    final currentUser = ref.read(currentUserModelStreamProvider).value;
    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(projectRepositoryProvider)
          .addMembersToProject(
            widget.projectId,
            _selectedUserIds.toList(),
            addedByName: currentUser?.fullName,
          );

      if (mounted) {
        context.showSuccessSnackBar(
          'Added ${_selectedUserIds.length} member(s) to ${widget.groupName}!',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar('Failed to add members: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    final filteredUsers = _allAvailableUsers.where((u) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return u.fullName.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();

    final allSelected =
        filteredUsers.isNotEmpty &&
        filteredUsers.every((u) => _selectedUserIds.contains(u.id));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.group_add,
                      color: AppColors.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Add Members to Group',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.groupName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Search Input
              TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'Search users by name or email...',
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
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF1F5F9),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Action Bar: Select All / Deselect All
              if (!_isLoading && filteredUsers.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available Users (${filteredUsers.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _toggleSelectAll(filteredUsers),
                      icon: Icon(
                        allSelected ? Icons.deselect : Icons.select_all,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        allSelected ? 'Deselect All' : 'Select All',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

              // List of Users
              Expanded(
                child: _isLoading
                    ? const Center(child: AppLoader())
                    : filteredUsers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'All registered users are already members of this group!'
                                : 'No users found matching "$_searchQuery"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textMutedDark
                                  : AppColors.textMutedLight,
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, idx) {
                          final user = filteredUsers[idx];
                          final isSelected = _selectedUserIds.contains(user.id);

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedUserIds.add(user.id);
                                } else {
                                  _selectedUserIds.remove(user.id);
                                }
                              });
                            },
                            activeColor: AppColors.primary,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            secondary: AppAvatar(
                              name: user.fullName,
                              imageUrl: user.photoUrl,
                              size: 38,
                            ),
                            title: Text(
                              user.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              '@${user.username} • ${user.email}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const Divider(height: 20),

              // Bottom Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _selectedUserIds.isEmpty || _isSubmitting
                        ? null
                        : _submitAddMembers,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Add Selected (${_selectedUserIds.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
