import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/enums/bug_status.dart';
import '../../../../core/enums/bug_severity.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/app_badge.dart';
import '../../../../core/widgets/app_animated_item.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../shared/models/bug_model.dart';
import '../../../bug_reporting/presentation/providers/bug_provider.dart';

class BugBoardScreen extends ConsumerStatefulWidget {
  final String projectId;

  const BugBoardScreen({super.key, required this.projectId});

  @override
  ConsumerState<BugBoardScreen> createState() => _BugBoardScreenState();
}

class _BugBoardScreenState extends ConsumerState<BugBoardScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isKanbanView = false;
  String _searchQuery = '';
  BugStatus? _selectedStatusFilter;
  BugSeverity? _selectedSeverityFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bugsAsync = ref.watch(projectBugsStreamProvider(widget.projectId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bug Board',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isKanbanView
                  ? Icons.view_list_rounded
                  : Icons.view_kanban_rounded,
            ),
            tooltip: _isKanbanView
                ? 'Switch to List View'
                : 'Switch to Kanban View',
            onPressed: () {
              setState(() => _isKanbanView = !_isKanbanView);
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search bugs by ID, title, or assignee...',
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
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    fillColor: isDark
                        ? AppColors.surfaceDark
                        : const Color(0xFFF1F5F9),
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        color: isDark ? AppColors.secondary : AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 6.0,
                ),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All Statuses'),
                      selected: _selectedStatusFilter == null,
                      onSelected: (_) =>
                          setState(() => _selectedStatusFilter = null),
                      selectedColor: isDark ? AppColors.secondary : AppColors.primary,
                      labelStyle: TextStyle(
                        color: _selectedStatusFilter == null
                            ? Colors.white
                            : null,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    ...BugStatus.values.map((s) {
                      final isSelected = _selectedStatusFilter == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: FilterChip(
                          label: Text(s.label),
                          selected: isSelected,
                          onSelected: (_) => setState(
                            () => _selectedStatusFilter = isSelected ? null : s,
                          ),
                          selectedColor: s.color,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : null,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: bugsAsync.when(
        data: (bugs) {
          final filtered = bugs.where((b) {
            if (_selectedStatusFilter != null &&
                b.status != _selectedStatusFilter) {
              return false;
            }
            if (_selectedSeverityFilter != null &&
                b.severity != _selectedSeverityFilter) {
              return false;
            }
            if (_searchQuery.isNotEmpty) {
              final idMatch = b.bugNumber.toLowerCase().contains(_searchQuery);
              final titleMatch = b.title.toLowerCase().contains(_searchQuery);
              final assigneeMatch =
                  b.assigneeName?.toLowerCase().contains(_searchQuery) ?? false;
              if (!idMatch && !titleMatch && !assigneeMatch) return false;
            }
            return true;
          }).toList();

          if (filtered.isEmpty) {
            return const AppEmptyView(
              icon: Icons.pest_control_outlined,
              title: 'No Bugs Found',
              message: 'No bug reports match your search or filter criteria.',
            );
          }

          return _isKanbanView
              ? _buildKanbanView(filtered, isDark)
              : _buildListView(filtered, isDark);
        },
        loading: () => const AppLoader(),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildListView(List<BugModel> bugs, bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bugs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final bug = bugs[index];
        return AppAnimatedItem(
          index: index,
          child: Material(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push(RoutePaths.bugDetailsPath(bug.id)),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.foxGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            bug.bugNumber,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          bug.category.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.secondary
                                : AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        AppBadge.status(bug.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      bug.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        AppBadge.severity(bug.severity),
                        const SizedBox(width: 6),
                        AppBadge.priority(bug.priority),
                        const Spacer(),
                        if (bug.assigneeName != null) ...[
                          Icon(Icons.person, size: 13, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text(
                            bug.assigneeName!,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Unassigned',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textMutedLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildKanbanView(List<BugModel> bugs, bool isDark) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(14),
      children: BugStatus.values.map((status) {
        final columnBugs = bugs.where((b) => b.status == status).toList();
        return Container(
          width: 280,
          margin: const EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Column Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.15),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(14),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: status.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: status.color,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        columnBugs.length.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: status.color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bug Cards in this Column
              Expanded(
                child: columnBugs.isEmpty
                    ? Center(
                        child: Text(
                          'No ${status.label} bugs',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(10),
                        itemCount: columnBugs.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final bug = columnBugs[idx];
                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => context.push(
                                RoutePaths.bugDetailsPath(bug.id),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          bug.bugNumber,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                        const Spacer(),
                                        AppBadge.severity(bug.severity),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      bug.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Text(
                                          bug.category.label,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (bug.assigneeName != null)
                                          Text(
                                            bug.assigneeName!,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
