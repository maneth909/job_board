import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:job_board/features/profile/providers/profile_state_provider.dart';
import '../services/job_service.dart';

class JobDetailScreen extends ConsumerWidget {
  final String jobId;

  const JobDetailScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobDetailsProvider(jobId));
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
                Text(job.title, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('Category: ${job.category}', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 16),
                Text('Description', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(job.description),
                const SizedBox(height: 16),
                Text('Skills Required', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: job.skillsRequired.map((skill) => Chip(label: Text(skill))).toList(),
                ),
                const Spacer(),
                if (!isEmployer) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Apply callback
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Apply via Telegram'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // AI Match callback
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('AI Match'),
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
