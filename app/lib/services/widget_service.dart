import 'package:home_widget/home_widget.dart';
import 'package:app/db/cabinet_db.dart' as cabinet_db;
import 'package:app/db/intake_log.dart' as log_db;
import 'package:app/models/cabinet_model.dart';

class WidgetService {
  static const String appGroupId = 'com.example.app';
  static const String iOSWidgetName = 'DoseWidget';
  static const String androidWidgetName = 'DoseWidgetProvider';

  /// Updates the widget data by calculating the missed and upcoming medicines
  /// from the database.
  static Future<void> updateWidgetState() async {
    try {
      final now = DateTime.now();

      // Read all medicines and today's logs
      final allMedicines =
          await cabinet_db.DatabaseHelper.instance.readAllMedicines();
      final todayLogs = await log_db.DatabaseHelper.instance.readintakelog();

      // Extract today's date in MM/dd/yyyy format (matching the app's log format)
      final todayString = '${now.month}/${now.day}/${now.year}';
      final logsToday =
          todayLogs.where((log) => log.date == todayString).toList();

      List<Cabinet> missed = [];
      List<Cabinet> upcoming = [];

      for (var medicine in allMedicines) {
        // Did we take or skip this today?
        final hasLog = logsToday.any((log) => log.name == medicine.name);

        if (!hasLog) {
          // Parse the scheduled time (e.g. "14:30" or "09:00")
          final timeParts = medicine.time.split(':');
          if (timeParts.length == 2) {
            final hour = int.tryParse(timeParts[0]) ?? 0;
            final min = int.tryParse(timeParts[1]) ?? 0;

            final scheduledTime =
                DateTime(now.year, now.month, now.day, hour, min);

            if (scheduledTime.isBefore(now)) {
              missed.add(medicine);
            } else {
              upcoming.add(medicine);
            }
          }
        }
      }

      // Sort both arrays by time
      missed.sort((a, b) => a.time.compareTo(b.time));
      upcoming.sort((a, b) => a.time.compareTo(b.time));

      // Build friendly text
      String missedText =
          missed.isEmpty
              ? 'No missed medicines'
              : missed.map((m) => '${m.name} at ${m.time}').join('\n');

      String upcomingText =
          upcoming.isEmpty
              ? 'Nothing scheduled'
              : upcoming.map((m) => '${m.name} at ${m.time}').join('\n');

      // Save to SharedPreferences via home_widget
      await HomeWidget.saveWidgetData<String>('widget_missed_text', missedText);
      await HomeWidget.saveWidgetData<String>(
        'widget_upcoming_text',
        upcomingText,
      );

      // Trigger the OS update
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (e) {
      print('Widget update failed: $e');
    }
  }
}
