import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:vu_hub/core/widgets/app_fui_icon.dart';

import '../../../core/utils/app_page_route.dart';
import '../../../core/widgets/section_header.dart';
import '../../admin/presentation/admin_dashboard_screen.dart';
import '../../auth/data/app_session.dart';
import '../../auth/data/user_profile.dart';
import '../../auth/data/user_profile_repository.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final profile = session.profile;
    final user = session.firebaseUser;
    final scheme = Theme.of(context).colorScheme;
    final role = _roleLabel(session.role);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Back',
                  onPressed: () => Navigator.maybePop(context),
                  icon: const FUI(BoldRounded.arrowLeft, width: 20, height: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'My Profile',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  colors: [
                    scheme.primary,
                    scheme.secondary,
                    const Color(0xFF7C3AED),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 38,
                        backgroundColor: Colors.white.withValues(alpha: 0.18),
                        child: Text(
                          _initials(
                            profile?.displayName ?? user?.email ?? 'VU',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const Spacer(),
                      FilledButton.tonalIcon(
                        onPressed: user == null
                            ? null
                            : () => _openEditProfile(context, session),
                        icon: const FUI(
                          BoldRounded.pencil,
                          width: 17,
                          height: 17,
                        ),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    profile?.displayName ?? user?.displayName ?? 'VU User',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user?.email ?? profile?.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _GlassTag(icon: BoldRounded.badge, label: role),
                      if ((profile?.faculty ?? '').trim().isNotEmpty)
                        _GlassTag(
                          icon: BoldRounded.school,
                          label: profile!.faculty,
                        ),
                      if ((profile?.regNo ?? '').trim().isNotEmpty)
                        _GlassTag(
                          icon: BoldRounded.document,
                          label: profile!.regNo,
                        ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 320.ms).slideY(begin: 0.04),
            const SizedBox(height: 22),
            const SectionHeader(title: 'Campus Identity'),
            const SizedBox(height: 12),
            _ProfileInfoTile(
              icon: BoldRounded.user,
              label: 'Display name',
              value: profile?.displayName ?? user?.displayName ?? 'VU User',
              tone: scheme.primary,
            ),
            _ProfileInfoTile(
              icon: BoldRounded.envelope,
              label: 'Email',
              value: user?.email ?? profile?.email ?? 'Not available',
              tone: scheme.secondary,
            ),
            _ProfileInfoTile(
              icon: BoldRounded.school,
              label: 'Faculty',
              value: (profile?.faculty ?? '').trim().isEmpty
                  ? 'Add faculty'
                  : profile!.faculty,
              tone: const Color(0xFFFFB703),
            ),
            _ProfileInfoTile(
              icon: BoldRounded.document,
              label: 'Registration number',
              value: (profile?.regNo ?? '').trim().isEmpty
                  ? 'Add registration number'
                  : profile!.regNo,
              tone: const Color(0xFF8B5CF6),
            ),
            const SizedBox(height: 22),
            const SectionHeader(title: 'Access'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _AccessChip(
                  icon: BoldRounded.megaphone,
                  label: session.canPublishAnnouncements
                      ? 'Can publish feed'
                      : 'Student feed access',
                  active: session.canPublishAnnouncements,
                ),
                _AccessChip(
                  icon: BoldRounded.folder,
                  label: session.canUploadResources
                      ? 'Can upload vault'
                      : 'Vault reader',
                  active: session.canUploadResources,
                ),
                _AccessChip(
                  icon: BoldRounded.chartPie,
                  label: session.canViewAdminInsights
                      ? 'Admin insights'
                      : 'Standard insights',
                  active: session.canViewAdminInsights,
                ),
              ],
            ),
            if (session.role == AppUserRole.admin) ...[
              const SizedBox(height: 22),
              const SectionHeader(title: 'Administration'),
              const SizedBox(height: 12),
              _AdminCenterCard(
                onTap: () => Navigator.of(
                  context,
                ).push(buildAppPageRoute(const AdminDashboardScreen())),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdminCenterCard extends StatelessWidget {
  const _AdminCenterCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  color: scheme.primary.withValues(alpha: 0.13),
                ),
                child: FUI(
                  BoldRounded.shieldCheck,
                  width: 22,
                  height: 22,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Open Admin Center',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage feed posts, guild notices, live activity, and roles.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const FUI(RegularRounded.arrowSmallRight, width: 20, height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tone,
  });

  final String icon;
  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: tone.withValues(alpha: 0.13),
            child: FUI(icon, color: tone, width: 20, height: 20),
          ),
          title: Text(label),
          subtitle: Text(value),
          trailing: FUI(
            RegularRounded.check,
            color: scheme.primary,
            width: 18,
            height: 18,
          ),
        ),
      ),
    );
  }
}

class _AccessChip extends StatelessWidget {
  const _AccessChip({
    required this.icon,
    required this.label,
    required this.active,
  });

  final String icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = active ? scheme.primary : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: tone.withValues(alpha: active ? 0.14 : 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FUI(icon, width: 17, height: 17, color: tone),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: tone),
          ),
        ],
      ),
    );
  }
}

class _GlassTag extends StatelessWidget {
  const _GlassTag({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FUI(icon, width: 14, height: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openEditProfile(BuildContext context, AppSession session) async {
  final profile = session.profile;
  final user = session.firebaseUser;
  if (user == null) return;
  final nameController = TextEditingController(
    text: profile?.displayName ?? user.displayName ?? '',
  );
  final facultyController = TextEditingController(text: profile?.faculty ?? '');
  final regNoController = TextEditingController(text: profile?.regNo ?? '');
  var isSaving = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Edit profile',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Display name',
                    prefixIcon: FUI(BoldRounded.user),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: facultyController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Faculty',
                    prefixIcon: FUI(BoldRounded.school),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: regNoController,
                  decoration: const InputDecoration(
                    labelText: 'Registration number',
                    prefixIcon: FUI(BoldRounded.document),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setSheetState(() => isSaving = true);
                          try {
                            await UserProfileRepository().updateProfile(
                              uid: user.uid,
                              displayName: nameController.text,
                              faculty: facultyController.text,
                              regNo: regNoController.text,
                            );
                            if (context.mounted) Navigator.pop(context);
                          } catch (error) {
                            setSheetState(() => isSaving = false);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        },
                  icon: isSaving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const FUI(BoldRounded.check, width: 18, height: 18),
                  label: const Text('Save profile'),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  nameController.dispose();
  facultyController.dispose();
  regNoController.dispose();
}

String _roleLabel(AppUserRole role) {
  switch (role) {
    case AppUserRole.admin:
      return 'Administrator';
    case AppUserRole.lecturer:
      return 'Lecturer';
    case AppUserRole.guildOfficial:
      return 'Guild official';
    case AppUserRole.unknown:
      return 'Campus user';
    case AppUserRole.student:
      return 'Student';
  }
}

String _initials(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .toList();
  if (parts.isEmpty) return 'VU';
  return parts.map((part) => part.characters.first.toUpperCase()).join();
}
