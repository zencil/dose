import 'package:flutter/material.dart';
import 'package:dose/models/cabinet_model.dart';
import 'package:dose/models/medicine_category.dart';
import 'package:dose/db/cabinet_db.dart';
import 'package:dose/services/notification_service.dart';
import 'package:dose/services/alarm_service.dart';
import 'package:dose/services/widget_service.dart';

class AddMedicineMenu extends StatefulWidget {
  final VoidCallback onSave;
  final Cabinet? medicineToEdit;
  final MedicineCategory? initialCategory;

  const AddMedicineMenu({
    super.key,
    required this.onSave,
    this.medicineToEdit,
    this.initialCategory,
  });

  @override
  State<AddMedicineMenu> createState() => _AddMedicineMenuState();
}

class _AddMedicineMenuState extends State<AddMedicineMenu> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _conditionController = TextEditingController();
  final _doctorController = TextEditingController();
  final _stockController = TextEditingController();

  TimeOfDay _selectedTime = TimeOfDay.now();
  String _cycle = '1/day';
  int _priority = 1;
  late MedicineCategory _selectedCategory;
  late String _selectedUnit;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    _selectedCategory = widget.initialCategory ?? MedicineCategory.tablet;
    _selectedUnit = _selectedCategory.defaultUnit;

    if (widget.medicineToEdit != null) {
      final med = widget.medicineToEdit!;
      _nameController.text = med.name;
      _dosageController.text = med.dosage.replaceAll(' pills/spoons', '');
      _stockController.text = med.currstock.toString();
      _priority = med.priority;
      _selectedCategory = MedicineCategory.fromString(med.category);
      _selectedUnit = _selectedCategory.units.contains(med.unit)
          ? med.unit
          : _selectedCategory.defaultUnit;

      final parts = med.time.split(':');
      if (parts.length == 2) {
        _selectedTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _conditionController.dispose();
    _doctorController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String _dateLabel() {
    final now = DateTime.now();
    if (_selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day) {
      return 'Today';
    }
    return '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}';
  }

  void _saveMedicine() async {
    if (_formKey.currentState!.validate()) {
      final String timeString =
          "${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}";

      final medicine = Cabinet(
        id: widget.medicineToEdit?.id,
        name: _nameController.text,
        dosage: _dosageController.text,
        time: timeString,
        currstock: int.tryParse(_stockController.text) ?? 0,
        initstock: widget.medicineToEdit != null
            ? widget.medicineToEdit!.initstock
            : (int.tryParse(_stockController.text) ?? 0),
        priority: _priority,
        category: _selectedCategory.name,
        unit: _selectedUnit,
      );

      int savedId;
      if (widget.medicineToEdit == null) {
        savedId = await DatabaseHelper.instance.createMedicine(medicine);
      } else {
        await DatabaseHelper.instance.updateMedicine(medicine);
        savedId = medicine.id!;
      }
      if (widget.medicineToEdit != null) {
        await AlarmService().cancelAlarm(savedId);
        await NotificationHelper().cancelNotification(savedId);
      }

      await AlarmService().scheduleMedicineAlarm(savedId, medicine);
      if (medicine.priority != 2) {
        await NotificationHelper().scheduleMedicineNotification(
          savedId,
          medicine.name,
          timeString,
        );
      }
      await WidgetService.updateWidgetState();

      widget.onSave();

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  InputDecoration _buildInputDecoration(String label, {String? suffixText}) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      suffixText: suffixText,
      filled: true,
      fillColor: cs.surfaceContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(width: 3.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(width: 3.0, color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(width: 3.0, color: cs.primary),
      ),
    );
  }

  InputDecorationTheme _dropdownDecorationTheme(ColorScheme cs) {
    return InputDecorationTheme(
      filled: true,
      fillColor: cs.surfaceContainer,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(width: 3.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(width: 3.0, color: cs.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(width: 3.0, color: cs.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Zone 1: Page Title
                    Text(
                      widget.medicineToEdit == null
                          ? 'Add Medicine'
                          : 'Edit Medicine',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Date/Time Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Date side
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _dateLabel(),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        // Time side
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _selectTime(context),
                              child: Card(
                                color: colorScheme.secondaryContainer,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    _selectedTime.hourOfPeriod
                                        .toString()
                                        .padLeft(2, '0'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              colorScheme.onSecondaryContainer,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              ':',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            GestureDetector(
                              onTap: () => _selectTime(context),
                              child: Card(
                                color: colorScheme.secondaryContainer,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    _selectedTime.minute.toString().padLeft(
                                      2,
                                      '0',
                                    ),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              colorScheme.onSecondaryContainer,
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Card(
                              color: colorScheme.secondaryContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Text(
                                  _selectedTime.period == DayPeriod.am
                                      ? 'AM'
                                      : 'PM',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colorScheme.onSecondaryContainer,
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Form Fields
                    TextFormField(
                      controller: _nameController,
                      decoration: _buildInputDecoration("Medicine Name"),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    DropdownMenu<MedicineCategory>(
                      initialSelection: _selectedCategory,
                      label: const Text("Category"),
                      expandedInsets: EdgeInsets.zero,
                      menuStyle: MenuStyle(
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      inputDecorationTheme: _dropdownDecorationTheme(
                        colorScheme,
                      ),
                      dropdownMenuEntries: MedicineCategory.values
                          .map(
                            (cat) => DropdownMenuEntry(
                              value: cat,
                              label: cat.label,
                              leadingIcon: Icon(cat.icon),
                            ),
                          )
                          .toList(),
                      onSelected: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                            _selectedUnit = val.defaultUnit;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Unit + Dosage Row Focus: Unit to the right of the box as suffix.
                    TextFormField(
                      controller: _dosageController,
                      keyboardType: TextInputType.number,
                      decoration: _buildInputDecoration("Dosage").copyWith(
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 16.0),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedUnit,
                              icon: Icon(
                                Icons.keyboard_arrow_down,
                                color: colorScheme.primary,
                              ),
                              style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              items: _selectedCategory.units
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedUnit = val);
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: DropdownMenu<String>(
                            initialSelection: _cycle,
                            label: const Text("Cycle"),
                            expandedInsets: EdgeInsets.zero,
                            menuHeight: 200,
                            menuStyle: MenuStyle(
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            inputDecorationTheme: _dropdownDecorationTheme(
                              colorScheme,
                            ),
                            dropdownMenuEntries: const [
                              DropdownMenuEntry(value: '6h', label: '6 hours'),
                              DropdownMenuEntry(
                                value: '12h',
                                label: '12 hours',
                              ),
                              DropdownMenuEntry(value: '1/day', label: '1/day'),
                              DropdownMenuEntry(value: '2/day', label: '2/day'),
                              DropdownMenuEntry(value: '3/day', label: '3/day'),
                              DropdownMenuEntry(
                                value: 'weekly',
                                label: 'Weekly',
                              ),
                              DropdownMenuEntry(
                                value: 'monthly',
                                label: 'Monthly',
                              ),
                            ],
                            onSelected: (val) {
                              if (val != null) setState(() => _cycle = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownMenu<int>(
                            initialSelection: _priority,
                            label: const Text("Priority"),
                            expandedInsets: EdgeInsets.zero,
                            menuHeight: 200,
                            menuStyle: MenuStyle(
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            inputDecorationTheme: _dropdownDecorationTheme(
                              colorScheme,
                            ),
                            dropdownMenuEntries: const [
                              DropdownMenuEntry(value: 0, label: 'Low'),
                              DropdownMenuEntry(value: 1, label: 'Medium'),
                              DropdownMenuEntry(value: 2, label: 'High'),
                            ],
                            onSelected: (val) {
                              if (val != null) setState(() => _priority = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _conditionController,
                      decoration: _buildInputDecoration("Condition"),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _doctorController,
                      decoration: _buildInputDecoration("Prescribed By"),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: _buildInputDecoration("Current Stock"),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // Zone 4: Sticky Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (_nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Please enter a medicine name'),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                    return;
                  }
                  _saveMedicine();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.medicineToEdit == null
                      ? 'Save Reminder'
                      : 'Update Reminder',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
