import 'package:flutter/material.dart';
import 'package:dose/models/cabinet_model.dart';
import 'package:dose/models/extensions.dart';
import 'package:dose/db/cabinet_db.dart';
import 'package:dose/pages/add_menu_page.dart';
import 'package:dose/services/widget_service.dart';
import 'package:dose/widgets/dose_card.dart';
import 'package:dose/models/medicine_category.dart';

class CabinetPage extends StatefulWidget {
  const CabinetPage({super.key});

  @override
  State<CabinetPage> createState() => _CabinetPageState();
}

class _CabinetPageState extends State<CabinetPage> {
  late Future<List<Cabinet>> _medicinesFuture;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Cabinet? _editingMedicine;
  MedicineCategory? _selectedCategoryForNewMed;

  @override
  void initState() {
    super.initState();
    _refreshMedicines();
  }

  void _refreshMedicines() {
    setState(() {
      _medicinesFuture = DatabaseHelper.instance.readAllMedicines().then((
        medicines,
      ) {
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
              child: Text(
                'Delete',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
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
    await WidgetService.updateWidgetState();
    _refreshMedicines();
  }

  void _showCategoryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Padding(
          padding: EdgeInsets.only(
            left: 24.0,
            right: 24.0,
            top: 24.0,
            bottom: MediaQuery.of(context).padding.bottom + 24.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Medicine',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: MedicineCategory.values.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final cat = MedicineCategory.values[index];
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _editingMedicine = null;
                          _selectedCategoryForNewMed = cat;
                        });
                        _scaffoldKey.currentState?.openEndDrawer();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: cs.outlineVariant.withValues(alpha: 0.5),
                              width: 1.5),
                          borderRadius: BorderRadius.circular(16),
                          color: cs.surfaceContainerLowest,
                        ),
                        child: Row(
                          children: [
                            Icon(cat.icon, size: 28, color: cs.onSurfaceVariant),
                            const SizedBox(width: 16),
                            Text(
                              cat.label,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        toolbarHeight: 130,
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
            'Cabinet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 35,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        centerTitle: false,
        actions: const [SizedBox.shrink()],
      ),
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width,
        child: AddMedicineMenu(
          medicineToEdit: _editingMedicine,
          initialCategory: _selectedCategoryForNewMed,
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
        onPressed: () => _showCategoryBottomSheet(context),
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
              return DoseCard(
                padding: EdgeInsets.zero,
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    leading: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(medicine.priority, context),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      medicine.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 16.0,
                          right: 16.0,
                          bottom: 16.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dosage: ${medicine.dosage.formattedDosage} ${medicine.unit}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Time: ${medicine.time}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Stock: ${medicine.currstock} / ${medicine.initstock}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 12),
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
                                  icon: const Icon(Icons.edit, size: 20),
                                  tooltip: 'Edit',
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () =>
                                      _showDeleteConfirmation(medicine),
                                  icon: const Icon(Icons.delete, size: 20),
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
