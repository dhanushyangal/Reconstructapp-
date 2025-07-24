import 'package:flutter/material.dart';
import '../services/subscription_manager.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentMethodsPage extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onStartFreeTrial;
  final VoidCallback? onRedeemCode;
  final String email;
  final DateTime trialEndDate;

  const PaymentMethodsPage({
    super.key,
    required this.email,
    required this.trialEndDate,
    this.onClose,
    this.onStartFreeTrial,
    this.onRedeemCode,
  });

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
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
      bool isPremium = await subscriptionManager.isPremium();

      debugPrint('Premium status check in payment page: $isPremium');

      // If user is premium, preload features before showing UI
      if (isPremium) {
        await _preloadPremiumFeatures();

        // For premium users, close the page immediately instead of showing it
        if (widget.onClose != null && mounted) {
          debugPrint('User is premium, closing payment page automatically');
          Future.microtask(() => widget.onClose!());
          return;
        }
      }

      if (mounted) {
        setState(() {
          _isPremium = isPremium;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking premium status in payment page: $e');

      // Fallback to local check on error
      final prefs = await SharedPreferences.getInstance();
      final isSubscribedLocally = prefs.getBool('is_subscribed') ?? false;
      final hasCompletedPayment =
          prefs.getBool('has_completed_payment') ?? false;
      final premiumFeaturesEnabled =
          prefs.getBool('premium_features_enabled') ?? false;

      final localIsPremium =
          isSubscribedLocally || hasCompletedPayment || premiumFeaturesEnabled;

      if (localIsPremium && widget.onClose != null && mounted) {
        // For premium users, close the page automatically
        debugPrint(
            'User is premium (local check), closing payment page automatically');
        Future.microtask(() => widget.onClose!());
        return;
      }

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

      debugPrint('Premium features preloaded before showing UI');
    } catch (e) {
      debugPrint('Error preloading premium features: $e');
    }
  }

  Future<void> _handleStartFreeTrial() async {
    // Show loading state while we prepare premium features
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Use the simplified subscription manager to handle the payment process
      final subscriptionManager = SubscriptionManager();
      final currentUser = AuthService.instance.currentUser;

      if (currentUser?.email != null) {
        // Show processing message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Processing payment...'),
            duration: Duration(seconds: 1),
          ),
        );

        // This will handle both the database update and local state changes
        await subscriptionManager.startUpgradeFlow(context,
            email: currentUser!.email);

        debugPrint('Payment process completed through SubscriptionManager');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not logged in'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error processing payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Call the parent callback to complete the process
      if (widget.onStartFreeTrial != null) {
        widget.onStartFreeTrial!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _isPremium
                ? _buildAlreadyPremiumContent()
                : _buildPaymentContent(),
      ),
    );
  }

  Widget _buildAlreadyPremiumContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildHeader(),
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
              SizedBox(height: 24),
              Text(
                'You are already a premium member!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'You already have full access to all premium features and benefits.',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
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
                'Return to App',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTitle(),
                _buildTrialTimeline(),
                _buildGooglePlaySection(),
                _buildButton(),
                if (widget.onRedeemCode != null) _buildRedeemOption(),
                _buildRatings(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildLogo(),
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

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          height: 8,
          width: 50,
          color: Colors.red,
        ),
        Container(
          height: 8,
          width: 50,
          color: Colors.green.shade400,
        ),
        Container(
          height: 8,
          width: 50,
          color: Colors.yellow.shade400,
        ),
        Container(
          height: 8,
          width: 50,
          color: Colors.lightBlue,
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Text(
        'Start Your Free Trial',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTrialTimeline() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      child: Column(
        children: [
          _buildTimelineItem(
            icon: Icons.lock_open,
            iconBackground: Colors.grey.shade200,
            title: 'Start',
            description: 'Get full access to all premium features.',
            isFirst: true,
          ),
          _buildTimelineItem(
            icon: Icons.notifications_outlined,
            iconBackground: Colors.grey.shade200,
            title: 'Day 5',
            description: 'Reminder before trial ends.',
          ),
          _buildTimelineItem(
            icon: Icons.star_border,
            iconBackground: Colors.grey.shade200,
            title: 'Day 7',
            description: 'Trial ends. Subscribe to continue.',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconBackground,
    required String title,
    required String description,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.grey,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGooglePlaySection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Google Play',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Add payment method to your Google Account',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.email,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add a payment method to your Google Account to start your free trial. You won\'t be charged if you cancel before the trial ends.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ElevatedButton(
            onPressed: _handleStartFreeTrial,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              elevation: 3,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.play_circle_fill, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Start Free Trial',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your subscription will begin after the 7-day trial period',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRedeemOption() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextButton(
        onPressed: widget.onRedeemCode,
        child: const Text(
          'Have a promo code?',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildRatings() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.star,
            color: Colors.amber,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text(
            'Rated 4.9',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          const Text('•'),
          const SizedBox(width: 8),
          const Text(
            '2k+ downloads',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 8),
          const Text('•'),
          const SizedBox(width: 8),
          const Text(
            '500+ users',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
