import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/role_selection_screen.dart';
import '../features/profile/screens/jobseeker_profile_screen.dart';
import '../features/profile/screens/employer_profile_screen.dart';
import '../features/profile/screens/cv_upload_screen.dart';
import '../features/profile/screens/employer_public_profile_screen.dart';
import '../features/auth/services/auth_service.dart';
import '../features/profile/providers/profile_state_provider.dart';
import '../features/jobs/screens/job_listing_screen.dart';
import '../features/jobs/screens/job_detail_screen.dart';
import '../features/ai/screens/ai_match_screen.dart';
import '../features/jobs/screens/job_post_screen.dart';
import '../features/jobs/screens/manage_jobs_screen.dart';
import '../features/jobs/models/job_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profileState = ref.watch(profileStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) {
      final session = authState.value?.session;
      final isAuthenticated = session != null;

      final isLoginRoute = state.matchedLocation == '/login';
      final isRegisterRoute = state.matchedLocation == '/register';
      final isRoleSelectionRoute = state.matchedLocation == '/role-selection';
      final isAuthRoute = isLoginRoute || isRegisterRoute;

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      if (isAuthenticated) {
        if (profileState.isLoading) {
          // If profile state is loading, we wait internally before doing advanced redirects
          return null;
        }

        final role = profileState.role;
        final isCompleted = profileState.isCompleted;

        if (role == null && !isRoleSelectionRoute) {
          return '/role-selection';
        }

        if (role != null && !isCompleted) {
          final targetSetupRoute = role == 'jobseeker'
              ? '/profile-setup/jobseeker'
              : '/profile-setup/employer';
          if (state.matchedLocation != targetSetupRoute &&
              state.matchedLocation != '/profile/cv-upload') {
            return targetSetupRoute;
          }
        }

        if (isCompleted &&
            (isAuthRoute ||
                isRoleSelectionRoute ||
                state.matchedLocation.startsWith('/profile-setup'))) {
          // Prevent backstack access to login or profile setup if already completed
          return role == 'employer' ? '/jobs/manage' : '/jobs';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/jobs',
        builder: (context, state) => const JobListingScreen(),
      ),
      GoRoute(
        path: '/jobs/post',
        builder: (context, state) {
          final job = state.extra as Job?;
          return JobPostScreen(job: job);
        },
      ),
      GoRoute(
        path: '/jobs/manage',
        builder: (context, state) => const ManageJobsScreen(),
      ),
      GoRoute(
        path: '/jobs/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return JobDetailScreen(jobId: id);
        },
      ),
      GoRoute(
        path: '/jobs/:id/match',
        builder: (context, state) {
          final matchResult = state.extra as Map<String, dynamic>;
          return AiMatchScreen(matchResult: matchResult);
        },
      ),
      GoRoute(
        path: '/profile-setup/jobseeker',
        builder: (context, state) => const JobseekerProfileScreen(),
      ),
      GoRoute(
        path: '/profile-setup/employer',
        builder: (context, state) => const EmployerProfileScreen(),
      ),
      GoRoute(
        path: '/profile/cv-upload',
        builder: (context, state) => const CvUploadScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) {
          final profileState = ref.read(profileStateProvider);
          if (profileState.role == 'employer') {
            return const EmployerProfileScreen();
          }
          return const JobseekerProfileScreen();
        },
      ),
      GoRoute(
        path: '/employer/:id',
        builder: (context, state) {
          final employerId = state.pathParameters['id']!;
          return EmployerPublicProfileScreen(employerId: employerId);
        },
      ),
    ],
  );
});
