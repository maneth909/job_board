import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/job_service.dart';
import '../models/job_model.dart';
import '../../profile/services/profile_service.dart'; // Added for user data

class JobListingScreen extends ConsumerStatefulWidget {
  const JobListingScreen({super.key});

  @override
  ConsumerState<JobListingScreen> createState() => _JobListingScreenState();
}

class _JobListingScreenState extends ConsumerState<JobListingScreen> {
  String _searchQuery = '';
  String _category = 'All';
  int _totalJobs = 0;
  String _userName = 'User'; // Dynamic user name

  List<Job> _jobs = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _offset = 0;
  static const int _limit = 10;

  final ScrollController _scrollController = ScrollController();
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
    _scrollController.addListener(_onScroll);
    _loadUserName();
    _fetchTotalCount();
    _loadJobs();
  }

  void _loadUserName() {
    try {
      final profileService = ref.read(profileServiceProvider);
      final user = profileService.getCurrentUser();

      if (user != null) {
        setState(() {
          // Extracts full_name from auth metadata, falls back to email prefix, then 'User'
          _userName =
              user.userMetadata?['full_name'] ??
              user.email?.split('@')[0] ??
              'User';

          // Capitalize first letter for a cleaner look
          if (_userName.isNotEmpty) {
            _userName = _userName[0].toUpperCase() + _userName.substring(1);
          }
        });
      }
    } catch (e) {
      // Ignore errors and fall back to default 'User'
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreJobs();
    }
  }

  Future<void> _loadJobs() async {
    final jobService = ref.read(jobServiceProvider);
    final jobs = await jobService.getJobs(
      searchQuery: _searchQuery,
      category: _category,
      offset: 0,
      limit: _limit,
    );
    if (mounted) {
      setState(() {
        _jobs = jobs;
        _offset = jobs.length;
        _hasMore = jobs.length >= _limit;
      });
    }
  }

  Future<void> _loadMoreJobs() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final jobService = ref.read(jobServiceProvider);
      final moreJobs = await jobService.getJobs(
        searchQuery: _searchQuery,
        category: _category,
        offset: _offset,
        limit: _limit,
      );

      if (mounted) {
        setState(() {
          _jobs.addAll(moreJobs);
          _offset += moreJobs.length;
          _hasMore = moreJobs.length >= _limit;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _refreshJobs() async {
    setState(() {
      _jobs = [];
      _offset = 0;
      _hasMore = true;
    });
    await _loadJobs();
  }

  Future<void> _fetchTotalCount() async {
    try {
      final jobService = ref.read(jobServiceProvider);
      final count = await jobService.getTotalJobsCount(
        searchQuery: _searchQuery,
        category: _category,
      );
      if (mounted) {
        setState(() {
          _totalJobs = count;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
        });
        _refreshJobsWithCount();
      }
    });
  }

  Future<void> _refreshJobsWithCount() async {
    await Future.wait([_fetchTotalCount(), _refreshJobs()]);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorScheme.primary.withOpacity(0.8), colorScheme.primary],
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hi, $_userName', // Dynamic Name applied here
                          style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.onPrimary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.notifications_none,
                            color: colorScheme.onPrimary,
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search by title or keyword...',
                          hintStyle: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.4),
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: colorScheme.onSurface.withOpacity(0.4),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: _categories.map((cat) {
                            final isSelected = _category == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: Text(
                                  cat,
                                  style: TextStyle(
                                    color: isSelected
                                        ? colorScheme.onPrimary
                                        : colorScheme.onSurface,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _category = cat;
                                    });
                                    _fetchTotalCount();
                                    _refreshJobs();
                                  }
                                },
                                backgroundColor: colorScheme.surface,
                                selectedColor: colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : colorScheme.outline.withOpacity(0.3),
                                  ),
                                ),
                                showCheckmark: false,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _jobs.isEmpty && !_isLoadingMore
                            ? Center(
                                child: Text(
                                  'No active jobs found.',
                                  style: TextStyle(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.5,
                                    ),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                                itemCount: _jobs.length + (_hasMore ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index >= _jobs.length) {
                                    return _buildLoadMoreButton(colorScheme);
                                  }
                                  final job = _jobs[index];
                                  return _buildModernJobCard(
                                    job,
                                    colorScheme,
                                    context,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: _isLoadingMore
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: TextButton(
                onPressed: _loadMoreJobs,
                child: Text(
                  'Load More',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildModernJobCard(
    dynamic job,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () => context.push('/jobs/${job.id}'),
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
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modernized Company Icon with blue-ish background
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(
                      0.08,
                    ), // Soft blue tint
                    borderRadius: BorderRadius.circular(12),
                    image: job.companyLogo != null
                        ? DecorationImage(
                            image: NetworkImage(job.companyLogo!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: job.companyLogo == null
                      ? Icon(
                          Icons.domain_rounded, // Modern building icon
                          color: colorScheme.primary.withOpacity(
                            0.6,
                          ), // Matching blue tint
                          size: 28,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.companyName ?? 'Unknown Company',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.more_horiz,
                  color: colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...job.skillsRequired
                    .take(3)
                    .map((skill) => _buildTagPill(skill, colorScheme)),
                if (job.skillsRequired.length > 3)
                  _buildTagPill(
                    '+${job.skillsRequired.length - 3}',
                    colorScheme,
                  ),
                if (job.cachedMatchScore != null)
                  _buildMatchTarget(job.cachedMatchScore!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagPill(String text, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurface.withOpacity(0.7),
          fontWeight: FontWeight.w500,
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            'Match $score%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
