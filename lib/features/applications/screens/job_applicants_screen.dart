import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/applications_service.dart';

class JobApplicantsScreen extends ConsumerWidget {
  final String jobId;
  final String jobTitle;

  const JobApplicantsScreen({
    super.key,
    required this.jobId,
    required this.jobTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final applicantsAsync = ref.watch(jobApplicantsProvider(jobId));

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.chevron_left_rounded, color: colorScheme.onSurface, size: 28),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Applicants',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            Text(
              jobTitle,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: applicantsAsync.when(
        data: (applicants) {
          if (applicants.isEmpty) {
            return _buildEmptyState(colorScheme);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(jobApplicantsProvider(jobId)),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: applicants.length,
              itemBuilder: (context, index) {
                return _ApplicantCard(
                  applicant: applicants[index],
                  onStatusChanged: (appId, status) async {
                    try {
                      await ref
                          .read(applicationsServiceProvider)
                          .updateApplicationStatus(
                            applicationId: appId,
                            status: status,
                          );
                      ref.invalidate(jobApplicantsProvider(jobId));
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to update status: $e')),
                        );
                      }
                    }
                  },
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(
                'Failed to load applicants.',
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.invalidate(jobApplicantsProvider(jobId)),
                child: const Text('Retry'),
              ),
            ],
          ),
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
              Icons.person_search_rounded,
              size: 44,
              color: colorScheme.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Applicants Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Candidates who apply to this job\nwill appear here.',
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

class _ApplicantCard extends StatelessWidget {
  final Map<String, dynamic> applicant;
  final Future<void> Function(String appId, String status) onStatusChanged;

  const _ApplicantCard({
    required this.applicant,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = applicant['profile'] as Map<String, dynamic>?;
    final avatarUrl = applicant['avatar_url'] as String?;
    final status = applicant['status'] as String? ?? 'applied';
    final message = applicant['message'] as String?;
    final appliedAt = applicant['applied_at'] != null
        ? DateTime.tryParse(applicant['applied_at'] as String)
        : null;
    final appId = applicant['id'] as String;

    final university = profile?['university'] as String?;
    final major = profile?['major'] as String?;
    final bio = profile?['bio'] as String?;
    final rawSkills = profile?['skills'];
    final List<String> skills = rawSkills is List
        ? rawSkills.map((s) => s.toString()).toList()
        : [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                    image: avatarUrl != null
                        ? DecorationImage(
                            image: NetworkImage(avatarUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: avatarUrl == null
                      ? Icon(
                          Icons.person_rounded,
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
                      if (university != null)
                        Text(
                          university,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      if (major != null)
                        Text(
                          major,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withOpacity(0.55),
                          ),
                        ),
                      if (university == null && major == null)
                        Text(
                          'Applicant',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusBadge(status, colorScheme),
              ],
            ),

            if (appliedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Applied ${_formatDate(appliedAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ],

            if (skills.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: skills.take(5).map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      skill,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            if (bio != null && bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                bio,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withOpacity(0.6),
                  height: 1.5,
                ),
              ),
            ],

            if (message != null && message.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Message',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface.withOpacity(0.4),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withOpacity(0.7),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),

            Row(
              children: [
                Text(
                  'Update Status:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _statusButton('viewed', 'Viewed', Colors.orange, status, appId, onStatusChanged),
                        const SizedBox(width: 6),
                        _statusButton('shortlisted', 'Shortlist', Colors.green, status, appId, onStatusChanged),
                        const SizedBox(width: 6),
                        _statusButton('rejected', 'Reject', Colors.red, status, appId, onStatusChanged),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusButton(
    String value,
    String label,
    Color color,
    String currentStatus,
    String appId,
    Future<void> Function(String, String) onChanged,
  ) {
    final isActive = currentStatus == value;
    return GestureDetector(
      onTap: isActive ? null : () => onChanged(appId, value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? color.withOpacity(0.5) : color.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status, ColorScheme colorScheme) {
    Color color;
    String label;
    switch (status) {
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
