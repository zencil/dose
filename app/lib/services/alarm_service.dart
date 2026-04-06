import 'dart:async';
import 'package:flutter/services.dart';
import 'package:dose/models/cabinet_model.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dose/main.dart';
import 'package:dose/services/alarm_ring_service.dart';
import 'package:dose/services/intake_service.dart';
import 'package:dose/db/cabinet_db.dart';
import 'package:dose/services/snooze_service.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  static const _channel = MethodChannel('org.orbitronhd.dose/alarm');
  static const _eventChannel = EventChannel('org.orbitronhd.dose/alarm_events');

  StreamSubscription? _eventSubscription;

  /// Checks if SCHEDULE_EXACT_ALARM is granted; opens settings if not.
  /// Returns true if granted.
  static Future<bool> checkAndRequestAlarmPermission() async {
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isGranted) return true;

    final result = await Permission.scheduleExactAlarm.request();
    return result.isGranted;
  }

  Future<void> triggerTestAlarm() async {
    await _channel.invokeMethod('scheduleAlarm', {
      'id': 999,
      'triggerAtMs': DateTime.now()
          .add(const Duration(seconds: 3))
          .millisecondsSinceEpoch,
      'title': 'Test Alarm',
      'body': 'Testing the alarm system.',
      'loopAudio': true,
      'vibrate': true,
    });
  }

  Future<void> init() async {
    _eventSubscription?.cancel();
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen((
      event,
    ) async {
      final map = Map<String, dynamic>.from(event);
      if (map['type'] == 'alarmFired') {
        final id = map['id'] as int;
        final title = map['title'] as String;

        // Critical check: Make sure the alarm hasn't been dismissed in the background
        // before we push the overlay onto the screen!
        final currentlyRinging = await isRinging(id);
        if (!currentlyRinging) return;

        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AlarmRingScreen(
                alarmData: AlarmRingData(id: id, title: title),
              ),
            ),
          );
        }
      } else if (map['type'] == 'alarmAction') {
        final id = map['id'] as int;
        final action = map['action'] as String;
        _handleBackgroundAction(id, action);
      }
    });
  }

  Future<void> _handleBackgroundAction(int id, String action) async {
    try {
      final med = await DatabaseHelper.instance.readMedicine(id);
      if (med == null) return;

      if (action == 'snooze') {
        final result = await SnoozeService.incrementSnooze(id);
        if (result != -1) {
          await scheduleSnoozeAlarm(id, med.name);
        }
      } else if (action == 'done') {
        await IntakeService.handleDone(med);
      }

      await minimizeIfLocked();
    } catch (e) {
      debugPrint('Background action error: \$e');
    } finally {
      // Always ensure the ring screen is popped if it was drawn
      final currentState = navigatorKey.currentState;
      if (currentState != null && currentState.canPop()) {
        currentState.popUntil((route) => route.isFirst);
      }
    }
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

    await _channel.invokeMethod('scheduleAlarm', {
      'id': id,
      'triggerAtMs': scheduledDate.millisecondsSinceEpoch,
      'title': 'Time to take ${medicine.name}',
      'body': 'Please take your scheduled dose.',
      'loopAudio': true,
      'vibrate': true,
    });
  }

  Future<void> scheduleSnoozeAlarm(int id, String title) async {
    final snoozeTime = DateTime.now().add(const Duration(minutes: 5));

    await _channel.invokeMethod('scheduleAlarm', {
      'id': id,
      'triggerAtMs': snoozeTime.millisecondsSinceEpoch,
      'title': title,
      'body': 'Snoozed alarm. Please take your scheduled dose.',
      'loopAudio': true,
      'vibrate': true,
    });
  }

  Future<void> cancelAlarm(int id) async {
    await _channel.invokeMethod('cancelAlarm', {'id': id});
  }

  Future<bool> isRinging(int id) async {
    final result = await _channel.invokeMethod<bool>('isRinging', {'id': id});
    return result ?? false;
  }

  Future<void> stopRinging(int id) async {
    await _channel.invokeMethod('stopRinging', {'id': id});
  }

  Future<void> minimizeIfLocked() async {
    await _channel.invokeMethod('minimizeIfLocked');
  }
}
