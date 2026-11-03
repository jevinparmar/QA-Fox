import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/firestore_constants.dart';
import '../../../../core/enums/bug_category.dart';
import '../../../../core/enums/bug_priority.dart';
import '../../../../core/enums/bug_severity.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../shared/models/chat_model.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../../shared/widgets/app_file_image.dart';
import '../../../projects/presentation/providers/project_provider.dart';
import '../../domain/repositories/bug_repository.dart';
import '../providers/bug_draft_provider.dart';
import '../providers/bug_provider.dart';

class MultiBugComposerScreen extends ConsumerStatefulWidget {
  final String chatId;

  const MultiBugComposerScreen({super.key, required this.chatId});

  @override
  ConsumerState<MultiBugComposerScreen> createState() =>
      _MultiBugComposerScreenState();
}

class _MultiBugComposerScreenState
    extends ConsumerState<MultiBugComposerScreen> {
  final _descController = TextEditingController();
  final _screenController = TextEditingController();
  final _urlController = TextEditingController();
  final _stepsController = TextEditingController();
  final _expectedController = TextEditingController();
  final _actualController = TextEditingController();

  final List<String> _customCategories = [];
  String? _selectedProjectId;
  String? _selectedOrgId;
  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    _loadChatMetadata();
    _syncFormWithCurrentDraft();
  }

  @override
  void dispose() {
    _descController.dispose();
    _screenController.dispose();
    _urlController.dispose();
    _stepsController.dispose();
    _expectedController.dispose();
    _actualController.dispose();
    super.dispose();
  }

  Future<void> _loadChatMetadata() async {
    final doc = await ref
        .read(firestoreServiceProvider)
        .getDoc('${FirestoreConstants.chats}/${widget.chatId}');
    if (doc.exists && doc.data() != null) {
      final chat = ChatModel.fromMap(doc.data()!, doc.id);
      setState(() {
        _selectedProjectId = chat.projectId;
        _selectedOrgId = chat.organizationId;
      });
    }
  }

  void _syncFormWithCurrentDraft() {
    final draft = ref.read(bugDraftProvider).currentDraft;
    _descController.text = draft.description;
    _screenController.text = draft.screenName ?? '';
    _urlController.text = draft.url ?? '';
    _stepsController.text = draft.stepsToReproduce ?? '';
    _expectedController.text = draft.expectedResult ?? '';
    _actualController.text = draft.actualResult ?? '';
  }

  void _saveCurrentFieldsToDraft() {
    final desc = _descController.text.trim();
    String title = '';
    if (desc.isNotEmpty) {
      final firstLine = desc.split('\n').first.trim();
      title = firstLine.length > 60
          ? '${firstLine.substring(0, 57)}...'
          : firstLine;
    } else {
      title = '${ref.read(bugDraftProvider).currentDraft.category} Issue';
    }

    ref
        .read(bugDraftProvider.notifier)
        .updateCurrentDraft(
          title: title,
          description: _descController.text,
          screenName: _screenController.text.isNotEmpty
              ? _screenController.text
              : null,
          url: _urlController.text.isNotEmpty ? _urlController.text : null,
          stepsToReproduce: _stepsController.text.isNotEmpty
              ? _stepsController.text
              : null,
          expectedResult: _expectedController.text.isNotEmpty
              ? _expectedController.text
              : null,
          actualResult: _actualController.text.isNotEmpty
              ? _actualController.text
              : null,
        );
  }

  void _onSwitchDraft(int index) {
    _saveCurrentFieldsToDraft();
    ref.read(bugDraftProvider.notifier).setCurrentIndex(index);
    _syncFormWithCurrentDraft();
    setState(() {});
  }

  void _onAddMore() {
    _saveCurrentFieldsToDraft();
    final draft = ref.read(bugDraftProvider).currentDraft;
    if (_descController.text.trim().isEmpty && draft.localFiles.isEmpty) {
      context.showSnackBar(
        'Please enter description or attach a screenshot before adding another draft.',
        isError: true,
      );
      return;
    }

    ref.read(bugDraftProvider.notifier).addNewDraft();
    _syncFormWithCurrentDraft();
    setState(() {
      _showAdvanced = false;
    });
    context.showSuccessSnackBar('Draft saved! Starting new blank report form.');
  }

  Future<void> _pickAttachment({bool isCamera = false}) async {
    final picker = ref.read(imagePickerServiceProvider);
    XFile? file;
    if (isCamera) {
      file = await picker.pickImageFromCamera(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
    } else {
      file = await picker.pickImageFromGallery(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 75,
      );
    }

    if (file != null) {
      ref.read(bugDraftProvider.notifier).addFilesToCurrentDraft([file]);
      setState(() {});
    }
  }

  Future<void> _showAddCategoryDialog() async {
    final textController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category Option'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Security, Payment, Billing',
            labelText: 'Option Name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                if (!_customCategories.contains(text)) {
                  setState(() {
                    _customCategories.add(text);
                  });
                }
                final draft = ref.read(bugDraftProvider).currentDraft;
                setState(() {
                  draft.category = text;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSendAll() async {
    _saveCurrentFieldsToDraft();
    final draftState = ref.read(bugDraftProvider);
    final drafts = draftState.drafts;

    // Validate all drafts
    for (var i = 0; i < drafts.length; i++) {
      final d = drafts[i];
      if (d.description.trim().isEmpty && d.localFiles.isEmpty) {
        context.showSnackBar(
          'Report #${i + 1} is empty. Please enter description or attach a screenshot.',
          isError: true,
        );
        _onSwitchDraft(i);
        return;
      }
      if (d.title.trim().isEmpty) {
        if (d.description.trim().isNotEmpty) {
          final firstLine = d.description.trim().split('\n').first.trim();
          d.title = firstLine.length > 60
              ? '${firstLine.substring(0, 57)}...'
              : firstLine;
        } else {
          d.title = '${d.category} Issue';
        }
      }
    }

    // Check project association
    var projectId = _selectedProjectId;
    var orgId = _selectedOrgId;

    if (projectId == null || orgId == null) {
      // Find user's first available project
      final user = ref.read(currentFirebaseUserProvider);
      if (user != null) {
        final projects = await ref.read(allUserProjectsStreamProvider.future);
        if (projects.isNotEmpty) {
          projectId = projects.first.id;
          orgId = projects.first.organizationId;
        }
      }
    }

    if (projectId == null || orgId == null) {
      if (!mounted) return;
      context.showSnackBar(
        'No associated project found for submitting bugs. Please create a project first.',
        isError: true,
      );
      return;
    }

    final user = ref.read(currentUserModelStreamProvider).value;
    if (user == null) return;

    ref.read(bugDraftProvider.notifier).setSubmitting(true, 0.1);

    try {
      final repo = ref.read(bugRepositoryProvider);
      final submitted = await repo.submitMultipleBugs(
        projectId: projectId,
        organizationId: orgId,
        groupChatId: widget.chatId,
        reporterId: user.id,
        reporterName: user.fullName,
        reporterAvatar: user.photoUrl,
        drafts: drafts,
        onProgress: (progress) {
          ref.read(bugDraftProvider.notifier).setSubmitting(true, progress);
        },
      );

      ref.read(bugDraftProvider.notifier).reset();

      if (mounted) {
        context.showSuccessSnackBar(
          'Successfully submitted ${submitted.length} bug report${submitted.length > 1 ? 's' : ''} to the project!',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar(e.toString(), isError: true);
      }
    } finally {
      ref.read(bugDraftProvider.notifier).setSubmitting(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final draftState = ref.watch(bugDraftProvider);
    final currentDraft = draftState.currentDraft;
    final currentIndex = draftState.currentIndex;
    final totalDrafts = draftState.drafts.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Report Bug Composer',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              'Draft ${currentIndex + 1} of $totalDrafts',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textMutedDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        actions: [
          if (totalDrafts > 1)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Remove Draft',
              onPressed: () async {
                final confirm = await AppDialog.show(
                  context,
                  title: 'Remove Draft #${currentIndex + 1}?',
                  message:
                      'Are you sure you want to discard this report draft?',
                  confirmText: 'Discard',
                  isDestructive: true,
                );
                if (confirm == true) {
                  ref.read(bugDraftProvider.notifier).removeDraft(currentIndex);
                  _syncFormWithCurrentDraft();
                  setState(() {});
                }
              },
            ),
        ],
      ),
      body: draftState.isSubmitting
          ? _buildSubmittingProgress(draftState.uploadProgress, isDark)
          : Column(
              children: [
                // Draft Pills Navigation Bar
                _buildDraftsBar(draftState, isDark),

                // Report Form Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18.0,
                      vertical: 12.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Bug Category Selector
                        _buildCategorySelector(currentDraft, isDark),
                        const SizedBox(height: 16),

                        // Description Field
                        AppTextField(
                          controller: _descController,
                          labelText: 'Bug Description *',
                          hintText: 'Describe what goes wrong, frequency, and impact...',
                          maxLines: 4,
                          minLines: 2,
                          onChanged: (val) {
                            currentDraft.description = val;
                            final lines = val.trim().split('\n');
                            currentDraft.title =
                                lines.isNotEmpty && lines.first.isNotEmpty
                                ? (lines.first.length > 60
                                      ? '${lines.first.substring(0, 57)}...'
                                      : lines.first)
                                : '';
                          },
                        ),
                        const SizedBox(height: 18),

                        // Attachments Section
                        _buildAttachmentsSection(currentDraft, isDark),
                        const SizedBox(height: 20),

                        // Severity & Priority Pickers
                        _buildSeverityAndPriority(currentDraft, isDark),
                        const SizedBox(height: 16),

                        // Collapsible Additional Details (Steps to reproduce, URLs, etc.)
                        Material(
                          color: isDark
                              ? AppColors.surfaceDark
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () =>
                                setState(() => _showAdvanced = !_showAdvanced),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.playlist_add_check_rounded,
                                    size: 18,
                                    color: isDark
                                        ? AppColors.secondary
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Reproduction & Expected Steps',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? AppColors.textMainDark
                                            : AppColors.textMainLight,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isDark
                                              ? AppColors.secondary
                                              : AppColors.primary)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _showAdvanced ? 'Hide' : 'Optional',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppColors.secondary
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    _showAdvanced
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    size: 20,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        if (_showAdvanced) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceDark.withValues(alpha: 0.6)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                              ),
                            ),
                            child: Column(
                              children: [
                                AppTextField(
                                  controller: _screenController,
                                  labelText: 'Screen / Page Name',
                                  hintText: 'e.g. Auth / Sign In Screen',
                                  onChanged: (val) =>
                                      currentDraft.screenName = val,
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  controller: _urlController,
                                  labelText: 'URL (Optional)',
                                  hintText: 'https://staging.app.com/login',
                                  onChanged: (val) => currentDraft.url = val,
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  controller: _stepsController,
                                  labelText: 'Steps to Reproduce',
                                  hintText:
                                      '1. Open app\n2. Tap Sign In\n3. Click Login button',
                                  maxLines: 3,
                                  onChanged: (val) =>
                                      currentDraft.stepsToReproduce = val,
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  controller: _expectedController,
                                  labelText: 'Expected Result',
                                  hintText: 'What should have happened...',
                                  maxLines: 2,
                                  onChanged: (val) =>
                                      currentDraft.expectedResult = val,
                                ),
                                const SizedBox(height: 12),
                                AppTextField(
                                  controller: _actualController,
                                  labelText: 'Actual Result',
                                  hintText: 'What actually happened instead...',
                                  maxLines: 2,
                                  onChanged: (val) =>
                                      currentDraft.actualResult = val,
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      // Bottom Action Bar: Add More & Send All side-by-side
      bottomNavigationBar: _buildBottomActions(draftState, isDark),
    );
  }

  Widget _buildDraftsBar(BugDraftState state, bool isDark) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.drafts.length + 1,
        itemBuilder: (context, index) {
          if (index == state.drafts.length) {
            return TextButton.icon(
              onPressed: _onAddMore,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Draft'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final isSelected = index == state.currentIndex;
          final activeThemeColor = isDark ? AppColors.secondary : AppColors.primary;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text('Report #${index + 1}'),
              selected: isSelected,
              onSelected: (_) => _onSwitchDraft(index),
              selectedColor: activeThemeColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppColors.textMainLight),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(
                color: isSelected
                    ? activeThemeColor
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySelector(BugDraft draft, bool isDark) {
    final standardCategories = BugCategory.values
        .where((c) => c != BugCategory.other)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bug Category',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...standardCategories.map((cat) {
                final isSelected = draft.category == cat.label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    avatar: Icon(
                      cat.icon,
                      size: 15,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppColors.secondary : AppColors.primary),
                    ),
                    label: Text(cat.label),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        draft.category = cat.label;
                      });
                    },
                    selectedColor: isDark ? AppColors.secondary : AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : AppColors.textMainLight),
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }),
              ..._customCategories.map((customName) {
                final isSelected = draft.category == customName;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    avatar: Icon(
                      Icons.label_outline,
                      size: 15,
                      color: isSelected ? Colors.white : AppColors.accent,
                    ),
                    label: Text(customName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        draft.category = customName;
                      });
                    },
                    selectedColor: AppColors.accent,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : AppColors.textMainLight),
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }),
              // In last: + option chip to add new custom category
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ActionChip(
                  avatar: const Icon(
                    Icons.add,
                    size: 16,
                    color: AppColors.accent,
                  ),
                  label: const Text('+ Option'),
                  onPressed: _showAddCategoryDialog,
                  backgroundColor: isDark
                      ? const Color(0xFF1E293B)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: AppColors.accent, width: 1.2),
                  ),
                  labelStyle: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection(BugDraft draft, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 4,
          spacing: 8,
          children: [
            Text(
              'Screenshots & Attachments (${draft.localFiles.length})',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  onPressed: () => _pickAttachment(isCamera: true),
                  icon: const Icon(Icons.camera_alt_outlined, size: 16),
                  label: const Text('Camera', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _pickAttachment(isCamera: false),
                  icon: const Icon(Icons.photo_library_outlined, size: 16),
                  label: const Text('Gallery', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (draft.localFiles.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: draft.localFiles.length,
              itemBuilder: (context, index) {
                final file = draft.localFiles[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Stack(
                    children: [
                      AppFileImage(
                        xFile: file,
                        width: 90,
                        height: 90,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            ref
                                .read(bugDraftProvider.notifier)
                                .removeFileFromCurrentDraft(index);
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSeverityAndPriority(BugDraft draft, bool isDark) {
    return Row(
      children: [
        // Severity
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Severity',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: draft.severity,
                isDense: true,
                items: BugSeverity.values.map((s) {
                  return DropdownMenuItem(
                    value: s.label,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: s.color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(s.label, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => draft.severity = val);
                  }
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceDark
                      : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.secondary : AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),

        // Priority
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Priority',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: draft.priority,
                isDense: true,
                items: BugPriority.values.map((p) {
                  return DropdownMenuItem(
                    value: p.label,
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined, size: 14, color: p.color),
                        const SizedBox(width: 6),
                        Text(p.label, style: const TextStyle(fontSize: 13)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => draft.priority = val);
                  }
                },
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.surfaceDark
                      : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.secondary : AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BugDraftState state, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 360;
            final sendText = state.drafts.length > 1
                ? (isNarrow
                      ? 'Send All (${state.drafts.length})'
                      : 'Send All (${state.drafts.length} Bugs)')
                : (isNarrow ? 'Submit' : 'Submit Bug Report');

            return Row(
              children: [
                // Add More Button
                Expanded(
                  flex: isNarrow ? 4 : 5,
                  child: AppButton(
                    text: 'Add More',
                    icon: const Icon(Icons.add, size: 16),
                    variant: AppButtonVariant.outline,
                    height: 46,
                    onPressed: _onAddMore,
                  ),
                ),
                const SizedBox(width: 10),

                // Send All Button (Fox Orange!)
                Expanded(
                  flex: isNarrow ? 6 : 7,
                  child: AppButton(
                    text: sendText,
                    icon: const Icon(Icons.send_rounded, size: 16),
                    variant: AppButtonVariant.fox,
                    height: 46,
                    onPressed: _handleSendAll,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSubmittingProgress(double progress, bool isDark) {
    final pct = (progress * 100).toInt();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_outlined,
                size: 54,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Uploading & Submitting Bug Reports...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textMainLight,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Uploading media to Firebase Storage and generating unique BUG IDs for your project.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 28),
            LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              backgroundColor: isDark
                  ? AppColors.surfaceDark
                  : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              borderRadius: BorderRadius.circular(8),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Text(
              '$pct% Completed',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
