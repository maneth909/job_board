import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_service.dart';
import '../services/file_upload_service.dart';
import '../providers/profile_state_provider.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class JobseekerProfileScreen extends ConsumerStatefulWidget {
  const JobseekerProfileScreen({super.key});

  @override
  ConsumerState<JobseekerProfileScreen> createState() => _JobseekerProfileScreenState();
}

class _JobseekerProfileScreenState extends ConsumerState<JobseekerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _universityController = TextEditingController();
  final _majorController = TextEditingController();
  final _skillsController = TextEditingController();
  final _bioController = TextEditingController();

  File? _avatarFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _avatarFile = File(pickedFile.path);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final profileService = ref.read(profileServiceProvider);
      final user = profileService.getCurrentUser();
      if (user != null) {
        final profile = await profileService.getJobseekerProfile(user.id);
        if (profile != null && mounted) {
          setState(() {
            _universityController.text = profile['university'] as String? ?? '';
            _majorController.text = profile['major'] as String? ?? '';
            
            final skills = profile['skills'] as List<dynamic>?;
            if (skills != null) {
              _skillsController.text = skills.join(', ');
            }
            
            _bioController.text = profile['bio'] as String? ?? '';
          });
        }
      }
    } catch (e) {
      // Ignore initial load errors
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final profileService = ref.read(profileServiceProvider);
      final fileUploadService = ref.read(fileUploadServiceProvider);

      if (_avatarFile != null) {
        await fileUploadService.uploadAvatar(_avatarFile!);
      }

      await profileService.upsertJobseekerProfile(
        university: _universityController.text,
        major: _majorController.text,
        skillsString: _skillsController.text.isNotEmpty ? _skillsController.text : null,
        bio: _bioController.text.isNotEmpty ? _bioController.text : null,
      );

      ref.read(profileStateProvider.notifier).markAsCompleted();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _universityController.dispose();
    _majorController.dispose();
    _skillsController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Jobseeker Profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: InkWell(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: _avatarFile != null ? FileImage(_avatarFile!) : null,
                    child: _avatarFile == null ? const Icon(Icons.camera_alt, size: 40) : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _universityController,
                decoration: const InputDecoration(labelText: 'University *'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _majorController,
                decoration: const InputDecoration(labelText: 'Major *'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skillsController,
                decoration: const InputDecoration(labelText: 'Skills (comma separated)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Profile'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  context.push('/profile/cv-upload');
                },
                child: const Text('Upload CV (PDF)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
