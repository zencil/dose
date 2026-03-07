import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:app/db/cabinetdb.dart';
import 'package:app/models/cabinet_model.dart';

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    final TimezoneInfo timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);
    
    await plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null && response.payload!.startsWith('med_')) {
          final int id = int.parse(response.payload!.split('_')[1]);
          
          if (response.actionId == 'action_done') {
            final med = await DatabaseHelper.instance.readMedicine(id);
            if (med != null && med.currstock > 0) {
              final updatedMed = Cabinet(
                id: med.id,
                name: med.name,
                dosage: med.dosage,
                time: med.time,
                initstock: med.initstock,
                currstock: med.currstock - 1,
                priority: med.priority,
              );
              await DatabaseHelper.instance.updateMedicine(updatedMed);
            }
          }
        }
      },
    );

    final androidImplementation = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();
  }

  Future<void> scheduleMedicineNotification(int id, String name, String timeString) async {
    final parts = timeString.split(':');
    final int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'priority_channel',
      'Priority Reminders',
      importance: Importance.max,
      priority: Priority.high,
      actions: [
        AndroidNotificationAction('action_done', 'Done'),
        AndroidNotificationAction('action_not_taken', 'Not taken'),
      ],
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await plugin.zonedSchedule(
      id: id,
      title: 'Time to take $name',
      body: 'Did you take your dose?',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, 
      payload: 'med_$id',
    );
  }

  Future<void> cancelNotification(int id) async {
  await plugin.cancel(id: id); 
  }
}