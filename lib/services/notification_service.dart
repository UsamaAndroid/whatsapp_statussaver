import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Must be a top-level function. Registered before [runApp].
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await NotificationService.instance.setupLocalNotificationsOnly();
  await NotificationService.instance.showRemoteMessage(message);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  // Keep old factory for existing call sites.
  factory NotificationService() => instance;

  // Lazy: must not touch Firebase until [initFirebase] has run.
  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'status_saver_channel',
    'Status Saver Notifications',
    description: 'Notifications for Status Saver updates and reminders',
    importance: Importance.high,
    playSound: true,
  );

  bool _firebaseReady = false;
  bool _localReady = false;
  bool _handlersReady = false;

  /// Call this BEFORE [runApp].
  Future<void> initFirebase() async {
    if (_firebaseReady) return;
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _firebaseReady = true;
  }

  /// Call after UI is up (permissions + listeners + token).
  Future<void> init() async {
    if (!_firebaseReady) {
      await initFirebase();
    }

    await setupLocalNotificationsOnly();
    await _requestPermission();

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (!_handlersReady) {
      FirebaseMessaging.onMessage.listen((message) {
        if (kDebugMode) {
          debugPrint(
            'FCM foreground: title=${message.notification?.title} '
            'data=${message.data}',
          );
        }
        showRemoteMessage(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

      final initial = await _messaging.getInitialMessage();
      if (initial != null) {
        _onMessageOpened(initial);
      }

      _handlersReady = true;
    }

    try {
      final token = await _messaging.getToken();
      if (kDebugMode) {
        debugPrint('========== FCM TOKEN ==========');
        debugPrint(token);
        debugPrint('================================');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM getToken failed: $e');
      }
    }

    _messaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        debugPrint('FCM Token refreshed: $newToken');
      }
    });
  }

  Future<void> setupLocalNotificationsOnly() async {
    if (_localReady) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {},
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);

    _localReady = true;
  }

  Future<void> _requestPermission() async {
    // Android 13+ system dialog is requested from HomeScreen via
    // PermissionService.requestNotificationPermission() so it shows on-screen.
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      debugPrint('FCM permission: ${settings.authorizationStatus}');
    }
  }

  Future<void> showRemoteMessage(RemoteMessage message) async {
    await setupLocalNotificationsOnly();

    final notification = message.notification;
    final title = notification?.title ??
        message.data['title']?.toString() ??
        'Status Saver';
    final body = notification?.body ??
        message.data['body']?.toString() ??
        message.data['message']?.toString();

    // Nothing useful to show.
    if (body == null && notification == null && message.data.isEmpty) {
      return;
    }

    await _localNotifications.show(
      message.hashCode,
      title,
      body ?? '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  void _onMessageOpened(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Notification opened: ${message.data}');
    }
  }

  Future<String?> getToken() => _messaging.getToken();
}
