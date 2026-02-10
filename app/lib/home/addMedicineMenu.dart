import 'package:flutter/material.dart';
import 'package:app/models/medicine.dart';
import 'package:app/db/db_helper.dart';

class AddMedicineMenu extends StatefulWidget {
  final VoidCallback onSave;

  const AddMedicineMenu({super.key, required this.onSave});

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
      final String timeString = "${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')}";
      
      final medicine = Medicine(
        name: _nameController.text,
        dosage: "${_dosageController.text} mg",
        time: timeString,
        cycle: _cycle,
        condition: _conditionController.text,
        doctor: _doctorController.text,
        stock: int.tryParse(_stockController.text) ?? 0,
        priority: _priority,
      );

      await DatabaseHelper.instance.create(medicine);
      widget.onSave();
      
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text("Add Reminder"),
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
                decoration: const InputDecoration(labelText: "Medicine Name", border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dosageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Dosage", suffixText: "mg", border: OutlineInputBorder()),
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
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_selectedTime.format(context)),
                            const Icon(Icons.access_time, size: 20),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      items: List.generate(5, (index) => index + 1).map((int value) {
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
                decoration: const InputDecoration(labelText: "Condition", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _doctorController,
                decoration: const InputDecoration(labelText: "Prescribed By", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Current Stock", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: "Priority", border: OutlineInputBorder()),
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
                child: const Text("Save Reminder"),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}