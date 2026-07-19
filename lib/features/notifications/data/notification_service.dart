import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../auth/data/user_profile.dart';
import 'notification_repository.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const campusTopic = 'campus_all';
  static const communityChatTopic = 'community_chat';
  static const _channel = AndroidNotificationChannel(
    'campus_activity',
    'Campus activity',
    description: 'Important VU Hub posts, live streams, and campus events.',
    importance: Importance.high,
  );

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final NotificationRepository _repository = NotificationRepository();

  StreamSubscription<String>? _tokenSubscription;
  User? _user;
  UserProfile? _profile;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    await _messaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );

    final android = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(_channel);

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    _tokenSubscription = _messaging.onTokenRefresh.listen((token) async {
      final user = _user;
      if (user == null) return;
      await _tryNotificationAction(
        () => _repository.saveToken(
          uid: user.uid,
          token: token,
          profile: _profile,
        ),
      );
    });
  }

  Future<void> syncUser(User? user, UserProfile? profile) async {
    _user = user;
    _profile = profile;

    if (kIsWeb) return;
    if (user == null) {
      await _tryNotificationAction(
        () => _messaging.unsubscribeFromTopic(campusTopic),
      );
      await _tryNotificationAction(
        () => _messaging.unsubscribeFromTopic(communityChatTopic),
      );
      return;
    }

    await _tryNotificationAction(
      () => _messaging.subscribeToTopic(campusTopic),
    );
    await _tryNotificationAction(
      () => _messaging.subscribeToTopic(communityChatTopic),
    );
    await _subscribeRoleTopic(profile);

    await _tryNotificationAction(() async {
      final token = await _messaging.getToken();
      if (token != null) {
        await _repository.saveToken(
          uid: user.uid,
          token: token,
          profile: profile,
        );
      }
    });
  }

  Future<void> detachUser(User? user) async {
    if (kIsWeb || user == null) return;
    await _tryNotificationAction(() async {
      final token = await _messaging.getToken();
      if (token != null) {
        await _repository.deleteToken(uid: user.uid, token: token);
      }
    });
    await _tryNotificationAction(
      () => _messaging.unsubscribeFromTopic(campusTopic),
    );
    await _tryNotificationAction(
      () => _messaging.unsubscribeFromTopic(communityChatTopic),
    );
    _user = null;
    _profile = null;
  }

  Future<void> _subscribeRoleTopic(UserProfile? profile) async {
    final role = profile == null
        ? 'student'
        : UserProfile.roleKey(profile.role).replaceAll('_', '-');
    await _tryNotificationAction(
      () => _messaging.subscribeToTopic('role_$role'),
    );
  }

  Future<void> _tryNotificationAction(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      debugPrint('VU Hub notification setup skipped: $error');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final uid = _user?.uid;
    final senderId = message.data['senderId'];
    final targetUserId = message.data['targetUserId'];
    if (uid != null && senderId == uid) return;
    if (uid != null && targetUserId != null && targetUserId.isNotEmpty) {
      if (targetUserId != uid) return;
    }

    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'VU Hub';
    final body =
        notification?.body ??
        message.data['body'] ??
        message.data['message'] ??
        'New campus activity is available.';

    await _localNotifications.show(
      id:
          (message.messageId ?? message.hashCode.toString()).hashCode &
          0x7fffffff,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['sourceId'],
    );
  }

  void dispose() {
    _tokenSubscription?.cancel();
  }
}

const _channelId = 'campus_activity';
const _channelName = 'Campus activity';
const _channelDescription =
    'Important VU Hub posts, live streams, and campus events.';
