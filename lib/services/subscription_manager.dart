import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/subscription_modal.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';
import '../main.dart'; // Import navigatorKey and state classes
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as Math;

class SubscriptionManager {
  static final SubscriptionManager _instance = SubscriptionManager._internal();
  static const String _hasShownSubscriptionKey = 'has_shown_subscription';
  static const String _isSubscribedKey = 'is_subscribed';
  static const String _subscriptionTypeKey = 'subscription_type';
  static const String _subscriptionEndKey = 'subscription_end';
  static const String _trialStartedKey = 'trial_started';
  static const String _trialStartDateKey = 'trial_start_date';
  static const String _trialEndDateKey = 'trial_end_date';
  static const String _trialEndPopupShownKey = 'trial_end_popup_shown';
  static const String _lastTrialCheckKey = 'last_trial_check_timestamp';

  // Cache expiration time (in minutes)
  static const int _trialCheckCacheMinutes = 1440; // Check once per day at most

  // Subscription product IDs
  static const String yearlySubscriptionId = 'reconstruct';
  static const bool useTestMode = false; // Set to false for production

  // API endpoint - made public so it can be accessed from outside
  static const String _apiBaseUrl = 'https://reconstrect-api.onrender.com';

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
    // Check if the store is available
    final isAvailable = await _inAppPurchase.isAvailable();
    _isAvailable = isAvailable;

    if (!isAvailable) {
      debugPrint('Store is not available');
      return;
    }

