import 'package:flutter/material.dart';
import 'package:app/models/cabinet_model.dart';
import 'package:app/db/cabinetdb.dart';
import 'package:app/home/add_menu.dart';

class CabinetPage extends StatefulWidget {
  const CabinetPage({super.key});

  @override
  State<CabinetPage> createState() => _CabinetPageState();
}

class _CabinetPageState extends State<CabinetPage> {
  late Future<List<Cabinet>> _medicinesFuture;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Cabinet? _editingMedicine;

  @override
  void initState() {
    super.initState();
    _refreshMedicines();
  }

  void _refreshMedicines() {
    setState(() {
      _medicinesFuture = DatabaseHelper.instance.readAllMedicines().then((medicines) {
        medicines.sort((a, b) {
          int priorityComparison = b.priority.compareTo(a.priority);
          if (priorityComparison != 0) {
            return priorityComparison;
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        return medicines;
      });
    });
  }

  Future<void> _showDeleteConfirmation(Cabinet medicine) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Medicine'),
          content: Text('Are you sure you want to delete ${medicine.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _deleteMedicine(medicine.id!);
                Navigator.of(context).pop();
              },
              child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        );
      },
    );
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

  void _deleteMedicine(int id) async {
    await DatabaseHelper.instance.deleteMedicine(id);
    _refreshMedicines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
          padding: const EdgeInsets.only(top: 70.0), 
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
        actions: const [
          SizedBox.shrink(),
        ],
      ),
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width,
        child: AddMedicineMenu(
          medicineToEdit: _editingMedicine,
          onSave: () {
            setState(() {
              _editingMedicine = null;
            });
            _refreshMedicines();
            Navigator.pop(context); 
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _editingMedicine = null;
          });
          _scaffoldKey.currentState?.openEndDrawer();
        },
        child: const Icon(Icons.add),
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
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                margin: const EdgeInsets.only(bottom: 12.0),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _getPriorityColor(medicine.priority, context),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    title: Text(
                      medicine.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dosage: ${medicine.dosage}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Time: ${medicine.time}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Stock: ${medicine.currstock} / ${medicine.initstock}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _editingMedicine = medicine;
                                    });
                                    _scaffoldKey.currentState?.openEndDrawer();
                                  },
                                  icon: const Icon(Icons.edit),
                                  tooltip: 'Edit',
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _showDeleteConfirmation(medicine),
                                  icon: const Icon(Icons.delete),
                                  tooltip: 'Delete',
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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