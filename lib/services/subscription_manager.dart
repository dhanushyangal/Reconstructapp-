import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/subscription_modal.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';
import '../main.dart';
import 'supabase_database_service.dart';
import 'auth_service.dart';

class SubscriptionManager extends ChangeNotifier {
  static final SubscriptionManager _instance = SubscriptionManager._internal();

  // Simplified keys - only what we need
  static const String _isPremiumKey = 'is_premium';
  static const String _trialStartDateKey = 'trial_start_date';
  static const String _trialEndDateKey = 'trial_end_date';
  static const String _lastCheckKey = 'last_premium_check';
  static const String _premiumConvertedDateKey = 'premium_converted_date';

  // Subscription product IDs
  static const String yearlySubscriptionId = 'reconstruct';

  // Cache expiration (5 minutes for better UX)
  static const int _cacheMinutes = 5;

  // Purchase streams
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;

  factory SubscriptionManager() {
    return _instance;
  }

  SubscriptionManager._internal() {
    _initializeStore();
  }

  Future<void> _initializeStore() async {
    final isAvailable = await _inAppPurchase.isAvailable();
    _isAvailable = isAvailable;

    if (!isAvailable) {
      debugPrint('Store is not available');
      return;
    }

    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _listenToPurchaseUpdated,
      onDone: () => _subscription.cancel(),
      onError: (error) => debugPrint('Purchase error: $error'),
    );

    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final Set<String> productIds = <String>{yearlySubscriptionId};
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(productIds);

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('Products not found: ${response.notFoundIDs}');
      }

      _products = response.productDetails;
      debugPrint('Products loaded: ${_products.length}');
    } catch (e) {
      debugPrint('Error loading products: $e');
    }
  }

  void _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        debugPrint('Purchase pending');
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('Error: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          await _handleSuccessfulPurchase(purchaseDetails);
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          debugPrint('Purchase canceled');
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    if (purchase.productID == yearlySubscriptionId) {
      debugPrint('Premium subscription purchased successfully');

      // Get current user email
      final currentUser = AuthService.instance.currentUser;
      if (currentUser?.email != null) {
        final conversionDate = DateTime.now();

        // Update Supabase database with premium conversion date
        final databaseService = SupabaseDatabaseService();
        await databaseService.setPremiumStatus(
          email: currentUser!.email!,
          conversionDate: conversionDate,
        );

        // Update local cache with conversion date
        await _updateLocalPremiumStatus(
          isPremium: true,
          conversionDate: conversionDate,
        );

        debugPrint(
            'Premium status updated in database and local cache with conversion date: ${conversionDate.toIso8601String()}');

        // Show success dialog
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = navigatorKey.currentContext;
          if (context != null) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Payment Successful!'),
                  content: const Text(
                      'Your premium subscription has been activated. You now have full access to all premium features.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
        });

        notifyListeners();
      }
    }
  }

  /// Main method to check if user has premium access
  /// Returns true if user is premium OR has active trial
  Future<bool> hasAccess() async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser?.email == null) {
        debugPrint('No user email available');
        return false;
      }

      final email = currentUser!.email!;

      // Check if we have recent cached data
      final prefs = await SharedPreferences.getInstance();
      final lastCheckTime = prefs.getInt(_lastCheckKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeSinceLastCheck = currentTime - lastCheckTime;
      final cacheExpired = timeSinceLastCheck > (_cacheMinutes * 60 * 1000);

      // Use cache if available and not expired
      if (!cacheExpired && lastCheckTime > 0) {
        final cachedIsPremium = prefs.getBool(_isPremiumKey) ?? false;
        final cachedTrialStart = prefs.getString(_trialStartDateKey);
        final cachedTrialEnd = prefs.getString(_trialEndDateKey);

        if (cachedIsPremium) {
          debugPrint('User is premium (cached)');
          return true;
        }

        if (cachedTrialStart != null && cachedTrialEnd != null) {
          final trialEndDate = DateTime.parse(cachedTrialEnd);
          final now = DateTime.now();
          final hasActiveTrial =
              now.isBefore(trialEndDate) || now.isAtSameMomentAs(trialEndDate);

          debugPrint(
              'Trial status (cached): ${hasActiveTrial ? "Active" : "Expired"}');
          return hasActiveTrial;
        }

        debugPrint('No premium access (cached)');
        return false;
      }

      // Only fetch fresh data if cache is expired or doesn't exist
      // Add a small delay to prevent rapid successive calls
      final lastFetchTime = prefs.getInt('_last_fetch_time') ?? 0;
      final timeSinceLastFetch = currentTime - lastFetchTime;
      if (timeSinceLastFetch < 2000) {
        // 2 seconds minimum between fetches
        debugPrint('Skipping fetch - too soon since last fetch');
        final cachedIsPremium = prefs.getBool(_isPremiumKey) ?? false;
        return cachedIsPremium;
      }

      // Fetch fresh data from Supabase
      debugPrint('Fetching fresh premium status from Supabase for: $email');
      await prefs.setInt('_last_fetch_time', currentTime);

      final databaseService = SupabaseDatabaseService();
      final response = await databaseService.checkTrialStatus(email: email);

      if (response['success'] == true) {
        final data = response['data'];
        final isPremium = data['is_premium'] ?? false;
        final trialStartDate = data['trial_start_date'];
        final trialEndDate = data['trial_end_date'];
        final hasActiveAccess = data['has_active_access'] ?? false;
        final premiumConvertedDate = data['premium_converted_date'];

        // Update local cache
        await prefs.setInt(_lastCheckKey, currentTime);
        await prefs.setBool(_isPremiumKey, isPremium);

        if (trialStartDate != null) {
          await prefs.setString(_trialStartDateKey, trialStartDate);
        } else {
          await prefs.remove(_trialStartDateKey);
        }

        if (trialEndDate != null) {
          await prefs.setString(_trialEndDateKey, trialEndDate);
        } else {
          await prefs.remove(_trialEndDateKey);
        }

        // Cache premium conversion date if available
        if (premiumConvertedDate != null) {
          await prefs.setString(_premiumConvertedDateKey, premiumConvertedDate);
          debugPrint('Premium conversion date cached: $premiumConvertedDate');
        } else {
          await prefs.remove(_premiumConvertedDateKey);
        }

        debugPrint(
            'Premium status updated from Supabase: isPremium=$isPremium, hasActiveAccess=$hasActiveAccess, conversionDate=$premiumConvertedDate');
        return hasActiveAccess;
      } else {
        debugPrint(
            'Failed to fetch premium status from Supabase: ${response['message']}');
        // Fallback to local cache
        final cachedIsPremium = prefs.getBool(_isPremiumKey) ?? false;
        return cachedIsPremium;
      }
    } catch (e) {
      debugPrint('Error in hasAccess: $e');
      // Fallback to local cache
      final prefs = await SharedPreferences.getInstance();
      final cachedIsPremium = prefs.getBool(_isPremiumKey) ?? false;
      return cachedIsPremium;
    }
  }

  /// Start a free trial for new users
  Future<bool> startFreeTrial() async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser?.email == null) {
        debugPrint('No user email available for trial');
        return false;
      }

      final email = currentUser!.email!;
      final databaseService = SupabaseDatabaseService();

      // Check if user already has trial or premium
      final response = await databaseService.checkTrialStatus(email: email);
      if (response['success'] == true) {
        final data = response['data'];
        final isPremium = data['is_premium'] ?? false;
        final hasActiveAccess = data['has_active_access'] ?? false;

        if (isPremium) {
          debugPrint('User is already premium, no trial needed');
          return true;
        }

        if (hasActiveAccess) {
          debugPrint('User already has active trial');
          return true;
        }

        // Check if trial was already used
        final trialStartDate = data['trial_start_date'];
        if (trialStartDate != null) {
          debugPrint('User already used their trial');
          return false;
        }
      }

      // Start new trial
      final now = DateTime.now();
      final trialEndDate = now.add(const Duration(days: 7));

      final updateResponse = await databaseService.updateUserPremiumStatus(
        email: email,
        isPremium: false,
        trialStartDate: now,
        trialEndDate: trialEndDate,
      );

      if (updateResponse['success'] == true) {
        // Update local cache
        await _updateLocalTrialStatus(
          trialStartDate: now.toIso8601String().split('T')[0],
          trialEndDate: trialEndDate.toIso8601String().split('T')[0],
        );

        debugPrint(
            'Free trial started successfully: ${now.toIso8601String().split('T')[0]} to ${trialEndDate.toIso8601String().split('T')[0]}');
        return true;
      } else {
        debugPrint('Failed to start trial: ${updateResponse['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('Error starting free trial: $e');
      return false;
    }
  }

  /// Check if user is premium (not including trial)
  Future<bool> isPremium() async {
    try {
      final currentUser = AuthService.instance.currentUser;
      if (currentUser?.email == null) return false;

      final prefs = await SharedPreferences.getInstance();
      final lastCheckTime = prefs.getInt(_lastCheckKey) ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeSinceLastCheck = currentTime - lastCheckTime;
      final cacheExpired = timeSinceLastCheck > (_cacheMinutes * 60 * 1000);

      if (!cacheExpired && lastCheckTime > 0) {
        return prefs.getBool(_isPremiumKey) ?? false;
      }

      // Refresh from database
      await hasAccess();
      return prefs.getBool(_isPremiumKey) ?? false;
    } catch (e) {
      debugPrint('Error checking premium status: $e');
      return false;
    }
  }

  /// Legacy method for compatibility
  Future<bool> isSubscribed() async {
    return await isPremium();
  }

  /// Check if trial has ended
  Future<bool> hasTrialEnded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trialEndDateStr = prefs.getString(_trialEndDateKey);

      if (trialEndDateStr == null) return false;

      final trialEndDate = DateTime.parse(trialEndDateStr);
      final now = DateTime.now();

      return now.isAfter(trialEndDate);
    } catch (e) {
      debugPrint('Error checking if trial ended: $e');
      return false;
    }
  }

  /// Update local premium status
  Future<void> _updateLocalPremiumStatus({
    required bool isPremium,
    DateTime? conversionDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    await prefs.setInt(_lastCheckKey, currentTime);
    await prefs.setBool(_isPremiumKey, isPremium);

    // Store premium conversion date if provided
    if (conversionDate != null && isPremium) {
      await prefs.setString(
          _premiumConvertedDateKey, conversionDate.toIso8601String());
      debugPrint(
          'Premium conversion date stored locally: ${conversionDate.toIso8601String()}');
    }

    // Clear trial data if user is now premium
    if (isPremium) {
      await prefs.remove(_trialStartDateKey);
      await prefs.remove(_trialEndDateKey);
    }
  }

  /// Update local trial status
  Future<void> _updateLocalTrialStatus({
    required String trialStartDate,
    required String trialEndDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    await prefs.setInt(_lastCheckKey, currentTime);
    await prefs.setBool(_isPremiumKey, false);
    await prefs.setString(_trialStartDateKey, trialStartDate);
    await prefs.setString(_trialEndDateKey, trialEndDate);
  }

  /// Start subscription flow
  Future<void> startSubscriptionFlow(BuildContext context,
      {String? email}) async {
    try {
      // Check if user is already premium
      final isPremiumUser = await isPremium();
      if (isPremiumUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You already have premium access!'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      // Show subscription modal
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const SubscriptionModal(),
      );
    } catch (e) {
      debugPrint('Error starting subscription flow: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Start upgrade flow (initiates the actual payment process)
  Future<void> startUpgradeFlow(BuildContext context, {String? email}) async {
    try {
      // Check if user is already premium
      final isPremiumUser = await isPremium();
      if (isPremiumUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You already have premium access!'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      // Process the actual payment
      await processRealPayment(context);
    } catch (e) {
      debugPrint('Error in startUpgradeFlow: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting payment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Get premium conversion date from local storage
  Future<DateTime?> getPremiumConversionDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = prefs.getString(_premiumConvertedDateKey);
      if (dateString != null) {
        return DateTime.parse(dateString);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting premium conversion date: $e');
      return null;
    }
  }

  /// Clear all premium data (for logout)
  Future<void> clearPremiumData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isPremiumKey);
    await prefs.remove(_trialStartDateKey);
    await prefs.remove(_trialEndDateKey);
    await prefs.remove(_lastCheckKey);
    await prefs.remove(_premiumConvertedDateKey);
    debugPrint('Premium data cleared');
  }

  /// Force refresh premium status
  Future<void> refreshPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastCheckKey); // Clear cache
    await hasAccess(); // This will fetch fresh data
    notifyListeners();
  }

  /// Check if trial is started (legacy method for compatibility)
  Future<bool> isTrialStarted() async {
    final prefs = await SharedPreferences.getInstance();
    final trialStartDate = prefs.getString(_trialStartDateKey);
    return trialStartDate != null;
  }

  /// Legacy method for compatibility - no longer needed with Supabase-only approach
  Future<void> checkAndSyncPremiumStatus(String token) async {
    debugPrint('checkAndSyncPremiumStatus called - refreshing from Supabase');
    await refreshPremiumStatus();
  }

  /// Legacy method for compatibility
  Future<bool> checkPremiumStatus(String token) async {
    return await hasAccess();
  }

  /// Legacy method for compatibility
  Future<void> refreshPremiumFeatures() async {
    await refreshPremiumStatus();
  }

  /// Legacy method for compatibility
  Future<void> lockFeaturesIfTrialEnded() async {
    // This is now handled automatically in hasAccess() method
    await hasAccess();
  }

  /// Process real payment (This is a new method to handle actual payment processing)
  Future<bool> processRealPayment(BuildContext context) async {
    try {
      if (!_isAvailable) {
        debugPrint('Store is not available');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Store is not available'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }

      if (_products.isEmpty) {
        debugPrint('No products available');
        // Try to load products again
        await _loadProducts();

        if (_products.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No subscription products available'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
      }

      // Find our product
      final productDetails = _products.firstWhere(
        (product) => product.id == yearlySubscriptionId,
        orElse: () =>
            throw Exception('Product not found: $yearlySubscriptionId'),
      );

      debugPrint('Starting purchase flow for: ${productDetails.title}');

      // Start purchase
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: null,
      );

      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      return true; // Purchase started successfully
    } catch (e) {
      debugPrint('Error processing payment: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
