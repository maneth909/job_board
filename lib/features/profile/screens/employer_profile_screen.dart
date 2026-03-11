import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_service.dart';
import '../services/file_upload_service.dart';
import '../providers/profile_state_provider.dart';
import '../../../shared/widgets/custom_app_bar.dart';

class EmployerProfileScreen extends ConsumerStatefulWidget {
  const EmployerProfileScreen({super.key});

  @override
  ConsumerState<EmployerProfileScreen> createState() => _EmployerProfileScreenState();
}

class _EmployerProfileScreenState extends ConsumerState<EmployerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _telegramController = TextEditingController();

  String? _selectedIndustry;
  final List<String> _industries = ['Technology', 'Healthcare', 'Finance', 'Education', 'Other'];

  File? _logoFile;
  bool _isLoading = false;

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

    setState(() {
      _isLoading = true;
    });

    try {
      final profileService = ref.read(profileServiceProvider);
      final fileUploadService = ref.read(fileUploadServiceProvider);

      if (_logoFile != null) {
        await fileUploadService.uploadAvatar(_logoFile!); // treating logo as avatar in profiles
      }

      await profileService.upsertEmployerProfile(
        companyName: _companyNameController.text,
        industry: _selectedIndustry,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        website: _websiteController.text.isNotEmpty ? _websiteController.text : null,
        telegramHandle: _telegramController.text,
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
    _companyNameController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _telegramController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Employer Profile'),
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
                    backgroundImage: _logoFile != null ? FileImage(_logoFile!) : null,
                    child: _logoFile == null ? const Icon(Icons.business, size: 40) : null,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _companyNameController,
                decoration: const InputDecoration(labelText: 'Company Name *'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedIndustry,
                decoration: const InputDecoration(labelText: 'Industry'),
                items: _industries.map((industry) {
                  return DropdownMenuItem(
                    value: industry,
                    child: Text(industry),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedIndustry = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(labelText: 'Website'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telegramController,
                decoration: const InputDecoration(labelText: 'Telegram Handle *', prefixText: '@'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
