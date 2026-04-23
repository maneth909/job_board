import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/applications_service.dart';

class ApplicationsScreen extends ConsumerWidget {
  const ApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final appsAsync = ref.watch(appliedJobsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Text(
                'My Applications',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Expanded(
              child: appsAsync.when(
                data: (apps) {
                  if (apps.isEmpty) {
                    return _buildEmptyState(colorScheme);
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(appliedJobsProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: apps.length,
                      itemBuilder: (context, index) {
                        return _ApplicationCard(app: apps[index]);
                      },
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load applications.',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => ref.invalidate(appliedJobsProvider),
                        child: const Text('Retry'),
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

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.briefcase,
              size: 44,
              color: colorScheme.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Applications Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse jobs and hit "Apply Now"\nto track your applications here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.5),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final Map<String, dynamic> app;

  const _ApplicationCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final jobData = app['jobs'] as Map<String, dynamic>?;
    if (jobData == null) return const SizedBox.shrink();

    final title = jobData['title'] as String? ?? 'Unknown Job';
    final category = jobData['category'] as String? ?? '';
    final location = jobData['location'] as String?;
    final profilesData = jobData['profiles'] as Map<String, dynamic>?;
    final companyLogo = profilesData?['avatar_url'] as String?;
    final empProfiles = profilesData?['employer_profiles'];
    String? companyName;
    if (empProfiles is List && empProfiles.isNotEmpty) {
      companyName = empProfiles[0]['company_name'] as String?;
    } else if (empProfiles is Map) {
      companyName = empProfiles['company_name'] as String?;
    }

    final status = app['status'] as String? ?? 'applied';
    final appliedAt = app['applied_at'] != null
        ? DateTime.tryParse(app['applied_at'] as String)
        : null;
    final jobId = jobData['id'] as String?;

    return GestureDetector(
      onTap: jobId != null ? () => context.push('/jobs/$jobId') : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                image: companyLogo != null
                    ? DecorationImage(
                        image: NetworkImage(companyLogo),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: companyLogo == null
                  ? Icon(
                      Icons.domain_rounded,
                      color: colorScheme.primary.withOpacity(0.6),
                      size: 26,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    companyName ?? 'Unknown Company',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPill(category, colorScheme),
                      if (location != null) ...[
                        const SizedBox(width: 6),
                        _buildPill(location, colorScheme),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStatusBadge(status, colorScheme),
                if (appliedAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(appliedAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPill(String text, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface.withOpacity(0.65),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, ColorScheme colorScheme) {
    Color color;
    String label;
    switch (status) {
      case 'applied':
        color = Colors.blue;
        label = 'Applied';
        break;
      case 'viewed':
        color = Colors.orange;
        label = 'Viewed';
        break;
      case 'shortlisted':
        color = Colors.green;
        label = 'Shortlisted';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rejected';
        break;
      default:
        color = Colors.blue;
        label = 'Applied';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return '1d ago';
    if (diff < 30) return '${diff}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
