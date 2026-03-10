import 'package:app/models/cabinet_model.dart';
import 'package:app/models/intake_model.dart' as log_model;
import 'package:flutter/material.dart';
import 'package:app/db/cabinet_db.dart';
import 'package:app/db/intake_log.dart' as log_db;
import 'package:app/services/widget_service.dart';
import 'package:app/services/snooze_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Cabinet>> _medicinesFuture;
  late Future<List<log_model.Intake>> _todayLogsFuture;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    _medicinesFuture = DatabaseHelper.instance.readAllMedicines();
    _todayLogsFuture = log_db.DatabaseHelper.instance.readintakelog();
  }



  bool _isUpcoming(Cabinet med, List<log_model.Intake> todayLogs) {
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    bool isTaken = todayLogs.any((log) =>
        log.name == med.name && log.ttime == med.time && log.date == todayStr);
    if (isTaken) return false;

    final timeParts = med.time.split(':');
    final int hour = int.parse(timeParts[0]);
    final int minute = int.parse(timeParts[1]);

    // Handle day wraparounds conceptually by checking diff
    var targetTime = DateTime(now.year, now.month, now.day, hour, minute);

    // If target is 23:50 and now is 00:10 (next day)
    // Diff is target - now -> -20.
    // So normal diff works nicely within the same day.
    int diff = targetTime.difference(now).inMinutes;

    // Check edge case where target is close to midnight
    if (diff < -12 * 60) diff += 24 * 60;
    if (diff > 12 * 60) diff -= 24 * 60;

    return diff >= -30 && diff <= 30;
  }

  Future<void> _handleDone(Cabinet med) async {
    if (med.currstock > 0) {
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
      String timeStr =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      String dateStr =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final intake = log_model.Intake(
        id: med.id,
        name: med.name,
        ttime: med.time,
        time: timeStr,
        date: dateStr,
        currstock: med.currstock - 1,
      );
      await log_db.DatabaseHelper.instance.createlog(intake);
      await WidgetService.updateWidgetState();
    }
    
    if (med.id != null) {
      await SnoozeService.resetSnooze(med.id!);
    }

    setState(() {
      _refreshList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return FutureBuilder(
      future: Future.wait([_medicinesFuture, _todayLogsFuture]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Error loading data: ${snapshot.error}",
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.error),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final medicines = (snapshot.data?[0] as List<Cabinet>?) ?? [];
        final logs = (snapshot.data?[1] as List<log_model.Intake>?) ?? [];

        // Determine Upcoming list
        final upcomingMedicines = medicines.where((med) => _isUpcoming(med, logs)).toList();
        upcomingMedicines.sort((a, b) => a.time.compareTo(b.time));

        // Create deduplicated condesned list
        final Map<String, String> uniqueMedicines = {};
        for (final med in medicines) {
          uniqueMedicines[med.name] = med.dosage;
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [
            if (upcomingMedicines.isNotEmpty) ...[
              // Upcoming Header
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  'Upcoming',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ),
              ...upcomingMedicines.map((med) => _buildUpcomingCard(med, cs)),
            ],

            // All Medicines Header
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
              child: Text(
                'All Medicines',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
            ),

            if (uniqueMedicines.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 0.0),
                child: Text(
                  "Cabinet is empty.",
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              )
            else
              _buildCondensedList(uniqueMedicines, cs),

            const SizedBox(height: 80), // extra padding for bottom scrolling
          ],
        );
      },
    );
  }

  Widget _buildUpcomingCard(Cabinet med, ColorScheme cs) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12.0),
      color: cs.surfaceContainer,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cs.outlineVariant, width: 3.0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.medication, color: cs.onTertiaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    med.dosage.replaceAll('mg', 'pills/spoons'),
                    style: TextStyle(
                      fontSize: 14,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              med.time,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: () => _handleDone(med),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.check, color: cs.onPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCondensedList(Map<String, String> uniqueMedicines, ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant, width: 3.0),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: uniqueMedicines.length,
        itemBuilder: (context, index) {
          String name = uniqueMedicines.keys.elementAt(index);
          String dosage = uniqueMedicines[name]!;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: cs.primary),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Text(
                  dosage.replaceAll('mg', 'pills/spoons'),
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 1,
          color: cs.outlineVariant.withValues(alpha: 0.5),
          indent: 16,
          endIndent: 16,
        ),
      ),
    );
  }
}
