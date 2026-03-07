import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';

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
            ElevatedButton(
              onPressed: () async {
                await Alarm.stop(alarmSettings.id);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Stop Alarm'),
            ),
          ],
        ),
      ),
    );
  }
}