import 'package:app/models/cabinet_model.dart';
import 'package:flutter/material.dart';
import 'package:app/db/cabinetdb.dart';
import 'package:app/services/notification_service.dart';
import 'package:app/services/alarm_service.dart';
import 'package:app/profile/cabinet/cabinet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Cabinet>> _medicinesFuture;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    _medicinesFuture = DatabaseHelper.instance.readAllMedicines();
  }

  void _deleteMedicine(int id, Offset position) async {
    final colorScheme = Theme.of(context).colorScheme;

    final result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: colorScheme.error),
              const SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: colorScheme.error)),
            ],
          ),
        ),
      ],
    );

    if (result == 'delete') {
      await DatabaseHelper.instance.delete(id);
      await NotificationHelper().cancelNotification(id);
      await AlarmService().cancelAlarm(id);
      setState(() {
         _refreshList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CabinetPage(),
              ),
            );
          },
          child: const Text('Test'),
        ),
        Expanded(
          child: FutureBuilder<List<Cabinet>>(
            future: _medicinesFuture,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      "Error loading data: ${snapshot.error}",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final medicines = snapshot.data ?? [];

              if (medicines.isEmpty) {
                return Center(
                  child: Text(
                    "No reminders added yet.",
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                );
              }
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: medicines.length,
                itemBuilder: (context, index) {
                  final med = medicines[index];
                  return GestureDetector(
                    onLongPressStart: (details) {
                      _deleteMedicine(med.id!, details.globalPosition);
                    },
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      color: colorScheme.surfaceContainer, 
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.medication, color: colorScheme.onTertiaryContainer),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    med.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    med.dosage,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colorScheme.onSurfaceVariant,
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
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.check, color: colorScheme.onPrimaryContainer),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}