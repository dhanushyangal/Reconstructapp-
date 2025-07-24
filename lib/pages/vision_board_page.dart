import 'package:flutter/material.dart';
import 'box_them_vision_board.dart';
import 'post_it_theme_vision_board.dart';
import 'premium_them_vision_board.dart';
import 'winter_warmth_theme_vision_board.dart';
import 'ruby_reds_theme_vision_board.dart';
import 'coffee_hues_theme_vision_board.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/subscription_manager.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/activity_tracker_mixin.dart';

// Key for checking premium status
const String _hasCompletedPaymentKey = 'has_completed_payment';

class VisionBoardPage extends StatefulWidget {
  const VisionBoardPage({super.key});

  @override
  State<VisionBoardPage> createState() => _VisionBoardPageState();
}

class _VisionBoardPageState extends State<VisionBoardPage>
    with ActivityTrackerMixin {
  bool _isPremium = false;
  bool _isLoading = true;

  @override
  String get pageName => 'Vision Board';

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

      debugPrint('VisionBoardPage - Premium status check:');
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
      debugPrint('Error checking premium status in VisionBoardPage: $e');
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

    // Only Box theme is free
    return title != 'Box theme Vision Board';
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
    // Check if user is in guest mode
    if (AuthService.isGuest) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Sign In Required'),
            content: const Text('This feature requires you to sign in to your account. '
                'Please sign in to access all templates and save your progress.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to login page
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Sign In'),
              ),
            ],
          );
        },
      );
      return;
    }

    // Show regular premium dialog for authenticated users
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Premium Feature'),
          content:
              const Text('This template is only available for premium users. '
                  'Upgrade to premium to unlock all templates.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
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
              child: const Text('Upgrade'),
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
        trackClick('$title content');
        if (title == 'Premium theme Vision Board') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PremiumThemeVisionBoard(),
            ),
          );
        } else if (title == 'PostIt theme Vision Board') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PostItThemeVisionBoard(),
            ),
          );
        } else if (title == 'Winter Warmth theme Vision Board') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WinterWarmthThemeVisionBoard(),
            ),
          );
        } else if (title == 'Ruby Reds theme Vision Board') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RubyRedsThemeVisionBoard(),
            ),
          );
        } else if (title == 'Coffee Hues theme Vision Board') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CoffeeHuesThemeVisionBoard(),
            ),
          );
        } else if (title == 'Box theme Vision Board') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VisionBoardDetailsPage(title: title),
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
        title: const Text('Vision Board'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vision Board Templates for 2025',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your own custom vision board. Choose from stunning templates. ${_isPremium ? 'Access all premium templates.' : 'Upgrade to premium to unlock all templates.'}',
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
                      'assets/vision-board-ruled-theme.png',
                      'Box theme Vision Board'),
                  _buildTemplateCard(
                      context,
                      'assets/Postit-Theme-Vision-Board.png',
                      'PostIt theme Vision Board'),
                  _buildTemplateCard(context, 'assets/premium-theme.png',
                      'Premium theme Vision Board'),
                  _buildTemplateCard(
                      context,
                      'assets/winter-warmth-theme-vision-board.png',
                      'Winter Warmth theme Vision Board'),
                  _buildTemplateCard(
                      context,
                      'assets/ruby-reds-theme-vision-board.png',
                      'Ruby Reds theme Vision Board'),
                  _buildTemplateCard(
                      context,
                      'assets/coffee-hues-theme-vision-board.png',
                      'Coffee Hues theme Vision Board'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
