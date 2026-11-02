import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/enums/app_status.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../shared/models/message_model.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../../shared/widgets/app_file_image.dart';
import '../providers/chat_provider.dart';

class PendingAttachment {
  final XFile file;
  final bool isImage;
  final String name;
  final int size;

  PendingAttachment({
    required this.file,
    required this.isImage,
    required this.name,
    required this.size,
  });

  static Future<PendingAttachment> fromXFile(
    XFile file, {
    bool? isImage,
  }) async {
    final name = file.name;
    final ext = name.split('.').last.toLowerCase();
    final img =
        isImage ?? ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext);
    final size = await file.length();
    return PendingAttachment(file: file, isImage: img, name: name, size: size);
  }
}

class AttachmentPreviewScreen extends ConsumerStatefulWidget {
  final String chatId;
  final List<PendingAttachment> initialAttachments;

  const AttachmentPreviewScreen({
    super.key,
    required this.chatId,
    required this.initialAttachments,
  });

  static Future<void> show(
    BuildContext context, {
    required String chatId,
    required List<PendingAttachment> attachments,
  }) async {
    if (attachments.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AttachmentPreviewScreen(
          chatId: chatId,
          initialAttachments: attachments,
        ),
      ),
    );
  }

  @override
  ConsumerState<AttachmentPreviewScreen> createState() =>
      _AttachmentPreviewScreenState();
}

class _AttachmentPreviewScreenState
    extends ConsumerState<AttachmentPreviewScreen> {
  late List<PendingAttachment> _attachments;
  late PageController _pageController;
  final TextEditingController _captionController = TextEditingController();

  int _currentIndex = 0;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatusText = '';

  @override
  void initState() {
    super.initState();
    _attachments = List.from(widget.initialAttachments);
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  void _removeAttachment(int index) {
    if (_attachments.length <= 1) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _attachments.removeAt(index);
      if (_currentIndex >= _attachments.length) {
        _currentIndex = _attachments.length - 1;
      }
    });

    _pageController.jumpToPage(_currentIndex);
  }

  Future<void> _pickAdditionalImages() async {
    final picker = ref.read(imagePickerServiceProvider);
    final files = await picker.pickMultipleImages(
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (files.isNotEmpty) {
      final list = <PendingAttachment>[];
      for (final f in files) {
        list.add(await PendingAttachment.fromXFile(f, isImage: true));
      }
      setState(() {
        _attachments.addAll(list);
      });
    }
  }

  Future<void> _pickAdditionalFiles() async {
    final pickedFiles = await FilePicker.pickFiles();
    if (pickedFiles.isNotEmpty) {
      final list = <PendingAttachment>[];
      for (final pf in pickedFiles) {
        list.add(await PendingAttachment.fromXFile(pf.xFile, isImage: false));
      }
      setState(() {
        _attachments.addAll(list);
      });
    }
  }

  Future<void> _sendAttachments() async {
    if (_isUploading || _attachments.isEmpty) return;

    final user = ref.read(currentUserModelStreamProvider).value;
    if (user == null) {
      context.showSnackBar(
        'User not found. Please log in again.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    final uploader = ref.read(fileUploadServiceProvider);
    final chatRepo = ref.read(chatRepositoryProvider);
    final caption = _captionController.text.trim();

    try {
      for (int i = 0; i < _attachments.length; i++) {
        final item = _attachments[i];
        setState(() {
          _uploadStatusText = 'Sending ${i + 1} of ${_attachments.length}...';
          _uploadProgress = (i) / _attachments.length;
        });

        final downloadUrl = await uploader.uploadChatAttachment(
          chatId: widget.chatId,
          file: item.file,
          onProgress: (p) {
            setState(() {
              _uploadProgress = (i + p) / _attachments.length;
            });
          },
        );

        // Assign caption to the first item (or as content if only 1 item)
        final itemCaption = (i == 0 && caption.isNotEmpty)
            ? caption
            : (item.isImage ? 'Photo' : item.name);

        final msg = MessageModel(
          id: const Uuid().v4(),
          chatId: widget.chatId,
          senderId: user.id,
          senderName: user.fullName,
          senderAvatar: user.photoUrl,
          type: item.isImage ? MessageType.image : MessageType.file,
          content: itemCaption,
          mediaUrl: downloadUrl,
          mediaName: item.name,
          mediaSize: item.size,
          createdAt: DateTime.now(),
        );

        await chatRepo.sendMessage(msg);
      }

      if (mounted) {
        Navigator.of(context).pop();
        context.showSuccessSnackBar(
          'Sent ${_attachments.length} attachment${_attachments.length > 1 ? 's' : ''}',
        );
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar(
          'Unable to send attachments. Please check your connection and try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} of ${_attachments.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            tooltip: 'Remove',
            onPressed: _isUploading
                ? null
                : () => _removeAttachment(_currentIndex),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Main Attachment Preview Viewport
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _attachments.length,
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemBuilder: (context, index) {
                    final item = _attachments[index];
                    return _buildAttachmentPreview(item);
                  },
                ),
              ),

              // Bottom Thumbnail Strip
              if (_attachments.length > 1) _buildThumbnailStrip(),

              // Caption and Send Bar
              _buildCaptionBar(),
            ],
          ),

          // Uploading Progress Overlay
          if (_isUploading)
            Container(
              color: Colors.black87,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.accent),
                      const SizedBox(height: 16),
                      Text(
                        _uploadStatusText.isNotEmpty
                            ? _uploadStatusText
                            : 'Uploading...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _uploadProgress > 0 ? _uploadProgress : null,
                        color: AppColors.accent,
                        backgroundColor: Colors.white24,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentPreview(PendingAttachment item) {
    if (item.isImage) {
      return Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 3.0,
          child: AppFileImage(xFile: item.file, fit: BoxFit.contain),
        ),
      );
    }

    // Document Preview Card
    final ext = item.name.split('.').last.toUpperCase();
    final formattedSize = AppFileUtils.getFileSizeString(item.size);

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.insert_drive_file,
                size: 56,
                color: AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$ext • $formattedSize',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnailStrip() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: Colors.black.withValues(alpha: 0.6),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _attachments.length,
              itemBuilder: (context, index) {
                final item = _attachments[index];
                final isSelected = index == _currentIndex;

                return GestureDetector(
                  onTap: () {
                    setState(() => _currentIndex = index);
                    _pageController.jumpToPage(index);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.accent : Colors.white24,
                        width: isSelected ? 2.5 : 1.0,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: item.isImage
                          ? AppFileImage(xFile: item.file, fit: BoxFit.cover)
                          : Container(
                              color: const Color(0xFF1E293B),
                              child: const Icon(
                                Icons.insert_drive_file,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.add_photo_alternate_outlined,
              color: AppColors.accent,
            ),
            tooltip: 'Add More',
            onPressed: _showAddOptionsSheet,
          ),
        ],
      ),
    );
  }

  void _showAddOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.accent,
                ),
                title: const Text(
                  'Add Images from Gallery',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAdditionalImages();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.insert_drive_file,
                  color: AppColors.secondary,
                ),
                title: const Text(
                  'Add Documents',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAdditionalFiles();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaptionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: Colors.black.withValues(alpha: 0.9),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _captionController,
                  maxLines: 3,
                  minLines: 1,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Add a caption...',
                    hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.foxGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _isUploading ? null : _sendAttachments,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
