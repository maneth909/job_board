import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase_client.dart';

final profileServiceProvider = Provider((ref) => ProfileService(supabase));

class ProfileService {
  final SupabaseClient _supabase;

  ProfileService(this._supabase);

  User? getCurrentUser() => _supabase.auth.currentUser;

  Future<Map<String, dynamic>?> getProfileStatus() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final profileResponse = await _supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();

    if (profileResponse == null) return null;

    final role = profileResponse['role'] as String?;
    bool isCompleted = false;

    if (role == 'jobseeker') {
      final jsProfile = await _supabase
          .from('jobseeker_profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      isCompleted = jsProfile != null;
    } else if (role == 'employer') {
      final empProfile = await _supabase
          .from('employer_profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      isCompleted = empProfile != null;
    }

    return {'role': role, 'isCompleted': isCompleted};
  }

  Future<void> updateRole(String role) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _supabase.from('profiles').upsert({'id': user.id, 'role': role});
  }

  Future<void> upsertJobseekerProfile({
    required String university,
    required String major,
    String? skillsString,
    String? bio,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    List<String> skills = [];
    if (skillsString != null && skillsString.trim().isNotEmpty) {
      skills = skillsString.split(',').map((s) => s.trim()).toList();
    }

    await _supabase.from('jobseeker_profiles').upsert({
      'id': user.id,
      'university': university,
      'major': major,
      'skills': skills.isNotEmpty ? skills : null,
      'bio': bio?.trim().isNotEmpty == true ? bio : null,
    });
  }

  Future<void> upsertEmployerProfile({
    required String companyName,
    String? industry,
    String? description,
    String? website,
    required String telegramHandle,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    String cleanTelegram = telegramHandle.trim();
    if (cleanTelegram.startsWith('@')) {
      cleanTelegram = cleanTelegram.substring(1);
    }

    await _supabase.from('employer_profiles').upsert({
      'id': user.id,
      'company_name': companyName,
      'industry': industry?.trim().isNotEmpty == true ? industry : null,
      'description': description?.trim().isNotEmpty == true
          ? description
          : null,
      'website': website?.trim().isNotEmpty == true ? website : null,
      'telegram_handle': cleanTelegram,
    });
  }

  Future<Map<String, dynamic>?> getEmployerProfile(String employerId) async {
    final response = await _supabase
        .from('employer_profiles')
        .select('*, profiles(avatar_url)')
        .eq('id', employerId)
        .maybeSingle();
    return response;
  }

  Future<Map<String, dynamic>?> getJobseekerProfile(String jobseekerId) async {
    final response = await _supabase
        .from('jobseeker_profiles')
        .select('*, profiles(avatar_url)')
        .eq('id', jobseekerId)
        .maybeSingle();
    return response;
  }
}
