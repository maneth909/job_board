import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_service.dart';
import '../services/file_upload_service.dart';

class EditEmployerProfileScreen extends ConsumerStatefulWidget {
  const EditEmployerProfileScreen({super.key});

  @override
  ConsumerState<EditEmployerProfileScreen> createState() =>
      _EditEmployerProfileScreenState();
}

class _EditEmployerProfileScreenState
    extends ConsumerState<EditEmployerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _telegramController = TextEditingController();

  String? _selectedIndustry;
  final List<String> _industries = [
    'Technology',
    'Healthcare',
    'Finance',
    'Education',
    'Retail',
    'Manufacturing',
    'Other',
  ];

  File? _logoFile;
  String? _existingLogoUrl;
  bool _isLoadingData = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final profileService = ref.read(profileServiceProvider);
      final user = profileService.getCurrentUser();

      if (user != null) {
        _nameController.text = user.userMetadata?['full_name'] as String? ?? '';
        final profile = await profileService.getEmployerProfile(user.id);

        if (profile != null && mounted) {
          setState(() {
            _companyNameController.text =
                profile['company_name'] as String? ?? '';
            _selectedIndustry = profile['industry'] as String?;
            _descriptionController.text =
                profile['description'] as String? ?? '';
            _websiteController.text = profile['website'] as String? ?? '';
            _telegramController.text =
                profile['telegram_handle'] as String? ?? '';
            _existingLogoUrl = profile['avatar_url'] as String?;
          });
        }
      }
    } catch (e) {
      // Ignored
    } finally {
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _logoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final profileService = ref.read(profileServiceProvider);
      final fileUploadService = ref.read(fileUploadServiceProvider);

      await profileService.updateFullName(_nameController.text);

      if (_logoFile != null) {
        await fileUploadService.uploadAvatar(_logoFile!);
      }

      await profileService.upsertEmployerProfile(
        companyName: _companyNameController.text,
        industry: _selectedIndustry,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        website: _websiteController.text.isNotEmpty
            ? _websiteController.text
            : null,
        telegramHandle: _telegramController.text,
      );

      // Do NOT call markAsCompleted() here, to prevent jumping to the home screen.

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        context.pop(); // Returns to the view profile screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyNameController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _telegramController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left_rounded, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Company Profile',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar Edit
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: colorScheme.onSurface.withOpacity(
                              0.05,
                            ),
                            backgroundImage: _logoFile != null
                                ? FileImage(_logoFile!) as ImageProvider
                                : (_existingLogoUrl != null
                                      ? NetworkImage(_existingLogoUrl!)
                                      : null),
                            child: _logoFile == null && _existingLogoUrl == null
                                ? Icon(
                                    Icons.business,
                                    size: 40,
                                    color: colorScheme.primary.withOpacity(0.6),
                                  )
                                : null,
                          ),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colorScheme.surface,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildModernInput(
                      label: 'Your Full Name',
                      controller: _nameController,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 16),
                    _buildModernInput(
                      label: 'Company Name *',
                      controller: _companyNameController,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 16),

                    // Modern Dropdown
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Industry',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedIndustry,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: colorScheme.onSurface.withOpacity(0.04),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          items: _industries.map((industry) {
                            return DropdownMenuItem(
                              value: industry,
                              child: Text(industry),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _selectedIndustry = value),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    _buildModernInput(
                      label: 'Company Description',
                      controller: _descriptionController,
                      colorScheme: colorScheme,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    _buildModernInput(
                      label: 'Website',
                      controller: _websiteController,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 16),
                    _buildModernInput(
                      label: 'Telegram Handle *',
                      controller: _telegramController,
                      colorScheme: colorScheme,
                      prefixText: '@ ',
                    ),

                    const SizedBox(height: 48),

                    // Save Button
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF18181B,
                          ), // Dark button matching jobseeker style
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'SAVE CHANGES',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildModernInput({
    required String label,
    required TextEditingController controller,
    required ColorScheme colorScheme,
    int maxLines = 1,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: (value) {
            // Only validate if label has a *
            if (label.contains('*') &&
                (value == null || value.trim().isEmpty)) {
              return 'Required';
            }
            return null;
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: colorScheme.onSurface.withOpacity(0.04),
            prefixText: prefixText,
            prefixStyle: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.bold,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
