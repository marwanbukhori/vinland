import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();
    debugPrint('[NotificationService] Initializing...');

    // Android Setup
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS Setup
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,);

    // Initialisation
    const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        debugPrint('[NotificationService] Notification tapped: ${response.payload}');
      },
    );
     debugPrint('[NotificationService] Initialization Complete.');
  }
  
  Future<void> requestPermissions() async {
     debugPrint('[NotificationService] Requesting permissions...');
     await flutterLocalNotificationsPlugin
         .resolvePlatformSpecificImplementation<
             IOSFlutterLocalNotificationsPlugin>()
         ?.requestPermissions(
           alert: true,
           badge: true,
           sound: true,
         );
  }

  // Show Immediate Notification (for Check-in)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    debugPrint('[NotificationService] Showing Notification: $title - $body');
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
            'engage360_channel_id', 'Engage360 Notifications',
            channelDescription: 'Notifications for Engage360',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true);
            
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
            DarwinNotificationDetails();
            
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics, iOS: iOSPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
        id, title, body, platformChannelSpecifics);
  }

  // Schedule Notification (for Reminders)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    debugPrint('[NotificationService] Scheduling Notification for $scheduledTime');
    await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledTime, tz.local),
        const NotificationDetails(
            android: AndroidNotificationDetails(
                'engage360_reminders', 'Activity Reminders',
                channelDescription: 'Reminders for upcoming activities',
                importance: Importance.max,
                priority: Priority.high,
                showWhen: true),
            iOS: DarwinNotificationDetails()),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime);
  }
  
  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }
}
