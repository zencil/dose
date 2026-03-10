import 'package:shared_preferences/shared_preferences.dart';

/// Tracks snooze counts per medicine using SharedPreferences.
/// Resets daily so each day gets a fresh set of 5 snoozes.
class SnoozeService {
  static const int maxSnoozes = 5;
  static const int snoozeDurationMinutes = 5;

  /// Returns current snooze count for a medicine today.
  static Future<int> getSnoozeCount(int medicineId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(medicineId);
    return prefs.getInt(key) ?? 0;
  }

  /// Increments and returns the new snooze count. Returns -1 if limit reached.
  static Future<int> incrementSnooze(int medicineId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(medicineId);
    final current = prefs.getInt(key) ?? 0;
    if (current >= maxSnoozes) return -1;
    final newCount = current + 1;
    await prefs.setInt(key, newCount);
    return newCount;
  }

  /// Resets snooze count for a medicine (called after Done).
  static Future<void> resetSnooze(int medicineId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(medicineId));
  }

  /// Whether snoozing is still allowed.
  static Future<bool> canSnooze(int medicineId) async {
    final count = await getSnoozeCount(medicineId);
    return count < maxSnoozes;
  }

  /// Key uses today's date so snooze counts reset daily.
  static String _key(int medicineId) {
    final now = DateTime.now();
    final date = '${now.year}-${now.month}-${now.day}';
    return 'snooze_${medicineId}_$date';
  }
}
