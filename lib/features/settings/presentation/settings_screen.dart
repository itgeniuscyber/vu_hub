import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vu_hub/core/widgets/app_fui_icon.dart';

import '../../../core/utils/app_page_route.dart';
import '../../../core/widgets/feature_hero_banner.dart';
import '../../../core/widgets/section_header.dart';
import '../../admin/presentation/admin_dashboard_screen.dart';
import '../../auth/data/app_session.dart';
import '../../auth/data/user_profile.dart';
import '../../directory/presentation/dept_finder_screen.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final session = context.watch<AppSession>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
        children: [
          FeatureHeroBanner(
            title: 'App settings',
            subtitle:
                'Manage your campus profile, notifications, account security, and support routes.',
            icon: BoldRounded.settings,
            scheme: scheme,
            badge: 'VU Hub',
            height: 176,
          ),
          const SizedBox(height: 20),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: scheme.primary.withValues(alpha: 0.13),
                child: FUI(
                  BoldRounded.user,
                  width: 20,
                  height: 20,
                  color: scheme.primary,
                ),
              ),
              title: Text(session.profile?.displayName ?? 'VU User'),
              subtitle: Text(session.firebaseUser?.email ?? 'Signed in'),
              trailing: FilledButton.tonal(
                onPressed: () => Navigator.of(
                  context,
                ).push(buildAppPageRoute(const ProfileScreen())),
                child: const Text('View'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Preferences'),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: BoldRounded.bellRing,
            title: 'Notifications',
            subtitle: 'Campus alerts, chat replies, feed, and live activity',
            tone: scheme.primary,
            onTap: () => Navigator.of(
              context,
            ).push(buildAppPageRoute(const NotificationsScreen())),
          ),
          _SettingsTile(
            icon: BoldRounded.moon,
            title: 'Theme',
            subtitle: 'VU Hub follows your device light or dark mode',
            tone: const Color(0xFF8B5CF6),
          ),
          _SettingsTile(
            icon: BoldRounded.headset,
            title: 'Support routes',
            subtitle: 'Find Registry, Finance, ICT, and Student Support',
            tone: const Color(0xFF22C55E),
            onTap: () => Navigator.of(
              context,
            ).push(buildAppPageRoute(const DeptFinderScreen())),
          ),
          if (session.role == AppUserRole.admin) ...[
            const SizedBox(height: 18),
            const SectionHeader(title: 'Administration'),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: BoldRounded.shieldCheck,
              title: 'Admin Center',
              subtitle: 'Manage posts, live activity, guild notices, and roles',
              tone: scheme.primary,
              onTap: () => Navigator.of(
                context,
              ).push(buildAppPageRoute(const AdminDashboardScreen())),
            ),
          ],
          const SizedBox(height: 18),
          const SectionHeader(title: 'Security'),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: BoldRounded.lock,
            title: 'Reset password',
            subtitle: 'Send a secure reset link to your email',
            tone: const Color(0xFFFFB703),
            onTap: () => _sendResetLink(context, session.firebaseUser?.email),
          ),
          _SettingsTile(
            icon: BoldRounded.signOut,
            title: 'Sign out',
            subtitle: 'Leave this device session safely',
            tone: scheme.error,
            onTap: session.isSignedIn ? () => _signOut(context, session) : null,
          ),
        ],
      ),
    );
  }
}

void _signOut(BuildContext context, AppSession session) {
  Navigator.of(context).popUntil((route) => route.isFirst);
  unawaited(session.signOut());
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final Color tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: tone.withValues(alpha: 0.13),
                  ),
                  child: FUI(icon, width: 20, height: 20, color: tone),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  const FUI(
                    RegularRounded.arrowSmallRight,
                    width: 20,
                    height: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _sendResetLink(BuildContext context, String? email) async {
  final address = email?.trim() ?? '';
  if (address.isEmpty) return;
  await FirebaseAuth.instance.sendPasswordResetEmail(email: address);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Password reset link sent to $address')),
  );
}
