import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dose/db/cabinet_db.dart' as cabinet_db;
import 'package:dose/db/intake_log_db.dart' as log_db;
import 'package:dose/db/profile_db.dart' as profile_db;
import 'package:dose/db/dose_database.dart';

class BackupService {
  static final BackupService instance = BackupService._init();
  BackupService._init();

  /// Export all app data to a JSON file in the Downloads directory.
  /// Returns the file path on success.
  Future<String> exportData() async {
    final medicines = await cabinet_db.DatabaseHelper.instance
        .readAllMedicines();
    final intakeLogs = await log_db.DatabaseHelper.instance.readintakelog();
    List<Map<String, dynamic>> profileMaps = [];

    // We can safely read profiles now without swallowing errors,
    // as it's guaranteed database tables exist.
    final profiles = await profile_db.DatabaseHelper.instance.readprofile();
    profileMaps = profiles.map((p) => p.toMap()).toList();

    final prefs = await SharedPreferences.getInstance();

    final backup = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'cabinet': medicines.map((m) => m.toMap()).toList(),
      'intake_log': intakeLogs.map((i) => i.toMap()).toList(),
      'profile': profileMaps,
      'preferences': {
        'user_name': prefs.getString('user_name') ?? '',
        'user_age': prefs.getString('user_age') ?? '',
        'user_sex': prefs.getString('user_sex') ?? '',
        'onboarding_complete': prefs.getBool('onboarding_complete') ?? false,
      },
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(backup);
    final directory = await _getExportDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final file = File('${directory.path}/dose_backup_$timestamp.json');
    await file.writeAsString(jsonString);

    return file.path;
  }

  /// Import data from a JSON backup file. Clears existing data first.
  Future<void> importData(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Backup file not found.');
    }

    final jsonString = await file.readAsString();
    final Map<String, dynamic> backup;
    try {
      backup = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Invalid backup file format.');
    }
    if (!backup.containsKey('cabinet') || !backup.containsKey('intake_log')) {
      throw Exception('Backup file is missing required data.');
    }
    await _importCabinet(backup['cabinet'] as List<dynamic>);
    await _importIntakeLog(backup['intake_log'] as List<dynamic>);

    if (backup.containsKey('profile')) {
      await _importProfile(backup['profile'] as List<dynamic>);
    }

    if (backup.containsKey('preferences')) {
      await _importPreferences(backup['preferences'] as Map<String, dynamic>);
    }
  }

  Future<void> _importCabinet(List<dynamic> data) async {
    final db = await DoseDatabase.instance.database;
    await db.delete('cabinet');

    for (final item in data) {
      final map = Map<String, dynamic>.from(item as Map);
      await db.insert('cabinet', map);
    }
  }

  Future<void> _importIntakeLog(List<dynamic> data) async {
    final db = await DoseDatabase.instance.database;
    await db.delete('intake_log');

    for (final item in data) {
      final map = Map<String, dynamic>.from(item as Map);
      await db.insert('intake_log', map);
    }
  }

  Future<void> _importProfile(List<dynamic> data) async {
    // We removed empty try-catch blocks to ensure that serious SQLite failures
    // propagate correctly instead of silently resulting in empty DB states.
    final db = await DoseDatabase.instance.database;
    await db.delete('profile');

    for (final item in data) {
      final map = Map<String, dynamic>.from(item as Map);
      await db.insert('profile', map);
    }
  }

  Future<void> _importPreferences(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    if (data.containsKey('user_name')) {
      await prefs.setString('user_name', data['user_name'] as String);
    }
    if (data.containsKey('user_age')) {
      await prefs.setString('user_age', data['user_age'] as String);
    }
    if (data.containsKey('user_sex')) {
      await prefs.setString('user_sex', data['user_sex'] as String);
    }
    if (data.containsKey('onboarding_complete')) {
      await prefs.setBool(
        'onboarding_complete',
        data['onboarding_complete'] as bool,
      );
    }
  }

  Future<Directory> _getExportDirectory() async {
    Directory? dir;
    if (Platform.isAndroid) {
      dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        dir = await getExternalStorageDirectory();
      }
    }
    dir ??= await getApplicationDocumentsDirectory();
    return dir;
  }
}
