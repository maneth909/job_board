import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/saved_jobs_service.dart';
import '../../jobs/models/job_model.dart';

class SavedJobsScreen extends ConsumerWidget {
  const SavedJobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final savedAsync = ref.watch(savedJobsProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Text(
                'Saved Jobs',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            Expanded(
              child: savedAsync.when(
                data: (jobs) {
                  if (jobs.isEmpty) {
                    return _buildEmptyState(colorScheme);
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(savedJobsProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: jobs.length,
                      itemBuilder: (context, index) {
                        return _SavedJobCard(
                          job: jobs[index],
                          onRemoved: () => ref.invalidate(savedJobsProvider),
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
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load saved jobs.',
                        style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => ref.invalidate(savedJobsProvider),
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
              CupertinoIcons.bookmark,
              size: 44,
              color: colorScheme.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Saved Jobs Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the bookmark icon on any job\nto save it for later.',
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

class _SavedJobCard extends ConsumerStatefulWidget {
  final Job job;
  final VoidCallback onRemoved;

  const _SavedJobCard({required this.job, required this.onRemoved});

  @override
  ConsumerState<_SavedJobCard> createState() => _SavedJobCardState();
}

class _SavedJobCardState extends ConsumerState<_SavedJobCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _unsave() async {
    try {
      final service = ref.read(savedJobsServiceProvider);
      await service.unsaveJob(widget.job.id);
      widget.onRemoved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: () => context.push('/jobs/${widget.job.id}'),
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
                  image: widget.job.companyLogo != null
                      ? DecorationImage(
                          image: NetworkImage(widget.job.companyLogo!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: widget.job.companyLogo == null
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
                      widget.job.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.job.companyName ?? 'Unknown Company',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withOpacity(0.55),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPill(widget.job.category, colorScheme),
                        if (widget.job.location != null) ...[
                          const SizedBox(width: 6),
                          _buildPill(widget.job.location!, colorScheme),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _unsave,
                icon: Icon(
                  CupertinoIcons.bookmark_fill,
                  color: colorScheme.primary,
                  size: 22,
                ),
                tooltip: 'Remove',
              ),
            ],
          ),
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
}
