import 'package:flutter/material.dart';
import 'vision_board_page.dart';
import '../Annual_calender/annual_calendar_page.dart';
import '../Annual_planner/annual_planner_page.dart';
import '../weekly_planners/weekly_planner_page.dart';
import '../Mind_tools/thought_shredder_page.dart';
import '../Mind_tools/bubble_wrap_popper_page.dart';
import '../Mind_tools/break_things_page.dart';
import '../Mind_tools/make_me_smile_page.dart';
import '../Activity_Tools/memory_game_page.dart';
import '../Activity_Tools/riddle_quiz_page.dart';
import '../Activity_Tools/color_me_now.dart';
import '../Activity_Tools/sliding_puzzle_page.dart';
import '../Daily_notes/daily_notes_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/subscription_manager.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

// Key for checking premium status
const String _hasCompletedPaymentKey = 'has_completed_payment';

class PlannersPage extends StatefulWidget {
  const PlannersPage({super.key});

  @override
  State<PlannersPage> createState() => _PlannersPageState();
}

class _PlannersPageState extends State<PlannersPage> {
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadPremiumStatus();
  }

  Future<void> _loadPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedPayment =
          prefs.getBool(_hasCompletedPaymentKey) ?? false;
      final premiumFeaturesEnabled =
          prefs.getBool('premium_features_enabled') ?? false;

      // Check if we have an active trial through the subscription manager
      final subscriptionManager = SubscriptionManager();
      final hasAccess = await subscriptionManager.hasAccess();

      debugPrint('PlannersPage - Premium status check:');
      debugPrint('- hasCompletedPayment: $hasCompletedPayment');
      debugPrint('- premiumFeaturesEnabled: $premiumFeaturesEnabled');
      debugPrint('- hasAccess from SubscriptionManager: $hasAccess');

      if (mounted) {
        setState(() {
          // User has premium access if any of these flags are true
          _isPremium =
              hasCompletedPayment || premiumFeaturesEnabled || hasAccess;
        });
      }

      // If local flags don't match subscription manager status, update them
      if (hasAccess && (!hasCompletedPayment || !premiumFeaturesEnabled)) {
        debugPrint('Updating local premium flags to match subscription status');
        await prefs.setBool(_hasCompletedPaymentKey, true);
        await prefs.setBool('premium_features_enabled', true);
        await prefs.setBool('is_subscribed', true);

        if (mounted) {
          setState(() {
            _isPremium = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking premium status in PlannersPage: $e');
      // On error, fall back to basic local check
      final prefs = await SharedPreferences.getInstance();
      final isPremium = prefs.getBool(_hasCompletedPaymentKey) ?? false;

      if (mounted) {
        setState(() {
          _isPremium = isPremium;
        });
      }
    }
  }

  // Check if a tool should be locked (free vs premium)
  bool _isToolLocked(String toolType, String toolName) {
    if (_isPremium) return false; // Premium users get access to everything

    // For free users, only allow basic templates
    if (toolType == 'Planner') {
      if (toolName == 'Vision Board Templates' ||
          toolName == '2025 calender Planner' ||
          toolName == '2025 Annual Planner' ||
          toolName == '2025 weakly Planner' ||
          toolName == 'Daily Notes') {
        return false;
      }
    }

    // All Mind Tools and Activity Tools require premium
    return true;
  }

  // Method to show payment page directly like profile page
  Future<void> _showPaymentPage() async {
    final email =
        Provider.of<AuthService>(context, listen: false).userData?['email'] ??
            AuthService.instance.currentUser?.email ??
            'user@example.com';

    // Use SubscriptionManager to handle the complete payment flow
    final subscriptionManager = SubscriptionManager();
    await subscriptionManager.startSubscriptionFlow(context, email: email);

    // After subscription flow, reload premium status
    await _loadPremiumStatus();
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Premium Feature'),
          content: Text('This feature is only available for premium users. '
              'Upgrade to premium to unlock all features.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Call the direct payment method
                _showPaymentPage();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text('Upgrade'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planners'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildPlannerTile(
            context: context,
            icon: Icons.dashboard_customize,
            title: 'Vision Board Templates',
            page: const VisionBoardPage(),
            toolType: 'Planner',
          ),
          _buildPlannerTile(
            context: context,
            icon: Icons.calendar_today,
            title: '2025 calender Planner',
            page: const AnnualCalenderPage(),
            toolType: 'Planner',
          ),
          _buildPlannerTile(
            context: context,
            icon: Icons.list,
            title: '2025 Annual Planner',
            page: const AnnualPlannerPage(),
            toolType: 'Planner',
          ),
          _buildPlannerTile(
            context: context,
            icon: Icons.view_week,
            title: '2025 weakly Planner',
            page: const WeeklyPlannerPage(),
            toolType: 'Planner',
          ),
          _buildPlannerTile(
            context: context,
            icon: Icons.note,
            title: 'Daily Notes',
            page: const DailyNotesPage(),
            toolType: 'Planner',
          ),
          const Divider(height: 32, thickness: 1),
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
            child: Text(
              'Mind Tools',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildPlannerTile(
            context: context,
            icon: Icons.delete_outline,
            title: 'Thoughtshredder',
            page: const ThoughtShredderPage(),
            toolType: 'MindTool',
          ),
          _buildPlannerTile(
            context: context,
            icon: Icons.mood,
            title: 'Make-me-smile',
            page: const MakeMeSmilePage(),
            toolType: 'MindTool',
          ),
          _buildPlannerTile(
            context: context,
            icon: Icons.bubble_chart,
            title: 'Bubble-wrap-popper',
            page: const BubbleWrapPopperPage(),
            toolType: 'MindTool',
          ),
          _buildPlannerTile(
            context: context,
            icon: Icons.broken_image,
            title: 'Break-things',
            page: const BreakThingsPage(),
            toolType: 'MindTool',
          ),
          const Divider(height: 32, thickness: 1),
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
            child: Text(
              'Activity Tools',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildPlannerTile(
            context: context,
            icon: Icons.quiz,
            title: 'Riddle Quiz',
            page: const RiddleQuizPage(),
            toolType: 'ActivityTool',
          ),
          _buildPlannerTile(
            context: context,
            icon: Icons.memory,
            title: 'Memory Game',
            page: const MemoryGamePage(),
            toolType: 'ActivityTool',
          ),
          _buildPlannerTile(
            context: context,
            icon: Icons.palette,
            title: 'Color Me Now',
            page: const ColorMeNowPage(),
            toolType: 'ActivityTool',
          ),
          _buildPlannerTile(
            context: context,
            icon: Icons.grid_3x3,
            title: 'Sliding Puzzle',
            page: const SlidingPuzzlePage(),
            toolType: 'ActivityTool',
          ),
        ],
      ),
    );
  }

  Widget _buildPlannerTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget page,
    required String toolType,
    String? subtitle,
  }) {
    final bool isLocked = _isToolLocked(toolType, title);

    return ListTile(
      leading: Icon(
        icon,
        color: isLocked ? Colors.grey : null,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isLocked ? Colors.grey : null,
              ),
            ),
          ),
          if (isLocked)
            Icon(
              Icons.lock,
              size: 16,
              color: Colors.grey,
            ),
        ],
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: isLocked ? Colors.grey.shade400 : null,
              ),
            )
          : null,
      onTap: () {
        if (isLocked) {
          _showPremiumDialog(context);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => page,
            ),
          );
        }
      },
    );
  }
}
