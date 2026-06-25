import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/shell/presentation/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/app', builder: (context, state) => const AppShell()),
  ],
);
