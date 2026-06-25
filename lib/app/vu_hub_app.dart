import 'package:flutter/material.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class VuHubApp extends StatelessWidget {
  const VuHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VU Hub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
