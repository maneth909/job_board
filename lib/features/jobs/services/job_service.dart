import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:job_board/features/auth/services/auth_service.dart';
import '../models/job_model.dart';

final jobServiceProvider = Provider<JobService>((ref) {
  return JobService(supabase: Supabase.instance.client, ref: ref);
});

final jobsProvider = FutureProvider.family<List<Job>, JobFilters>((
  ref,
  filters,
) async {
  final jobService = ref.watch(jobServiceProvider);
  return jobService.getJobs(
    searchQuery: filters.searchQuery,
    category: filters.category,
  );
});

final myJobsProvider = FutureProvider<List<Job>>((ref) async {
  final jobService = ref.watch(jobServiceProvider);
  return jobService.getMyJobs();
});

final jobDetailsProvider = FutureProvider.family<Job, String>((
  ref,
  jobId,
) async {
  final jobService = ref.watch(jobServiceProvider);
  return jobService.getJobById(jobId);
});

class JobFilters {
  final String? searchQuery;
  final String? category;

  JobFilters({this.searchQuery, this.category});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JobFilters &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          category == other.category;

  @override
  int get hashCode => searchQuery.hashCode ^ category.hashCode;
}

class JobService {
  final SupabaseClient supabase;
  final ProviderRef ref;

  JobService({required this.supabase, required this.ref});

  Future<int> getTotalJobsCount({String? searchQuery, String? category}) async {
    var query = supabase.from('jobs').select('id').eq('is_active', true);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.textSearch('fts', searchQuery);
    }

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.eq('category', category);
    }

    final response = await query.count(CountOption.exact);
    return response.count;
  }

  Future<List<Job>> getJobs({
    String? searchQuery,
    String? category,
    int offset = 0,
    int limit = 10,
  }) async {
    var query = supabase
        .from('jobs')
        .select(
          '*, profiles(avatar_url, employer_profiles(company_name, industry)), cv_matches(score)',
        )
        .eq('is_active', true);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.textSearch('fts', searchQuery);
    }

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.eq('category', category);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);
    return (response as List<dynamic>).map((job) => Job.fromMap(job)).toList();
  }

  Future<Job> getJobById(String jobId) async {
    final response = await supabase
        .from('jobs')
        .select(
          '*, profiles(avatar_url, employer_profiles(company_name, industry))',
        )
        .eq('id', jobId)
        .single();
    return Job.fromMap(response);
  }

  Future<List<Job>> getMyJobs() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) throw Exception('User not logged in');

    final response = await supabase
        .from('jobs')
        .select()
        .eq('employer_id', currentUser.id)
        .order('created_at', ascending: false);

    return (response as List<dynamic>).map((job) => Job.fromMap(job)).toList();
  }

  Future<void> postJob({
    required String title,
    required String description,
    required List<String> skillsRequired,
    required String category,
    String? location,
    String? salaryRange,
    String? telegramContact,
    bool isActive = true,
  }) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) throw Exception('User not logged in');

    await supabase.from('jobs').insert({
      'employer_id': currentUser.id,
      'title': title,
      'description': description,
      'skills_required': skillsRequired,
      'category': category,
      'location': location?.trim().isNotEmpty == true ? location : null,
      'salary_range': salaryRange?.trim().isNotEmpty == true
          ? salaryRange
          : null,
      'telegram_contact': telegramContact?.trim().isNotEmpty == true
          ? telegramContact
          : null,
      'is_active': isActive,
    });
  }

  Future<void> duplicateJob(Job job) async {
    await postJob(
      title: '${job.title} (Copy)',
      description: job.description,
      skillsRequired: job.skillsRequired,
      category: job.category,
      location: job.location,
      salaryRange: job.salaryRange,
      telegramContact: job.telegramContact,
      isActive:
          false, // Copies start as inactive so employer can edit before publishing
    );
  }

  Future<void> updateJob(Job job) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) throw Exception('User not logged in');

    await supabase
        .from('jobs')
        .update({
          'title': job.title,
          'description': job.description,
          'skills_required': job.skillsRequired,
          'category': job.category,
          'location': job.location,
          'salary_range': job.salaryRange,
          'telegram_contact': job.telegramContact,
          'is_active': job.isActive,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', job.id)
        .eq('employer_id', currentUser.id);
  }

  Future<void> deleteJob(String jobId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) throw Exception('User not logged in');

    await supabase
        .from('jobs')
        .delete()
        .eq('id', jobId)
        .eq('employer_id', currentUser.id);
  }
}
