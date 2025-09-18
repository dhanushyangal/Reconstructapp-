import 'package:flutter/material.dart';

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
        onTap: onNavigationTap,
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
