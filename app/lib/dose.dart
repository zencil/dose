import 'package:flutter/material.dart';
import 'package:app/home/home.dart';
import 'package:app/analytics/analytics.dart';
import 'package:app/profile/profile.dart';
import 'package:app/home/addMedicineMenu.dart';
class Dose extends StatefulWidget {
  const Dose({super.key});

  @override
  State<Dose> createState() => _DoseState();
}

class _DoseState extends State<Dose> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  Key _homeKey = UniqueKey();

  List<Widget> _pages() => [
    HomePage(key: _homeKey),
    const AnalyticsPage(),
    const ProfilePage(),
  ];

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return "Dose";
      case 1:
        return "Analytics";
      case 2: 
        final hour = DateTime.now().hour;
        if (hour < 12) {
          return "Good Morning";
        } else if (hour < 17) {
          return "Good Afternoon";
        } else {
          return "Good Evening";
        }
      default:
        return "Dose";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          _getAppBarTitle(_selectedIndex),
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 40, 
            color: Theme.of(context).colorScheme.primary, 
          ),
        ),
        centerTitle: false,
        toolbarHeight: 110, 
        
        automaticallyImplyLeading: false, 
        actions: const [
          SizedBox.shrink(), 
        ], 
      ),
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width,
        child: AddMedicineMenu(
          onSave: () {
            setState(() {
              _homeKey = UniqueKey();
            });
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