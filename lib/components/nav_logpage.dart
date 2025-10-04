import 'package:flutter/material.dart';
import '../pages/planners_page.dart';
import '../pages/active_dashboard_page.dart';
import '../Mind_tools/dashboard_traker.dart';
import '../main.dart';

class NavLogPage extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget body;
  final int selectedIndex;
  final Function(int)? onNavigationTap;

  const NavLogPage({
    super.key,
    required this.title,
    required this.body,
    this.showBackButton = true,
    this.actions,
    this.selectedIndex = 2,
    this.onNavigationTap,
  });

  // Default navigation handler if none provided
  void _handleDefaultNavigation(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Navigate to HomePage
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
        break;
      case 1:
        // Navigate to PlannersPage
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const PlannersPage()),
          (route) => false,
        );
        break;
      case 2:
        // Navigate to ActiveDashboardPage
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ActiveDashboardPage()),
          (route) => false,
        );
        break;
      case 3:
        // Navigate to DashboardTrackerPage
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DashboardTrackerPage()),
          (route) => false,
        );
        break;
      case 4:
        // Navigate to ProfilePage
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
          (route) => false,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        toolbarHeight: 60,
        automaticallyImplyLeading: showBackButton,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: Image.asset('assets/logo.png', height: 32),
            ),
          ],
        ),
        centerTitle: true,
        actions: actions,
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          if (onNavigationTap != null) {
            onNavigationTap!(index);
          } else {
            _handleDefaultNavigation(context, index);
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Browse'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: '+'),
          BottomNavigationBarItem(
              icon: Icon(Icons.track_changes), label: 'Tracker'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        selectedItemColor: const Color(0xFF23C4F7),
        selectedLabelStyle: const TextStyle(color: Colors.black),
        unselectedItemColor: Colors.black,
      ),
    );
  }
}
