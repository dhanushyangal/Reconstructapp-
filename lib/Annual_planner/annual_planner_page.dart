import 'package:flutter/material.dart';
import 'postit_theme_annual_planner.dart';
import 'premium_theme_annual_planner.dart';
import 'watercolor_theme_annual_planner.dart';
import 'floral_theme_annual_planner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/subscription_manager.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/activity_tracker_mixin.dart';

// Key for checking premium status
const String _hasCompletedPaymentKey = 'has_completed_payment';

class AnnualPlannerPage extends StatefulWidget {
  const AnnualPlannerPage({super.key});

  @override
  State<AnnualPlannerPage> createState() => _AnnualPlannerPageState();
}

class _AnnualPlannerPageState extends State<AnnualPlannerPage>
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

      debugPrint('AnnualPlannerPage - Premium status check:');
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
      debugPrint('Error checking premium status in AnnualPlannerPage: $e');
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

    // Only Watercolor theme is free
    return title != 'Watercolor them 2025 Planner';
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

    // Update premium status based on subscription status
    final isPremium = await subscriptionManager.isSubscribed();
    if (isPremium) {
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
          _showPremiumDialog(context);
          return;
        }

        if (title == 'PostIt theme 2025 Planner') {
          trackClick('$title content');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostItThemeAnnualPlanner(
                monthIndex: 0,
                eventId: null,
                showEvents: false,
              ),
            ),
          );
        } else if (title == 'Watercolor them 2025 Planner') {
          trackClick('$title content');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WatercolorThemeAnnualPlanner(
                monthIndex: 0,
                eventId: null,
                showEvents: false,
              ),
            ),
          );
        } else if (title == 'Floral theme 2025 Planner') {
          trackClick('$title content');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FloralThemeAnnualPlanner(
                monthIndex: 0,
                eventId: null,
                showEvents: false,
              ),
            ),
          );
        } else if (title == 'Premium theme 2025 Planner') {
          trackClick('$title content');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PremiumThemeAnnualPlanner(
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
        title: const Text('Annual Planner'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Interactive Annual Planner Templates',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your own custom annual calendar. Choose from stunning templates to organize your year. ${_isPremium ? 'Access all premium templates.' : 'Upgrade to premium to unlock all templates.'}',
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
                    'assets/watercolor_theme_annual_planner.png',
                    'Watercolor them 2025 Planner',
                  ),
                  _buildTemplateCard(
                    context,
                    'assets/postit_theme_annual_planner.png',
                    'PostIt theme 2025 Planner',
                  ),
                  _buildTemplateCard(
                    context,
                    'assets/floral_theme_annual_planner.png',
                    'Floral theme 2025 Planner',
                  ),
                  _buildTemplateCard(
                    context,
                    'assets/premium_theme_annual_planner.png',
                    'Premium theme 2025 Planner',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
