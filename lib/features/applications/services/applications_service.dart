import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';

const _kApplicationsKey = 'job_applications_local';

final applicationsServiceProvider = Provider<ApplicationsService>((ref) {
  return ApplicationsService(supabase);
});

final appliedJobsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(applicationsServiceProvider).getApplications();
});

final isJobAppliedProvider = FutureProvider.family<bool, String>((ref, jobId) async {
  return ref.watch(applicationsServiceProvider).isApplied(jobId);
});

class ApplicationsService {
  final SupabaseClient _supabase;

  ApplicationsService(this._supabase);

  Future<List<Map<String, dynamic>>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kApplicationsKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  Future<void> _saveLocal(List<Map<String, dynamic>> apps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kApplicationsKey, jsonEncode(apps));
  }

  Future<void> applyToJob({required String jobId, String? message}) async {
    final apps = await _loadLocal();
    final alreadyApplied = apps.any((a) => a['job_id'] == jobId);
    if (alreadyApplied) return;

    apps.insert(0, {
      'job_id': jobId,
      'status': 'applied',
      'message': message,
      'applied_at': DateTime.now().toIso8601String(),
    });
    await _saveLocal(apps);
  }

  Future<bool> isApplied(String jobId) async {
    final apps = await _loadLocal();
    return apps.any((a) => a['job_id'] == jobId);
  }

  Future<List<Map<String, dynamic>>> getApplications() async {
    final apps = await _loadLocal();
    if (apps.isEmpty) return [];

    final jobIds = apps.map((a) => a['job_id'] as String).toList();
    final response = await _supabase
        .from('jobs')
        .select(
          'id, title, location, category, salary_range, profiles(avatar_url, employer_profiles(company_name))',
        )
        .inFilter('id', jobIds);

    final jobsById = <String, Map<String, dynamic>>{};
    for (final job in (response as List<dynamic>)) {
      jobsById[job['id'] as String] = job as Map<String, dynamic>;
    }

    return apps.map((app) {
      return {
        ...app,
        'jobs': jobsById[app['job_id']],
      };
    }).toList();
  }
}
