import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import 'package:dose/models/cabinet_model.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dose/main.dart';
import 'package:dose/services/alarm_ring_service.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  StreamSubscription<AlarmSet>? _ringingSubscription;

  /// Checks if SCHEDULE_EXACT_ALARM is granted; opens settings if not.
  /// Returns true if granted.
  static Future<bool> checkAndRequestAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isGranted) return true;

    final result = await Permission.scheduleExactAlarm.request();
    return result.isGranted;
  }

  Future<void> triggerTestAlarm() async {
    final alarmSettings = AlarmSettings(
      id: 999,
      dateTime: DateTime.now().add(const Duration(seconds: 3)),
      assetAudioPath: null,
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fade(
        volume: 1.0,
        fadeDuration: Duration(seconds: 3),
      ),
      notificationSettings: NotificationSettings(
        title: 'Test Alarm',
        body: 'Testing the alarm system.',
        stopButton: 'Stop',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
  }

  Future<void> init() async {
    await Alarm.init();

    _ringingSubscription?.cancel();
    _ringingSubscription = Alarm.ringing
        .where((alarmSet) => alarmSet.alarms.isNotEmpty)
        .listen((alarmSet) {
      final alarmSettings = alarmSet.alarms.first;
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AlarmRingScreen(alarmSettings: alarmSettings),
          ),
        );
      }
    });
  }

  Future<void> scheduleMedicineAlarm(int id, Cabinet medicine) async {
    if (medicine.priority != 2) return;

    final parts = medicine.time.split(':');
    final int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);

    DateTime now = DateTime.now();
    DateTime scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: scheduledDate,
      assetAudioPath: null,
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fade(
        volume: 1.0,
        fadeDuration: Duration(seconds: 3),
      ),
      notificationSettings: NotificationSettings(
        title: 'Time to take ${medicine.name}',
        body: 'Please take your scheduled dose.',
        stopButton: 'Stop',
      ),
    );

    await Alarm.set(alarmSettings: alarmSettings);
  }

  Future<void> cancelAlarm(int id) async {
    await Alarm.stop(id);
  }
}
