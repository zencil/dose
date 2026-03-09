import 'package:flutter/foundation.dart';
import 'package:app/db/intake_log.dart';

// Since this requires sqflite, which only runs on a device or emulator,
// a simple Dart script executing `dart run` won't work natively on Windows to read the device DB.
// Instead, adding a hidden/dev-only button or logging right inside the main app during testing is safer.
// However, the easiest way is to print the logs in a widget or during startup.
//
// I'll create a simple function you can call inside your `HomePage`'s `initState`,
// or I can build a quick route to display them visually.

void dumpLogs() async {
  final logs = await DatabaseHelper.instance.readintakelog();
  if (kDebugMode) {
    print("----- INTAKE LOGS DUMP -----");
    if (logs.isEmpty) {
      print("No logs found.");
    } else {
      for (var log in logs) {
        print(
          "Log ID: ${log.id}, Name: ${log.name}, Target Time: ${log.ttime}, Taken Time: ${log.time}, Date: ${log.date}, Stock Left: ${log.currstock}",
        );
      }
    }
    print("----------------------------");
  }
}
