import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/job_service.dart';

class JobListingScreen extends ConsumerStatefulWidget {
  const JobListingScreen({super.key});

  @override
  ConsumerState<JobListingScreen> createState() => _JobListingScreenState();
}

class _JobListingScreenState extends ConsumerState<JobListingScreen> {
  String _searchQuery = '';
  String _category = 'All';
  int _currentPage = 1;
  int _totalJobs = 0;
  bool _isLoadingTotal = false;

  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Internship',
    'Full-time',
    'Part-time',
  ];

  @override
  void initState() {
    super.initState();
    _fetchTotalCount();
  }

  Future<void> _fetchTotalCount() async {
    setState(() => _isLoadingTotal = true);
    try {
      final jobService = ref.read(jobServiceProvider);
      final count = await jobService.getTotalJobsCount(
        searchQuery: _searchQuery,
        category: _category,
      );
      if (mounted) {
        setState(() {
          _totalJobs = count;
          _isLoadingTotal = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingTotal = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
          _currentPage = 1; // RESET page visually
        });
        _fetchTotalCount();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filters = JobFilters(
        searchQuery: _searchQuery, category: _category, page: _currentPage);
    final jobsAsyncValue = ref.watch(jobsProvider(filters));

    final totalPages = (_totalJobs / 10).ceil().clamp(1, 9999);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Board'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'), // Simplified
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by title or keyword...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _categories.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: _category == cat,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _category = cat;
                          _currentPage = 1; // RESET
                        });
                        _fetchTotalCount();
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: jobsAsyncValue.when(
              data: (jobs) {
                if (jobs.isEmpty) {
                  return const Center(child: Text('No active jobs found.'));
                }
                return ListView.builder(
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: job.companyLogo != null
                              ? NetworkImage(job.companyLogo!)
                              : null,
                          child: job.companyLogo == null
                              ? const Icon(Icons.business)
                              : null,
                        ),
                        title: Text(
                          job.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job.companyName ?? 'Unknown Company'),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: job.skillsRequired
                                  .map(
                                    (skill) => Chip(
                                      label: Text(
                                        skill,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      padding: EdgeInsets.zero,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  )
                                  .toList(),
                            ),
                            if (job.cachedMatchScore != null) ...[
                              const SizedBox(height: 8),
                              _buildMatchTarget(job.cachedMatchScore!),
                            ],
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        isThreeLine: true,
                        onTap: () => context.push('/jobs/${job.id}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),

          if (!_isLoadingTotal && _totalJobs > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () => setState(() => _currentPage--)
                        : null,
                  ),
                  Text('Page $_currentPage of $totalPages'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < totalPages
                        ? () => setState(() => _currentPage++)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMatchTarget(int score) {
    Color color;
    if (score < 40) {
      color = Colors.red;
    } else if (score < 70) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        'Match: $score%',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
