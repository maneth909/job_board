import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/role_selection_screen.dart';
import 'supabase_client.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: supabase.auth.currentSession != null ? '/jobs' : '/login',
    redirect: (BuildContext context, GoRouterState state) {
      final session = supabase.auth.currentSession;
      final isAuthenticated = session != null;
      
      final isLoginRoute = state.matchedLocation == '/login';
      final isRegisterRoute = state.matchedLocation == '/register';
      final isAuthRoute = isLoginRoute || isRegisterRoute;

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/jobs';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
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
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Jobs Placeholder')),
        ),
      ),
      GoRoute(
        path: '/profile-setup/jobseeker',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Jobseeker Profile Setup')),
        ),
      ),
      GoRoute(
        path: '/profile-setup/employer',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Employer Profile Setup')),
        ),
      ),
    ],
  );
});
