import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/profile_service.dart';
import '../services/file_upload_service.dart';
import '../providers/profile_state_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _universityController = TextEditingController();
  final _majorController = TextEditingController();
  final _skillsController = TextEditingController();
  final _bioController = TextEditingController();

  File? _avatarFile;
  String? _existingAvatarUrl;

  File? _selectedPdf;
  String? _pdfFileName;
  String? _existingCvFilename;

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
        final profile = await profileService.getJobseekerProfile(user.id);
        if (profile != null && mounted) {
          setState(() {
            _universityController.text = profile['university'] as String? ?? '';
            _majorController.text = profile['major'] as String? ?? '';
            _existingAvatarUrl = profile['avatar_url'] as String?;
            _existingCvFilename = profile['cv_filename'] as String?;

            final skills = profile['skills'] as List<dynamic>?;
            if (skills != null) {
              _skillsController.text = skills.join(', ');
            }
            _bioController.text = profile['bio'] as String? ?? '';
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
        _avatarFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final fileSize = await file.length();

      if (fileSize > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File must be under 5MB')),
          );
        }
        return;
      }

      setState(() {
        _selectedPdf = file;
        _pdfFileName = result.files.single.name;
      });
    }
  }

  Future<void> _saveProfile() async {
    // 1. Validate the form first
    if (!_formKey.currentState!.validate()) return;

    // 2. Show the loading spinner
    setState(() => _isSaving = true);

    try {
      final profileService = ref.read(profileServiceProvider);
      final fileUploadService = ref.read(fileUploadServiceProvider);

      // 3. Update the user's name in Auth metadata
      await profileService.updateFullName(_nameController.text);

      // 4. Upload Avatar if a new one was selected
      if (_avatarFile != null) {
        await fileUploadService.uploadAvatar(_avatarFile!);
      }

      // 5. Upload CV if a new one was selected
      if (_selectedPdf != null && _pdfFileName != null) {
        await fileUploadService.uploadCv(_selectedPdf!, _pdfFileName!);
      }

      // 6. Update the database with the text fields
      await profileService.upsertJobseekerProfile(
        university: _universityController.text,
        major: _majorController.text,
        skillsString: _skillsController.text.isNotEmpty
            ? _skillsController.text
            : null,
        bio: _bioController.text.isNotEmpty ? _bioController.text : null,
      );

      // ---------------------------------------------------------
      // CRITICAL FIX: Do NOT call markAsCompleted() here.
      // That is what is causing your app to jump to the home screen.
      // ---------------------------------------------------------

      // 7. Show success message and pop the screen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );

        // This will smoothly slide back to the View Profile screen
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _universityController.dispose();
    _majorController.dispose();
    _skillsController.dispose();
    _bioController.dispose();
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
          'Edit Profile',
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
                            backgroundImage: _avatarFile != null
                                ? FileImage(_avatarFile!) as ImageProvider
                                : (_existingAvatarUrl != null
                                      ? NetworkImage(_existingAvatarUrl!)
                                      : null),
                            child:
                                _avatarFile == null &&
                                    _existingAvatarUrl == null
                                ? Icon(
                                    Icons.person,
                                    size: 40,
                                    color: colorScheme.onSurface.withOpacity(
                                      0.4,
                                    ),
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
                      label: 'Full Name',
                      controller: _nameController,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 16),
                    _buildModernInput(
                      label: 'University',
                      controller: _universityController,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 16),
                    _buildModernInput(
                      label: 'Major',
                      controller: _majorController,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 16),
                    _buildModernInput(
                      label: 'Skills (comma separated)',
                      controller: _skillsController,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 16),
                    _buildModernInput(
                      label: 'Bio',
                      controller: _bioController,
                      colorScheme: colorScheme,
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),

                    // Modern CV Upload Area
                    Text(
                      'Resume / CV',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickPdf,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedPdf != null
                                ? colorScheme.primary
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.picture_as_pdf_rounded,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _pdfFileName ??
                                        _existingCvFilename ??
                                        'Upload new CV (PDF)',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _pdfFileName != null
                                        ? 'Ready to upload'
                                        : 'Tap to select file (Max 5MB)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurface.withOpacity(
                                        0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.upload_file_rounded,
                              color: colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Save Button (Matches Dark Reference Button)
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF18181B,
                          ), // Dark button like ref
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
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Required' : null,
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
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
