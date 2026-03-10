import 'package:flutter/material.dart';
import 'dart:async';
import 'package:alarm/alarm.dart';
import 'package:dose/db/cabinet_db.dart';
import 'package:dose/models/cabinet_model.dart';
import 'package:dose/models/intake_model.dart';
import 'package:dose/db/intake_log_db.dart' as log_db;
import 'package:dose/services/widget_service.dart';
import 'package:dose/services/snooze_service.dart';
import 'package:dose/services/notification_service.dart';

class AlarmRingScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;

  const AlarmRingScreen({super.key, required this.alarmSettings});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  bool _canSnooze = true;
  int _snoozeCount = 0;
  Timer? _snoozeTimer;

  @override
  void initState() {
    super.initState();
    _loadSnoozeState();
    _startAutoSnoozeTimer();
  }

  void _startAutoSnoozeTimer() {
    _snoozeTimer = Timer(const Duration(seconds: 50), () {
      if (_canSnooze) {
        _handleSnooze();
      } else {
        _handleQuietDone();
      }
    });
  }

  @override
  void dispose() {
    _snoozeTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSnoozeState() async {
    final count = await SnoozeService.getSnoozeCount(widget.alarmSettings.id);
    if (mounted) {
      setState(() {
        _snoozeCount = count;
        _canSnooze = count < SnoozeService.maxSnoozes;
      });
    }
  }

  Future<void> _handleQuietDone() async {
    _snoozeTimer?.cancel();
    await Alarm.stop(widget.alarmSettings.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _handleDone() async {
    _snoozeTimer?.cancel();
    Navigator.pop(context);
    await Alarm.stop(widget.alarmSettings.id);
    final med = await DatabaseHelper.instance.readMedicine(
      widget.alarmSettings.id,
    );
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
    await SnoozeService.resetSnooze(widget.alarmSettings.id);
  }

  Future<void> _handleSnooze() async {
    _snoozeTimer?.cancel();
    final result = await SnoozeService.incrementSnooze(widget.alarmSettings.id);
    if (result == -1) return;
    await Alarm.stop(widget.alarmSettings.id);
    final snoozeTime = DateTime.now().add(
      const Duration(minutes: SnoozeService.snoozeDurationMinutes),
    );
    final snoozedAlarm = AlarmSettings(
      id: widget.alarmSettings.id,
      dateTime: snoozeTime,
      assetAudioPath: widget.alarmSettings.assetAudioPath,
      loopAudio: widget.alarmSettings.loopAudio,
      vibrate: widget.alarmSettings.vibrate,
      warningNotificationOnKill: widget.alarmSettings.warningNotificationOnKill,
      androidFullScreenIntent: widget.alarmSettings.androidFullScreenIntent,
      volumeSettings: widget.alarmSettings.volumeSettings,
      notificationSettings: widget.alarmSettings.notificationSettings,
    );
    await Alarm.set(alarmSettings: snoozedAlarm);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.alarm, size: 100),
            const SizedBox(height: 20),
            Text(
              widget.alarmSettings.notificationSettings.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (_snoozeCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Snoozed $_snoozeCount/${SnoozeService.maxSnoozes} times',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_canSnooze)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer,
                    ),
                    onPressed: _handleSnooze,
                    icon: const Icon(Icons.snooze),
                    label: const Text('Snooze'),
                  ),
                if (_canSnooze) const SizedBox(width: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                  ),
                  onPressed: _handleDone,
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
