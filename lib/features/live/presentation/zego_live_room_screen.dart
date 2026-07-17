import 'package:flutter/material.dart';
import 'package:vu_hub/core/widgets/app_fui_icon.dart';
import 'package:provider/provider.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

import '../../auth/data/app_session.dart';
import '../data/live_posts_repository.dart';
import '../data/zego_live_config.dart';

class ZegoLiveRoomScreen extends StatelessWidget {
  const ZegoLiveRoomScreen({
    super.key,
    required this.postId,
    required this.roomId,
    required this.title,
    required this.isHost,
  });

  final String postId;
  final String roomId;
  final String title;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<AppSession>();
    final user = session.firebaseUser;
    if (user == null) {
      return const _LiveSetupMessage(
        icon: BoldRounded.lock,
        title: 'Sign in required',
        message: 'Please sign in before joining a camera live room.',
      );
    }

    if (!ZegoLiveConfig.isConfigured) {
      return const _LiveSetupMessage(
        icon: BoldRounded.key,
        title: 'Live SDK keys needed',
        message:
            'Add ZEGO_APP_ID and ZEGO_APP_SIGN using dart-define, then restart the app to enable camera broadcasting.',
      );
    }

    final userId = _zegoSafeId(user.uid, fallback: 'vu_user');
    final userName = _zegoSafeId(
      session.profile?.displayName ?? user.displayName ?? 'VU User',
      fallback: 'VU User',
    );
    final config = isHost
        ? ZegoUIKitPrebuiltLiveStreamingConfig.host()
        : ZegoUIKitPrebuiltLiveStreamingConfig.audience();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ZegoUIKitPrebuiltLiveStreaming(
          appID: ZegoLiveConfig.appId,
          appSign: ZegoLiveConfig.appSign,
          userID: userId,
          userName: userName,
          liveID: _zegoSafeId(roomId, fallback: postId),
          config: config,
          events: ZegoUIKitPrebuiltLiveStreamingEvents(
            onEnded: (event, defaultAction) {
              if (isHost) {
                LivePostsRepository().endLiveRoom(postId).catchError((_) {});
              }
              defaultAction.call();
            },
          ),
        ),
      ),
    );
  }
}

class _LiveSetupMessage extends StatelessWidget {
  const _LiveSetupMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final String icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Camera live')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FUI(icon, width: 54, height: 54, color: scheme.primary),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => Navigator.maybePop(context),
                icon: const FUI(BoldRounded.arrowLeft),
                label: const Text('Back to Live'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _zegoSafeId(String value, {required String fallback}) {
  final safe = value
      .trim()
      .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  return safe.isEmpty ? fallback : safe;
}
