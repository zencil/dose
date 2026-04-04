import 'package:flutter/material.dart';
import 'package:dose/models/profile_model.dart';
import 'package:dose/db/profile_db.dart';

class EditProfilePage extends StatefulWidget {
  final Profile profileData;

  const EditProfilePage({super.key, required this.profileData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _dobController;
  late TextEditingController _bloodTypeController;
  late TextEditingController _sexController;
  late TextEditingController _donorController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profileData.name);
    _dobController = TextEditingController(text: widget.profileData.dob);
    _bloodTypeController = TextEditingController(
      text: widget.profileData.bloodtype,
    );
    _sexController = TextEditingController(text: widget.profileData.sex);
    _donorController = TextEditingController(text: widget.profileData.donor);
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final updatedProfile = Profile(
        id: widget.profileData.id,
        name: _nameController.text.trim(),
        dob: _dobController.text.trim(),
        bloodtype: _bloodTypeController.text.trim(),
        sex: _sexController.text.trim(),
        donor: _donorController.text.trim(),
      );

      try {
        await DatabaseHelper.instance.updateProfile(updatedProfile);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        Navigator.pop(context, true); // Return true indicating a save happened
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _bloodTypeController.dispose();
    _sexController.dispose();
    _donorController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dobController.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = picked.toString().split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 110,
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
            'Edit Profile',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 35,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    filled: true,
                    fillColor: cs.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(width: 3.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        width: 3.0,
                        color: cs.outlineVariant,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(width: 3.0, color: cs.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dobController,
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    filled: true,
                    fillColor: cs.surfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(width: 3.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                        width: 3.0,
                        color: cs.outlineVariant,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(width: 3.0, color: cs.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    prefixIcon: const Icon(Icons.calendar_today),
                    suffixIcon: const Icon(Icons.edit_calendar_outlined),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Please select your DOB' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownMenu<String>(
                        initialSelection: _bloodTypeController.text.isEmpty
                            ? null
                            : _bloodTypeController.text,
                        label: const Text('Blood'),
                        leadingIcon: const Icon(Icons.water_drop, size: 20),
                        expandedInsets: EdgeInsets.zero,
                        menuHeight: 250,
                        textStyle: const TextStyle(fontSize: 14),
                        menuStyle: MenuStyle(
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        inputDecorationTheme: InputDecorationTheme(
                          labelStyle: const TextStyle(fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(width: 3.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              width: 3.0,
                              color: cs.outlineVariant,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              width: 3.0,
                              color: cs.primary,
                            ),
                          ),
                        ),
                        dropdownMenuEntries:
                            ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
                                .map(
                                  (t) => DropdownMenuEntry(value: t, label: t),
                                )
                                .toList(),
                        onSelected: (val) {
                          if (val != null) {
                            setState(() => _bloodTypeController.text = val);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownMenu<String>(
                        initialSelection: _sexController.text.isEmpty
                            ? null
                            : _sexController.text,
                        label: const Text('Sex'),
                        leadingIcon: const Icon(Icons.wc, size: 20),
                        expandedInsets: EdgeInsets.zero,
                        menuHeight: 200,
                        textStyle: const TextStyle(fontSize: 14),
                        menuStyle: MenuStyle(
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        inputDecorationTheme: InputDecorationTheme(
                          labelStyle: const TextStyle(fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(width: 3.0),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              width: 3.0,
                              color: cs.outlineVariant,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              width: 3.0,
                              color: cs.primary,
                            ),
                          ),
                        ),
                        dropdownMenuEntries: ['Male', 'Female', 'Other', 'N/A']
                            .map((s) => DropdownMenuEntry(value: s, label: s))
                            .toList(),
                        onSelected: (val) {
                          if (val != null) {
                            setState(() => _sexController.text = val);
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Organ Donor'),
                  subtitle: Text(
                    _donorController.text == 'Yes'
                        ? 'Yes, I am a donor'
                        : 'No, I am not a donor',
                  ),
                  secondary: Icon(
                    _donorController.text == 'Yes'
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: _donorController.text == 'Yes' ? Colors.red : null,
                  ),
                  value: _donorController.text == 'Yes',
                  onChanged: (bool value) {
                    setState(() {
                      _donorController.text = value ? 'Yes' : 'No';
                    });
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: cs.outlineVariant, width: 3.0),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _saveProfile,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
