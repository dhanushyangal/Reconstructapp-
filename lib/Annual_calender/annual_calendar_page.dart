import 'package:flutter/material.dart';
import 'animal_theme_annual_planner.dart';
import 'summer_theme_annual_planner.dart';
import 'spaniel_theme_annual_planner.dart';
import 'happy_couple_theme_annual_planner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/subscription_manager.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/activity_tracker_mixin.dart';

// Key for checking premium status
const String _hasCompletedPaymentKey = 'has_completed_payment';

class AnnualCalenderPage extends StatefulWidget {
  const AnnualCalenderPage({super.key});

  @override
  State<AnnualCalenderPage> createState() => _AnnualCalenderPageState();
}

class _AnnualCalenderPageState extends State<AnnualCalenderPage>
    with ActivityTrackerMixin {
  bool _isPremium = false;
  bool _isLoading = true;

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

      debugPrint('AnnualCalendarPage - Premium status check:');
      debugPrint('- hasCompletedPayment: $hasCompletedPayment');
      debugPrint('- premiumFeaturesEnabled: $premiumFeaturesEnabled');
      debugPrint('- hasAccess from SubscriptionManager: $hasAccess');

      if (mounted) {
        setState(() {
          // User has premium access if any of these flags are true
          _isPremium =
              hasCompletedPayment || premiumFeaturesEnabled || hasAccess;
          _isLoading = false;
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
      debugPrint('Error checking premium status in AnnualCalendarPage: $e');
      // On error, fall back to basic local check
      final prefs = await SharedPreferences.getInstance();
      final isPremium = prefs.getBool(_hasCompletedPaymentKey) ?? false;

      if (mounted) {
        setState(() {
          _isPremium = isPremium;
          _isLoading = false;
        });
      }
    }
  }

  // Check if a template should be locked (free vs premium)
  bool _isTemplateLocked(String title) {
    if (_isPremium) return false; // Premium users get access to everything

    // Only Animal theme is free
    return title != 'Animal theme 2025 Calendar';
  }

  // Method to show payment page directly like profile page
  Future<void> _showPaymentPage() async {
    trackClick('annual_calendar_payment_page_opened');

    final email =
        Provider.of<AuthService>(context, listen: false).userData?['email'] ??
            AuthService.instance.currentUser?.email ??
            'user@example.com';

    // Use SubscriptionManager to handle the complete payment flow
    final subscriptionManager = SubscriptionManager();
    await subscriptionManager.startSubscriptionFlow(context, email: email);

    // Update premium status based on subscription status
    final isPremium = await subscriptionManager.isSubscribed();
    if (isPremium) {
      trackClick('annual_calendar_premium_upgraded');
      setState(() {
        _isPremium = true;
        _isLoading = false;
      });
    }
  }

  void _showPremiumDialog(BuildContext context) {
    final bool isGuest = AuthService.isGuest;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isGuest ? 'Sign In Required' : 'Premium Feature'),
          content: Text(isGuest 
            ? 'This template requires you to sign in or create an account. '
              'Sign in to save your progress and access all templates.'
            : 'This template is only available for premium users. '
              'Upgrade to premium to unlock all templates.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (isGuest) {
                  // Navigate to login page for guest users
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                } else {
                  // Call the direct payment method for regular users
                  _showPaymentPage();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isGuest ? Colors.orange : Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(isGuest ? 'Sign In' : 'Upgrade'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTemplateCard(
      BuildContext context, String imagePath, String title) {
    final bool isLocked = _isTemplateLocked(title);

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          trackClick('annual_calendar_premium_template_clicked - $title');
          _showPremiumDialog(context);
          return;
        }
        trackClick('$title content');
        if (title == 'Animal theme 2025 Calendar') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AnimalThemeCalendarApp(monthIndex: 0, eventId: null),
            ),
          );
        } else if (title == 'Summer theme 2025 Calendar') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SummerThemeCalendarApp(
                monthIndex: 0,
                eventId: null,
                showEvents: false,
              ),
            ),
          );
        } else if (title == 'Spanish theme 2025 Calendar') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SpanielThemeCalendarApp(
                monthIndex: 0,
                eventId: null,
                showEvents: false,
              ),
            ),
          );
        } else if (title == 'Happy Couple theme 2025 Calendar') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HappyCoupleThemeCalendarApp(
                monthIndex: 0,
                eventId: null,
                showEvents: false,
              ),
            ),
          );
        }
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isLocked ? Colors.grey : null,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
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
                ),
              ],
            ),
            if (isLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withOpacity(0.3),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.lock,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Annual Calendar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Annual Calendar Templates for 2025',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Colorcode dates and create your own custom 2025 calendar. Choose from stunning templates to track the months. ${_isPremium ? 'Access all premium templates.' : 'Upgrade to premium to unlock all templates.'}',
              style: const TextStyle(fontSize: 18, height: 1.5),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                children: [
                  _buildTemplateCard(
                      context,
                      'assets/animal_theme_calendar.png',
                      'Animal theme 2025 Calendar'),
                  _buildTemplateCard(
                      context,
                      'assets/summer_theme_calendar.png',
                      'Summer theme 2025 Calendar'),
                  _buildTemplateCard(
                      context,
                      'assets/spaniel_theme_calendar.png',
                      'Spanish theme 2025 Calendar'),
                  _buildTemplateCard(
                      context,
                      'assets/happy_couple_theme_calendar.png',
                      'Happy Couple theme 2025 Calendar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
