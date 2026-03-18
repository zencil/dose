import 'package:flutter/material.dart';
import 'package:dose/pages/cabinet_page.dart';
import 'package:dose/pages/about_page.dart';
import 'package:dose/pages/settings_page.dart';
import 'package:dose/pages/profile_details_page.dart';
import 'package:dose/pages/history_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 48),
            _buildOutlinedButton(
              context: context,
              label: 'Profile',
              icon: Icons.person_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileDetailsPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildOutlinedButton(
              context: context,
              label: 'Cabinet',
              icon: Icons.medication_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CabinetPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildOutlinedButton(
              context: context,
              label: 'History',
              icon: Icons.history,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildOutlinedButton(
              context: context,
              label: 'Settings',
              icon: Icons.settings_outlined,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildOutlinedButton(
              context: context,
              label: 'About',
              icon: Icons.info_outline,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlinedButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 3.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
