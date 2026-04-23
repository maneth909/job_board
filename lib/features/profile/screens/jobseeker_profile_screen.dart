import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profile_service.dart';
import '../../../core/theme_provider.dart';

class JobseekerProfileScreen extends ConsumerStatefulWidget {
  const JobseekerProfileScreen({super.key});

  @override
  ConsumerState<JobseekerProfileScreen> createState() =>
      _JobseekerProfileScreenState();
}

class _JobseekerProfileScreenState
    extends ConsumerState<JobseekerProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  String _fullName = 'User';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final profileService = ref.read(profileServiceProvider);
      final user = profileService.getCurrentUser();

      if (user != null) {
        // Fetch name from auth metadata
        _fullName = user.userMetadata?['full_name'] as String? ?? 'User';

        // Fetch all other data directly from your DB
        final profile = await profileService.getJobseekerProfile(user.id);
        if (mounted) {
          setState(() {
            _profile = profile;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logging out: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Dynamic Data Extraction (Fallback strings if DB is empty)
    final String university = _profile?['university'] as String? ?? '';
    final String major = _profile?['major'] as String? ?? '';
    final String bio =
        _profile?['bio'] as String? ??
        'No bio added yet. Tap edit to tell us about yourself!';
    final List<dynamic> skills = _profile?['skills'] as List<dynamic>? ?? [];
    final String? cvFilename = _profile?['cv_filename'] as String?;

    // Format Education Text dynamically
    String educationText = 'Add your education details';
    if (university.isNotEmpty && major.isNotEmpty) {
      educationText = '$major at $university';
    } else if (university.isNotEmpty) {
      educationText = university;
    } else if (major.isNotEmpty) {
      educationText = major;
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        // Removed "Profile" title text
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final isDark =
                  ref.watch(themeModeProvider) == ThemeMode.dark;
              return IconButton(
                onPressed: () =>
                    ref.read(themeModeProvider.notifier).toggle(),
                icon: Icon(
                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: colorScheme.onSurface,
                ),
                tooltip: isDark ? 'Light Mode' : 'Dark Mode',
              );
            },
          ),
          // Modern Logout Button moved to Top Right
          IconButton(
            onPressed: _handleLogout,
            icon: Icon(Icons.logout_rounded, color: colorScheme.onSurface),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfileData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar with Edit Badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 54,
                      backgroundColor: colorScheme.onSurface.withOpacity(0.05),
                      backgroundImage: _profile?['avatar_url'] != null
                          ? NetworkImage(_profile!['avatar_url'])
                          : null,
                      child: _profile?['avatar_url'] == null
                          ? Icon(
                              Icons.person,
                              size: 48,
                              color: colorScheme.onSurface.withOpacity(0.4),
                            )
                          : null,
                    ),
                  ),
                  // Edit Badge (Syncs data when returning)
                  GestureDetector(
                    onTap: () async {
                      // Navigate to edit screen and wait for it to pop
                      await context.push('/profile/edit');
                      // Re-fetch data from DB to sync UI
                      _loadProfileData();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 4,
                        ),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Dynamic Name
              Text(
                _fullName,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),

              // Dynamic Education
              Text(
                educationText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),

              // Hardcoded Stats Row (As requested)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('12', 'Applied', colorScheme),
                    _buildVerticalDivider(colorScheme),
                    _buildStatItem('5', 'Saved', colorScheme),
                    _buildVerticalDivider(colorScheme),
                    _buildStatItem('3', 'Interviews', colorScheme),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Dynamic About Me
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'About Me',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  bio,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Dynamic Skills
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Skills',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: skills.isEmpty
                    ? Text(
                        'No skills added yet.',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      )
                    : Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: skills
                            .map(
                              (skill) =>
                                  _buildSkillTag(skill.toString(), colorScheme),
                            )
                            .toList(),
                      ),
              ),

              const SizedBox(height: 32),

              // Dynamic CV Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Resume / CV',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_rounded,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cvFilename ?? 'No CV Uploaded',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (cvFilename != null)
                            Text(
                              'PDF Document',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // Hardcoded Stats Builder
  Widget _buildStatItem(String number, String label, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(ColorScheme colorScheme) {
    return Container(
      height: 40,
      width: 1,
      color: colorScheme.onSurface.withOpacity(0.1),
    );
  }

  Widget _buildSkillTag(String text, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
