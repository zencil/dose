import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:dose/db/cabinet_db.dart';
import 'package:dose/models/cabinet_model.dart';
import 'package:dose/models/intake_model.dart';
import 'package:dose/db/intake_log_db.dart' as log_db;
import 'package:dose/services/widget_service.dart';
import 'package:dose/services/snooze_service.dart';
import 'package:dose/main.dart';
import 'package:dose/pages/cabinet_page.dart';

/// Handles the "Done" action from a notification by updating stock and logging intake.
Future<void> _handleDoneAction(int id) async {
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

    final now = DateTime.now();
    String timeString =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    String dateString =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final intake = Intake(
      id: med.id,
      name: med.name,
      ttime: med.time,
      time: timeString,
      date: dateString,
      currstock: med.currstock - 1,
    );
    await log_db.DatabaseHelper.instance.createlog(intake);
    await WidgetService.updateWidgetState();

    if (updatedMed.currstock < 3) {
      await NotificationHelper().showLowStockNotification(updatedMed);
    }
  }
  await SnoozeService.resetSnooze(id);
}

/// Handles "Snooze" by rescheduling the notification 5 minutes later.
Future<void> _handleSnoozeAction(int id) async {
  final result = await SnoozeService.incrementSnooze(id);
  if (result == -1) return; // limit reached

  final med = await DatabaseHelper.instance.readMedicine(id);
  if (med != null) {
    await NotificationHelper().scheduleSnoozeNotification(
      id,
      med.name,
      canSnoozeAgain: result < SnoozeService.maxSnoozes,
    );
  }
}

@pragma('vm:entry-point')
Future<void> onBackgroundNotificationResponse(
  NotificationResponse response,
) async {
  WidgetsFlutterBinding.ensureInitialized();

  if (response.payload != null && response.payload!.startsWith('med_')) {
    final int id = int.parse(response.payload!.split('_')[1]);
    if (response.actionId == 'action_done') {
      await _handleDoneAction(id);
    } else if (response.actionId == 'action_snooze') {
      await _handleSnoozeAction(id);
    }
  }
}

class NotificationHelper {
  static final NotificationHelper _instance = NotificationHelper._internal();
  factory NotificationHelper() => _instance;
  NotificationHelper._internal();

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    final TimezoneInfo timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null && response.payload!.startsWith('med_')) {
          final int id = int.parse(response.payload!.split('_')[1]);
          if (response.actionId == 'action_done') {
            await _handleDoneAction(id);
          } else if (response.actionId == 'action_snooze') {
            await _handleSnoozeAction(id);
          }
        } else if (response.payload != null &&
            response.payload!.startsWith('restock_')) {
          if (response.actionId == 'action_restock' ||
              response.actionId == null) {
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (_) => const CabinetPage()),
            );
          }
        }
      },
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationResponse,
    );
  }

  Future<void> scheduleMedicineNotification(
    int id,
    String name,
    String timeString,
  ) async {
    final parts = timeString.split(':');
    final int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      'priority_channel',
      'Priority Reminders',
      importance: Importance.max,
      priority: Priority.high,
      actions: await _buildNotificationActions(id),
    );

    final details = NotificationDetails(android: androidDetails);

    await plugin.zonedSchedule(
      id: id,
      title: 'Time to take $name',
      body: 'Did you take your dose?',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'med_$id',
    );
  }

  /// Schedules a snoozed notification 5 minutes from now.
  Future<void> scheduleSnoozeNotification(
    int id,
    String name, {
    required bool canSnoozeAgain,
  }) async {
    final snoozeTime = tz.TZDateTime.now(
      tz.local,
    ).add(const Duration(minutes: SnoozeService.snoozeDurationMinutes));

    final actions = <AndroidNotificationAction>[
      const AndroidNotificationAction(
        'action_done',
        'Done',
        showsUserInterface: true,
      ),
    ];
    if (canSnoozeAgain) {
      actions.add(
        const AndroidNotificationAction(
          'action_snooze',
          'Snooze',
          showsUserInterface: true,
        ),
      );
    }

    final androidDetails = AndroidNotificationDetails(
      'priority_channel',
      'Priority Reminders',
      importance: Importance.max,
      priority: Priority.high,
      actions: actions,
    );

    final details = NotificationDetails(android: androidDetails);

    await plugin.zonedSchedule(
      id: id,
      title: 'Reminder: Take $name',
      body: 'You snoozed this reminder. Did you take your dose?',
      scheduledDate: snoozeTime,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      payload: 'med_$id',
    );
  }

  /// Builds notification actions, conditionally including Snooze based on count.
  Future<List<AndroidNotificationAction>> _buildNotificationActions(
    int id,
  ) async {
    final canSnooze = await SnoozeService.canSnooze(id);
    final actions = <AndroidNotificationAction>[
      const AndroidNotificationAction(
        'action_done',
        'Done',
        showsUserInterface: true,
      ),
    ];
    if (canSnooze) {
      actions.add(
        const AndroidNotificationAction(
          'action_snooze',
          'Snooze',
          showsUserInterface: true,
        ),
      );
    }
    return actions;
  }

  Future<void> cancelNotification(int id) async {
    await plugin.cancel(id: id);
  }

  /// Displays a low stock notification prompting the user to restock.
  Future<void> showLowStockNotification(Cabinet med) async {
    if (med.id == null) return;

    final actions = <AndroidNotificationAction>[
      const AndroidNotificationAction(
        'action_restock',
        'Restock',
        showsUserInterface: true,
      ),
    ];

    final androidDetails = AndroidNotificationDetails(
      'stock_channel',
      'Low Stock Alerts',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      actions: actions,
    );

    final details = NotificationDetails(android: androidDetails);

    await plugin.show(
      id:
          med.id! +
          100000, // Offset ID to avoid colliding with medication alarm IDs
      title: 'Low Stock Alert',
      body: 'You have less than 3 doses of ${med.name} left. Please restock.',
      notificationDetails: details,
      payload: 'restock_${med.id}',
    );
  }
}
