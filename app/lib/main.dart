import 'package:flutter/material.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dose/dose.dart';
import 'package:dose/pages/onboarding_page.dart';
import 'package:dose/services/theme_service.dart';
import 'package:dose/services/app_bootstrapper.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  await AppBootstrapper.initAll();

  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete = prefs.getBool('has_completed_onboarding') ?? false;

  runApp(MyApp(onboardingComplete: onboardingComplete));
}

class MyApp extends StatelessWidget {
  final bool onboardingComplete;

  const MyApp({super.key, required this.onboardingComplete});

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
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeService().themeNotifier,
          builder: (context, themeMode, _) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: lightDynamic ?? _defaultLightColorScheme,
                useMaterial3: true,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
              ),
              darkTheme: ThemeData(
                colorScheme: darkDynamic ?? _defaultDarkColorScheme,
                useMaterial3: true,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
              ),
              themeMode: themeMode,
              home: onboardingComplete
                  ? const Dose()
                  : const OnboardingScreen(),
            );
          },
        );
      },
    );
  }
}
