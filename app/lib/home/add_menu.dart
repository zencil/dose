import 'package:flutter/material.dart';
import 'package:app/models/cabinet_model.dart';
import 'package:app/db/cabinetdb.dart';
import 'package:app/services/notification_service.dart';
import 'package:app/services/alarm_service.dart';

class AddMedicineMenu extends StatefulWidget {
  final VoidCallback onSave;
  final Cabinet? medicineToEdit;

  const AddMedicineMenu({super.key, required this.onSave, this.medicineToEdit});

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
  int _cycle = 1;
  int _priority = 1;

  @override
  void initState() {
    super.initState();
    if (widget.medicineToEdit != null) {
      final med = widget.medicineToEdit!;
      _nameController.text = med.name;
      _dosageController.text = med.dosage.replaceAll(' mg', '');
      _stockController.text = med.currstock.toString();
      _priority = med.priority;

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

  void _saveMedicine() async {
    if (_formKey.currentState!.validate()) {
      final String timeString =
          "${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}";

      final medicine = Cabinet(
        id: widget.medicineToEdit?.id,
        name: _nameController.text,
        dosage: "${_dosageController.text} mg",
        time: timeString,
        currstock: int.tryParse(_stockController.text) ?? 0,
        initstock: widget.medicineToEdit != null
            ? widget.medicineToEdit!.initstock
            : (int.tryParse(_stockController.text) ?? 0),
        priority: _priority,
      );

      int savedId;
      if (widget.medicineToEdit == null) {
        savedId = await DatabaseHelper.instance.createMedicine(medicine);
      } else {
        await DatabaseHelper.instance.updateMedicine(medicine);
        savedId = medicine.id!;
      }

      await AlarmService().scheduleMedicineAlarm(savedId, medicine);
      await NotificationHelper().scheduleMedicineNotification(
        savedId,
        medicine.name,
        timeString,
      );

      widget.onSave();

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.medicineToEdit == null ? "Add Reminder" : "Edit Reminder",
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.only(top: 20),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Medicine Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dosageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Dosage",
                  suffixText: "mg",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "Time",
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedTime.format(context),
                              style: TextStyle(color: colorScheme.onSurface),
                            ),
                            Icon(
                              Icons.access_time,
                              size: 20,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _cycle,
                      decoration: const InputDecoration(
                        labelText: "Cycle",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      items: List.generate(5, (index) => index + 1).map((
                        int value,
                      ) {
                        return DropdownMenuItem<int>(
                          value: value,
                          child: Text("$value /day"),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _cycle = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _conditionController,
                decoration: const InputDecoration(
                  labelText: "Condition",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _doctorController,
                decoration: const InputDecoration(
                  labelText: "Prescribed By",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Current Stock",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: "Priority",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 2, child: Text("High")),
                  DropdownMenuItem(value: 1, child: Text("Medium")),
                  DropdownMenuItem(value: 0, child: Text("Low")),
                ],
                onChanged: (val) => setState(() => _priority = val!),
              ),
              const SizedBox(height: 30),

              FilledButton(
                onPressed: _saveMedicine,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  widget.medicineToEdit == null
                      ? "Save Reminder"
                      : "Update Reminder",
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
