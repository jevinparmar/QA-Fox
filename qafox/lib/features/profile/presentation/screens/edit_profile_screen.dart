import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_file_image.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _designationController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();

  XFile? _newAvatarFile;
  bool _removePhoto = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserModelStreamProvider).value;
    if (user != null) {
      _fullNameController.text = user.fullName;
      _usernameController.text = user.username;
      _designationController.text = user.designation ?? '';
      _bioController.text = user.bio ?? '';
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _designationController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showAvatarPickerSheet() {
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
                'Profile Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.primary,
                ),
                title: const Text('Take Photo with Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatar(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.secondary,
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAvatar(ImageSource.gallery);
                },
              ),
              if (_newAvatarFile != null ||
                  (ref.read(currentUserModelStreamProvider).value?.photoUrl !=
                      null))
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Remove Current Photo',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _newAvatarFile = null;
                      _removePhoto = true;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final picker = ref.read(imagePickerServiceProvider);
    final file = source == ImageSource.camera
        ? await picker.pickImageFromCamera(
            maxWidth: 600,
            maxHeight: 600,
            imageQuality: 75,
          )
        : await picker.pickImageFromGallery(
            maxWidth: 600,
            maxHeight: 600,
            imageQuality: 75,
          );

    if (file != null) {
      setState(() {
        _newAvatarFile = file;
        _removePhoto = false;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserModelStreamProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      String? photoUrl = _removePhoto ? null : user.photoUrl;

      if (_newAvatarFile != null) {
        final uploader = ref.read(fileUploadServiceProvider);
        photoUrl = await uploader.uploadAvatar(
          userId: user.id,
          file: _newAvatarFile!,
        );
      }

      final updated = user.copyWith(
        fullName: _fullNameController.text.trim(),
        username: _usernameController.text.trim(),
        designation: _designationController.text.trim(),
        bio: _bioController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        photoUrl: photoUrl,
      );

      await ref.read(authControllerProvider.notifier).updateProfile(updated);
      if (mounted) {
        context.showSuccessSnackBar('Profile updated successfully!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        context.showSnackBar(ErrorHandler.getFriendlyMessage(e), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserModelStreamProvider).value;
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar Picker Section
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.5),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.3 : 0.08,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _newAvatarFile != null
                              ? AppFileImage(
                                  xFile: _newAvatarFile!,
                                  fit: BoxFit.cover,
                                )
                              : _removePhoto
                              ? AppAvatar(
                                  name: _fullNameController.text.isNotEmpty
                                      ? _fullNameController.text
                                      : 'User',
                                  size: 104,
                                )
                              : AppAvatar(
                                  name: user?.fullName ?? 'User',
                                  imageUrl: user?.photoUrl,
                                  size: 104,
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: GestureDetector(
                          onTap: _showAvatarPickerSheet,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppColors.foxGradient,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.surfaceDark
                                    : Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
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
                const SizedBox(height: 24),

                AppTextField(
                  controller: _fullNameController,
                  labelText: 'Full Name *',
                  hintText: 'Enter your full name',
                  validator: (v) =>
                      Validators.required(v, 'Full name required'),
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _usernameController,
                  labelText: 'Username *',
                  hintText: 'e.g. alex_qa',
                  validator: (v) => Validators.required(v, 'Username required'),
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _designationController,
                  labelText: 'Role / Designation',
                  hintText: 'e.g. Lead QA Engineer',
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  hintText: '+1 234 567 8900',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _bioController,
                  labelText: 'Bio',
                  hintText: 'Tell teammates about your testing expertise...',
                  maxLines: 3,
                ),
                const SizedBox(height: 28),

                AppButton(
                  text: 'Save Changes',
                  variant: AppButtonVariant.fox,
                  height: 48,
                  isLoading: _isLoading,
                  onPressed: _handleSave,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
