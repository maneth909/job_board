import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/supabase_client.dart';

final fileUploadServiceProvider = Provider(
  (ref) => FileUploadService(supabase),
);

class FileUploadService {
  final SupabaseClient _supabase;

  FileUploadService(this._supabase);

  Future<String?> uploadAvatar(File imageFile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final filePath = '${user.id}/profile_pic.jpg';

    await _supabase.storage
        .from('avatars')
        .upload(
          filePath,
          imageFile,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    final publicUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);

    // Update the profiles table
    await _supabase
        .from('profiles')
        .update({'avatar_url': publicUrl})
        .eq('id', user.id);

    return publicUrl;
  }

  Future<String?> uploadCv(File pdfFile, String originalFilename) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final filePath = '${user.id}/cv.pdf';

    await _supabase.storage
        .from('cvs')
        .upload(
          filePath,
          pdfFile,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'application/pdf',
          ),
        );

    final publicUrlBase = _supabase.storage.from('cvs').getPublicUrl(filePath);
    final publicUrl =
        '$publicUrlBase?t=${DateTime.now().millisecondsSinceEpoch}';

    // Update jobseeker profile with cv details
    // Ensure the profile exists before this step, otherwise this update might fail using .update().
    // We will assume jobseeker_profiles record is already created by profile setup.
    await _supabase
        .from('jobseeker_profiles')
        .update({'cv_url': publicUrl, 'cv_filename': originalFilename})
        .eq('id', user.id);

    return publicUrl;
  }
}
