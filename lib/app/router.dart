import 'package:go_router/go_router.dart';

import '../features/auth/data/app_session.dart';
import '../features/auth/presentation/auth_loading_screen.dart';
import '../features/auth/presentation/login_screen.dart';
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
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/app', builder: (context, state) => const AppShell()),
    ],
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isLoading = session.isInitializing || session.isProfileLoading;
      final isLoggedIn = session.isSignedIn;

      if (isLoading) {
        return location == '/' ? null : '/';
      }
      if (!isLoggedIn) {
        return location == '/login' ? null : '/login';
      }
      if (location == '/' || location == '/login') {
        return '/app';
      }
      return null;
    },
  );
}
