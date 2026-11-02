import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../../shared/widgets/app_file_image.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _designationController = TextEditingController();
  final _bioController = TextEditingController();

  XFile? _avatarFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserModelStreamProvider).value;
    if (user != null) {
      _fullNameController.text = user.fullName;
      _usernameController.text = user.username;
      _designationController.text = user.designation ?? 'QA Engineer / Tester';
      _bioController.text = user.bio ?? '';
    } else {
      _designationController.text = 'QA Engineer / Tester';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _designationController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ref.read(imagePickerServiceProvider);
    final file = await picker.pickImageFromGallery(
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (file != null) {
      setState(() => _avatarFile = file);
    }
  }

  Future<void> _saveAndContinue() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserModelStreamProvider).value;
      if (user == null) {
        context.go(RoutePaths.chats);
        return;
      }

      String? photoUrl = user.photoUrl;
      if (_avatarFile != null) {
        final uploader = ref.read(fileUploadServiceProvider);
        photoUrl = await uploader.uploadAvatar(
          userId: user.id,
          file: _avatarFile!,
        );
      }

      final updatedUser = user.copyWith(
        fullName: _fullNameController.text.trim().isNotEmpty
            ? _fullNameController.text.trim()
            : user.fullName,
        username: _usernameController.text.trim().isNotEmpty
            ? _usernameController.text.trim()
            : user.username,
        designation: _designationController.text.trim(),
        bio: _bioController.text.trim(),
        photoUrl: photoUrl,
      );

      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(updatedUser);
      if (mounted) {
        context.go(RoutePaths.chats);
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar(e.toString(), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Profile'),
        actions: [
          TextButton(
            onPressed: () => context.go(RoutePaths.chats),
            child: const Text(
              'Skip',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Tell us about yourself',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColors.textMainDark
                      : AppColors.textMainLight,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'This info helps your testing team and collaborators recognize you.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 28),

              // Avatar with camera icon
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.1),
                        border: Border.all(
                          color: AppColors.primaryLight,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: _avatarFile != null
                            ? AppFileImage(
                                xFile: _avatarFile!,
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.person,
                                size: 54,
                                color: AppColors.primary,
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Full Name
              AppTextField(
                controller: _fullNameController,
                labelText: 'Full Name',
                hintText: 'Alex Morgan',
                prefixIcon: const Icon(Icons.person_outline, size: 20),
              ),
              const SizedBox(height: 16),

              // Username
              AppTextField(
                controller: _usernameController,
                labelText: 'Username',
                hintText: 'alex_qa',
                prefixIcon: const Icon(Icons.alternate_email, size: 20),
              ),
              const SizedBox(height: 16),

              // Designation
              AppTextField(
                controller: _designationController,
                labelText: 'Role / Designation',
                hintText: 'e.g. Senior QA Engineer, Lead Developer',
                prefixIcon: const Icon(Icons.badge_outlined, size: 20),
              ),
              const SizedBox(height: 16),

              // Bio
              AppTextField(
                controller: _bioController,
                labelText: 'Short Bio',
                hintText:
                    'Passionate about catching edge-case bugs and UI glitches.',
                maxLines: 3,
                prefixIcon: const Icon(Icons.notes_outlined, size: 20),
              ),
              const SizedBox(height: 32),

              // Save & Continue Button
              AppButton(
                text: 'Complete & Go to Chats',
                isLoading: _isLoading,
                onPressed: _saveAndContinue,
                variant: AppButtonVariant.primary,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
