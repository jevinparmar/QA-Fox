import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../../../organizations/presentation/providers/organization_provider.dart';
import '../providers/project_provider.dart';

class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _urlController = TextEditingController();

  String _selectedPlatform = 'Website';
  String? _selectedOrgId;
  bool _isLoading = false;

  final List<String> _platforms = ['Website', 'Android', 'iOS', 'Multiple'];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserModelStreamProvider).value;
    if (user == null) return;

    var orgId = _selectedOrgId;
    if (orgId == null) {
      final orgs = await ref.read(userOrganizationsProvider.future);
      if (orgs.isNotEmpty) {
        orgId = orgs.first.id;
      } else {
        // Automatically create a default organization for the user if none exists
        final newOrg = await ref
            .read(organizationRepositoryProvider)
            .createOrganization(
              name: '${user.fullName}\'s Team',
              description: 'Personal organization workspace',
              ownerId: user.id,
              ownerEmail: user.email,
              ownerName: user.fullName,
            );
        orgId = newOrg.id;
      }
    }

    setState(() => _isLoading = true);
    try {
      final project = await ref
          .read(projectRepositoryProvider)
          .createProject(
            organizationId: orgId,
            name: _nameController.text.trim(),
            description: _descController.text.trim(),
            platform: _selectedPlatform,
            projectUrl: _urlController.text.isNotEmpty
                ? _urlController.text.trim()
                : null,
            creatorId: user.id,
          );

      if (mounted) {
        context.showSuccessSnackBar(
          'Testing Group "${project.name}" created! You are the Group Master.',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) context.showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final orgsAsync = ref.watch(userOrganizationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Testing Group / Project')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Group Master Role Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF713F12).withValues(alpha: 0.25)
                        : const Color(0xFFFEF08A).withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFEAB308),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('👑', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You will be the Group Master',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark
                                    ? const Color(0xFFFDE047)
                                    : const Color(0xFF854D0E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'You can add anyone and all users, see all members, and manage the testing channel.',
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
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  'Group & Project Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.textMainDark
                        : AppColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Every group gets its own dedicated channel for test discussions and structured bug reporting.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 20),
                // Organization selection (if multiple)
                orgsAsync.when(
                  data: (orgs) {
                    if (orgs.length > 1) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedOrgId ?? orgs.first.id,
                          decoration: const InputDecoration(
                            labelText: 'Organization Workspace',
                          ),
                          items: orgs
                              .map(
                                (o) => DropdownMenuItem(
                                  value: o.id,
                                  child: Text(o.name),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedOrgId = val),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),

                // Project Name
                AppTextField(
                  controller: _nameController,
                  labelText: 'Project Name *',
                  hintText: 'e.g. AppointmentPro, FreightFlow',
                  validator: (v) =>
                      Validators.required(v, 'Please enter project name'),
                ),
                const SizedBox(height: 16),

                // Description
                AppTextField(
                  controller: _descController,
                  labelText: 'Description',
                  hintText:
                      'Brief summary of what this application or website is...',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Platform Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Platform',
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
                      initialValue: _selectedPlatform,
                      items: _platforms
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedPlatform = val);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // URL
                AppTextField(
                  controller: _urlController,
                  labelText: 'Project / Testing URL (Optional)',
                  hintText: 'https://staging.appointmentpro.com',
                  keyboardType: TextInputType.url,
                  prefixIcon: const Icon(Icons.link, size: 20),
                ),
                const SizedBox(height: 32),

                // Create Button
                AppButton(
                  text: '👑 Create Group & Become Master',
                  isLoading: _isLoading,
                  onPressed: _handleCreate,
                  variant: AppButtonVariant.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
