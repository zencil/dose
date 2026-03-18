import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dose/dose.dart';
import 'package:dose/models/profile_model.dart';
import 'package:dose/db/profile_db.dart';
import 'package:dose/services/backup_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 5;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _bloodTypeController = TextEditingController();
  final TextEditingController _sexController = TextEditingController();
  final TextEditingController _donorController = TextEditingController(
    text: 'No',
  );
  bool _notificationGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final notifStatus = await Permission.notification.status;
    setState(() {
      _notificationGranted = notifStatus.isGranted;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _dobController.dispose();
    _bloodTypeController.dispose();
    _sexController.dispose();
    _donorController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();
    await Permission.ignoreBatteryOptimizations.request();

    if (!mounted) return;

    setState(() {
      _notificationGranted = status.isGranted;
    });

    if (!_notificationGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please grant notification permission to continue. If the popup doesn\'t appear, check app settings.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _completeOnboarding() async {
    final newProfile = Profile(
      name: _nameController.text.trim(),
      dob: _dobController.text.trim(),
      bloodtype: _bloodTypeController.text.trim(),
      sex: _sexController.text.trim(),
      donor: _donorController.text.trim(),
    );

    try {
      await DatabaseHelper.instance.createprof(newProfile);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_onboarding', true);

      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const Dose()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    }
  }

  bool get _isProfileValid =>
      _nameController.text.trim().isNotEmpty &&
      _dobController.text.trim().isNotEmpty &&
      _bloodTypeController.text.trim().isNotEmpty &&
      _sexController.text.trim().isNotEmpty &&
      _donorController.text.trim().isNotEmpty;

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
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: List.generate(_totalPages, (i) {
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      height: 4,
                      margin: EdgeInsets.only(
                        right: i < _totalPages - 1 ? 6 : 0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: i <= _currentPage
                            ? cs.primary
                            : cs.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildWelcomePage(cs),
                  _buildIntroPage(cs),
                  _buildPermissionsPage(cs),
                  _buildImportPage(cs),
                  _buildProfilePage(cs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomePage(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medication_rounded,
              size: 60,
              color: cs.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Welcome to Dose',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your personal medicine companion',
            style: TextStyle(fontSize: 16, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 3),
          _buildActionButton(cs, 'Next', _goToNextPage),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildIntroPage(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: cs.tertiaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 56,
              color: cs.onTertiaryContainer,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Optimized Medicine\nManagement',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Dose helps you stay on track with timely reminders, '
            'smart stock tracking, and insightful analytics.',
            style: TextStyle(
              fontSize: 15,
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 3),
          _buildActionButton(cs, 'Next', _goToNextPage),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPermissionsPage(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Spacer(flex: 1),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_outlined,
              size: 48,
              color: cs.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Permissions',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Dose needs a few permissions to work properly.',
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          _buildPermissionCard(
            cs,
            icon: Icons.notifications_active_rounded,
            title: 'Notifications',
            subtitle: 'To remind you when it\'s time to take your medicine.',
            granted: _notificationGranted,
          ),

          const Spacer(flex: 2),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: _notificationGranted
                  ? _goToNextPage
                  : _requestPermissions,
              icon: Icon(
                _notificationGranted
                    ? Icons.arrow_forward_rounded
                    : Icons.security_rounded,
              ),
              label: Text(
                _notificationGranted ? 'Continue' : 'Grant',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(
    ColorScheme cs, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool granted,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: granted
              ? cs.primary.withValues(alpha: 0.5)
              : cs.outlineVariant,
          width: 3.0,
        ),
      ),
      color: granted
          ? cs.primaryContainer.withValues(alpha: 0.1)
          : cs.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: granted ? cs.primaryContainer : cs.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: granted
                    ? cs.onPrimaryContainer
                    : cs.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (granted)
              Icon(Icons.check_circle_rounded, color: cs.primary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildImportPage(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: cs.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_download_rounded,
              size: 48,
              color: cs.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Returning User?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'If you have a previous backup, you can restore your medicines, history, and profile data.',
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton.icon(
              onPressed: _handleImport,
              icon: const Icon(Icons.file_upload_outlined),
              label: const Text(
                'Import Backup',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.outlineVariant, width: 3.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const Spacer(flex: 3),
          _buildActionButton(cs, 'Start Fresh', _goToNextPage),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _handleImport() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Restoring data...')));
        }

        await BackupService.instance.importData(result.files.single.path!);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data restored successfully!')),
          );
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('has_completed_onboarding', true);

          if (mounted) {
            Navigator.of(
              context,
            ).pushReplacement(MaterialPageRoute(builder: (_) => const Dose()));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }

  Widget _buildProfilePage(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                size: 40,
                color: cs.onTertiaryContainer,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Profile Setup',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 24),

            _buildTextField(cs, _nameController, 'Name', Icons.badge_outlined),
            const SizedBox(height: 12),
            _buildTextField(
              cs,
              _dobController,
              'Date of Birth',
              Icons.calendar_today_outlined,
              readOnly: true,
              onTap: _selectDate,
              suffixIcon: const Icon(Icons.edit_calendar_outlined, size: 20),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDropdownField(
                    cs,
                    controller: _bloodTypeController,
                    label: 'Blood',
                    icon: Icons.water_drop_outlined,
                    items: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
                    horizontalPadding: 12,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDropdownField(
                    cs,
                    controller: _sexController,
                    label: 'Sex',
                    icon: Icons.wc_outlined,
                    items: ['Male', 'Female', 'Other', 'N/A'],
                    horizontalPadding: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            _buildSwitchField(
              cs,
              controller: _donorController,
              label: 'Organ Donor',
              icon: Icons.favorite_border_rounded,
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: _isProfileValid ? _completeOnboarding : null,
                icon: const Icon(Icons.rocket_launch_rounded),
                label: const Text(
                  'Jump In!',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    ColorScheme cs,
    TextEditingController controller,
    String label,
    IconData icon, {
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: suffixIcon,
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
        filled: true,
        fillColor: cs.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    ColorScheme cs, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> items,
    double horizontalPadding = 20,
  }) {
    return DropdownMenu<String>(
      initialSelection: controller.text.isEmpty ? null : controller.text,
      label: Text(label, style: const TextStyle(fontSize: 14)),
      leadingIcon: Icon(icon, size: 20),
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
        filled: true,
        fillColor: cs.surfaceContainer,
        contentPadding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: 16,
        ),
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
      ),
      dropdownMenuEntries: items.map((t) {
        return DropdownMenuEntry<String>(value: t, label: t);
      }).toList(),
      onSelected: (val) {
        if (val != null) {
          setState(() => controller.text = val);
        }
      },
    );
  }

  Widget _buildSwitchField(
    ColorScheme cs, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant, width: 3.0),
      ),
      color: cs.surfaceContainer,
      child: SwitchListTile(
        title: Text(label, style: const TextStyle(fontSize: 16)),
        subtitle: Text(
          controller.text == 'Yes'
              ? 'Yes, I am a donor'
              : 'No, I am not a donor',
          style: const TextStyle(fontSize: 12),
        ),
        secondary: Icon(
          icon,
          color: controller.text == 'Yes' ? Colors.red : cs.onSurfaceVariant,
        ),
        value: controller.text == 'Yes',
        onChanged: (bool value) {
          setState(() {
            controller.text = value ? 'Yes' : 'No';
          });
        },
      ),
    );
  }

  Widget _buildActionButton(
    ColorScheme cs,
    String label,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
