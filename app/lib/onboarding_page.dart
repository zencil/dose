import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/dose.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 4;

  // Profile fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String _selectedSex = 'Prefer not to say';
  final List<String> _sexOptions = [
    'Male',
    'Female',
    'Non-binary',
    'Prefer not to say',
  ];

  // Permission states
  bool _notificationGranted = false;
  bool _alarmGranted = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
    _ageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _requestPermissions() async {
    final notifStatus = await Permission.notification.request();
    final alarmStatus = await Permission.scheduleExactAlarm.request();
    await Permission.ignoreBatteryOptimizations.request();

    setState(() {
      _notificationGranted = notifStatus.isGranted;
      _alarmGranted = alarmStatus.isGranted;
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    // Save profile data
    await prefs.setString('user_name', _nameController.text.trim());
    await prefs.setString('user_age', _ageController.text.trim());
    await prefs.setString('user_sex', _selectedSex);

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const Dose()));
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
            // Progress indicator
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

            // Pages
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
                  _buildProfilePage(cs),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Screen 1: Welcome ──────────────────────────────────────────────

  Widget _buildWelcomePage(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 2),
          // App icon
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
          _buildNextButton(cs, 'Next'),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Screen 2: Introduction ─────────────────────────────────────────

  Widget _buildIntroPage(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
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
            'smart stock tracking, and insightful analytics — '
            'so you never miss a dose again.',
            style: TextStyle(
              fontSize: 15,
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const Spacer(flex: 3),
          _buildNextButton(cs, 'Next'),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Screen 3: Permissions ──────────────────────────────────────────

  Widget _buildPermissionsPage(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
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

          // Permission cards
          _buildPermissionCard(
            cs,
            icon: Icons.notifications_active_rounded,
            title: 'Notifications',
            subtitle: 'To remind you when it\'s time to take your medicine.',
            granted: _notificationGranted,
          ),
          const SizedBox(height: 12),
          _buildPermissionCard(
            cs,
            icon: Icons.alarm_rounded,
            title: 'Exact Alarms',
            subtitle: 'To trigger alarms at the exact scheduled time.',
            granted: _alarmGranted,
          ),

          const Spacer(flex: 2),

          // Grant / Continue button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              onPressed: (_notificationGranted && _alarmGranted)
                  ? _goToNextPage
                  : () async {
                      await _requestPermissions();
                    },
              icon: Icon(
                (_notificationGranted && _alarmGranted)
                    ? Icons.arrow_forward_rounded
                    : Icons.security_rounded,
              ),
              label: Text(
                (_notificationGranted && _alarmGranted) ? 'Continue' : 'Grant',
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
        ),
      ),
      color: granted
          ? cs.primaryContainer.withValues(alpha: 0.3)
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

  // ── Screen 4: Profile Setup ────────────────────────────────────────

  Widget _buildProfilePage(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 48),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_rounded,
                size: 48,
                color: cs.onTertiaryContainer,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Set Up Your Profile',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us a little about yourself.',
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 36),

            // Name field
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'Enter your name',
                prefixIcon: const Icon(Icons.badge_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: cs.surfaceContainer,
              ),
            ),
            const SizedBox(height: 16),

            // Age field
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Age',
                hintText: 'Enter your age',
                prefixIcon: const Icon(Icons.cake_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: cs.surfaceContainer,
              ),
            ),
            const SizedBox(height: 16),

            // Sex dropdown
            DropdownButtonFormField<String>(
              initialValue: _selectedSex,
              decoration: InputDecoration(
                labelText: 'Sex',
                prefixIcon: const Icon(Icons.wc_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: cs.surfaceContainer,
              ),
              items: _sexOptions.map((option) {
                return DropdownMenuItem(value: option, child: Text(option));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSex = value);
                }
              },
            ),
            const SizedBox(height: 48),

            // Jump In button
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

  // ── Helpers ─────────────────────────────────────────────────────────

  bool get _isProfileValid =>
      _nameController.text.trim().isNotEmpty &&
      _ageController.text.trim().isNotEmpty;

  Widget _buildNextButton(ColorScheme cs, String label) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: _goToNextPage,
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
