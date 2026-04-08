import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Added for modern, sleek icons
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/jobs/screens/job_listing_screen.dart';
import '../../features/saved_jobs/screens/saved_jobs_screen.dart';
import '../../features/applications/screens/applications_screen.dart';
import '../../features/profile/screens/jobseeker_profile_screen.dart';
import '../../features/profile/screens/employer_profile_screen.dart';
import '../../features/profile/providers/profile_state_provider.dart';

class MainLayoutScreen extends ConsumerStatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  ConsumerState<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends ConsumerState<MainLayoutScreen> {
  int _currentIndex = 0;

  Widget _buildProfileScreen(ProfileState profileState) {
    if (profileState.role == 'employer') {
      return const EmployerProfileScreen();
    }
    return const JobseekerProfileScreen();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final profileState = ref.watch(profileStateProvider);

    return Scaffold(
      // IndexedStack keeps the state of the screens alive when switching tabs
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const JobListingScreen(),
          const SavedJobsScreen(),
          const ApplicationsScreen(),
          _buildProfileScreen(profileState),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outline.withOpacity(
                0.15,
              ), // Subtle sleek border
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: colorScheme.surface,
          type:
              BottomNavigationBarType.fixed, // Prevents the icons from shifting
          elevation: 0, // Handled by the border above
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.onSurface.withOpacity(0.4),
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(CupertinoIcons.house),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(CupertinoIcons.house_fill),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(CupertinoIcons.bookmark),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(CupertinoIcons.bookmark_solid),
              ),
              label: 'Saved',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(CupertinoIcons.briefcase),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(CupertinoIcons.briefcase_fill),
              ),
              label: 'Applied',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(CupertinoIcons.person),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(CupertinoIcons.person_solid),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
