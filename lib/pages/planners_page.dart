import 'package:flutter/material.dart';
import 'vision_board_page.dart'; // Import your VisionBoardPage
// Import other planner pages as needed

class PlannersPage extends StatelessWidget {
  const PlannersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planners'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.dashboard_customize),
            title: const Text('Vision Board Templates'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VisionBoardPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('2024 Annual Planner'),
            onTap: () {
              // Navigate to Annual Planner page
            },
          ),
          ListTile(
            leading: const Icon(Icons.view_week),
            title: const Text('2024 Weekly Planner'),
            onTap: () {
              // Navigate to Weekly Planner page
            },
          ),
          ListTile(
            leading: const Icon(Icons.checklist),
            title: const Text('2024 Daily To Do List'),
            onTap: () {
              // Navigate to Daily To Do List page
            },
          ),
        ],
      ),
    );
  }
}
