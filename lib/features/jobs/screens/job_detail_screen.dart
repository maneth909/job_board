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
        // State 2: Already Analyzed
        final response = await supabase
            .from('cv_matches')
            .select('match_data')
            .eq('job_id', job.id)
            .eq('jobseeker_id', currentUser.id)
            .single();

        matchResult = response['match_data'] as Map<String, dynamic>;
      } else {
        // State 1: First Time Analysis
        final profileService = ref.read(profileServiceProvider);
        final jsProfile = await profileService.getJobseekerProfile(currentUser.id);

        if (jsProfile == null || jsProfile['cv_text'] == null || jsProfile['cv_text'].toString().trim().isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please upload your CV in your Profile first to use AI Match.')),
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

        // Refresh the feed
        ref.invalidate(jobsProvider);
      }

      if (mounted) {
        context.push('/jobs/${job.id}/match', extra: matchResult);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to analyze match: $e')),
        );
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

    return Scaffold(
      appBar: AppBar(title: const Text('Job Details')),
      body: jobAsync.when(
        data: (job) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => context.push('/employer/${job.employerId}'),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: job.companyLogo != null
                            ? NetworkImage(job.companyLogo!)
                            : null,
                        child: job.companyLogo == null
                            ? const Icon(Icons.business)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          job.companyName ?? 'Unknown Company',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  job.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Category: ${job.category}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                if (job.location != null && job.location!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        job.location!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
                if (job.salaryRange != null && job.salaryRange!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        job.salaryRange!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(job.description),
                const SizedBox(height: 16),
                Text(
                  'Skills Required',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: job.skillsRequired
                      .map((skill) => Chip(label: Text(skill)))
                      .toList(),
                ),
                const Spacer(),
                if (!isEmployer) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Apply callback
                        final contact =
                            job.telegramContact ?? 'employer_handle';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Would open Telegram to: $contact'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Apply via Telegram'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isCheckingMatch ? null : () => _handleAiMatch(job),
                      icon: _isCheckingMatch
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        job.cachedMatchScore != null
                            ? '✨ View Match Result'
                            : '✨ Analyze Match',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
