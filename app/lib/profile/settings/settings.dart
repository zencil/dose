import 'package:flutter/material.dart';
import 'package:app/services/theme_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 110,
        leading: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: BackButton(onPressed: () => Navigator.pop(context)),
          ),
        ),
        titleSpacing: -37,
        title: Padding(
          padding: const EdgeInsets.only(top: 70.0),
          child: Text(
            'Settings',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 35,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_buildThemeSelector(context)],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final themeService = ThemeService();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeService.themeNotifier,
      builder: (context, currentMode, _) {
        String subtitleText = 'System';
        if (currentMode == ThemeMode.light) subtitleText = 'Light';
        if (currentMode == ThemeMode.dark) subtitleText = 'Dark';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.brightness_6),
          title: const Text('Theme'),
          subtitle: Text(subtitleText),
          onTap: () {
            _showThemeBottomSheet(context, currentMode, themeService);
          },
        );
      },
    );
  }

  void _showThemeBottomSheet(
    BuildContext context,
    ThemeMode currentMode,
    ThemeService themeService,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Choose Theme',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.brightness_5),
                title: const Text('Light'),
                trailing: currentMode == ThemeMode.light
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  themeService.updateThemeMode(ThemeMode.light);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.brightness_2),
                title: const Text('Dark'),
                trailing: currentMode == ThemeMode.dark
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  themeService.updateThemeMode(ThemeMode.dark);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.brightness_auto),
                title: const Text('System'),
                trailing: currentMode == ThemeMode.system
                    ? const Icon(Icons.check)
                    : null,
                onTap: () {
                  themeService.updateThemeMode(ThemeMode.system);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
