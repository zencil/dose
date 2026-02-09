import 'package:flutter/material.dart';
import 'package:app/home/home.dart';
import 'package:app/analytics/analytics.dart';
import 'package:app/profile/profile.dart';
import 'package:app/home/add_menu.dart';

class Dose extends StatefulWidget {
  const Dose({super.key});

  @override
  State<Dose> createState() => _DoseState();
}

class _DoseState extends State<Dose> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> _pages() => [
    const HomePage(),
    const AnalyticsPage(), 
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text("Dose", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32)),
        centerTitle: false,
        toolbarHeight: 80,
      ),
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width, 
        child: AddMedicineMenu(
          onSave: () {
            setState(() {});
          },
        ),
      ),
      floatingActionButton: _selectedIndex == 0 
          ? FloatingActionButton(
              onPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
      body: _pages()[_selectedIndex],
    );
  }
}