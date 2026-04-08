import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/job_model.dart';
import '../services/job_service.dart';

class JobPostScreen extends ConsumerStatefulWidget {
  final Job? job; // Optional job for editing

  const JobPostScreen({super.key, this.job});

  @override
  ConsumerState<JobPostScreen> createState() => _JobPostScreenState();
}

class _JobPostScreenState extends ConsumerState<JobPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skillsController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _telegramController = TextEditingController();

  String _category = 'Full-time';
  final List<String> _categories = ['Internship', 'Full-time', 'Part-time'];

  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.job != null) {
      _titleController.text = widget.job!.title;
      _descriptionController.text = widget.job!.description;
      _skillsController.text = widget.job!.skillsRequired.join(', ');
      _locationController.text = widget.job!.location ?? '';
      _salaryController.text = widget.job!.salaryRange ?? '';
      _telegramController.text = widget.job!.telegramContact ?? '';
      _isActive = widget.job!.isActive;
      if (_categories.contains(widget.job!.category)) {
        _category = widget.job!.category;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _skillsController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _telegramController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final jobService = ref.read(jobServiceProvider);
      final skillsList = _skillsController.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      if (widget.job != null) {
        // Update
        final updatedJob = widget.job!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          skillsRequired: skillsList,
          category: _category,
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          salaryRange: _salaryController.text.trim().isEmpty
              ? null
              : _salaryController.text.trim(),
          telegramContact: _telegramController.text.trim().isEmpty
              ? null
              : _telegramController.text.trim(),
          isActive: _isActive,
        );
        await jobService.updateJob(updatedJob);
      } else {
        // Post new
        await jobService.postJob(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          skillsRequired: skillsList,
          category: _category,
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          salaryRange: _salaryController.text.trim().isEmpty
              ? null
              : _salaryController.text.trim(),
          telegramContact: _telegramController.text.trim().isEmpty
              ? null
              : _telegramController.text.trim(),
          isActive: _isActive,
        );
      }

      // Refresh jobs list for this employer
      ref.invalidate(myJobsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.job != null
                  ? 'Job updated successfully!'
                  : 'Job posted successfully!',
            ),
          ),
        );
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.job != null;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Modern Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: Icon(
                      Icons.chevron_left_rounded,
                      size: 28,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        isEditing ? 'Edit Job Post' : 'Create Job Post',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balances the layout
                ],
              ),
            ),

            // Scrollable Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      _buildModernInput(
                        label: 'Job Title *',
                        controller: _titleController,
                        colorScheme: colorScheme,
                        hintText: 'e.g. Senior Flutter Developer',
                      ),
                      const SizedBox(height: 20),

                      // Modern Dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category *',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _category,
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: colorScheme.onSurface.withOpacity(0.5),
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: colorScheme.onSurface.withOpacity(
                                0.04,
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
                                borderSide: BorderSide(
                                  color: colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            items: _categories.map((cat) {
                              return DropdownMenuItem(
                                value: cat,
                                child: Text(cat),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _category = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _buildModernInput(
                        label: 'Job Description *',
                        controller: _descriptionController,
                        colorScheme: colorScheme,
                        maxLines: 6,
                        hintText:
                            'Describe the role, responsibilities, and requirements...',
                      ),
                      const SizedBox(height: 20),

                      _buildModernInput(
                        label: 'Skills Required *',
                        controller: _skillsController,
                        colorScheme: colorScheme,
                        hintText:
                            'e.g. Flutter, Dart, Firebase (comma separated)',
                      ),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: _buildModernInput(
                              label: 'Location',
                              controller: _locationController,
                              colorScheme: colorScheme,
                              hintText: 'e.g. Remote',
                              isRequired: false,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildModernInput(
                              label: 'Salary Range',
                              controller: _salaryController,
                              colorScheme: colorScheme,
                              hintText: 'e.g. \$4k - \$6k',
                              isRequired: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _buildModernInput(
                        label: 'Telegram Contact',
                        controller: _telegramController,
                        colorScheme: colorScheme,
                        hintText: '@employer_handle',
                        prefixText: '@ ',
                        isRequired: false,
                      ),
                      const SizedBox(height: 32),

                      // Modern Toggle
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _isActive
                              ? colorScheme.primary.withOpacity(0.05)
                              : colorScheme.onSurface.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isActive
                                ? colorScheme.primary.withOpacity(0.2)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Active Listing',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Inactive jobs are hidden from job seekers.',
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
                            Switch.adaptive(
                              value: _isActive,
                              activeColor: colorScheme.primary,
                              onChanged: (val) =>
                                  setState(() => _isActive = val),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Submit Button
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF18181B,
                            ), // Dark sleek button
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isEditing ? 'SAVE CHANGES' : 'PUBLISH JOB',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function for modern inputs
  Widget _buildModernInput({
    required String label,
    required TextEditingController controller,
    required ColorScheme colorScheme,
    int maxLines = 1,
    String? hintText,
    String? prefixText,
    bool isRequired = true,
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
          validator: isRequired
              ? (value) => value == null || value.trim().isEmpty
                    ? 'This field is required'
                    : null
              : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: colorScheme.onSurface.withOpacity(0.04),
            hintText: hintText,
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.3),
              fontSize: 14,
            ),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
