import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../services/file_upload_service.dart';
import '../services/profile_service.dart';

class CvUploadScreen extends ConsumerStatefulWidget {
  const CvUploadScreen({super.key});

  @override
  ConsumerState<CvUploadScreen> createState() => _CvUploadScreenState();
}

class _CvUploadScreenState extends ConsumerState<CvUploadScreen> {
  bool _isLoadingInitial = true;
  String? _existingCvUrl;
  String? _existingCvFilename;
  File? _selectedPdf;
  String? _fileName;
  bool _isUploading = false;
  String? _uploadedUrl;

  @override
  void initState() {
    super.initState();
    _loadExistingCv();
  }

  Future<void> _loadExistingCv() async {
    try {
      final profileService = ref.read(profileServiceProvider);
      final user = profileService.getCurrentUser();
      if (user != null) {
        final profile = await profileService.getJobseekerProfile(user.id);
        if (profile != null && mounted) {
          setState(() {
            _existingCvUrl = profile['cv_url'] as String?;
            _existingCvFilename = profile['cv_filename'] as String?;
          });
        }
      }
    } catch (e) {
      // Ignored for UI
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingInitial = false;
        });
      }
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

      // Check 5MB limit
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
        _fileName = result.files.single.name;
        _uploadedUrl = null; // reset if selecting new file
      });
    }
  }

  Future<void> _uploadPdf() async {
    if (_selectedPdf == null || _fileName == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final fileUploadService = ref.read(fileUploadServiceProvider);
      final url = await fileUploadService.uploadCv(_selectedPdf!, _fileName!);

      setState(() {
        _uploadedUrl = url;
        _existingCvUrl = url;
        _existingCvFilename = _fileName;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CV uploaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading CV: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload CV')),
      body: _isLoadingInitial
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_existingCvFilename != null) ...[
                    const Text(
                      'Current CV:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_existingCvFilename!),
                    if (_existingCvUrl != null) ...[
                      const SizedBox(height: 8),
                      SelectableText(
                        'Public URL: $_existingCvUrl',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),
                  ],
                  if (_fileName != null &&
                      _fileName != _existingCvFilename) ...[
                    const Text(
                      'Selected File (New):',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(_fileName!),
                    const SizedBox(height: 24),
                  ],
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _pickPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Choose PDF'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _selectedPdf == null || _isUploading
                        ? null
                        : _uploadPdf,
                    child: _isUploading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Upload CV'),
                  ),
                  if (_uploadedUrl != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'CV Uploaded!',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
