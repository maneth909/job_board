import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/profile_service.dart';
import '../../jobs/services/job_service.dart';
import '../../jobs/models/job_model.dart';
import 'package:go_router/go_router.dart';

final employerProfileProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((
      ref,
      employerId,
    ) async {
      final profileService = ref.watch(profileServiceProvider);
      return profileService.getEmployerProfile(employerId);
    });

final employerJobsProvider = FutureProvider.family<List<Job>, String>((
  ref,
  employerId,
) async {
  final jobService = ref.watch(jobServiceProvider);
  final jobs = await jobService.getJobs();
  return jobs.where((job) => job.employerId == employerId).toList();
});

class EmployerPublicProfileScreen extends ConsumerWidget {
  final String employerId;

  const EmployerPublicProfileScreen({super.key, required this.employerId});

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    final uri = Uri.parse(
      urlString.startsWith('http') ? urlString : 'https://$urlString',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(employerProfileProvider(employerId));
    final jobsAsync = ref.watch(employerJobsProvider(employerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Company Profile')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Employer not found.'));
          }

          final companyName = profile['company_name'] as String? ?? 'Unknown';
          final industry = profile['industry'] as String? ?? 'Not specified';
          final description =
              profile['description'] as String? ?? 'No description provided.';
          final website = profile['website'] as String?;

          final profilesData = profile['profiles'];
          String? avatarUrl;
          if (profilesData != null) {
            if (profilesData is List && profilesData.isNotEmpty) {
              avatarUrl = profilesData[0]['avatar_url'] as String?;
            } else if (profilesData is Map) {
              avatarUrl = profilesData['avatar_url'] as String?;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: avatarUrl != null
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null
                        ? const Icon(Icons.business, size: 48)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    companyName,
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                Center(
                  child: Text(
                    industry,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 24),
                if (website != null && website.isNotEmpty) ...[
                  InkWell(
                    onTap: () => _launchUrl(website),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.link, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          website,
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  'About the Company',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(description),
                const SizedBox(height: 32),
                Text(
                  'Active Jobs',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                jobsAsync.when(
                  data: (jobs) {
                    if (jobs.isEmpty) {
                      return const Text(
                        'This employer currently has no active job postings.',
                      );
                    }
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        final job = jobs[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(
                              job.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(job.category),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/jobs/${job.id}'),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (err, stack) => Text('Error loading jobs: $err'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading profile: $err')),
      ),
    );
  }
}
