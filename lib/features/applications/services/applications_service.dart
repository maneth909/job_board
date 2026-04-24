import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';

final applicationsServiceProvider = Provider<ApplicationsService>((ref) {
  return ApplicationsService(supabase);
});

final appliedJobsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(applicationsServiceProvider).getApplications();
});

final isJobAppliedProvider = FutureProvider.family<bool, String>((ref, jobId) async {
  return ref.watch(applicationsServiceProvider).isApplied(jobId);
});

final jobApplicantsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((
  ref,
  jobId,
) async {
  return ref.watch(applicationsServiceProvider).getApplicantsForJob(jobId);
});

class ApplicationsService {
  final SupabaseClient _supabase;

  ApplicationsService(this._supabase);

  Future<void> applyToJob({required String jobId, String? message}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase.from('job_applications').upsert({
      'job_id': jobId,
      'jobseeker_id': user.id,
      'status': 'applied',
      'message': message,
    }, onConflict: 'job_id, jobseeker_id');
  }

  Future<bool> isApplied(String jobId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    final result = await _supabase
        .from('job_applications')
        .select('id')
        .eq('job_id', jobId)
        .eq('jobseeker_id', user.id)
        .maybeSingle();

    return result != null;
  }

  Future<List<Map<String, dynamic>>> getApplications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('job_applications')
        .select(
          'id, status, message, applied_at, jobs(id, title, location, category, salary_range, profiles(avatar_url, employer_profiles(company_name)))',
        )
        .eq('jobseeker_id', user.id)
        .order('applied_at', ascending: false);

    return List<Map<String, dynamic>>.from(response as List);
  }

  Future<List<Map<String, dynamic>>> getApplicantsForJob(String jobId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final appsResponse = await _supabase
        .from('job_applications')
        .select('id, status, message, applied_at, jobseeker_id')
        .eq('job_id', jobId)
        .order('applied_at', ascending: false);

    final apps = List<Map<String, dynamic>>.from(appsResponse as List);
    if (apps.isEmpty) return [];

    final seekerIds = apps.map((a) => a['jobseeker_id'] as String).toList();

    final profilesResponse = await _supabase
        .from('jobseeker_profiles')
        .select('id, university, major, skills, bio, cv_url, cv_filename')
        .inFilter('id', seekerIds);

    final avatarResponse = await _supabase
        .from('profiles')
        .select('id, avatar_url')
        .inFilter('id', seekerIds);

    final profilesById = <String, Map<String, dynamic>>{};
    for (final p in (profilesResponse as List)) {
      profilesById[p['id'] as String] = Map<String, dynamic>.from(p as Map);
    }

    final avatarsById = <String, String?>{};
    for (final p in (avatarResponse as List)) {
      avatarsById[p['id'] as String] = p['avatar_url'] as String?;
    }

    return apps.map((app) {
      final seekerId = app['jobseeker_id'] as String;
      return {
        ...app,
        'profile': profilesById[seekerId],
        'avatar_url': avatarsById[seekerId],
      };
    }).toList();
  }

  Future<void> updateApplicationStatus({
    required String applicationId,
    required String status,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase
        .from('job_applications')
        .update({'status': status})
        .eq('id', applicationId);
  }
}