    // Set up purchase stream listener
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _listenToPurchaseUpdated,
      onDone: () {
        _subscription.cancel();
      },
      onError: (error) {
        debugPrint('Purchase error: $error');
      },
    );

    // Load products
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final Set<String> _kIds = <String>{
        yearlySubscriptionId,
      };
      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails(_kIds);

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
          // Grant entitlement for this purchase
          await _handleSuccessfulPurchase(purchaseDetails);
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          debugPrint('Purchase canceled');
        }

        // Complete the purchase if not already completed
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    // Get stored auth token
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token') ?? '';

    // Save subscription data locally
    if (purchase.productID == yearlySubscriptionId) {
      await _saveSubscriptionData('annual');
      debugPrint('Annual subscription activated locally');

      // Update premium status on server if token is available - THIS IS REAL PAYMENT
      if (authToken.isNotEmpty) {
        debugPrint(
            'Attempting to update premium status on server after payment...');
        int retryCount = 0;
        bool success = false;

        // Try up to 3 times to update premium status on the server
        while (retryCount < 3 && !success) {
          success = await updatePremiumStatus(authToken);

          if (success) {
            debugPrint(
                'Premium status updated on server after successful payment (attempt: ${retryCount + 1})');
            break;
          } else {
            retryCount++;
            if (retryCount < 3) {
              debugPrint(
                  'Failed to update premium status on server, retry attempt $retryCount');
              // Exponential backoff: 2, 4, 8 seconds
              await Future.delayed(
                  Duration(seconds: Math.pow(2, retryCount).toInt()));
            } else {
              debugPrint(
                  'Failed to update premium status after maximum retries');
            }
          }
        }
      } else {
        debugPrint(
            'No auth token available to update premium status on server');

        // Store that we need to sync with server later when token is available
        await prefs.setBool('needs_premium_sync', true);

        // Set a flag to indicate that we need to attempt sync on every app start
        // until it's successful
        await prefs.setBool('persistent_premium_sync_needed', true);
        debugPrint(
            'Set persistent sync flag for when auth token becomes available');
      }

      // Refresh premium status UI in app
      _refreshAppPremiumStatus();

      // Show success dialog on main UI thread
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Payment Successful!'),
                content: const Text(
                    'Your Reconstruct Circle subscription has been activated. You now have full access to all premium features.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );

          // Also show a snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Subscription activated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        }
      });
    }
  }

  // Add new method to refresh premium status across the app
  void _refreshAppPremiumStatus() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = navigatorKey.currentContext;
      if (context != null) {
        try {
          // First ensure premium flags are consistently set in SharedPreferences
          final prefs = await SharedPreferences.getInstance();

          // Check if we're in the middle of a refresh already to prevent loops
          final isRefreshing =
              prefs.getBool('_premium_refresh_in_progress') ?? false;
          if (isRefreshing) {
            debugPrint(
                'Premium refresh already in progress, skipping redundant refresh');
            return;
          }

          // Set refresh in progress flag to prevent loops
          await prefs.setBool('_premium_refresh_in_progress', true);

          // Get both local and server premium status
          final isPremiumLocal = prefs.getBool('has_completed_payment') ??
              prefs.getBool(_isSubscribedKey) ??
              prefs.getBool('premium_features_enabled') ??
              false;

          // Check if server says user is premium
          final authToken = prefs.getString('auth_token') ?? '';
          bool isPremiumServer = false;
          if (authToken.isNotEmpty) {
            try {
              // Use a very brief timeout to avoid waiting too long
              isPremiumServer = await checkPremiumStatus(authToken).timeout(
                  const Duration(seconds: 2),
                  onTimeout: () => isPremiumLocal);
            } catch (e) {
              debugPrint('Error checking server premium status: $e');
              isPremiumServer = isPremiumLocal; // Fall back to local status
            }
          } else {
            isPremiumServer = isPremiumLocal;
          }

          // If server says premium, always trust server over local trial ended status
          if (isPremiumServer) {
            await prefs.setBool('has_completed_payment', true);
            await prefs.setBool(_isSubscribedKey, true);
            await prefs.setBool('premium_features_enabled', true);
            debugPrint(
                'Server confirms premium status, forcefully setting all premium flags to TRUE');
          } else {
            // Check if trial is active before setting to false
            final trialStarted = prefs.getBool(_trialStartedKey) ?? false;
            bool trialHasEnded = false;
            final trialEndDateStr = prefs.getString(_trialEndDateKey);

            if (trialEndDateStr != null) {
              final trialEndDate = DateTime.parse(trialEndDateStr);
              final now = DateTime.now();
              trialHasEnded = now.isAfter(trialEndDate);
            }

            // If trial is active and not ended, keep premium features enabled
            if (trialStarted && !trialHasEnded) {
              await prefs.setBool('has_completed_payment', true);
              await prefs.setBool(_isSubscribedKey, true);
              await prefs.setBool('premium_features_enabled', true);
              debugPrint(
                  'Active trial detected, premium flags forcefully set to TRUE');
            } else if (!isPremiumLocal) {
              // Only update flags to false if they aren't already false
              // This prevents unnecessary UI refreshes when status hasn't changed
              await prefs.setBool('has_completed_payment', false);
              await prefs.setBool(_isSubscribedKey, false);
              await prefs.setBool('premium_features_enabled', false);
              debugPrint('Premium flags forcefully updated and set to FALSE');
            }
          }

          // Clear refresh in progress flag
          await prefs.setBool('_premium_refresh_in_progress', false);

          // Only show notification for significant status changes
          bool statusChanged = false;
          if ((isPremiumServer && !isPremiumLocal) ||
              (!isPremiumServer && isPremiumLocal)) {
            statusChanged = true;
          }

          if (statusChanged) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Premium features refreshed'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 1),
              ),
            );
          }

          // Check if we're on the profile page - improved detection
          bool isOnProfilePage = false;
          try {
            // Look at the current route name
            ModalRoute? route = ModalRoute.of(context);
            if (route != null && route.settings.name != null) {
              isOnProfilePage = route.settings.name!.contains('profile');
            }

            // Also check if the current widget tree contains ProfilePage
            final currentWidget = route?.settings.arguments;
            if (currentWidget != null) {
              final widgetStr = currentWidget.toString().toLowerCase();
              if (widgetStr.contains('profile')) {
                isOnProfilePage = true;
              }
            }

            // Additional check - look at the current page's class name
            final currentContext = navigatorKey.currentContext;
            if (currentContext != null) {
              final currentType =
                  currentContext.widget.runtimeType.toString().toLowerCase();
              if (currentType.contains('profile')) {
                isOnProfilePage = true;
              }
            }

            debugPrint('Current page is profile page: $isOnProfilePage');
          } catch (e) {
            debugPrint('Error checking current route: $e');
          }

          // Only force a navigation refresh when we actually changed the premium status
          // and limit to at most one refresh per 10 seconds to prevent loops
          // and don't do it if we're on the profile page
          final lastRefreshTime =
              prefs.getInt('_last_premium_refresh_time') ?? 0;
          final currentTime = DateTime.now().millisecondsSinceEpoch;
          final timeSinceLastRefresh = currentTime - lastRefreshTime;

          // Only navigate if:
          // 1. Premium status actually changed
          // 2. We haven't refreshed in the last 10 seconds
          // 3. We're not on the profile page
          // 4. We're not in a loop
          if (statusChanged &&
              timeSinceLastRefresh > 10000 &&
              !isOnProfilePage) {
            // 10 seconds minimum between refreshes and not on profile page
            await prefs.setInt('_last_premium_refresh_time', currentTime);

            Future.delayed(const Duration(milliseconds: 300), () {
              if (navigatorKey.currentState != null &&
                  navigatorKey.currentState!.mounted) {
                try {
                  debugPrint(
                      'Forcing full app refresh by navigating to home page');
                  // Manually navigate to home page to force full UI rebuild
                  Navigator.pushNamedAndRemoveUntil(
                    navigatorKey.currentContext!,
                    '/home',
                    (route) => false,
                  );
                } catch (e) {
                  debugPrint('Error navigating to home: $e');
                }
              }
            });
          } else {
            if (isOnProfilePage) {
              debugPrint(
                  'Skipping navigation refresh - currently on profile page');
            } else if (!statusChanged) {
              debugPrint(
                  'Skipping navigation refresh - premium status did not change');
            } else {
              debugPrint(
                  'Skipping navigation refresh - last refresh was ${timeSinceLastRefresh}ms ago');
            }
          }
        } catch (e) {
          debugPrint('Error in _refreshAppPremiumStatus: $e');

          // Clear refresh in progress flag on error
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('_premium_refresh_in_progress', false);
        }
      }
    });
  }

  // Check if the user is premium from the server
  Future<bool> checkPremiumStatus(String authToken) async {
    final stopwatch = Stopwatch()..start();
    debugPrint('Starting premium status check from server...');

    try {
      // First check local storage for offline access
      final prefs = await SharedPreferences.getInstance();
      final localIsPremium = prefs.getBool(_isSubscribedKey) ?? false;
      final hasCompletedPayment =
          prefs.getBool('has_completed_payment') ?? false;
      final premiumFeaturesEnabled =
          prefs.getBool('premium_features_enabled') ?? false;

      debugPrint(
          'Local premium status check: isPremium=$localIsPremium, hasCompletedPayment=$hasCompletedPayment, premiumFeaturesEnabled=$premiumFeaturesEnabled');

      // Try to reach the server
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/auth/premium-status'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 5), // Shorter timeout for better offline UX
        onTimeout: () {
          debugPrint(
              'Premium status server check timed out - using local value');
          // Return a fake response to trigger the offline fallback
          return http.Response('{"error":"timeout"}', 408);
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isPremium = data['isPremium'] ?? false;

        // Update local storage to match server status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isSubscribedKey, isPremium);
        await prefs.setBool('has_completed_payment', isPremium);
        await prefs.setBool('premium_features_enabled', isPremium);

        // If premium, ensure we refresh premium features application-wide
        if (isPremium) {
          debugPrint(
              'Server confirms premium status, refreshing app-wide premium features');
          // Force refresh premium features across the app (will be done after return)
          Future.delayed(Duration.zero, () => _refreshAppPremiumStatus());
        }

        stopwatch.stop();
        debugPrint(
            'Premium status check completed in ${stopwatch.elapsedMilliseconds}ms. isPremium: $isPremium');
        return isPremium;
      } else {
        stopwatch.stop();
        debugPrint(
            'Error checking premium status: ${response.statusCode}. Time elapsed: ${stopwatch.elapsedMilliseconds}ms');

        // Fall back to local storage in case of server error
        debugPrint('Falling back to local premium status: $localIsPremium');

        // Ensure premium_features_enabled matches the other flags for consistency
        if (localIsPremium && hasCompletedPayment) {
          await prefs.setBool('premium_features_enabled', true);
          // Force refresh premium features across the app
          Future.delayed(Duration.zero, () => _refreshAppPremiumStatus());
        }

        return localIsPremium && hasCompletedPayment;
      }
    } catch (e) {
      stopwatch.stop();
      debugPrint(
          'Exception checking premium status: $e. Time elapsed: ${stopwatch.elapsedMilliseconds}ms');

      // Fall back to local storage in case of any error
      final prefs = await SharedPreferences.getInstance();
      final localIsPremium = prefs.getBool(_isSubscribedKey) ?? false;
      final hasCompletedPayment =
          prefs.getBool('has_completed_payment') ?? false;

      // Ensure premium_features_enabled matches the other flags
      if (localIsPremium && hasCompletedPayment) {
        await prefs.setBool('premium_features_enabled', true);
        // Force refresh premium features across the app
        Future.delayed(Duration.zero, () => _refreshAppPremiumStatus());
      }

      debugPrint(
          'Network error - falling back to local premium status: $localIsPremium');
      return localIsPremium && hasCompletedPayment;
    }
  }

  // Update premium status on the server
  Future<bool> updatePremiumStatus(String authToken) async {
    try {
      debugPrint(
          'Updating premium status on server - making API request to $_apiBaseUrl/auth/update-premium');
      debugPrint('Using auth token: ${authToken.substring(0, 10)}...');

      // Add connectivity check before making the API call
      bool isConnected = await _checkConnectivity();
      if (!isConnected) {
        debugPrint('No internet connection. Will save for later sync.');
        // Store that we need to sync with server later when connection is available
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('needs_premium_sync', true);
        return false;
      }

      // Make the API call with a timeout - explicitly set isPremium=1 in the request body
      final response = await http
          .post(
            Uri.parse('$_apiBaseUrl/auth/update-premium'),
            headers: {
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'isPremium': 1, // Explicitly set isPremium to 1 for database
              'subscriptionType': 'annual'
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('Premium status update response: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Update local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isSubscribedKey, true);
        await prefs.setBool('has_completed_payment', true);
        await prefs.setBool('needs_premium_sync', false); // Clear sync flag

        // Log success details
        try {
          final responseBody = jsonDecode(response.body);
          debugPrint('Server response: ${responseBody['message']}');
        } catch (_) {
          debugPrint('Could not parse response body');
        }

        return true;
      } else {
        // Log error details
        debugPrint('Error updating premium status: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');

        // Try to parse the error details
        try {
          final errorData = jsonDecode(response.body);
          debugPrint('Error message: ${errorData['message']}');
        } catch (_) {
          debugPrint('Could not parse error details from response');
        }

        // Mark for later sync if there was a server error (5xx)
        if (response.statusCode >= 500) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('needs_premium_sync', true);
        }

        return false;
      }
    } catch (e) {
      debugPrint('Exception updating premium status: $e');

      // Mark for later sync in case of network or timeout exceptions
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('needs_premium_sync', true);

      return false;
    }
  }

  // Helper method to check internet connectivity
  Future<bool> _checkConnectivity() async {
    try {
      // Simple connectivity check - try to reach Google's DNS
      final response = await http
          .get(
            Uri.parse('https://8.8.8.8'),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Connectivity check failed: $e');
      return false;
    }
  }

  // New method to start free trial with server update
  Future<void> startFreeTrial() async {
    debugPrint('Starting free trial...');
    final prefs = await SharedPreferences.getInstance();

    // First check if trial has been used before (both started and ended)
    final trialStarted = prefs.getBool(_trialStartedKey) ?? false;
    final trialEndPopupShown = prefs.getBool(_trialEndPopupShownKey) ?? false;

    // Check if trial end date exists and has passed
    bool trialHasEnded = false;
    final trialEndDateStr = prefs.getString(_trialEndDateKey);
    if (trialEndDateStr != null) {
      final trialEndDate = DateTime.parse(trialEndDateStr);
      final now = DateTime.now();
      trialHasEnded = now.isAfter(trialEndDate);
    }

    // If trial was previously started and has ended, don't allow a new trial
    if (trialStarted && (trialHasEnded || trialEndPopupShown)) {
      debugPrint(
          'Trial has been used before and ended, cannot start a new trial');

      // Ensure premium features are disabled
      await prefs.setBool(_isSubscribedKey, false);
      await prefs.setBool('has_completed_payment', false);
      await prefs.setBool('premium_features_enabled', false);

      // Show subscription modal instead - handled by the calling code
      return;
    }

    // Get the auth token
    final authToken = prefs.getString('auth_token') ?? '';
    if (authToken.isEmpty) {
      debugPrint('No auth token available, falling back to local trial only');

      // Use local storage as fallback if no auth token available
      await _startTrialLocally();
      return;
    }

    // Call server to start trial
    try {
      final response = await http
          .post(
            Uri.parse('$_apiBaseUrl/auth/start-trial'),
            headers: {
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'trial_days': 7 // 7-day trial
            }),
          )
          .timeout(const Duration(seconds: 5));

      // When starting a trial, reset the cache timestamp to ensure fresh status
      final currentTimeMs = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt(_lastTrialCheckKey, currentTimeMs);

      if (response.statusCode == 200) {
        // Success - parse response for trial details
        final data = jsonDecode(response.body);

        // Check if user already has premium status
        if (data['is_premium'] == true) {
          debugPrint('User already has premium status, not starting trial');

          // Still set premium flags locally for immediate UI update
          await prefs.setBool(_isSubscribedKey, true);
          await prefs.setBool('has_completed_payment', true);
          await prefs.setBool('premium_features_enabled', true);

          // Refresh UI
          _refreshAppPremiumStatus();
          return;
        }

        // Check if trial has ended according to server
        if (data['trial_ended'] == true) {
          debugPrint('Server reports trial has already ended, cannot restart');

          // Ensure premium features are disabled
          await prefs.setBool(_isSubscribedKey, false);
          await prefs.setBool('has_completed_payment', false);
          await prefs.setBool('premium_features_enabled', false);

          // Mark trial as started and ended in local storage
          await prefs.setBool(_trialStartedKey, true);

          if (data['trial_start_date'] != null) {
            await prefs.setString(_trialStartDateKey, data['trial_start_date']);
          }

          if (data['trial_end_date'] != null) {
            await prefs.setString(_trialEndDateKey, data['trial_end_date']);
          }

          return;
        }

        // Check if user already has an active trial
        if (data['trial_active'] == true) {
          debugPrint('User already has an active trial, using existing dates');

          // Use trial dates from response
          final trialStartDate = data['trial_start_date'];
          final trialEndDate = data['trial_end_date'];

          // Set trial status in local storage
          await prefs.setBool(_trialStartedKey, true);

          if (trialStartDate != null) {
            final startDate = DateTime.parse(trialStartDate);
            await prefs.setString(
                _trialStartDateKey, startDate.toIso8601String());
          }

          if (trialEndDate != null) {
            final endDate = DateTime.parse(trialEndDate);
            await prefs.setString(_trialEndDateKey, endDate.toIso8601String());
          }
        } else {
          // New trial started - use dates from response
          final trialStartDate = data['trial_start_date'];
          final trialEndDate = data['trial_end_date'];
          final trialDays = data['trial_days'] ?? 7;

          debugPrint('Trial started successfully for $trialDays days');
          debugPrint('Start date: $trialStartDate, End date: $trialEndDate');

          // Set trial status in local storage
          await prefs.setBool(_trialStartedKey, true);

          if (trialStartDate != null) {
            final startDate = DateTime.parse(trialStartDate);
            await prefs.setString(
                _trialStartDateKey, startDate.toIso8601String());
          } else {
            // Fallback: use current date if server didn't return start date
            await prefs.setString(
                _trialStartDateKey, DateTime.now().toIso8601String());
          }

          if (trialEndDate != null) {
            final endDate = DateTime.parse(trialEndDate);
            await prefs.setString(_trialEndDateKey, endDate.toIso8601String());
          } else {
            // Fallback: calculate end date if server didn't return it
            final endDate = DateTime.now().add(Duration(days: trialDays));
            await prefs.setString(_trialEndDateKey, endDate.toIso8601String());
          }
        }

        // Mark user as temporarily subscribed LOCALLY ONLY
        await prefs.setBool(_isSubscribedKey, true);
        await prefs.setBool('has_completed_payment', true);
        await prefs.setBool('premium_features_enabled', true);

        // Clear trial end popup shown flag
        await prefs.setBool(_trialEndPopupShownKey, false);

        debugPrint('Free trial successfully started with server');

        // Refresh UI to show premium status immediately
        _refreshAppPremiumStatus();

        // Show free trial started popup
        _showFreeTrialStartedPopup();
      } else {
        // Handle error from server
        debugPrint('Error starting trial on server: ${response.statusCode}');
        debugPrint('Error response: ${response.body}');

        // Fall back to local storage as a backup
        await _startTrialLocally();
      }
    } catch (e) {
      // Handle connection errors
      debugPrint('Exception starting trial on server: $e');

      // Fall back to local storage as a backup
      await _startTrialLocally();
    }
  }

  // Private method to start trial locally when server is unavailable
  Future<void> _startTrialLocally() async {
    debugPrint('Starting trial locally (fallback method)');
    final prefs = await SharedPreferences.getInstance();

    // First check if trial has been used before
    final trialStarted = prefs.getBool(_trialStartedKey) ?? false;
    final trialEndPopupShown = prefs.getBool(_trialEndPopupShownKey) ?? false;

    // Check if trial has ended
    bool trialHasEnded = false;
    final trialEndDateStr = prefs.getString(_trialEndDateKey);
    if (trialEndDateStr != null) {
      final trialEndDate = DateTime.parse(trialEndDateStr);
      final now = DateTime.now();
      trialHasEnded = now.isAfter(trialEndDate);
    }

    // If trial was previously used and has ended, don't allow a new trial
    if (trialStarted && (trialHasEnded || trialEndPopupShown)) {
      debugPrint(
          'Trial has been used before and ended locally, cannot start a new trial');

      // Ensure premium features are disabled
      await prefs.setBool(_isSubscribedKey, false);
      await prefs.setBool('has_completed_payment', false);
      await prefs.setBool('premium_features_enabled', false);

      return;
    }

    // Check if trial already started but not ended - continue with existing trial
    if (trialStarted && !trialHasEnded) {
      debugPrint(
          'Trial already started locally and still active, not restarting');

      // Ensure premium features are enabled for active trial
      await prefs.setBool(_isSubscribedKey, true);
      await prefs.setBool('has_completed_payment', true);
      await prefs.setBool('premium_features_enabled', true);

      // Mark that we need to sync trial data with server when connectivity is restored
      await prefs.setBool('needs_trial_sync', true);

      // Refresh UI
      _refreshAppPremiumStatus();
      return;
    }

    // Start new trial - Set trial status
    await prefs.setBool(_trialStartedKey, true);

    // Set trial start date to current time
    final startDate = DateTime.now();
    await prefs.setString(_trialStartDateKey, startDate.toIso8601String());

    // Set trial end date to 7 days from now
    final endDate = startDate.add(const Duration(days: 7));
    await prefs.setString(_trialEndDateKey, endDate.toIso8601String());

    // Mark user as temporarily subscribed LOCALLY ONLY
    await prefs.setBool(_isSubscribedKey, true);
    await prefs.setBool('has_completed_payment', true);
    await prefs.setBool('premium_features_enabled', true);

    // Clear trial end popup shown flag
    await prefs.setBool(_trialEndPopupShownKey, false);

    // Mark that we need to sync trial data with server when connectivity is restored
    await prefs.setBool('needs_trial_sync', true);

    debugPrint('Free trial started locally. Ends on: $endDate');

    // Attempt to sync with server in the background
    _scheduleSyncTrialData();

    // Refresh UI to show premium status immediately
    _refreshAppPremiumStatus();

    // Show free trial started popup
    _showFreeTrialStartedPopup();
  }

  // Method to sync trial data with server when connectivity is available
  Future<void> _scheduleSyncTrialData() async {
    // Attempt to sync immediately, and if it fails, it will be attempted again on next app start
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token') ?? '';

    if (authToken.isNotEmpty) {
      try {
        debugPrint('Attempting to sync local trial data with server...');

        // Get local trial dates
        final trialStartDateStr = prefs.getString(_trialStartDateKey);
        final trialEndDateStr = prefs.getString(_trialEndDateKey);

        if (trialStartDateStr != null && trialEndDateStr != null) {
          final response = await http
              .post(
                Uri.parse('$_apiBaseUrl/auth/sync-trial-data'),
                headers: {
                  'Authorization': 'Bearer $authToken',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({
                  'trial_started': true,
                  'trial_start_date': trialStartDateStr,
                  'trial_end_date': trialEndDateStr
                }),
              )
              .timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            debugPrint('Successfully synced trial data with server');
            await prefs.setBool('needs_trial_sync', false);
          } else {
            debugPrint(
                'Failed to sync trial data, will retry later: ${response.statusCode}');
          }
        }
      } catch (e) {
        debugPrint('Error syncing trial data with server: $e');
        // Will be retried on next app start
      }
    }
  }

  // Method to show free trial started popup
  void _showFreeTrialStartedPopup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Free Trial Started'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.celebration, color: Colors.amber, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Your free trial has started! You now have full access to all premium features.',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This trial will expire in 7 days.',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Start Using Premium Features'),
                ),
              ],
            );
          },
        );
      }
    });
  }

  // Enhanced version of hasTrialEnded to check with server first
  Future<bool> hasTrialEnded() async {
    final prefs = await SharedPreferences.getInstance();
    final trialStarted = prefs.getBool(_trialStartedKey) ?? false;

    // If trial hasn't started, then it hasn't ended
    if (!trialStarted) {
      debugPrint('Trial not started yet');
      return false;
    }

    // Get auth token for server check
    final authToken = prefs.getString('auth_token') ?? '';

    // Check if we've done a recent check and can use cached result
    final lastCheckTime = prefs.getInt(_lastTrialCheckKey) ?? 0;
    final currentTimeMs = DateTime.now().millisecondsSinceEpoch;
    final timeSinceLastCheck = currentTimeMs - lastCheckTime;
    final cacheExpiration =
        _trialCheckCacheMinutes * 60 * 1000; // Convert minutes to milliseconds

    // Create a cached copy of the trial end date on first check to avoid redundant checking
    String? cachedTrialEndState = prefs.getString('_cached_trial_end_state');

    // If we have a cached trial end state and cache hasn't expired, use it
    if (cachedTrialEndState != null && timeSinceLastCheck < cacheExpiration) {
      debugPrint(
          'Using cached trial status - last check was ${timeSinceLastCheck ~/ 60000} minutes ago');
      return cachedTrialEndState == 'true'; // Convert the string to boolean
    }

    // Get the local trial end date for comparison
    final trialEndDateStr = prefs.getString(_trialEndDateKey);
    bool localTrialEnded = false;

    if (trialEndDateStr != null) {
      try {
        final trialEndDate = DateTime.parse(trialEndDateStr);
        final now = DateTime.now();
        localTrialEnded = now.isAfter(trialEndDate);

        // Store the cached state for future checks
        await prefs.setString(
            '_cached_trial_end_state', localTrialEnded.toString());
        await prefs.setInt(_lastTrialCheckKey, currentTimeMs);

        debugPrint('Updated cached trial status: ended=${localTrialEnded}');
      } catch (e) {
        debugPrint('Error parsing trial end date: $e');
      }
    }

    // Only check with server if we have a token and need to refresh the cache
    if (authToken.isNotEmpty &&
        (timeSinceLastCheck >= cacheExpiration ||
            cachedTrialEndState == null)) {
      try {
        debugPrint(
            'Cache expired or first check, contacting server for trial status');

        final response = await http.get(
          Uri.parse('$_apiBaseUrl/auth/trial-status'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 3));

        // Update last check timestamp regardless of response
        await prefs.setInt(_lastTrialCheckKey, currentTimeMs);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // If user is premium according to server, trial status doesn't matter
          if (data['is_premium'] == true) {
            debugPrint(
                'Server reports user is premium, trial status irrelevant');

            // Update local premium status
            await prefs.setBool(_isSubscribedKey, true);
            await prefs.setBool('has_completed_payment', true);
            await prefs.setBool('premium_features_enabled', true);

            // Cache the result
            await prefs.setString('_cached_trial_end_state', 'false');
            return false;
          }

          // Get trial status from server
          final trialActive = data['trial_active'] ?? false;
          final trialEnded = data['trial_ended'] ?? false;

          // Update local trial dates if provided by server
          if (data['trial_start_date'] != null) {
            await prefs.setString(_trialStartDateKey, data['trial_start_date']);
          }

          if (data['trial_end_date'] != null) {
            await prefs.setString(_trialEndDateKey, data['trial_end_date']);
          }

          debugPrint(
              'Server reports trial_active=$trialActive, trial_ended=$trialEnded');

          // If trial has ended according to server, update local premium status
          if (trialEnded) {
            await prefs.setBool(_isSubscribedKey, false);
            await prefs.setBool('has_completed_payment', false);
            await prefs.setBool('premium_features_enabled', false);
          }

          // Cache the server result
          await prefs.setString(
              '_cached_trial_end_state', trialEnded.toString());
          return trialEnded;
        }
      } catch (e) {
        debugPrint('Error checking trial status with server: $e');
      }
    }

    // Return the local trial ended state (from either cache or direct check)
    return localTrialEnded;
  }

  // Method to check if trial has been started with server check
  Future<bool> isTrialStarted() async {
    final prefs = await SharedPreferences.getInstance();
    final localTrialStarted = prefs.getBool(_trialStartedKey) ?? false;

    // To avoid excessive checking, if we know locally that trial is started, trust that
    if (localTrialStarted) {
      return true;
    }

    // Get auth token for server check
    final authToken = prefs.getString('auth_token') ?? '';

    // Check if we've done a recent check and can use cached result
    final lastCheckTime = prefs.getInt(_lastTrialCheckKey) ?? 0;
    final currentTimeMs = DateTime.now().millisecondsSinceEpoch;
    final timeSinceLastCheck = currentTimeMs - lastCheckTime;
    final cacheExpiration =
        _trialCheckCacheMinutes * 60 * 1000; // Convert minutes to milliseconds

    // If we did a check recently, use local data instead of calling server again
    if (lastCheckTime > 0 && timeSinceLastCheck < cacheExpiration) {
      debugPrint(
          'Using cached trial started status - last check was ${timeSinceLastCheck ~/ 60000} minutes ago');
      // Skip server check and use local data
      return localTrialStarted;
    }
    // If we have an auth token and cache is expired, check with server
    else if (authToken.isNotEmpty) {
      try {
        debugPrint(
            'Cache expired or first check, contacting server for trial status');

        final response = await http.get(
          Uri.parse('$_apiBaseUrl/auth/trial-status'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 3));

        // Update last check timestamp regardless of response
        await prefs.setInt(_lastTrialCheckKey, currentTimeMs);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // Get trial status from server
          final trialActive = data['trial_active'] ?? false;
          final serverTrialStarted = data['trial_start_date'] != null;

          debugPrint(
              'Server reports trial_active=$trialActive, trial_started=$serverTrialStarted');

          // Update local trial started flag based on server data
          if (serverTrialStarted && !localTrialStarted) {
            await prefs.setBool(_trialStartedKey, true);

            // Also update trial dates if provided
            if (data['trial_start_date'] != null) {
              await prefs.setString(
                  _trialStartDateKey, data['trial_start_date']);
            }

            if (data['trial_end_date'] != null) {
              await prefs.setString(_trialEndDateKey, data['trial_end_date']);
              // Also cache this for subscription end date display
              await prefs.setString(
                  '_cached_subscription_end_date', data['trial_end_date']);
            }

            return true;
          }

          return serverTrialStarted;
        }
      } catch (e) {
        debugPrint('Error checking trial started status with server: $e');
        // Fall back to local check on server error
      }
    }

    // Fallback to local check
    return localTrialStarted;
  }

  // Method to lock features when trial ends
  Future<void> lockFeaturesIfTrialEnded() async {
    final prefs = await SharedPreferences.getInstance();

    // Rate limiting - don't check too frequently
    final lastLockCheckTime = prefs.getInt('_last_lock_check_time') ?? 0;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final timeSinceLastCheck = currentTime - lastLockCheckTime;

    // Only check once per minute maximum
    if (timeSinceLastCheck < 60000) {
      // 60 seconds
      debugPrint(
          'Skipping lock check - last check was ${timeSinceLastCheck}ms ago');
      return;
    }

    // Update check timestamp
    await prefs.setInt('_last_lock_check_time', currentTime);

    // Check if we're in the middle of a refresh already
    final isRefreshing = prefs.getBool('_premium_refresh_in_progress') ?? false;
    if (isRefreshing) {
      debugPrint('Premium refresh already in progress, skipping lock check');
      return;
    }

    // FIRST check if user is premium from the server
    final authToken = prefs.getString('auth_token') ?? '';
    if (authToken.isNotEmpty) {
      try {
        final isPremium = await checkPremiumStatus(authToken)
            .timeout(const Duration(seconds: 2), onTimeout: () => false);

        if (isPremium) {
          debugPrint(
              'User is premium according to server, not locking features');
          // Update local premium flags to match server
          await prefs.setBool(_isSubscribedKey, true);
          await prefs.setBool('has_completed_payment', true);
          await prefs.setBool('premium_features_enabled', true);
          return;
        }
      } catch (e) {
        debugPrint(
            'Error checking server premium status during lock check: $e');
        // Continue with local checks
      }
    }

    // Now check trial status
    final trialStarted = prefs.getBool(_trialStartedKey) ?? false;
    if (!trialStarted) {
      debugPrint('Trial has not started yet, nothing to lock');
      return;
    }

    // Check if subscription type exists (indicates a real paid subscription)
    final subscriptionType = prefs.getString(_subscriptionTypeKey);
    final isRealSubscription =
        subscriptionType != null && subscriptionType.isNotEmpty;

    if (isRealSubscription) {
      debugPrint('User has a real paid subscription, not locking features');
      return;
    }

    // Check if we've done a recent check and can use cached result
    final lastCheckTime = prefs.getInt(_lastTrialCheckKey) ?? 0;
    final timeSinceLastTrialCheck = currentTime - lastCheckTime;
    final cacheExpiration =
        _trialCheckCacheMinutes * 60 * 1000; // Convert minutes to milliseconds

    // If the last check was recent, use local data instead of calling server again
    if (lastCheckTime > 0 && timeSinceLastTrialCheck < cacheExpiration) {
      debugPrint(
          'Using cached trial status for lock check - last check was ${timeSinceLastTrialCheck ~/ 60000} minutes ago');
      // Skip server check and use local data only for determining lock status
    }
    // If we have an auth token and cache is expired, check with server
    else if (authToken.isNotEmpty) {
      try {
        debugPrint(
            'Cache expired or first check, contacting server for locking decision');

        final response = await http.get(
          Uri.parse('$_apiBaseUrl/auth/trial-status'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 3));

        // Update last check timestamp regardless of response
        await prefs.setInt(_lastTrialCheckKey, currentTime);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);

          // Get trial status from server
          final isServerPremium = data['is_premium'] ?? false;
          final trialActive = data['trial_active'] ?? false;
          final trialEnded = data['trial_ended'] ?? false;

          debugPrint(
              'Server reports: isPremium=$isServerPremium, trialActive=$trialActive, trialEnded=$trialEnded');

          // If user is premium on the server, don't lock features
          if (isServerPremium) {
            debugPrint(
                'User is premium according to server, not locking features');

            // Update local premium flags to match server
            await prefs.setBool(_isSubscribedKey, true);
            await prefs.setBool('has_completed_payment', true);
            await prefs.setBool('premium_features_enabled', true);

            return;
          }

          // If server says trial ended, lock features
          if (trialEnded) {
            debugPrint('Server confirms trial has ended, locking features');

            // Remove subscription status locally
            await prefs.setBool(_isSubscribedKey, false);
            await prefs.setBool('has_completed_payment', false);
            await prefs.setBool('premium_features_enabled', false);

            // Refresh UI to reflect locked status but don't use full app refresh
            await _updatePremiumStateOnly();

            // Show trial ended popup if not already shown
            final hasShownEndPopup =
                prefs.getBool(_trialEndPopupShownKey) ?? false;
            if (!hasShownEndPopup) {
              _showTrialEndedPopup();
            }

            return;
          }

          // If server says trial is active, make sure premium flags are set
          if (trialActive) {
            debugPrint(
                'Server confirms trial is active, ensuring premium features are enabled');

            // Set premium flags locally
            await prefs.setBool(_isSubscribedKey, true);
            await prefs.setBool('has_completed_payment', true);
            await prefs.setBool('premium_features_enabled', true);

            return;
          }
        }
      } catch (e) {
        debugPrint('Error checking trial status with server: $e');
        // Fall back to local check on server error
      }
    }

    // Fallback: Use local storage check
    debugPrint('Falling back to local trial check');

    // Check if trial has ended by comparing current time with end date
    final trialEndDateStr = prefs.getString(_trialEndDateKey);
    if (trialEndDateStr == null) {
      debugPrint('No trial end date found, cannot determine if trial ended');
      return;
    }

    final trialEndDate = DateTime.parse(trialEndDateStr);
    final now = DateTime.now();
    final hasEnded = now.isAfter(trialEndDate);

    // Check if we've already shown the popup
    final hasShownEndPopup = prefs.getBool(_trialEndPopupShownKey) ?? false;

    debugPrint('Local trial check:');
    debugPrint('- Trial end date: $trialEndDate');
    debugPrint('- Current time: $now');
    debugPrint('- Trial has ended: $hasEnded');
    debugPrint('- Popup already shown: $hasShownEndPopup');

    if (hasEnded) {
      debugPrint('Trial has ended, locking features');

      // Remove subscription status LOCALLY ONLY
      await prefs.setBool(_isSubscribedKey, false);
      await prefs.setBool('has_completed_payment', false);
      await prefs.setBool('premium_features_enabled', false);

      // Use a more targeted refresh approach instead of full app refresh
      await _updatePremiumStateOnly();

      // Only show payment dialog if we haven't shown it yet
      if (!hasShownEndPopup) {
        _showTrialEndedPopup();
      }
    } else {
      debugPrint('Trial is still active, not locking features');
    }
  }

  // Helper method to update premium state without full app refresh
  Future<void> _updatePremiumStateOnly() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('Updating premium state without full app refresh');
      final context = navigatorKey.currentContext;
      if (context != null) {
        // Show a quick notification about the status change
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premium status updated'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  // Helper method to show trial ended popup
  void _showTrialEndedPopup() {
    debugPrint('Attempting to show trial ended popup');

    // Mark popup as shown in SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(_trialEndPopupShownKey, true).then((_) {
        debugPrint('Trial end popup marked as shown');
      });
    });

    // Show popup on UI thread
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Trial Period Ended'),
              content: const Text(
                  'Your 7-day free trial has ended. Subscribe now to continue using all premium features.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    // Show subscription options
                    startSubscriptionFlow(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Subscribe Now'),
                ),
              ],
            );
          },
        );
      } else {
        debugPrint(
            'Could not show trial end popup: no valid context available');
      }
    });
  }

  Future<bool> shouldShowSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool(_hasShownSubscriptionKey) ?? false;
    final isSubscribed = prefs.getBool(_isSubscribedKey) ?? false;
    final hasCompletedPayment = prefs.getBool('has_completed_payment') ?? false;
    final premiumFeaturesEnabled =
        prefs.getBool('premium_features_enabled') ?? false;
    final trialStarted = prefs.getBool(_trialStartedKey) ?? false;

    // Check if user is premium from any of the flags
    final isPremiumFromLocalFlags =
        isSubscribed || hasCompletedPayment || premiumFeaturesEnabled;

    // If premium according to any local flag, never show subscription
    if (isPremiumFromLocalFlags) {
      debugPrint(
          'User is premium according to local flags, not showing subscription modal');
      return false;
    }

    // If trial has started but ended, show subscription
    if (trialStarted) {
      final trialEnded = await hasTrialEnded();
      if (trialEnded) {
        debugPrint('Trial has ended, should show subscription modal');
        return true;
      }

      // If trial is active, don't show subscription
      debugPrint('Trial is active, not showing subscription modal');
      return false;
    }

    // Check if auth token exists, if so verify premium status with server
    final authToken = prefs.getString('auth_token') ?? '';
    if (authToken.isNotEmpty) {
      try {
        final isPremiumFromServer = await checkPremiumStatus(authToken);
        if (isPremiumFromServer) {
          debugPrint(
              'User is premium according to server, not showing subscription modal');

          // Update local flags to match server status
          await prefs.setBool(_isSubscribedKey, true);
          await prefs.setBool('has_completed_payment', true);
          await prefs.setBool('premium_features_enabled', true);

          return false;
        }
      } catch (e) {
        debugPrint('Error checking premium status from server: $e');
        // Fall back to local check
      }
    }

    // Regular logic: show if not previously shown and not subscribed and not in trial
    return !hasShown && !isSubscribed && !trialStarted;
  }

  Future<void> markSubscriptionShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasShownSubscriptionKey, true);
  }

  Future<void> startSubscriptionFlow(BuildContext context,
      {String? email}) async {
    bool userInitiatedPayment = false;

    // First, check if the user is already premium - if so, don't show upgrade options
    final prefs = await SharedPreferences.getInstance();
    final isPremiumFromPrefs = prefs.getBool(_isSubscribedKey) ?? false;
    final hasCompletedPayment = prefs.getBool('has_completed_payment') ?? false;
    final premiumFeaturesEnabled =
        prefs.getBool('premium_features_enabled') ?? false;

    // Check local premium flags first
    bool isPremium =
        isPremiumFromPrefs || hasCompletedPayment || premiumFeaturesEnabled;

    // Double check with server if user has auth token and isn't already marked as premium
    if (!isPremium) {
      final authToken = prefs.getString('auth_token') ?? '';
      if (authToken.isNotEmpty) {
        try {
          isPremium = await checkPremiumStatus(authToken);
          debugPrint(
              'Premium status from server in startSubscriptionFlow: $isPremium');

          // If premium according to server, update local flags
          if (isPremium) {
            await prefs.setBool(_isSubscribedKey, true);
            await prefs.setBool('has_completed_payment', true);
            await prefs.setBool('premium_features_enabled', true);

            // Refresh UI
            await refreshPremiumFeatures();
          }
        } catch (e) {
          debugPrint('Error checking premium status from server: $e');
        }
      }
    }

    // If user is premium, show a confirmation dialog and exit
    if (isPremium) {
      // First, ensure all premium flags are properly set and UI is refreshed
      await prefs.setBool(_isSubscribedKey, true);
      await prefs.setBool('has_completed_payment', true);
      await prefs.setBool('premium_features_enabled', true);

      // Force refresh premium features across the app
      await refreshPremiumFeatures();

      // Call the private refresh method for immediate UI update
      _refreshAppPremiumStatus();

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Already Premium'),
              content: const Text(
                  'You already have premium access. All features are unlocked.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();

                    // Show confirmation that features are unlocked
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Premium features are now active!'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
      return;
    }

    // Check if we should offer free trial instead of immediate payment
    final hasTrialStarted = await isTrialStarted();
    final trialHasEnded = await hasTrialEnded();

    try {
      if (!hasTrialStarted && !trialHasEnded) {
        // Automatically start free trial instead of showing the payment methods page
        debugPrint('Automatically starting free trial for new user');
        await startFreeTrial();

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Your 7-day free trial has started! Enjoy all premium features.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        }

        // Refresh app to show premium features
        _refreshAppPremiumStatus();
        return;
      } else if (hasTrialStarted && trialHasEnded) {
        // Trial has ended - show subscription modal for payment
        debugPrint('Trial has ended, showing subscription modal');
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.zero,
            child: SubscriptionModal(
              onClose: () => Navigator.of(dialogContext).pop(false),
              onStartFreeTrial: () {
                userInitiatedPayment = true;
                _buySubscription(dialogContext);
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ),
        );

        debugPrint('Subscription modal result: $result');
      } else if (hasTrialStarted && !trialHasEnded) {
        // Trial is active - inform user
        debugPrint('Trial is still active, showing information');

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Your free trial is already active. Enjoy premium features!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        }

        // Refresh app to show premium features
        _refreshAppPremiumStatus();
        return;
      }
    } catch (e) {
      debugPrint('Error in subscription flow: $e');
    } finally {
      // Mark subscription as shown regardless of outcome
      await markSubscriptionShown();

      // Only show success message in test mode when user initiated payment
      if (userInitiatedPayment && useTestMode) {
        // Only for test mode - in production, success is handled by the purchase listener
        await _saveSubscriptionData('annual');

        // We don't need to show success message here as it's shown in _buySubscription for test mode
        // and in _handleSuccessfulPurchase for real purchases
      }
    }
  }

  Future<void> _buySubscription(BuildContext context) async {
    debugPrint('_buySubscription called');

    // Always show initial feedback that something is happening
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Initializing payment...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Use test mode for development
    if (useTestMode) {
      debugPrint('Using TEST MODE for subscription');

      // Show processing message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Processing your payment (TEST MODE)...'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Simulate processing time
      await Future.delayed(const Duration(seconds: 2));

      // Save subscription data
      await _saveSubscriptionData('annual');

      // Refresh UI to show premium status
      _refreshAppPremiumStatus();

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Payment successful! (TEST MODE) You now have full access to Reconstruct Circle.'),
            backgroundColor: Colors.green,
          ),
        );

        // Force refresh the context to recognize premium status change
        await Future.delayed(const Duration(milliseconds: 500));

        // Navigate back if dialog is still showing
        if (ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      }
      return;
    }

    // Real payment implementation below
    if (!_isAvailable) {
      debugPrint('Store is not available: $_isAvailable');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Store is not available. Please try again later.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_products.isEmpty) {
      debugPrint('Products list is empty');

      // Try to reload products
      await _loadProducts();

      // Check again after reload attempt
      if (_products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Payment failed: No subscription products available. Please try again later.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );

        // Wait a moment then close the payment page
        await Future.delayed(const Duration(seconds: 2));
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
    }

    // Debug: Log available products
    for (var product in _products) {
      debugPrint(
          'Available product: ${product.id} - ${product.title} - ${product.price}');
    }

    // Find the product in a safer way
    ProductDetails? yearlyProduct;

    try {
      // Manual search through products (safer than firstWhere with Android)
      for (var product in _products) {
        if (product.id == yearlySubscriptionId) {
          yearlyProduct = product;
          break;
        }
      }

      // If product not found, throw exception
      if (yearlyProduct == null) {
        throw Exception('Product with ID $yearlySubscriptionId not found');
      }

      debugPrint(
          'Selected product: ${yearlyProduct.id} - ${yearlyProduct.title}');

      // Show processing message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Processing your payment...'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.blue,
          ),
        );
      }

      // Purchase parameters
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: yearlyProduct,
      );

      // Start the purchase
      final success =
          await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      debugPrint('Purchase initiated: $success');

      // The purchase will be completed through the listener
      // Just wait here for the listener to process it
      await Future.delayed(const Duration(seconds: 1));

      // We don't mark as successful here, the listener will do that if the purchase completes
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('Error during purchase: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );

        // Wait a moment then go back
        await Future.delayed(const Duration(seconds: 2));
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  void showRedeemCodeDialog(BuildContext context) {
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redeem Subscription Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your subscription code below:'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Code',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.trim();
              if (code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid code'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // In a real app, validate the code with your backend
              // For now, just simulate a successful redemption
              _simulateCodeRedemption(context, code);
              Navigator.of(context).pop();
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }

  Future<void> _simulateCodeRedemption(
      BuildContext context, String code) async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Validating code...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // For demo purposes, accept any code that starts with "RECONSTRUCT"
    if (code.toUpperCase().startsWith('RECONSTRUCT')) {
      await _saveSubscriptionData('annual');

      // Refresh UI to show premium status immediately
      _refreshAppPremiumStatus();

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Code successfully redeemed! You now have full access.'),
            backgroundColor: Colors.green,
          ),
        );

        // Close the payment page
        Navigator.of(context).pop();
      }
    } else {
      // Show error for invalid code
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid code. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSubscriptionData(String type) async {
    // This method is called after real payment is completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isSubscribedKey, true);
    await prefs.setString(_subscriptionTypeKey, type);

    // Also save using the key used in the main app
    await prefs.setBool('has_completed_payment', true);

    // Calculate subscription end date based on type
    final DateTime subscriptionEndDate = type == 'annual'
        ? DateTime.now().add(const Duration(days: 365))
        : DateTime.now().add(const Duration(days: 30));
    await prefs.setString(
        _subscriptionEndKey, subscriptionEndDate.toIso8601String());

    // Clear trial data as user has a full subscription now
    await prefs.setBool(_trialStartedKey, false);

    debugPrint(
        'Saved real payment subscription data locally. Type: $type, End date: $subscriptionEndDate');
  }

  // Enhanced version of isSubscribed to check server status with offline support
  Future<bool> isSubscribed() async {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token') ?? '';
    final isSubscribedLocally = prefs.getBool(_isSubscribedKey) ?? false;
    final hasCompletedPayment = prefs.getBool('has_completed_payment') ?? false;
    final premiumFeaturesEnabled =
        prefs.getBool('premium_features_enabled') ?? false;
    final subscriptionType = prefs.getString(_subscriptionTypeKey);
    final isRealPaidSubscription =
        subscriptionType != null && subscriptionType.isNotEmpty;

    // Check if trial is active (user is temporarily subscribed)
    final trialStarted = prefs.getBool(_trialStartedKey) ?? false;
    final trialEnded = await hasTrialEnded();

    // Debug info
    debugPrint(
        'isSubscribed check: isSubscribedLocally=$isSubscribedLocally, hasCompletedPayment=$hasCompletedPayment, premiumFeaturesEnabled=$premiumFeaturesEnabled');
    debugPrint(
        'trialStarted=$trialStarted, trialEnded=$trialEnded, isRealPaidSubscription=$isRealPaidSubscription');

    // If user has a real paid subscription, return true regardless of trial status
    if (isRealPaidSubscription) {
      debugPrint('User has a real paid subscription');
      return true;
    }

    // First check if trial is active (not ended) - this is the fastest check
    if (trialStarted && !trialEnded) {
      debugPrint('Active trial detected - enabling premium features');

      // Make sure all premium flags are set properly for the trial
      await prefs.setBool(_isSubscribedKey, true);
      await prefs.setBool('has_completed_payment', true);
      await prefs.setBool('premium_features_enabled', true);

      return true;
    }

    // If trial has ended, ensure all premium flags are reset
    if (trialStarted && trialEnded) {
      debugPrint('Trial has ended - resetting premium flags');
      await prefs.setBool(_isSubscribedKey, false);
      await prefs.setBool('has_completed_payment', false);
      await prefs.setBool('premium_features_enabled', false);
      return false;
    }

    // If we have an auth token and network is available, check premium status from server
    if (authToken.isNotEmpty) {
      try {
        // Use a very brief timeout to avoid long waits when offline
        final serverStatus = await checkPremiumStatus(authToken)
            .timeout(const Duration(seconds: 3), onTimeout: () {
          debugPrint(
              'Server check timed out in isSubscribed - using local status');
          return isSubscribedLocally && hasCompletedPayment && !trialEnded;
        });

        // If server confirms premium, update local storage and return true
        if (serverStatus) {
          await prefs.setBool(_isSubscribedKey, true);
          await prefs.setBool('has_completed_payment', true);
          await prefs.setBool('premium_features_enabled', true);

          // This is a real paid subscriber
          debugPrint('Server confirmed premium status: true');
          return true;
        }
      } catch (e) {
        debugPrint('Error checking premium status from server: $e');
        // Fall back to local storage if server check fails
      }
    } else {
      debugPrint('No auth token - using only local premium status');
    }

    // If offline or server check fails, determine status from local data

    // Check if user has completed payment according to local storage
    // Only consider them premium if trial hasn't ended
    if (isSubscribedLocally &&
        hasCompletedPayment &&
        (!trialStarted || !trialEnded)) {
      debugPrint(
          'Local storage indicates user is premium - enabling features offline');

      // Ensure premium_features_enabled is also set
      await prefs.setBool('premium_features_enabled', true);
      return true;
    }

    // If we got here, user is not premium
    debugPrint('User is not premium based on local data');

    // Reset all premium flags to ensure consistency
    await prefs.setBool(_isSubscribedKey, false);
    await prefs.setBool('has_completed_payment', false);
    await prefs.setBool('premium_features_enabled', false);

    return false;
  }

  Future<DateTime?> getSubscriptionEndDate() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // First check if we already have a cached end date to avoid unnecessary checks
      final cachedEndDateStr = prefs.getString('_cached_subscription_end_date');
      if (cachedEndDateStr != null) {
        try {
          return DateTime.parse(cachedEndDateStr);
        } catch (e) {
          // If cached date is invalid, continue with normal checks
          debugPrint('Error parsing cached subscription end date: $e');
        }
      }

      // Check if user is in trial
      final trialStarted = prefs.getBool(_trialStartedKey) ?? false;
      if (trialStarted) {
        final trialEndDateStr = prefs.getString(_trialEndDateKey);
        if (trialEndDateStr != null) {
          try {
            final endDate = DateTime.parse(trialEndDateStr);
            // Cache the result to avoid future parsing
            await prefs.setString(
                '_cached_subscription_end_date', trialEndDateStr);
            return endDate;
          } catch (e) {
            debugPrint('Error parsing trial end date: $e');
            return null;
          }
        }
      }

      // Otherwise return regular subscription end date
      final endDateStr = prefs.getString(_subscriptionEndKey);
      if (endDateStr == null) return null;

      try {
        final endDate = DateTime.parse(endDateStr);
        // Cache the result
        await prefs.setString('_cached_subscription_end_date', endDateStr);
        return endDate;
      } catch (e) {
        debugPrint('Error parsing subscription end date: $e');
        return null;
      }
    } catch (e) {
      debugPrint('Error in getSubscriptionEndDate: $e');
      return null;
    }
  }

  // Method to manually check and reset trial status (for debugging)
  Future<void> checkAndResetTrialStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final trialStarted = prefs.getBool(_trialStartedKey) ?? false;

    if (trialStarted) {
      final trialEndDateStr = prefs.getString(_trialEndDateKey);
      if (trialEndDateStr != null) {
        final trialEndDate = DateTime.parse(trialEndDateStr);
        final now = DateTime.now();

        debugPrint('Trial end date: $trialEndDate');
        debugPrint('Current time: $now');
        debugPrint('Trial ended: ${now.isAfter(trialEndDate)}');

        if (now.isAfter(trialEndDate)) {
          // Trial has ended, reset subscription status
          await prefs.setBool(_isSubscribedKey, false);
          await prefs.setBool('has_completed_payment', false);
          debugPrint('Trial has ended, reset subscription status');
        }
      }
    }
  }

  // Method for testing - resets trial status to start a new trial
  Future<void> resetTrialForTesting() async {
    final prefs = await SharedPreferences.getInstance();

    // Clear all trial and subscription data
    await prefs.setBool(_trialStartedKey, false);
    await prefs.setBool(_isSubscribedKey, false);
    await prefs.setBool('has_completed_payment', false);
    await prefs.setBool(_trialEndPopupShownKey, false);
    await prefs.remove(_trialStartDateKey);
    await prefs.remove(_trialEndDateKey);

    debugPrint('Trial status reset for testing');
  }

  // Clean up on dispose
  void dispose() {
    _subscription.cancel();
  }

  // Sync premium status with server if needed (for recovery)
  Future<void> syncPremiumStatusOnLogin(String authToken) async {
    final prefs = await SharedPreferences.getInstance();
    final needsSync = prefs.getBool('needs_premium_sync') ?? false;
    final persistentSyncNeeded =
        prefs.getBool('persistent_premium_sync_needed') ?? false;
    final isSubscribedLocally = prefs.getBool(_isSubscribedKey) ?? false;
    final hasCompletedPayment = prefs.getBool('has_completed_payment') ?? false;

    debugPrint('Premium sync check on login:');
    debugPrint('- Regular sync needed: $needsSync');
    debugPrint('- Persistent sync needed: $persistentSyncNeeded');
    debugPrint('- Is subscribed locally: $isSubscribedLocally');
    debugPrint('- Has completed payment: $hasCompletedPayment');

    // Always verify premium status with server on login for consistency
    final stopwatch = Stopwatch()..start();
    debugPrint('Verifying premium status with server after login...');

    try {
      // First check if the user has premium flags locally
      if (isSubscribedLocally || hasCompletedPayment) {
        // If premium locally, verify with server and update if needed
        debugPrint('User has premium status locally, verifying with server');
        final serverIsPremium = await checkPremiumStatus(authToken);

        if (serverIsPremium) {
          debugPrint('Server confirmed premium status');
          // Ensure all premium flags are consistently set
          await prefs.setBool(_isSubscribedKey, true);
          await prefs.setBool('has_completed_payment', true);
          await prefs.setBool('premium_features_enabled', true);

          // Also clear sync flags since we're in sync now
          await prefs.setBool('needs_premium_sync', false);
          await prefs.setBool('persistent_premium_sync_needed', false);

          stopwatch.stop();
          debugPrint(
              'Premium status verified with server in ${stopwatch.elapsedMilliseconds}ms');

          // Refresh UI
          await refreshPremiumFeatures();
          return;
        } else {
          // Server says not premium but local says premium
          debugPrint(
              'Server indicates user is NOT premium, but local flags say premium');

          // If there's a sync needed flag, try to update the server
          if (needsSync || persistentSyncNeeded) {
            debugPrint('Attempting to update server with local premium status');
            final success = await updatePremiumStatus(authToken);

            if (success) {
              debugPrint('Successfully updated server premium status');
              await prefs.setBool('needs_premium_sync', false);
              await prefs.setBool('persistent_premium_sync_needed', false);
              // Ensure all premium flags are consistently set
              await prefs.setBool(_isSubscribedKey, true);
              await prefs.setBool('has_completed_payment', true);
              await prefs.setBool('premium_features_enabled', true);
            } else {
              // Server update failed - keep the sync flags for next time
              debugPrint(
                  'Failed to update server premium status, will try again later');
            }
          } else {
            // No sync needed, but server disagrees with local status
            // In this case, trust the server and update local status
            debugPrint(
                'No sync needed, updating local premium status to match server (non-premium)');
            await prefs.setBool(_isSubscribedKey, false);
            await prefs.setBool('has_completed_payment', false);
            await prefs.setBool('premium_features_enabled', false);
          }
        }
      } else {
        // User doesn't have premium locally, but check server to be sure
        debugPrint(
            'User does not have premium status locally, checking with server');
        final serverIsPremium = await checkPremiumStatus(authToken);

        if (serverIsPremium) {
          debugPrint('Server says user IS premium, updating local status');
          // Update local flags to match server
          await prefs.setBool(_isSubscribedKey, true);
          await prefs.setBool('has_completed_payment', true);
          await prefs.setBool('premium_features_enabled', true);

          // Refresh UI
          await refreshPremiumFeatures();
        } else {
          debugPrint('Server confirms user is NOT premium');
          // Ensure all premium flags are consistently set to false
          await prefs.setBool(_isSubscribedKey, false);
          await prefs.setBool('has_completed_payment', false);
          await prefs.setBool('premium_features_enabled', false);
        }
      }
    } catch (e) {
      stopwatch.stop();
      debugPrint(
          'Error during premium status sync: $e (${stopwatch.elapsedMilliseconds}ms)');

      // On error, retain local status and sync flags
      if (isSubscribedLocally || hasCompletedPayment) {
        // If locally premium, keep it that way despite sync error
        await prefs.setBool(_isSubscribedKey, true);
        await prefs.setBool('has_completed_payment', true);
        await prefs.setBool('premium_features_enabled', true);
      }
    }

    // Refresh UI regardless of outcome
    await refreshPremiumFeatures();
  }

  // Check if premium status needs to be synchronized with the server
  Future<void> checkAndSyncPremiumStatus(String authToken) async {
    final prefs = await SharedPreferences.getInstance();
    final needsSync = prefs.getBool('needs_premium_sync') ?? false;

    // Check if we need to sync trial data with the server
    final needsTrialSync = prefs.getBool('needs_trial_sync') ?? false;

    if (needsTrialSync) {
      debugPrint(
          'Found pending trial data that needs to be synced with server');
      await _syncTrialDataWithServer(authToken);
    }

    if (needsSync) {
      debugPrint('Premium status sync needed, will sync during initialization');
      await syncPremiumStatusOnLogin(authToken);
      return;
    }

    // Verify premium status anyway to ensure consistency
    await syncPremiumStatusOnLogin(authToken);
  }

  // Method to sync pending trial data with the server
  Future<bool> _syncTrialDataWithServer(String authToken) async {
    if (authToken.isEmpty) return false;

    try {
      debugPrint('Syncing trial data with server...');
      final prefs = await SharedPreferences.getInstance();

      // Check if we've attempted sync recently to avoid repeated failures
      final lastSyncAttempt = prefs.getInt('_last_trial_sync_attempt') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeSinceLastAttempt = currentTime - lastSyncAttempt;

      // Don't attempt more than once every 30 minutes
      if (timeSinceLastAttempt < 1800000) {
        debugPrint(
            'Skipping trial sync - last attempt was ${timeSinceLastAttempt ~/ 60000} minutes ago');
        return false;
      }

      // Update the last sync attempt time
      await prefs.setInt('_last_trial_sync_attempt', currentTime);

      // Get the trial dates from local storage
      final trialStarted = prefs.getBool(_trialStartedKey) ?? false;
      final trialStartDateStr = prefs.getString(_trialStartDateKey);
      final trialEndDateStr = prefs.getString(_trialEndDateKey);

      if (!trialStarted ||
          trialStartDateStr == null ||
          trialEndDateStr == null) {
        debugPrint('No valid trial data found to sync');
        await prefs.setBool('needs_trial_sync', false);
        return false;
      }

      // Parse the dates to ensure they're in the correct format
      try {
        final trialStartDate = DateTime.parse(trialStartDateStr);
        final trialEndDate = DateTime.parse(trialEndDateStr);

        // Ensure the end date is exactly 7 days after the start date
        final correctEndDate = trialStartDate.add(const Duration(days: 7));
        final formattedStartDate = trialStartDate.toIso8601String();
        final formattedEndDate = correctEndDate.toIso8601String();

        // Update local storage with the corrected end date if needed
        if (trialEndDate != correctEndDate) {
          debugPrint(
              'Correcting local trial end date to ensure 7-day duration');
          await prefs.setString(_trialEndDateKey, formattedEndDate);
        }

        // Send the trial data to the server
        final response = await http
            .post(
              Uri.parse('$_apiBaseUrl/auth/sync-trial-data'),
              headers: {
                'Authorization': 'Bearer $authToken',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'trial_started': trialStarted,
                'trial_start_date': formattedStartDate,
                'trial_end_date': formattedEndDate
              }),
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          debugPrint('Successfully synced trial data with server');

          // If the server returns trial data, update local storage to match
          try {
            final data = jsonDecode(response.body);
            if (data['trial_start_date'] != null &&
                data['trial_end_date'] != null) {
              // Always use server dates as the source of truth
              await prefs.setString(
                  _trialStartDateKey, data['trial_start_date']);
              await prefs.setString(_trialEndDateKey, data['trial_end_date']);
              debugPrint('Updated local trial dates from server response');
            }
          } catch (e) {
            debugPrint('Error parsing server response: $e');
          }

          await prefs.setBool('needs_trial_sync', false);
          return true;
        } else if (response.statusCode == 404) {
          // If endpoint doesn't exist, clear the flag to prevent repeated attempts
          debugPrint(
              'Trial sync endpoint not found (404), disabling sync attempts');
          await prefs.setBool('needs_trial_sync', false);
          return false;
        } else {
          debugPrint(
              'Failed to sync trial data with server: ${response.statusCode}');
          return false;
        }
      } catch (e) {
        debugPrint('Error parsing trial dates: $e');
        return false;
      }
    } catch (e) {
      debugPrint('Error syncing trial data with server: $e');
      return false;
    }
  }

  // Public method to refresh premium features across the app
  Future<void> refreshPremiumFeatures() async {
    // Update local storage first to ensure all parts of the app see premium status
    final prefs = await SharedPreferences.getInstance();
    final isPremiumUser = await this.isSubscribed();

    await prefs.setBool(_isSubscribedKey, isPremiumUser);
    await prefs.setBool('has_completed_payment', isPremiumUser);
    await prefs.setBool('premium_features_enabled', isPremiumUser);

    // Call the private refresh method that does UI updates
    _refreshAppPremiumStatus();

    // Allow some time for the updates to propagate
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // Method to check if user has access (either in trial or subscribed)
  Future<bool> hasAccess() async {
    try {
      // Get auth token for server check
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token') ?? '';

      // Check if we've done a recent check and can use cached result
      final lastCheckTime = prefs.getInt(_lastTrialCheckKey) ?? 0;
      final currentTimeMs = DateTime.now().millisecondsSinceEpoch;
      final timeSinceLastCheck = currentTimeMs - lastCheckTime;
      final cacheExpiration = _trialCheckCacheMinutes *
          60 *
          1000; // Convert minutes to milliseconds

      // If we did a check recently, use local data instead of calling server again
      if (lastCheckTime > 0 && timeSinceLastCheck < cacheExpiration) {
        debugPrint(
            'Using cached access status - last check was ${timeSinceLastCheck ~/ 60000} minutes ago');
        // Skip server check and use local data
      }
      // If we have an auth token and cache is expired, check with server
      else if (authToken.isNotEmpty) {
        try {
          debugPrint(
              'Cache expired or first check, contacting server for access status');

          final response = await http.get(
            Uri.parse('$_apiBaseUrl/auth/trial-status'),
            headers: {
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/json',
            },
          ).timeout(const Duration(seconds: 3));

          // Update last check timestamp regardless of response
          await prefs.setInt(_lastTrialCheckKey, currentTimeMs);

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);

            // Server provides a direct has_access field that considers both premium status and trial
            final hasAccess = data['has_access'] ?? false;

            debugPrint('Server reports has_access=$hasAccess');

            // Update local storage to match server values
            if (data['is_premium'] == true) {
              await prefs.setBool(_isSubscribedKey, true);
              await prefs.setBool('has_completed_payment', true);
              await prefs.setBool('premium_features_enabled', true);
            } else if (data['trial_active'] == true) {
              // If trial is active, set premium flags locally
              await prefs.setBool(_isSubscribedKey, true);
              await prefs.setBool('has_completed_payment', true);
              await prefs.setBool('premium_features_enabled', true);
              await prefs.setBool(_trialStartedKey, true);

              // Update trial dates
              if (data['trial_start_date'] != null) {
                await prefs.setString(
                    _trialStartDateKey, data['trial_start_date']);
              }

              if (data['trial_end_date'] != null) {
                await prefs.setString(_trialEndDateKey, data['trial_end_date']);
              }
            } else if (data['trial_ended'] == true) {
              // If trial has ended, reset premium flags
              await prefs.setBool(_isSubscribedKey, false);
              await prefs.setBool('has_completed_payment', false);
              await prefs.setBool('premium_features_enabled', false);
            }

            return hasAccess;
          }
        } catch (e) {
          debugPrint('Error checking access with server: $e');
          // Fall back to local check on server error
        }
      }

      // Fallback: Check local storage
      debugPrint('Falling back to local access check');

      // Check local storage for immediate response when offline
      final localIsPremium = prefs.getBool(_isSubscribedKey) ?? false;
      final hasCompletedPayment =
          prefs.getBool('has_completed_payment') ?? false;
      final premiumFeaturesEnabled =
          prefs.getBool('premium_features_enabled') ?? false;
      final subscriptionType = prefs.getString(_subscriptionTypeKey);
      final isRealPaidSubscription =
          subscriptionType != null && subscriptionType.isNotEmpty;

      // Debug info for troubleshooting
      debugPrint('hasAccess check:');
      debugPrint('- localIsPremium: $localIsPremium');
      debugPrint('- hasCompletedPayment: $hasCompletedPayment');
      debugPrint('- premiumFeaturesEnabled: $premiumFeaturesEnabled');
      debugPrint('- isRealPaidSubscription: $isRealPaidSubscription');

      // If user has a real paid subscription, grant access immediately
      if (isRealPaidSubscription) {
        debugPrint('User has a real paid subscription, granting access');
        return true;
      }

      // Check for the most direct premium access flag
      if (premiumFeaturesEnabled) {
        debugPrint('Premium features explicitly enabled');

        // Double check if this is a trial that has ended
        final trialStarted = prefs.getBool(_trialStartedKey) ?? false;
        if (trialStarted) {
          final trialEnded = await hasTrialEnded();
          if (trialEnded) {
            debugPrint(
                'Trial has ended, revoking access despite enabled flags');
            await prefs.setBool(_isSubscribedKey, false);
            await prefs.setBool('has_completed_payment', false);
            await prefs.setBool('premium_features_enabled', false);
            return false;
          }
        }

        return true;
      }

      // If local storage says user is premium, grant access immediately
      if (localIsPremium && hasCompletedPayment) {
        debugPrint('User has premium access according to local flags');

        // Double check if this is a trial that has ended
        final trialStarted = prefs.getBool(_trialStartedKey) ?? false;
        if (trialStarted) {
          final trialEnded = await hasTrialEnded();
          if (trialEnded) {
            debugPrint(
                'Trial has ended, revoking access despite premium flags');
            await prefs.setBool(_isSubscribedKey, false);
            await prefs.setBool('has_completed_payment', false);
            await prefs.setBool('premium_features_enabled', false);
            return false;
          }
        }

        // Ensure premium_features_enabled is also set for consistency
        await prefs.setBool('premium_features_enabled', true);
        return true;
      }

      // Check if trial is active (not ended)
      final trialStarted = prefs.getBool(_trialStartedKey) ?? false;

      if (trialStarted) {
        // First check if trial has ended to ensure we have up-to-date status
        final trialEnded = await hasTrialEnded();
        debugPrint('Trial status: started=$trialStarted, ended=$trialEnded');

        // Reset premium status if trial has ended
        if (trialEnded) {
          debugPrint('Trial has ended, resetting premium status');
          await prefs.setBool(_isSubscribedKey, false);
          await prefs.setBool('has_completed_payment', false);
          await prefs.setBool('premium_features_enabled', false);
          return false;
        } else {
          debugPrint('Trial is active, granting access');

          // Make sure all premium flags are set
          await prefs.setBool(_isSubscribedKey, true);
          await prefs.setBool('has_completed_payment', true);
          await prefs.setBool('premium_features_enabled', true);

          return true;
        }
      }

      // If user is subscribed according to isSubscribed check
      final isSubscribed = await this.isSubscribed();
      if (isSubscribed) {
        debugPrint('User is premium according to isSubscribed check');
        return true;
      }

      // If all checks fail, user doesn't have access
      debugPrint('All premium checks failed - user does not have access');
      return false;
    } catch (e) {
      debugPrint(
          'Error in hasAccess: $e - using local premium status fallback');

      // Fallback to most basic local check on error
      final prefs = await SharedPreferences.getInstance();
      final premiumFeaturesEnabled =
          prefs.getBool('premium_features_enabled') ?? false;
      final hasCompletedPayment =
          prefs.getBool('has_completed_payment') ?? false;
      final trialStarted = prefs.getBool(_trialStartedKey) ?? false;

      // If this is a trial, check if it has ended
      if (trialStarted) {
        try {
          final trialEndDateStr = prefs.getString(_trialEndDateKey);
          if (trialEndDateStr != null) {
            final trialEndDate = DateTime.parse(trialEndDateStr);
            final now = DateTime.now();
            if (now.isAfter(trialEndDate)) {
              debugPrint('Trial has ended (fallback check) - no access');
              return false;
            }
          }
        } catch (e) {
          debugPrint('Error checking trial end date in fallback: $e');
        }
      }

      return premiumFeaturesEnabled || hasCompletedPayment;
    }
  }

  // Getter for apiBaseUrl
  String get apiBaseUrl => _apiBaseUrl;
}
