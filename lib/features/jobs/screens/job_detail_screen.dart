import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:job_board/features/profile/providers/profile_state_provider.dart';
import '../services/job_service.dart';
import '../models/job_model.dart';

import '../../../core/supabase_client.dart';
import '../../ai/services/groq_service.dart';
import '../../profile/services/profile_service.dart';
import '../../saved_jobs/services/saved_jobs_service.dart';
import '../../applications/services/applications_service.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  bool _isCheckingMatch = false;
  bool _isSaved = false;
  bool _isApplied = false;
  bool _isTogglingBookmark = false;

  @override
  void initState() {
    super.initState();
    _loadSaveApplyState();
  }

  Future<void> _loadSaveApplyState() async {
    try {
      final savedService = ref.read(savedJobsServiceProvider);
      final appsService = ref.read(applicationsServiceProvider);
      final saved = await savedService.isJobSaved(widget.jobId);
      final applied = await appsService.isApplied(widget.jobId);
      if (mounted) {
        setState(() {
          _isSaved = saved;
          _isApplied = applied;
        });
      }
    } catch (_) {}
  }

  Future<void> _handleToggleSave() async {
    if (_isTogglingBookmark) return;
    setState(() => _isTogglingBookmark = true);
    try {
      final service = ref.read(savedJobsServiceProvider);
      if (_isSaved) {
        await service.unsaveJob(widget.jobId);
        if (mounted) {
          setState(() => _isSaved = false);
          ref.invalidate(savedJobsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from saved jobs')),
          );
        }
      } else {
        await service.saveJob(widget.jobId);
        if (mounted) {
          setState(() => _isSaved = true);
          ref.invalidate(savedJobsProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job saved!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTogglingBookmark = false);
    }
  }

  Future<void> _handleApply(Job job) async {
    if (_isApplied) return;
    final colorScheme = Theme.of(context).colorScheme;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ApplyBottomSheet(
        job: job,
        colorScheme: colorScheme,
        onApplied: () {
          if (mounted) {
            setState(() => _isApplied = true);
            ref.invalidate(appliedJobsProvider);
          }
        },
      ),
    );
  }

  Future<void> _handleAiMatch(Job job) async {
    if (_isCheckingMatch) return;

    setState(() {
      _isCheckingMatch = true;
    });

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      Map<String, dynamic> matchResult;

      if (job.cachedMatchScore != null) {
        final response = await supabase
            .from('cv_matches')
            .select('match_data')
            .eq('job_id', job.id)
            .eq('jobseeker_id', currentUser.id)
            .single();

        matchResult = response['match_data'] as Map<String, dynamic>;
      } else {
        final profileService = ref.read(profileServiceProvider);
        final jsProfile = await profileService.getJobseekerProfile(
          currentUser.id,
        );

        if (jsProfile == null ||
            jsProfile['cv_text'] == null ||
            jsProfile['cv_text'].toString().trim().isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Please upload your CV in your Profile first to use AI Match.',
                ),
              ),
            );
          }
          setState(() {
            _isCheckingMatch = false;
          });
          return;
        }

        final String cvText = jsProfile['cv_text'] as String;

        final groqService = ref.read(groqServiceProvider);
        matchResult = await groqService.getAndCacheCVMatchScore(
          jobId: job.id,
          cvText: cvText,
          jobDescription: job.description,
        );

        ref.invalidate(jobsProvider);
      }

      if (mounted) {
        context.push('/jobs/${job.id}/match', extra: matchResult);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to analyze match: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingMatch = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobAsync = ref.watch(jobDetailsProvider(widget.jobId));
    final profileState = ref.watch(profileStateProvider);
    final isEmployer = profileState.role == 'employer';
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        bottomNavigationBar: jobAsync.hasValue && !isEmployer
            ? _buildStickyBottomBar(jobAsync.value!, colorScheme, context)
            : null,
        body: jobAsync.when(
          data: (job) {
            return Stack(
              children: [
                // 1. Wavy Top Background matching your color theme
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: size.height * 0.4,
                  child: ClipPath(
                    clipper: InverseWavyTopClipper(),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colorScheme.primary.withOpacity(0.8),
                            colorScheme.primary,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. Main Scrollable Content
                Positioned.fill(
                  child: SafeArea(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Custom Header
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    onPressed: () => context.pop(),
                                    icon: const Icon(
                                      Icons.chevron_left_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const Text(
                                  'Jobs Details',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    onPressed: () {}, // Filter action
                                    icon: const Icon(
                                      Icons.tune_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 60),

                          // White Sheet Content
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(32),
                                topRight: Radius.circular(32),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Overlapping Logo & Company Name Stack
                                Transform.translate(
                                  offset: const Offset(0, -45),
                                  child: Column(
                                    children: [
                                      // Logo
                                      Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: colorScheme.surface,
                                          border: Border.all(
                                            color: colorScheme.surface,
                                            width: 4,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.08,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                          image: job.companyLogo != null
                                              ? DecorationImage(
                                                  image: NetworkImage(
                                                    job.companyLogo!,
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: job.companyLogo == null
                                            ? Icon(
                                                Icons.business,
                                                color: colorScheme.primary,
                                                size: 40,
                                              )
                                            : null,
                                      ),
                                      const SizedBox(height: 12),

                                      // Company Name
                                      Text(
                                        job.companyName ?? 'Unknown Company',
                                        style: TextStyle(
                                          color: colorScheme.primary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Transform.translate(
                                  offset: const Offset(
                                    0,
                                    -15,
                                  ), // Adjusting spacing due to translation above
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    child: Column(
                                      children: [
                                        // Job Title
                                        Text(
                                          job.title,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          job.location ?? 'Remote',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colorScheme.onSurface
                                                .withOpacity(0.5),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),

                                        const SizedBox(height: 24),

                                        // Primary colored Stat Boxes Row
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            _buildStatBox(
                                              'Salary/year',
                                              job.salaryRange ?? 'Undisclosed',
                                              colorScheme,
                                            ),
                                            const SizedBox(width: 16),
                                            _buildStatBox(
                                              'Job Type',
                                              job.category,
                                              colorScheme,
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 32),

                                        // Details Section
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Job Details',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            job.description,
                                            style: TextStyle(
                                              fontSize: 14,
                                              height: 1.6,
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 32),

                                        // Skills List
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Skills',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: job.skillsRequired
                                                .map(
                                                  (skill) => _buildTag(
                                                    skill,
                                                    colorScheme,
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ),

                                        const SizedBox(height: 32),

                                        // Modern Pill Match Result
                                        if (job.cachedMatchScore != null &&
                                            !isEmployer)
                                          _buildMatchTargetModern(
                                            job.cachedMatchScore!,
                                          ),

                                        const SizedBox(
                                          height: 40,
                                        ), // Bottom padding
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  // Helper for the Primary Color Stat Boxes
  Widget _buildStatBox(String label, String value, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.onSecondary.withOpacity(0.07), // Primary color box
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSecondary.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Helper for the Skill Tags
  Widget _buildTag(String text, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface.withOpacity(0.8),
        ),
      ),
    );
  }

  // Helper for Match Score Pill
  Widget _buildMatchTargetModern(int score) {
    Color color = score >= 70
        ? Colors.green
        : (score >= 40 ? Colors.orange : Colors.red);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            'Your match is $score%',
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // Modernized Sticky Bottom Bar
  Widget _buildStickyBottomBar(
    Job job,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          // Bookmark Button
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: _isSaved
                  ? colorScheme.primary.withOpacity(0.12)
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isSaved
                    ? colorScheme.primary.withOpacity(0.4)
                    : colorScheme.outline.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: _isTogglingBookmark
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  : Icon(
                      _isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_add_outlined,
                      color: _isSaved
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
              onPressed: _handleToggleSave,
            ),
          ),
          const SizedBox(width: 12),

          // AI Analyze Button
          Expanded(
            child: SizedBox(
              height: 54,
              child: OutlinedButton(
                onPressed: _isCheckingMatch ? null : () => _handleAiMatch(job),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _isCheckingMatch
                      ? colorScheme.primary.withOpacity(0.1)
                      : colorScheme.primary.withOpacity(0.1),
                  side: BorderSide.none, // Removed border
                  foregroundColor:
                      colorScheme.primary, // Text color matches background tint
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isCheckingMatch
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.primary,
                        ),
                      )
                    : Text(
                        job.cachedMatchScore != null
                            ? 'View Match'
                            : 'AI Analyze',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Apply Button
          Expanded(
            child: SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _isApplied ? null : () => _handleApply(job),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isApplied
                      ? colorScheme.primary.withOpacity(0.5)
                      : colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  disabledBackgroundColor: colorScheme.primary.withOpacity(0.5),
                  disabledForegroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _isApplied ? 'Applied ✓' : 'Apply Now',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplyBottomSheet extends ConsumerStatefulWidget {
  final Job job;
  final ColorScheme colorScheme;
  final VoidCallback onApplied;

  const _ApplyBottomSheet({
    required this.job,
    required this.colorScheme,
    required this.onApplied,
  });

  @override
  ConsumerState<_ApplyBottomSheet> createState() => _ApplyBottomSheetState();
}

class _ApplyBottomSheetState extends ConsumerState<_ApplyBottomSheet> {
  bool _isGenerating = false;
  bool _isApplying = false;
  String? _generatedMessage;
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _generateMessage() async {
    setState(() => _isGenerating = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final profileService = ref.read(profileServiceProvider);
      final profile = await profileService.getJobseekerProfile(user.id);
      final name =
          user.userMetadata?['full_name'] as String? ?? 'Applicant';
      final university = profile?['university'] as String? ?? '';
      final skills = (profile?['skills'] as List<dynamic>? ?? []).join(', ');
      final cvUrl = profile?['cv_url'] as String? ?? '';

      final groq = ref.read(groqServiceProvider);
      final msg = await groq.generateApplicationMessage(
        jobseekerName: name,
        university: university,
        skills: skills,
        jobTitle: widget.job.title,
        companyName: widget.job.companyName ?? '',
        cvUrl: cvUrl,
      );

      if (mounted) {
        setState(() {
          _generatedMessage = msg;
          _messageController.text = msg;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate message: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _submitApplication() async {
    setState(() => _isApplying = true);
    try {
      final appsService = ref.read(applicationsServiceProvider);
      await appsService.applyToJob(
        jobId: widget.job.id,
        message: _messageController.text.trim().isNotEmpty
            ? _messageController.text.trim()
            : null,
      );
      widget.onApplied();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.colorScheme;
    final contact = widget.job.telegramContact ?? '';

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Apply for ${widget.job.title}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          if (widget.job.companyName != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.job.companyName!,
              style: TextStyle(
                fontSize: 14,
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Application Message (optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _isGenerating ? null : _generateMessage,
                icon: _isGenerating
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      )
                    : Icon(Icons.auto_awesome, size: 16, color: cs.primary),
                label: Text(
                  _isGenerating ? 'Generating...' : 'AI Generate',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: cs.onSurface.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline.withOpacity(0.2)),
            ),
            child: TextField(
              controller: _messageController,
              maxLines: 4,
              style: TextStyle(fontSize: 14, color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Write a short message to the employer...',
                hintStyle:
                    TextStyle(color: cs.onSurface.withOpacity(0.4), fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
          ),
          if (_generatedMessage != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(
                    ClipboardData(text: _messageController.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied!')),
                );
              },
              child: Row(
                children: [
                  Icon(Icons.copy, size: 14, color: cs.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Copy message',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (contact.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.send_rounded,
                    size: 14,
                    color: cs.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Will send application via Telegram: @$contact',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isApplying ? null : _submitApplication,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isApplying
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : const Text(
                      'Confirm Application',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// Clipper for the wavy background header
class InverseWavyTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height - 20,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 40,
      size.width,
      size.height,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
