import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:job_board/features/profile/providers/profile_state_provider.dart';
import '../services/job_service.dart';
import '../models/job_model.dart';

import '../../../core/supabase_client.dart';
import '../../ai/services/groq_service.dart';
import '../../profile/services/profile_service.dart';

class JobDetailScreen extends ConsumerStatefulWidget {
  final String jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  ConsumerState<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends ConsumerState<JobDetailScreen> {
  bool _isCheckingMatch = false;

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
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.bookmark_add_outlined,
                color: colorScheme.onSurface,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Saved to bookmarks')),
                );
              },
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
                onPressed: () {
                  final contact = job.telegramContact ?? 'employer_handle';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Opening Telegram: $contact')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Apply Now',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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
