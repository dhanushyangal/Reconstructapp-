import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/subscription_manager.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/activity_tracker_mixin.dart';
import 'life_areas_selection_page.dart';

// Key for checking premium status
const String _hasCompletedPaymentKey = 'has_completed_payment';

class VisionBoardTemplateSelectionPage extends StatefulWidget {
  const VisionBoardTemplateSelectionPage({super.key});

  @override
  State<VisionBoardTemplateSelectionPage> createState() => _VisionBoardTemplateSelectionPageState();
}

class _VisionBoardTemplateSelectionPageState extends State<VisionBoardTemplateSelectionPage>
    with ActivityTrackerMixin, TickerProviderStateMixin {
  bool _isPremium = false;
  bool _isLoading = true;
  AnimationController? _progressAnimationController;
  Animation<double>? _progressAnimation;

  String get pageName => 'Vision Board Templates';

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
      end: 0.33, // 33% progress for step 1
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

      debugPrint('VisionBoardTemplateSelectionPage - Premium status check:');
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
      debugPrint('Error checking premium status in VisionBoardTemplateSelectionPage: $e');
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

    // Only Boxy theme is free
    return title != 'Boxy theme board';
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
        // Navigate to life areas selection page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LifeAreasSelectionPage(
              template: title,
              imagePath: imagePath,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // Image section - takes up most of the card
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                // Title section - smaller portion at bottom
                Expanded(
                  flex: 1,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Center(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isLocked ? Colors.grey : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (isLocked)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
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
        title: const Text('Choose a theme for your annual goals board'),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 30),
          // Templates grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                mainAxisSpacing: 20,
                crossAxisSpacing: 20,
                children: [
                  _buildTemplateCard(
                    context,
                    'assets\Plan_your_annual_goals-images\Annual-boxy.png',
                    'Boxy theme board'),
                  _buildTemplateCard(
                    context,
                    'assets\Plan_your_annual_goals-images\Annual-post.png',
                    'Post it theme board'),
                  _buildTemplateCard(context, 
                  'assets\Plan_your_annual_goals-images\Annual-premium.png',
                      'Premium black board'),
                  _buildTemplateCard(
                    context,
                    'assets\Plan_your_annual_goals-images\Annual-floral.png',
                    'Floral theme board'),
                ],
              ),
            ),
          ),
          // Progress bar at the bottom
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF8FBFF),
                  Colors.white,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Template Selection Progress',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _progressAnimation ?? const AlwaysStoppedAnimation(0.0),
                      builder: (context, child) {
                        return Text(
                          '${((_progressAnimation?.value ?? 0.0) * 100).toInt()}% Complete',
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
                SizedBox(height: 12),
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.grey[200],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}