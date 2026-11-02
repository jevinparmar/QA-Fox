import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../shared/providers/firebase_providers.dart';
import '../providers/organization_provider.dart';

class CreateOrganizationScreen extends ConsumerStatefulWidget {
  const CreateOrganizationScreen({super.key});

  @override
  ConsumerState<CreateOrganizationScreen> createState() =>
      _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState
    extends ConsumerState<CreateOrganizationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserModelStreamProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final org = await ref
          .read(organizationRepositoryProvider)
          .createOrganization(
            name: _nameController.text.trim(),
            description: _descController.text.trim(),
            ownerId: user.id,
            ownerEmail: user.email,
            ownerName: user.fullName,
          );

      if (mounted) {
        context.showSuccessSnackBar(
          'Organization "${org.name}" created successfully!',
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
    return Scaffold(
      appBar: AppBar(title: const Text('New Organization')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create an Organization',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Organizations contain testing projects, team members, and role-based permissions.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                AppTextField(
                  controller: _nameController,
                  labelText: 'Organization Name *',
                  hintText: 'e.g. Acme Software, Xpedria AI',
                  validator: (v) =>
                      Validators.required(v, 'Please enter organization name'),
                ),
                const SizedBox(height: 16),

                AppTextField(
                  controller: _descController,
                  labelText: 'Description',
                  hintText: 'Brief summary of the organization...',
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                AppButton(
                  text: 'Create Organization',
                  isLoading: _isLoading,
                  onPressed: _handleCreate,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
