import 'package:go_router/go_router.dart';

import '../features/auth/data/app_session.dart';
import '../features/auth/presentation/auth_loading_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/onboarding_screen.dart';
import '../features/auth/presentation/registration_screen.dart';
import '../features/shell/presentation/app_shell.dart';

GoRouter createRouter(AppSession session) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: session,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AuthLoadingScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegistrationScreen(),
      ),
      GoRoute(path: '/app', builder: (context, state) => const AppShell()),
    ],
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isLoading = session.isInitializing || session.isProfileLoading;
      final isLoggedIn = session.isSignedIn;

      if (isLoading) {
        return location == '/' ? null : '/';
      }
      final isPublicAuthRoute =
          location == '/onboarding' ||
          location == '/login' ||
          location == '/register';

      if (!isLoggedIn) {
        return isPublicAuthRoute ? null : '/onboarding';
      }
      if (location == '/' || isPublicAuthRoute) {
        return '/app';
      }
      return null;
    },
  );
}
