import 'package:flutter/material.dart';
import 'package:app/models/medicine.dart';
import 'package:app/db/databaseHelper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Medicine>> _medicinesFuture;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    _medicinesFuture = DatabaseHelper.instance.readAllMedicines();
  }

  void _deleteMedicine(int id, Offset position) async {
    final result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );

    if (result == 'delete') {
      await DatabaseHelper.instance.delete(id);
      setState(() {
         _refreshList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Medicine>>(
      future: _medicinesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Error loading data: ${snapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final medicines = snapshot.data ?? [];

        if (medicines.isEmpty) {
          return const Center(child: Text("No reminders added yet."));
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
                  side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                ),
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.medication, color: Colors.indigo),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              med.dosage,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        med.time,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 110, 126, 214),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.check, color: Colors.indigo),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}