import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../../core/enums/app_status.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_loader.dart';
import '../../../../shared/models/chat_model.dart';
import '../../../../shared/models/message_model.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/bug_report_message_card.dart';
import '../../../../shared/widgets/chat_message_bubble.dart';
import '../../../projects/presentation/widgets/add_group_members_dialog.dart';
import '../providers/chat_provider.dart';
import 'attachment_preview_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _markRead() async {
    final user = ref.read(currentFirebaseUserProvider);
    if (user != null) {
      ref.read(chatRepositoryProvider).markChatAsRead(widget.chatId, user.uid);
    }
  }

  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(currentUserModelStreamProvider).value;
    if (user == null) return;

    _textController.clear();
    setState(() => _isSending = true);

    try {
      final msg = MessageModel(
        id: const Uuid().v4(),
        chatId: widget.chatId,
        senderId: user.id,
        senderName: user.fullName,
        senderAvatar: user.photoUrl,
        type: MessageType.text,
        content: text,
        createdAt: DateTime.now(),
      );

      await ref.read(chatRepositoryProvider).sendMessage(msg);
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      if (mounted) context.showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Share Content',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: AppColors.secondary,
                  ),
                ),
                title: const Text('Gallery (Photos & Images)'),
                subtitle: const Text(
                  'Send one or multiple images with preview & captions',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImagesFromGallery();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text('Camera'),
                subtitle: const Text('Capture and review photo before sending'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhotoFromCamera();
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
                    Icons.insert_drive_file,
                    color: AppColors.accent,
                  ),
                ),
                title: const Text('Document'),
                subtitle: const Text('Send PDF, docs, logs, or other files'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickDocuments();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImagesFromGallery() async {
    final picker = ref.read(imagePickerServiceProvider);
    final files = await picker.pickMultipleImages(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (files.isEmpty) return;

    final attachments = <PendingAttachment>[];
    for (final f in files) {
      attachments.add(await PendingAttachment.fromXFile(f, isImage: true));
    }

    if (mounted) {
      await AttachmentPreviewScreen.show(
        context,
        chatId: widget.chatId,
        attachments: attachments,
      );
    }
  }

  Future<void> _pickPhotoFromCamera() async {
    final picker = ref.read(imagePickerServiceProvider);
    final file = await picker.pickImageFromCamera(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 75,
    );
    if (file == null) return;

    final attachment = await PendingAttachment.fromXFile(file, isImage: true);
    if (mounted) {
      await AttachmentPreviewScreen.show(
        context,
        chatId: widget.chatId,
        attachments: [attachment],
      );
    }
  }

  Future<void> _pickDocuments() async {
    final pickedFiles = await FilePicker.pickFiles();
    if (pickedFiles.isEmpty) return;

    final attachments = <PendingAttachment>[];
    for (final pf in pickedFiles) {
      attachments.add(
        await PendingAttachment.fromXFile(pf.xFile, isImage: false),
      );
    }

    if (mounted) {
      await AttachmentPreviewScreen.show(
        context,
        chatId: widget.chatId,
        attachments: attachments,
      );
    }
  }

  void _showMessageOptions(MessageModel msg, bool isSender) {
    final user = ref.read(currentUserModelStreamProvider).value;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    AppAvatar(
                      name: msg.senderName,
                      imageUrl: msg.senderAvatar,
                      size: 32,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg.senderName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            msg.type == MessageType.bugReport
                                ? '🐛 Bug: ${msg.content}'
                                : msg.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              if (msg.content.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.copy, size: 20),
                  title: const Text('Copy Text'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: msg.content));
                    Navigator.pop(ctx);
                    context.showSuccessSnackBar('Copied to clipboard');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, size: 20),
                title: const Text('Delete for me'),
                subtitle: const Text(
                  'Remove from your view only',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref
                      .read(chatRepositoryProvider)
                      .deleteMessageForMe(widget.chatId, msg.id, user.id);
                  if (mounted) context.showSnackBar('Message deleted for you');
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever,
                  size: 20,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Delete for everyone',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Permanently remove for all members so no one can read it',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Delete for everyone?'),
                      content: const Text(
                        'This message will be permanently deleted for all members in this conversation. No one will be able to read it.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                          onPressed: () => Navigator.pop(dCtx, true),
                          child: const Text(
                            'Delete for Everyone',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref
                        .read(chatRepositoryProvider)
                        .deleteMessageForEveryone(widget.chatId, msg.id);
                    if (mounted) {
                      context.showSuccessSnackBar(
                        'Message permanently deleted for all members',
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearChatOptions() {
    final user = ref.read(currentUserModelStreamProvider).value;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Clear Chat / Delete All'),
        content: const Text(
          'Choose how you want to clear the messages in this chat:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dCtx);
              await ref
                  .read(chatRepositoryProvider)
                  .deleteAllMessagesForMe(widget.chatId, user.id);
              if (mounted) {
                context.showSnackBar('Chat cleared for you');
              }
            },
            child: const Text('Delete for Me'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dCtx);
              await ref
                  .read(chatRepositoryProvider)
                  .deleteAllMessagesForEveryone(widget.chatId);
              if (mounted) {
                context.showSuccessSnackBar(
                  'Chat permanently cleared for all members',
                );
              }
            },
            child: const Text(
              'Delete for Everyone',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final currentUser = ref.watch(currentUserModelStreamProvider).value;
    final messagesAsync = ref.watch(chatMessagesStreamProvider(widget.chatId));

    // Fetch chat metadata
    final chatDocAsync = ref
        .watch(firestoreServiceProvider)
        .streamDoc('${FirestoreConstants.chats}/${widget.chatId}');

    return StreamBuilder(
      stream: chatDocAsync,
      builder: (context, snapshot) {
        ChatModel? chat;
        if (snapshot.hasData &&
            snapshot.data!.exists &&
            snapshot.data!.data() != null) {
          chat = ChatModel.fromMap(snapshot.data!.data()!, snapshot.data!.id);
        }

        final isGroup = chat?.type == ChatType.projectGroup;
        final chatTitle = chat?.name ?? 'Chat';
        final projectId = chat?.projectId;
        final otherUserId = chat?.participantIds.firstWhere(
          (id) => id != currentUser?.id,
          orElse: () => '',
        );

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (isGroup && projectId != null) {
                  context.push(RoutePaths.projectDetailsPath(projectId));
                } else if (!isGroup && otherUserId != null && otherUserId.isNotEmpty) {
                  context.push(RoutePaths.userProfilePath(otherUserId));
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppAvatar(name: chatTitle, imageUrl: chat?.iconUrl, size: 38),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          chatTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isGroup
                              ? '${chat?.participantIds.length ?? 0} members • Testing Group'
                              : 'Direct Message',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (isGroup && projectId != null) ...[
                IconButton(
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  tooltip: 'Add Members',
                  onPressed: () {
                    AddGroupMembersDialog.show(
                      context,
                      projectId: projectId,
                      groupName: chatTitle,
                      existingMemberIds: chat?.participantIds ?? [],
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.dashboard_outlined),
                  tooltip: 'Bug Board',
                  onPressed: () {
                    context.push(RoutePaths.bugBoardPath(projectId));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  tooltip: 'Group Details & Members',
                  onPressed: () {
                    context.push(RoutePaths.projectDetailsPath(projectId));
                  },
                ),
              ],
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'More Options',
                onSelected: (val) {
                  if (val == 'clear') {
                    _showClearChatOptions();
                  } else if (val == 'details' && projectId != null) {
                    context.push(RoutePaths.projectDetailsPath(projectId));
                  } else if (val == 'add_members' && projectId != null) {
                    AddGroupMembersDialog.show(
                      context,
                      projectId: projectId,
                      groupName: chatTitle,
                      existingMemberIds: chat?.participantIds ?? [],
                    );
                  }
                },
                itemBuilder: (ctx) => [
                  if (isGroup && projectId != null) ...[
                    const PopupMenuItem<String>(
                      value: 'details',
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 20),
                          SizedBox(width: 10),
                          Text('Group Details & Members'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'add_members',
                      child: Row(
                        children: [
                          Icon(Icons.person_add_alt_1_outlined, size: 20),
                          SizedBox(width: 10),
                          Text('Add Members'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                  ],
                  const PopupMenuItem<String>(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_sweep_outlined,
                          size: 20,
                          color: AppColors.error,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Clear Chat / Delete All',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Messages List
              Expanded(
                child: messagesAsync.when(
                  data: (rawMessages) {
                    final messages = rawMessages
                        .where((m) => !m.deletedFor.contains(currentUser?.id))
                        .toList();
                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          'No messages yet. Send a greeting or submit a bug report!',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textMutedDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      reverse: true,
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isSender = msg.senderId == currentUser?.id;

                        // Structured Bug Card
                        if (msg.type == MessageType.bugReport) {
                          return BugReportMessageCard(
                            message: msg,
                            isSender: isSender,
                            onTap: () {
                              if (msg.bugId != null) {
                                context.push(
                                  RoutePaths.bugDetailsPath(msg.bugId!),
                                );
                              }
                            },
                            onLongPress: () =>
                                _showMessageOptions(msg, isSender),
                          );
                        }

                        // Normal Message Bubble
                        return ChatMessageBubble(
                          message: msg,
                          isSender: isSender,
                          isGroup: isGroup,
                          onLongPress: () => _showMessageOptions(msg, isSender),
                        );
                      },
                    );
                  },
                  loading: () => const AppLoader(),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),

              // Bottom Composer Bar
              _buildComposerBar(context, isDark, isGroup, projectId),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComposerBar(
    BuildContext context,
    bool isDark,
    bool isGroup,
    String? projectId,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Attachment Button
            IconButton(
              icon: const Icon(
                Icons.attach_file,
                color: AppColors.secondary,
                size: 24,
              ),
              tooltip: 'Attach Media or Document',
              onPressed: _isSending ? null : _showAttachmentOptions,
            ),

            // Report Bug Button (Responsive: icon-only on compact, full chip on wider screens)
            Builder(
              builder: (ctx) {
                final isCompact = MediaQuery.of(ctx).size.width < 460;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      context.push(RoutePaths.reportBugPath(widget.chatId));
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 8 : 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.foxGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bug_report,
                            size: 16,
                            color: Colors.white,
                          ),
                          if (!isCompact) ...[
                            const SizedBox(width: 4),
                            const Text(
                              'Report Bug',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),

            // Message Input
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendTextMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Send Button
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.secondary : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                onPressed: _isSending ? null : _sendTextMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
