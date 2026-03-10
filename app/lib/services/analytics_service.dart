import 'package:dose/db/intake_log_db.dart' as log_db;
import 'package:dose/db/cabinet_db.dart' as cabinet_db;
import 'package:dose/models/intake_model.dart';

/// Data class for adherence summary (pie chart).
class AdherenceSummary {
  final int taken;
  final int late;
  final int skipped;

  AdherenceSummary({
    required this.taken,
    required this.late,
    required this.skipped,
  });

  int get total => taken + late + skipped;
}

/// Data class for monthly adherence (line graph).
class MonthlyAdherence {
  final String month; // "YYYY-MM"
  final double percent;

  MonthlyAdherence({required this.month, required this.percent});
}

/// Data point for stock timeline.
class StockPoint {
  final DateTime date;
  final int stock;

  StockPoint({required this.date, required this.stock});
}

/// Per-medicine stock timeline.
class MedicineStockTimeline {
  final String name;
  final int initStock;
  final List<StockPoint> points;

  MedicineStockTimeline({
    required this.name,
    required this.initStock,
    required this.points,
  });
}

class AnalyticsService {
  static final AnalyticsService instance = AnalyticsService._init();
  AnalyticsService._init();

  /// Tolerance in minutes for classifying a dose as "on time" vs "late".
  static const int _lateThresholdMinutes = 5;

  /// Parse a time string "HH:MM" to minutes since midnight.
  int _timeToMinutes(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return 0;
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  /// Parse date string "YYYY-MM-DD" to DateTime.
  DateTime? _parseDate(String date) {
    try {
      final parts = date.split('-');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  /// Build a lookup: medicineId -> { "YYYY-MM-DD" -> Intake }
  Map<int, Map<String, Intake>> _buildIntakeLookup(List<Intake> logs) {
    final lookup = <int, Map<String, Intake>>{};
    for (final log in logs) {
      if (log.id == null) continue;
      lookup.putIfAbsent(log.id!, () => {});
      lookup[log.id!]![log.date] = log;
    }
    return lookup;
  }

  /// Find the earliest date from intake logs.
  DateTime? _findEarliestDate(List<Intake> logs) {
    DateTime? earliest;
    for (final log in logs) {
      final d = _parseDate(log.date);
      if (d != null && (earliest == null || d.isBefore(earliest))) {
        earliest = d;
      }
    }
    return earliest;
  }

  /// Format a DateTime as "YYYY-MM-DD".
  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// Get adherence summary for the pie chart.
  Future<AdherenceSummary> getAdherenceSummary() async {
    final logs = await log_db.DatabaseHelper.instance.readintakelog();
    final medicines = await cabinet_db.DatabaseHelper.instance
        .readAllMedicines();

    if (medicines.isEmpty || logs.isEmpty) {
      return AdherenceSummary(taken: 0, late: 0, skipped: 0);
    }

    final lookup = _buildIntakeLookup(logs);
    final earliest = _findEarliestDate(logs);
    if (earliest == null) {
      return AdherenceSummary(taken: 0, late: 0, skipped: 0);
    }

    final today = DateTime.now();
    int taken = 0;
    int late = 0;
    int skipped = 0;

    for (final med in medicines) {
      if (med.id == null) continue;
      final medLogs = lookup[med.id!] ?? {};
      final scheduledMinutes = _timeToMinutes(med.time);
      DateTime day = earliest;
      while (!day.isAfter(today)) {
        final dateStr = _formatDate(day);
        final intake = medLogs[dateStr];

        if (intake != null) {
          final actualMinutes = _timeToMinutes(intake.time);
          if ((actualMinutes - scheduledMinutes).abs() <=
              _lateThresholdMinutes) {
            taken++;
          } else {
            late++;
          }
        } else {
          skipped++;
        }

        day = day.add(const Duration(days: 1));
      }
    }

    return AdherenceSummary(taken: taken, late: late, skipped: skipped);
  }

  /// Get monthly adherence percentages for the line graph.
  Future<List<MonthlyAdherence>> getMonthlyAdherence({int months = 6}) async {
    final logs = await log_db.DatabaseHelper.instance.readintakelog();
    final medicines = await cabinet_db.DatabaseHelper.instance
        .readAllMedicines();

    if (medicines.isEmpty) return [];

    final today = DateTime.now();
    final result = <MonthlyAdherence>[];
    final lookup = _buildIntakeLookup(logs);

    for (int i = months - 1; i >= 0; i--) {
      int year = today.year;
      int month = today.month - i;
      while (month <= 0) {
        month += 12;
        year--;
      }

      final firstDay = DateTime(year, month, 1);
      final lastDay = DateTime(year, month + 1, 0); // last day of month
      final endDay = lastDay.isAfter(today) ? today : lastDay;

      int totalExpected = 0;
      int totalTaken = 0;

      for (final med in medicines) {
        if (med.id == null) continue;
        final medLogs = lookup[med.id!] ?? {};

        DateTime day = firstDay;
        while (!day.isAfter(endDay)) {
          totalExpected++;
          final dateStr = _formatDate(day);
          if (medLogs.containsKey(dateStr)) {
            totalTaken++;
          }
          day = day.add(const Duration(days: 1));
        }
      }

      final percent = totalExpected > 0
          ? (totalTaken / totalExpected) * 100
          : 0.0;
      final monthStr = '$year-${month.toString().padLeft(2, '0')}';
      result.add(MonthlyAdherence(month: monthStr, percent: percent));
    }

    return result;
  }

  /// Get stock timeline data for each medicine.
  Future<List<MedicineStockTimeline>> getStockTimelines() async {
    final logs = await log_db.DatabaseHelper.instance.readintakelog();
    final medicines = await cabinet_db.DatabaseHelper.instance
        .readAllMedicines();

    if (medicines.isEmpty) return [];
    final logsByMed = <int, List<Intake>>{};
    for (final log in logs) {
      if (log.id == null) continue;
      logsByMed.putIfAbsent(log.id!, () => []);
      logsByMed[log.id!]!.add(log);
    }

    final timelines = <MedicineStockTimeline>[];

    for (final med in medicines) {
      if (med.id == null) continue;
      final medLogs = logsByMed[med.id!] ?? [];
      medLogs.sort((a, b) => a.date.compareTo(b.date));

      final points = <StockPoint>[];
      for (final log in medLogs) {
        final d = _parseDate(log.date);
        if (d != null) {
          points.add(StockPoint(date: d, stock: log.currstock));
        }
      }
      points.add(StockPoint(date: DateTime.now(), stock: med.currstock));

      timelines.add(
        MedicineStockTimeline(
          name: med.name,
          initStock: med.initstock,
          points: points,
        ),
      );
    }

    return timelines;
  }
}
