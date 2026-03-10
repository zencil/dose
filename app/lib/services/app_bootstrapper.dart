import 'package:flutter/material.dart';
import 'package:app/services/theme_service.dart';
import 'package:app/services/notification_service.dart';
import 'package:app/services/alarm_service.dart';
import 'package:app/services/widget_service.dart';
import 'package:workmanager/workmanager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await WidgetService.updateWidgetState();
    return Future.value(true);
  });
}

class AppBootstrapper {
  static Future<void> initAll() async {
    WidgetsFlutterBinding.ensureInitialized();
    await ThemeService().init();
    await NotificationHelper().init();
    await AlarmService().init();

    // Initialize background worker for widget updates
    Workmanager().initialize(callbackDispatcher);
    Workmanager().registerPeriodicTask(
      '1',
      'widgetUpdateTask',
      frequency: const Duration(minutes: 15),
    );

    // Initial widget update when the app opens
    await WidgetService.updateWidgetState();
  }
}
