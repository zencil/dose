import 'package:alarm/alarm.dart';
import 'package:app/models/cabinet.dart';

class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  Future<void> init() async {
    await Alarm.init();
  }

  Future<void> scheduleMedicineAlarm(Cabinet medicine) async {
    if (medicine.priority == 0) return;

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
      id: medicine.id!,
      dateTime: scheduledDate,
      assetAudioPath: 'assets/alarm.mp3',
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
      volumeSettings: VolumeSettings.fade(
        volume: medicine.priority == 2 ? 1.0 : 0.8,
        fadeDuration: const Duration(seconds: 3),
        volumeEnforced: true,
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