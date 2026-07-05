import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/auth/data/app_session.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class VuHubApp extends StatefulWidget {
  const VuHubApp({super.key});

  @override
  State<VuHubApp> createState() => _VuHubAppState();
}

class _VuHubAppState extends State<VuHubApp> {
  late final AppSession _session;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _session = AppSession();
    _router = createRouter(_session);
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppSession>.value(
      value: _session,
      child: MaterialApp.router(
        title: 'VU Hub',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: _router,
      ),
    );
  }
}
