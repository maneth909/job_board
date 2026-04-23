import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_client.dart';
import '../../jobs/models/job_model.dart';

const _kSavedJobsKey = 'saved_job_ids';

final savedJobsServiceProvider = Provider<SavedJobsService>((ref) {
  return SavedJobsService(supabase);
});

final savedJobsProvider = FutureProvider<List<Job>>((ref) async {
  return ref.watch(savedJobsServiceProvider).getSavedJobs();
});

final isJobSavedProvider = FutureProvider.family<bool, String>((ref, jobId) async {
  return ref.watch(savedJobsServiceProvider).isJobSaved(jobId);
});

class SavedJobsService {
  final SupabaseClient _supabase;

  SavedJobsService(this._supabase);

  Future<List<String>> _loadSavedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSavedJobsKey);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw));
  }

  Future<void> _saveIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSavedJobsKey, jsonEncode(ids));
  }

  Future<void> saveJob(String jobId) async {
    final ids = await _loadSavedIds();
    if (!ids.contains(jobId)) {
      ids.insert(0, jobId);
      await _saveIds(ids);
    }
  }

  Future<void> unsaveJob(String jobId) async {
    final ids = await _loadSavedIds();
    ids.remove(jobId);
    await _saveIds(ids);
  }

  Future<bool> isJobSaved(String jobId) async {
    final ids = await _loadSavedIds();
    return ids.contains(jobId);
  }

  Future<List<Job>> getSavedJobs() async {
    final ids = await _loadSavedIds();
    if (ids.isEmpty) return [];

    final response = await _supabase
        .from('jobs')
        .select(
          '*, profiles(avatar_url, employer_profiles(company_name, industry))',
        )
        .inFilter('id', ids);

    final jobs = (response as List<dynamic>)
        .map((j) => Job.fromMap(j))
        .toList();

    // Preserve saved order (most recently saved first)
    jobs.sort((a, b) => ids.indexOf(a.id).compareTo(ids.indexOf(b.id)));
    return jobs;
  }
}
