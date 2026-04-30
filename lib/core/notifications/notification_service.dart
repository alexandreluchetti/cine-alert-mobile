import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Notification messages are shown automatically by the OS in background.
  // Data-only messages must be shown manually.
  if (message.notification != null) return;

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  final title = message.data['title'] as String? ?? 'CineAlert';
  final body = message.data['body'] as String? ?? '';

  await plugin.show(
    id: message.hashCode,
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'cine_alert_channel',
        'Lembretes',
        channelDescription: 'Notificações de lembretes do CineAlert',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_notification',
      ),
      iOS: DarwinNotificationDetails(),
    ),
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void Function(String token)? onTokenRefresh;

  NotificationService._();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (_) {
      // Falha silenciosa: usa UTC.
    }

    // 'ic_launcher' requires the @mipmap prefix to be found inside Flutter's Android mipmap tree.
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {},
    );

    // FCM Setup
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Foreground listener — FCM does NOT auto-display in foreground, must be shown manually.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('=== FCM foreground: notification=${message.notification?.title}, data=${message.data} ===');
      final title = message.notification?.title ?? message.data['title'] as String? ?? 'CineAlert';
      final body = message.notification?.body ?? message.data['body'] as String? ?? '';
      _showNotification(message.hashCode, title, body);
    });

    // Keep FCM token in sync — Firebase can rotate it at any time.
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      print('=== FCM token refreshed ===');
      onTokenRefresh?.call(newToken);
    });
  }

  Future<void> _showNotification(int id, String title, String body) async {
    try {
      await flutterLocalNotificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'cine_alert_channel',
            'Lembretes',
            channelDescription: 'Notificações de lembretes do CineAlert',
            importance: Importance.max,
            priority: Priority.high,
            icon: 'ic_notification',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
      print('=== Local notification shown: $title ===');
    } catch (e) {
      print('=== Failed to show local notification: $e ===');
    }
  }

  Future<String?> getFcmToken() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      print('=== Error getting FCM token: $e ===');
      return null;
    }
  }

  Future<void> requestPermissions() async {
    // Request FCM permission
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    if (scheduledAt.isBefore(DateTime.now())) return;

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledAt, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'cine_alert_channel',
            'Lembretes',
            channelDescription: 'Notificações de lembretes do CineAlert',
            importance: Importance.max,
            priority: Priority.high,
            icon: 'ic_notification',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print('=== Notification scheduled successfully for: $scheduledAt ===');
    } catch (e) {
      print('=== Failed to schedule notification: $e ===');
    }
  }

  Future<void> cancelReminder(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }
}
