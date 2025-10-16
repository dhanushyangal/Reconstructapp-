import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/subscription_manager.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../utils/activity_tracker_mixin.dart';
import '../../components/nav_logpage.dart';
import 'weekly_life_areas_selection_page.dart';

// Key for checking premium status
const String _hasCompletedPaymentKey = 'has_completed_payment';

class WeeklyPlannerTemplateSelectionPage extends StatefulWidget {
  const WeeklyPlannerTemplateSelectionPage({super.key});

  @override
  State<WeeklyPlannerTemplateSelectionPage> createState() => _WeeklyPlannerTemplateSelectionPageState();
}

class _WeeklyPlannerTemplateSelectionPageState extends State<WeeklyPlannerTemplateSelectionPage>
    with ActivityTrackerMixin, TickerProviderStateMixin {
  bool _isPremium = false;
  bool _isLoading = true;
  AnimationController? _progressAnimationController;
  Animation<double>? _progressAnimation;

  String get pageName => 'Weekly Planner Templates';

  @override
  void initState() {
    super.initState();
    
    // Initialize progress animation
    _progressAnimationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 0.50, // 50% progress for step 2
    ).animate(CurvedAnimation(
      parent: _progressAnimationController!,
      curve: Curves.easeInOut,
    ));
    
    // Start the animation
    _progressAnimationController!.forward();
    
    _loadPremiumStatus();
  }

  @override
  void dispose() {
    _progressAnimationController?.dispose();
    super.dispose();
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

      debugPrint('WeeklyPlannerTemplateSelectionPage - Premium status check:');
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
      debugPrint('Error checking premium status in WeeklyPlannerTemplateSelectionPage: $e');
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

    // Only Floral theme is free
    return title != 'Floral Weekly Planner';
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

  Widget _buildTemplateCard(BuildContext context, String imagePath, String title) {
    final bool isLocked = _isTemplateLocked(title);

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          _showPremiumDialog(context);
          return;
        }
        trackClick('$title template');
        _navigateToTemplate(title);
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported,
                            size: 60,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    ),
                  ),
                  if (isLocked)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          color: Colors.black.withOpacity(0.3),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                ],
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
                        color: isLocked ? Colors.grey : Colors.black,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToTemplate(String template) {
    String imagePath;
    switch (template) {
      case 'Floral Weekly Planner':
        imagePath = 'assets/Plan_your_weekly_goals-images/floral.png';
        break;
      case 'Watercolor Weekly Planner':
        imagePath = 'assets/Plan_your_weekly_goals-images/watercolor.png';
        break;
      case 'Patterns Weekly Planner':
        imagePath = 'assets/Plan_your_weekly_goals-images/post.png';
        break;
      case 'Japanese Weekly Planner':
        imagePath = 'assets/Plan_your_weekly_goals-images/japanese.png';
        break;
      default:
        imagePath = 'assets/Plan_your_weekly_goals-images/floral.png';
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WeeklyLifeAreasSelectionPage(
          template: template,
          imagePath: imagePath,
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

    return NavLogPage(
      title: 'Choose a theme for your weekly goals planner',
      showBackButton: false,
      selectedIndex: 2, // Dashboard index
      // Using default navigation handler from NavLogPage
      body: Column(
        children: [
          // Progress bar at the top
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: AnimatedBuilder(
                        animation: _progressAnimation ?? const AlwaysStoppedAnimation(0.0),
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: _progressAnimation?.value ?? 0.0,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF23C4F7)),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                AnimatedBuilder(
                  animation: _progressAnimation ?? const AlwaysStoppedAnimation(0.0),
                  builder: (context, child) {
                    return Text(
                      '${((_progressAnimation?.value ?? 0.0) * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF23C4F7),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Main title with better spacing
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: Text(
              'Choose a theme for your weekly goals planner',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                height: 1.0,
              ),
              textAlign: TextAlign.left,
            ),
          ),
          
          // Templates grid with better spacing
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 0),
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                mainAxisSpacing: 12,
                crossAxisSpacing: 16,
                children: [
                  _buildTemplateCard(
                    context,
                    'assets/Plan_your_weekly_goals-images/floral.png',
                    'Floral Weekly Planner'),
                  _buildTemplateCard(
                    context,
                    'assets/Plan_your_weekly_goals-images/watercolor.png',
                    'Watercolor Weekly Planner'),
                  _buildTemplateCard(context, 
                  'assets/Plan_your_weekly_goals-images/post.png',
                      'Patterns Weekly Planner'),
                  _buildTemplateCard(
                    context,
                    'assets/Plan_your_weekly_goals-images/japanese.png',
                    'Japanese Weekly Planner'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
