import 'package:dose/models/cabinet_model.dart';
import 'package:dose/models/intake_model.dart' as log_model;
import 'package:dose/models/extensions.dart';
import 'package:dose/models/medicine_category.dart';
import 'package:flutter/material.dart';
import 'package:dose/db/cabinet_db.dart';
import 'package:dose/db/intake_log_db.dart' as log_db;
import 'package:dose/widgets/dose_card.dart';
import 'package:dose/services/intake_service.dart';

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
    return IntakeService.isUpcoming(med, todayLogs);
  }

  Future<void> _handleDone(Cabinet med) async {
    await IntakeService.handleDone(med);
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
        final upcomingMedicines = medicines
            .where((med) => _isUpcoming(med, logs))
            .toList();
        upcomingMedicines.sort((a, b) => a.time.compareTo(b.time));
        final lowStockMedicines = medicines
            .where((med) => med.currstock < 3)
            .toList();
        final Map<String, Cabinet> uniqueMedicines = {};
        for (final med in medicines) {
          if (!uniqueMedicines.containsKey(med.name)) {
            uniqueMedicines[med.name] = med;
          }
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [
            if (upcomingMedicines.isNotEmpty) ...[
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

            if (lowStockMedicines.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
                child: Text(
                  'Restock Reminder',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: cs.error,
                  ),
                ),
              ),
              DoseCard(
                padding: EdgeInsets.zero,
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: lowStockMedicines.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    thickness: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, index) {
                    final med = lowStockMedicines[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 14.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              med.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            'Stock: ${med.currstock}',
                            style: TextStyle(
                              color: cs.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
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
    return DoseCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: cs.tertiaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              MedicineCategory.fromString(med.category).icon,
              color: cs.onTertiaryContainer,
            ),
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
                  '${med.dosage.formattedDosage} ${med.unit}',
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
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
    );
  }

  Widget _buildCondensedList(
    Map<String, Cabinet> uniqueMedicines,
    ColorScheme cs,
  ) {
    return DoseCard(
      padding: EdgeInsets.zero,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: uniqueMedicines.length,
        itemBuilder: (context, index) {
          String name = uniqueMedicines.keys.elementAt(index);
          Cabinet med = uniqueMedicines[name]!;

          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 16.0,
            ),
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
                  '${med.dosage.formattedDosage} ${med.unit}',
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
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
