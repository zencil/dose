import 'package:flutter/material.dart';
import 'package:app/models/cabinet_model.dart';
import 'package:app/db/cabinetdb.dart';

class CabinetPage extends StatefulWidget {
  const CabinetPage({super.key});

  @override
  State<CabinetPage> createState() => _CabinetPageState();
}

class _CabinetPageState extends State<CabinetPage> {
  late Future<List<Cabinet>> _medicinesFuture;

  @override
  void initState() {
    super.initState();
    _refreshMedicines();
  }

  void _refreshMedicines() {
    setState(() {
      _medicinesFuture = DatabaseHelper.instance.readAllMedicines();
    });
  }

  Color _getPriorityColor(int priority, BuildContext context) {
    switch (priority) {
      case 2:
        return Theme.of(context).colorScheme.error;
      case 1:
        return Colors.orange;
      case 0:
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 110, 
        leading: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: BackButton(
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        titleSpacing: -37,
        title: Padding(
          padding: const EdgeInsets.only(top: 55.0), 
          child: Text(
            'Cabinet',
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 35, 
              color: Theme.of(context).colorScheme.primary, 
            ),
          ),
        ),
        centerTitle: false,
      ),
      body: FutureBuilder<List<Cabinet>>(
        future: _medicinesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Cabinet is empty.'));
          }

          final medicines = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              final medicine = medicines[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  title: Text(
                    medicine.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${medicine.dosage} • ${medicine.time}'),
                        Text('Stock: ${medicine.currstock} / ${medicine.initstock}'),
                      ],
                    ),
                  ),
                  trailing: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getPriorityColor(medicine.priority, context),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}