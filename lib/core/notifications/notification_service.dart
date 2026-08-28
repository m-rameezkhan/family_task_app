import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background notification payloads are displayed by the operating system.
}

class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;
  final FlutterLocalNotificationsPlugin _localNotifications;

  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _localNotifications =
           localNotifications ?? FlutterLocalNotificationsPlugin();

  static const _channel = AndroidNotificationChannel(
    'task_assignments',
    'Task assignments',
    description: 'Notifications for newly assigned family tasks.',
    importance: Importance.high,
  );

  static const _webVapidKey = String.fromEnvironment('FCM_WEB_VAPID_KEY');

  Future<void> initialize() async {
    if (!kIsWeb) {
      await _localNotifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);
    }

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    if (!kIsWeb) {
      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    }
  }

  Future<void> registerUser(String userId) async {
    try {
      if (kIsWeb && _webVapidKey.isEmpty) {
        debugPrint(
          'FCM web token unavailable: build with --dart-define=FCM_WEB_VAPID_KEY=...',
        );
        return;
      }
      final token = await _messaging.getToken(
        vapidKey: kIsWeb ? _webVapidKey : null,
      );
      if (token != null && token.isNotEmpty) {
        await _saveToken(userId, token);
      }
      _messaging.onTokenRefresh.listen((newToken) {
        _saveToken(userId, newToken);
      });
    } catch (error) {
      debugPrint('FCM token registration failed: $error');
    }
  }

  Future<void> _saveToken(String userId, String token) {
    return _firestore.collection('users').doc(userId).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null || kIsWeb) return;
    await _localNotifications.show(
      message.hashCode,
      notification.title ?? 'Family Task App',
      notification.body ?? 'You have a new task.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_assignments',
          'Task assignments',
          channelDescription: 'Notifications for newly assigned family tasks.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
