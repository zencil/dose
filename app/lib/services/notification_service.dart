import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings, 
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.actionId == 'mark_done') {
          print("Mark Done clicked for payload: ${response.payload}");
        }
      },
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String medicineName,
    required String timeString,
  }) async {
    final parts = timeString.split(':');
    final int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'medicine_channel_id',
      'Medicine Reminders',
      channelDescription: 'Notifications for medicine intake',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      ticker: 'Time to take your medicine',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'mark_done',
          'Done',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final tz.TZDateTime nextInstance = _nextInstanceOfTime(hour, minute);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id: id,
      title: 'Time for taking $medicineName',
      body: 'It is $timeString. Have you taken your dose?',
      scheduledDate: nextInstance,
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    print("Scheduled notification for $medicineName at $nextInstance (ID: $id)");
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}