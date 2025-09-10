import 'package:flutter/material.dart';
import '../services/subscription_manager.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/platform_features.dart';
import 'package:flutter/gestures.dart';

class SubscriptionModal extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onStartFreeTrial;

  const SubscriptionModal({
    super.key,
    this.onClose,
    this.onStartFreeTrial,
  });

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
    try {
      // Use the simplified subscription manager for consistent premium checks
      final subscriptionManager = SubscriptionManager();
      bool isPremium = await subscriptionManager.hasAccess();

      debugPrint('Premium status check in subscription modal: $isPremium');

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
    } catch (e) {
      debugPrint('Error checking premium status in subscription modal: $e');

      final prefs = await SharedPreferences.getInstance();
      final hasCompletedPayment =
          prefs.getBool('has_completed_payment') ?? false;

      final localIsPremium = hasCompletedPayment; // only honor actual payment flag

      if (mounted) {
        setState(() {
          _isPremium = localIsPremium;
          _isLoading = false;
        });
      }
    }
  }

  // Preload premium features to avoid delay after showing premium status
  Future<void> _preloadPremiumFeatures() async {
    try {
      // Use the simplified subscription manager to refresh premium status
      final subscriptionManager = SubscriptionManager();
      await subscriptionManager.refreshPremiumStatus();

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
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'You are already a premium member!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'You have access to all Reconstruct Circle features and benefits.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // Show premium conversion date if available
                FutureBuilder<DateTime?>(
                  future: SubscriptionManager().getPremiumConversionDate(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final conversionDate = snapshot.data!;
                      final formattedDate =
                          '${conversionDate.day}/${conversionDate.month}/${conversionDate.year}';
                      return Text(
                        'Premium member since: $formattedDate',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      );
                    }
                    return const SizedBox.shrink();
                  },
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
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 8),
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
                  size: 20,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Unlock Premium Features',
                style: TextStyle(
                  fontSize: 16,
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
                fontSize: 12,
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
        'Get your all-access membership to premium planners & tools for everyday mental strength.',
        style: TextStyle(
          fontSize: 14,
          color: Colors.black87,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }

Widget _buildFeaturesList() {
  List<String> features = [
    "Subscribe now and get access instantly",
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
      child: Column(
        children: [
          // Subscription details header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Text(
              'Reconstruct Subscription',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Main pricing container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.blue.shade200,
                width: 1,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Plan details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Annual Pro Plan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '₹49.92/month billed yearly at ₹599',
                          style: TextStyle(fontSize: 12),
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
                        size: 10,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),

                // Product details
                const SizedBox(height: 12),
                const Text(
                  'Subscription details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow('Product ID', 're_599_1yr'),
                const SizedBox(height: 16),

                // Benefits
                const Text(
                  'Benefits',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                _buildBulletPoint('Full access to premium planner & mind tools'),
                _buildBulletPoint('Unlock personal dashboard & progress trackers'),
                _buildBulletPoint('Save, edit & download planners and lists'),
                _buildBulletPoint('Set smart reminders and gentle nudges'),
                _buildBulletPoint('Enjoy new pro features at no extra cost'),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // Tax and policy
                const Text(
                  'Tax and policy settings',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildDetailRow('Digital content', 'Standard rates apply'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods for the pricing section
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        onPressed: () async {
          setState(() => _isLoading = true);
          try {
            // Use our simplified subscription manager to handle payment
            final subscriptionManager = SubscriptionManager();

            // Show a loading indicator while processing
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Processing payment...'),
                duration: Duration(seconds: 1),
              ),
            );

            // Get current user email
            final currentUser = AuthService.instance.currentUser;
            if (currentUser?.email != null) {
              // This will trigger the actual payment process
              await subscriptionManager.startUpgradeFlow(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please log in to upgrade'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (e) {
            debugPrint('Error processing payment: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          } finally {
            if (mounted) {
              setState(() => _isLoading = false);

              // Call onStartFreeTrial if provided
              if (widget.onStartFreeTrial != null) {
                widget.onStartFreeTrial!();
              }
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          'Subscribe Now',
          style: TextStyle(
            fontSize: 14,
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
                  text: PlatformFeatures.isAndroid ? "Cancel in Play Store" : "Cancel in App Store",
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      final uri = PlatformFeatures.isAndroid
                          ? Uri.parse("https://play.google.com/store/account/subscriptions")
                          : Uri.parse("https://apps.apple.com/account/subscriptions");
                      launchUrl(uri);
                    },
                ),
                TextSpan(
                  text: " anytime, no extra charges.",
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
                fontSize: 9,
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