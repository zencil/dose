import 'package:dose/models/cabinet_model.dart';
import 'package:dose/models/intake_model.dart' as log_model;
import 'package:dose/db/cabinet_db.dart';
import 'package:dose/db/intake_log_db.dart' as log_db;
import 'package:dose/services/notification_service.dart';
import 'package:dose/services/alarm_service.dart';
import 'package:dose/services/widget_service.dart';
import 'package:dose/services/snooze_service.dart';

class IntakeService {
  static bool isUpcoming(Cabinet med, List<log_model.Intake> todayLogs) {
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    bool isTaken = todayLogs.any(
      (log) =>
          log.name == med.name && log.ttime == med.time && log.date == todayStr,
    );
    if (isTaken) return false;

    final timeParts = med.time.split(':');
    final int hour = int.parse(timeParts[0]);
    final int minute = int.parse(timeParts[1]);

    var targetTime = DateTime(now.year, now.month, now.day, hour, minute);

    int diff = targetTime.difference(now).inMinutes;

    if (diff < -12 * 60) diff += 24 * 60;
    if (diff > 12 * 60) diff -= 24 * 60;

    return diff >= -30 && diff <= 30;
  }

  static Future<void> handleDone(Cabinet med) async {
    if (med.currstock > 0) {
      final updatedMed = Cabinet(
        id: med.id,
        name: med.name,
        dosage: med.dosage,
        time: med.time,
        initstock: med.initstock,
        currstock: med.currstock - 1,
        priority: med.priority,
        category: med.category,
        unit: med.unit,
      );
      await DatabaseHelper.instance.updateMedicine(updatedMed);

      final now = DateTime.now();
      String timeStr =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      String dateStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final intake = log_model.Intake(
        id: med.id,
        name: med.name,
        ttime: med.time,
        time: timeStr,
        date: dateStr,
        currstock: med.currstock - 1,
      );
      await log_db.DatabaseHelper.instance.createlog(intake);
      await WidgetService.updateWidgetState();

      if (updatedMed.currstock < 3) {
        await NotificationHelper().showLowStockNotification(updatedMed);
      }
    }

    if (med.id != null) {
      await SnoozeService.resetSnooze(med.id!);
      await NotificationHelper().cancelNotification(med.id!);
      await AlarmService().cancelAlarm(med.id!);
    }
  }
}
