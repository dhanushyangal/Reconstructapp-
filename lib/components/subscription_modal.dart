import 'package:flutter/material.dart';
import '../services/subscription_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';

class SubscriptionModal extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onStartFreeTrial;

  const SubscriptionModal({
    Key? key,
    this.onClose,
    this.onStartFreeTrial,
  }) : super(key: key);

  @override
  State<SubscriptionModal> createState() => _SubscriptionModalState();
}

class _SubscriptionModalState extends State<SubscriptionModal> {
  bool _isPremium = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token') ?? '';
    bool isPremium = false;

    // First check local storage for immediate decision
    final isSubscribedLocally = prefs.getBool('is_subscribed') ?? false;
    final hasCompletedPayment = prefs.getBool('has_completed_payment') ?? false;
    final premiumFeaturesEnabled =
        prefs.getBool('premium_features_enabled') ?? false;

    // If any premium flag is true, consider user premium without server check
    if (isSubscribedLocally || hasCompletedPayment || premiumFeaturesEnabled) {
      debugPrint(
          'User is premium according to local flags in subscription modal');
      isPremium = true;
    } else if (authToken.isNotEmpty) {
      // Only check with server if not already premium and we have a token
      isPremium = await SubscriptionManager().checkPremiumStatus(authToken);
      debugPrint(
          'Premium status from server in subscription modal: $isPremium');

      // If premium according to server, update all local flags
      if (isPremium) {
        await prefs.setBool('is_subscribed', true);
        await prefs.setBool('has_completed_payment', true);
        await prefs.setBool('premium_features_enabled', true);
      }
    } else {
      // No auth token, check if trial is active
      final subscriptionManager = SubscriptionManager();
      final trialStarted = await subscriptionManager.isTrialStarted();
      final trialEnded = await subscriptionManager.hasTrialEnded();

      if (trialStarted && !trialEnded) {
        debugPrint('Active trial detected in subscription modal');
        isPremium = true;
      }
    }

    // If user is premium, preload features before showing UI
    if (isPremium) {
      await _preloadPremiumFeatures();
    }

    if (mounted) {
      setState(() {
        _isPremium = isPremium;
        _isLoading = false;
      });
    }
  }

  // Preload premium features to avoid delay after showing premium status
  Future<void> _preloadPremiumFeatures() async {
    try {
      // Force SharedPreferences to update with premium status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_payment', true);
      await prefs.setBool('is_subscribed', true);
      await prefs.setBool('premium_features_enabled', true);

      // Use the public method to refresh premium features across the app
      final subscriptionManager = SubscriptionManager();
      await subscriptionManager.refreshPremiumFeatures();

      debugPrint(
          'Premium features preloaded before showing UI in subscription modal');
    } catch (e) {
      debugPrint('Error preloading premium features in subscription modal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.all(16),
        child: _isLoading
            ? _buildLoadingIndicator()
            : _isPremium
                ? _buildAlreadyPremiumContent()
                : _buildSubscriptionContent(),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildAlreadyPremiumContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                SizedBox(height: 16),
                Text(
                  'You are already a premium member!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  'You have access to all Reconstruct Circle features and benefits.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: widget.onClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionContent() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          _buildWelcomeText(),
          _buildFeaturesList(),
          _buildPricingOptions(),
          _buildActionButton(),
          _buildCancelInfo(),
          _buildFooterText(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F0FE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_open,
                  color: Colors.amber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Unlock the Reconstruct Circle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Text(
              'X',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeText() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'Welcome to the Circle. Reconstruct Circle is your all-access membership to tools that help you build everyday mental strength.',
        style: TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      'Full access — from vision boards to planners & tools',
      'A personal dashboard to track your growth and mental routines',
      'Save and return to your boards, planners, and reflections',
      'Smart reminders and gentle nudges to help you stay consistent',
      'Tools to stay consistent and build lasting mental strength',
      'First access to new features and exclusive Circle-only drops',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: features.map((feature) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  child: const Icon(
                    Icons.check,
                    color: Colors.teal,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    feature,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPricingOptions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.blue.shade200,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Annual Plan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '₹49.92/month billed yearly at ₹599',
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        onPressed: widget.onStartFreeTrial,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyan,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          'Upgrade',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildCancelInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              children: [
                TextSpan(
                  text: "Cancel",
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      launchUrl(Uri.parse(
                          "https://play.google.com/store/account/subscriptions"));
                    },
                ),
                TextSpan(
                  text: " anytime, no charges after current billing cycle.",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterText() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Flexible(
            child: Text(
              'Your subscription supports a hard-working team trying to improve the everyday lives of millions of people. ',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Icon(
            Icons.favorite,
            color: Colors.blue,
            size: 14,
          ),
        ],
      ),
    );
  }
}
