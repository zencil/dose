import 'package:flutter/material.dart';
import 'package:dose/pages/home_page.dart';
import 'package:dose/pages/analytics_page.dart';
import 'package:dose/pages/profile_page.dart';
import 'package:dose/pages/add_menu_page.dart';
import 'package:dose/models/medicine_category.dart';

class Dose extends StatefulWidget {
  const Dose({super.key});

  @override
  State<Dose> createState() => _DoseState();
}

class _DoseState extends State<Dose> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Key _homeKey = UniqueKey();
  MedicineCategory? _selectedCategoryForNewMed;

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
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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
        title: Padding(
          padding: const EdgeInsets.only(top: 70.0),
          child: Text(
            _getAppBarTitle(_selectedIndex),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 35,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        centerTitle: false,
        toolbarHeight: 130,

        automaticallyImplyLeading: false,
        actions: const [SizedBox.shrink()],
      ),
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width,
        child: AddMedicineMenu(
          initialCategory: _selectedCategoryForNewMed,
          onSave: () {
            setState(() {
              _homeKey = UniqueKey();
            });
          },
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showCategoryBottomSheet(context),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 1.0,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz_outlined),
              selectedIcon: Icon(Icons.more_horiz),
              label: 'More',
            ),
          ],
        ),
      ),
      body: _pages()[_selectedIndex],
    );
  }
}
