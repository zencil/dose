import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:app/dose.dart';
import 'package:app/services/notification_service.dart';
import 'package:app/services/alarm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationHelper().init();
  await AlarmService().init();
  runApp(const MyApp()); 
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final _defaultLightColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.deepPurple, 
    brightness: Brightness.light,
  );

  static final _defaultDarkColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.deepPurple, 
    brightness: Brightness.dark,
  );

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: lightDynamic ?? _defaultLightColorScheme,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: darkDynamic ?? _defaultDarkColorScheme,
            useMaterial3: true,
          ),
          themeMode: ThemeMode.system, 
          home: const Dose(),
        );
      },
    );
  }
}