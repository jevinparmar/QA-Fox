import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../providers/connection_provider.dart';

class ConnectionRequestsScreen extends ConsumerStatefulWidget {
  const ConnectionRequestsScreen({super.key});

  @override
  ConsumerState<ConnectionRequestsScreen> createState() =>
      _ConnectionRequestsScreenState();
}

class _ConnectionRequestsScreenState
    extends ConsumerState<ConnectionRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final receivedAsync = ref.watch(receivedRequestsStreamProvider);
    final sentAsync = ref.watch(sentRequestsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Requests'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: isDark ? Colors.white : AppColors.primary,
          unselectedLabelColor: isDark
              ? AppColors.textMutedDark
              : AppColors.textSecondaryLight,
          tabs: [
            Tab(text: 'Received (${receivedAsync.value?.length ?? 0})'),
            Tab(text: 'Sent (${sentAsync.value?.length ?? 0})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Received Requests Tab
          receivedAsync.when(
            data: (requests) {
              if (requests.isEmpty) {
                return const AppEmptyView(
                  icon: Icons.mark_email_read_outlined,
                  title: 'No Pending Requests',
                  message: 'When other testers or developers invite you to connect, they will appear here.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (itemCtx, index) {
                  final req = requests[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        AppAvatar(
                          name: req.senderName,
                          imageUrl: req.senderAvatar,
                          size: 44,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                req.senderName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                req.senderDesignation ?? 'Tester / Developer',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () async {
                                final scaffold = ScaffoldMessenger.of(context);
                                await ref
                                    .read(connectionRepositoryProvider)
                                    .declineConnectionRequest(req.id);
                                if (!mounted) return;
                                scaffold.showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Declined connection request.',
                                    ),
                                  ),
                                );
                              },
                              child: const Text(
                                'Decline',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 82,
                              child: AppButton(
                                text: 'Accept',
                                variant: AppButtonVariant.primary,
                                height: 34,
                                width: 82,
                                onPressed: () async {
                                  final scaffold = ScaffoldMessenger.of(
                                    context,
                                  );
                                  await ref
                                      .read(connectionRepositoryProvider)
                                      .acceptConnectionRequest(req);
                                  if (!mounted) return;
                                  scaffold.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Connected with ${req.senderName}!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const AppLoader(),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),

          // Sent Requests Tab
          sentAsync.when(
            data: (requests) {
              if (requests.isEmpty) {
                return const AppEmptyView(
                  icon: Icons.send_outlined,
                  title: 'No Sent Requests',
                  message: 'Requests you send to other users will show here until accepted.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (itemCtx, index) {
                  final req = requests[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        AppAvatar(
                          name: req.receiverName,
                          imageUrl: req.receiverAvatar,
                          size: 44,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                req.receiverName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Invitation Pending',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 84,
                          child: AppButton(
                            text: 'Cancel',
                            variant: AppButtonVariant.outline,
                            height: 34,
                            width: 84,
                            onPressed: () async {
                              final scaffold = ScaffoldMessenger.of(context);
                              await ref
                                  .read(connectionRepositoryProvider)
                                  .cancelSentRequest(req.id);
                              if (!mounted) return;
                              scaffold.showSnackBar(
                                const SnackBar(
                                  content: Text('Request cancelled.'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const AppLoader(),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }
}
