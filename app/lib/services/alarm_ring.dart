import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:app/db/cabinetdb.dart';
import 'package:app/models/cabinet_model.dart';
import 'package:app/models/intake_model.dart';
import 'package:app/db/intake_log.dart' as log_db;

class AlarmRingScreen extends StatelessWidget {
  final AlarmSettings alarmSettings;

  const AlarmRingScreen({super.key, required this.alarmSettings});

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
              alarmSettings.notificationSettings.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await Alarm.stop(alarmSettings.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Stop Alarm'),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () async {
                    final med = await DatabaseHelper.instance.readMedicine(
                      alarmSettings.id,
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
                    }
                    await Alarm.stop(alarmSettings.id);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
