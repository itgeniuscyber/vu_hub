import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vu_hub/core/widgets/app_fui_icon.dart';

import '../../auth/data/app_session.dart';
import '../data/app_update.dart';
import '../data/app_update_repository.dart';

class AppUpdateGate extends StatefulWidget {
  const AppUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate> {
  final _repository = AppUpdateRepository();

  StreamSubscription<AppUpdate?>? _subscription;
  String? _userId;
  bool _dialogVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final session = context.watch<AppSession>();
    final uid = session.firebaseUser?.uid;
    if (uid == _userId) return;
    _userId = uid;
    unawaited(_subscription?.cancel());
    _subscription = null;
    if (uid == null) return;
    _subscription = _repository.watchLatestActiveUpdate().listen(
      _handleUpdate,
      onError: (_) {},
    );
  }

  Future<void> _handleUpdate(AppUpdate? update) async {
    if (!mounted || update == null || _dialogVisible) return;

    final info = await PackageInfo.fromPlatform();
    final installedCode = int.tryParse(info.buildNumber) ?? 0;
    if (!update.isNewerThan(installedCode)) return;

    final prefs = await SharedPreferences.getInstance();
    final seenKey = 'seen_app_update_${update.id}_${update.versionCode}';
    if (!update.isRequired && (prefs.getBool(seenKey) ?? false)) return;
    if (!mounted) return;

    _dialogVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final action = await showDialog<_UpdateAction>(
        context: context,
        barrierDismissible: !update.isRequired,
        builder: (context) => _AppUpdateDialog(update: update),
      );
      if (!mounted) return;
      _dialogVisible = false;

      if (!update.isRequired) {
        await prefs.setBool(seenKey, true);
      }
      if (action == _UpdateAction.open) {
        await _openUpdateLink(update.updateUrl);
      }
    });
  }

  Future<void> _openUpdateLink(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null || !uri.hasScheme) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

enum _UpdateAction { open, later }

class _AppUpdateDialog extends StatelessWidget {
  const _AppUpdateDialog({required this.update});

  final AppUpdate update;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final changes = update.changes.isEmpty
        ? const ['Performance improvements and campus experience refinements.']
        : update.changes;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0EA5E9), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const FUI(
                      BoldRounded.rocket,
                      width: 28,
                      height: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          update.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version ${update.versionName}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                update.summary,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.7),
                  ),
                ),
                child: Column(
                  children: changes.take(5).map((change) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FUI(
                            BoldRounded.check,
                            color: scheme.primary,
                            width: 17,
                            height: 17,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              change,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (update.isRequired) ...[
                const SizedBox(height: 12),
                _RequiredUpdateNote(color: scheme.error),
              ],
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: update.updateUrl.trim().isEmpty
                    ? null
                    : () => Navigator.pop(context, _UpdateAction.open),
                icon: const FUI(BoldRounded.arrowUp, width: 18, height: 18),
                label: const Text('Get the new version'),
              ),
              if (!update.isRequired) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context, _UpdateAction.later),
                  child: const Text('Later'),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 180.ms).scale(
      begin: const Offset(0.96, 0.96),
      end: const Offset(1, 1),
      duration: 220.ms,
      curve: Curves.easeOutCubic,
    );
  }
}

class _RequiredUpdateNote extends StatelessWidget {
  const _RequiredUpdateNote({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FUI(BoldRounded.exclamation, color: color, width: 18, height: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'This update is required before continuing safely.',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
