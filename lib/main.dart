import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/vision_board_page.dart';
import 'Annual_calender/annual_calendar_page.dart';
import 'pages/planners_page.dart';
import 'pages/box_them_vision_board.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter/services.dart';
import 'pages/premium_them_vision_board.dart';
import 'pages/post_it_theme_vision_board.dart';
import 'pages/winter_warmth_theme_vision_board.dart';
import 'pages/ruby_reds_theme_vision_board.dart';
import 'pages/coffee_hues_theme_vision_board.dart';
import 'Annual_calender/animal_theme_annual_planner.dart';
import 'Annual_calender/summer_theme_annual_planner.dart';
import 'Annual_calender/spaniel_theme_annual_planner.dart';
import 'Annual_calender/happy_couple_theme_annual_planner.dart';
import 'Annual_planner/annual_planner_page.dart';
import 'weekly_planners/weekly_planner_page.dart';
import 'login/login_page.dart';
import 'login/register_page.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding/onboarding_screen.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'services/subscription_manager.dart';
import 'config/api_config.dart';
import 'pages/active_tasks_page.dart';
import 'pages/active_dashboard_page.dart';
import 'Mind_tools/thought_shredder_page.dart';
import 'Mind_tools/make_me_smile_page.dart';
import 'Mind_tools/bubble_wrap_popper_page.dart';
import 'Mind_tools/break_things_page.dart';
import 'Mind_tools/dashboard_traker.dart';
import 'package:provider/provider.dart';
import 'Activity_Tools/memory_game_page.dart';
import 'Activity_Tools/color_me_page.dart';
import 'Activity_Tools/riddle_quiz_page.dart';
import 'Activity_Tools/sliding_puzzle_page.dart';
import 'Daily_notes/daily_notes_page.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/gestures.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Annual_planner/floral_theme_annual_planner.dart';
import 'Annual_planner/postit_theme_annual_planner.dart';
import 'Annual_planner/premium_theme_annual_planner.dart';
import 'Annual_planner/watercolor_theme_annual_planner.dart';
import 'weekly_planners/patterns_theme_weekly_planner.dart';
import 'weekly_planners/floral_theme_weekly_planner.dart';
import 'weekly_planners/watercolor_theme_weekly_planner.dart';
import 'weekly_planners/japanese_theme_weekly_planner.dart';
// After imports section, add this global variable

// Add keys to check payment status
const String _hasCompletedPaymentKey = 'has_completed_payment';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize API configuration
    // You can set this based on build environment or configuration
    // For now, we'll use development as default
    ApiConfig.initialize(
      environment:
          Environment.development, // Change to .production for release builds
    );

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize in-app purchases
    if (Platform.isAndroid) {
      InAppPurchaseAndroidPlatformAddition.enablePendingPurchases();
    }

    // Check if first launch
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    // Add stream listener for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      debugPrint('Auth state changed: ${user?.email ?? 'No user'}');
    });

    // Check if user is already signed in
    final currentUser = FirebaseAuth.instance.currentUser;
    debugPrint('Current user at startup: ${currentUser?.email}');

    // Clear the session flag for subscription modal at app startup
    await prefs.setBool('has_shown_subscription_this_session', false);

    await HomeWidget.registerInteractivityCallback(backgroundCallback);

    // IMPORTANT: Initialize the session flag for subscription modal
    // This prevents the subscription modal from appearing repeatedly
    await prefs.setBool('has_shown_subscription_this_session', false);

    // Set up platform channel to receive widget intent
    const platform = MethodChannel('com.reconstrect.visionboard/widget');
    platform.setMethodCallHandler((call) async {
      if (call.method == 'openVisionBoardWithTheme') {
        final category = call.arguments['category'] as String?;
        final theme = call.arguments['theme'] as String?;
        final widgetType = call.arguments['widget_type'] as String?;

        // Skip navigation if it's a calendar widget
        if (widgetType == "calendar") {
          return;
        }

        if (category != null && theme != null) {
          Widget page;
          switch (theme) {
            case 'Premium Vision Board':
              page = const PremiumThemeVisionBoard();
              break;
            case 'PostIt Vision Board':
              page = const PostItThemeVisionBoard();
              break;
            case 'Winter Warmth Vision Board':
              page = const WinterWarmthThemeVisionBoard();
              break;
            case 'Ruby Reds Vision Board':
              page = const RubyRedsThemeVisionBoard();
              break;
            case 'Coffee Hues Vision Board':
              page = const CoffeeHuesThemeVisionBoard();
              break;
            case 'Box Vision Board':
              page = VisionBoardDetailsPage(title: theme);
              break;
            default:
              return; // Don't navigate if theme doesn't match
          }

          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (context) => page),
          );
        }
      } else if (call.method == 'openEventsView') {
        final monthIndex = call.arguments['month_index'] as int;
        final eventId = call.arguments['event_id'] as String?;
        final calendarTheme = call.arguments['calendar_theme'] as String?;

        debugPrint("Opening events view with theme: $calendarTheme");

        if (navigatorKey.currentContext != null) {
          // Pop to home first
          while (navigatorKey.currentState!.canPop()) {
            navigatorKey.currentState!.pop();
          }

          // Navigate to appropriate theme page
          Widget destinationPage;
          debugPrint("Matching theme: $calendarTheme");

          switch (calendarTheme?.trim()) {
            case 'Animal theme 2025 Calendar':
              debugPrint("Opening Animal theme");
              destinationPage = AnimalThemeCalendarApp(
                  monthIndex: monthIndex, eventId: eventId, showEvents: true);
              break;
            case 'Summer theme 2025 Calendar':
              debugPrint("Opening Summer theme");
              destinationPage = SummerThemeCalendarApp(
                  monthIndex: monthIndex, eventId: eventId);
              break;
            case 'Spaniel theme 2025 Calendar':
              debugPrint("Opening Spaniel theme");
              destinationPage = SpanielThemeCalendarApp(
                  monthIndex: monthIndex, eventId: eventId);
              break;
            case 'Happy Couple theme 2025 Calendar':
              debugPrint("Opening Happy Couple theme");
              destinationPage = HappyCoupleThemeCalendarApp(
                  monthIndex: monthIndex, eventId: eventId);
              break;
            default:
              debugPrint("No match found, defaulting to Animal theme");
              destinationPage = AnimalThemeCalendarApp(
                  monthIndex: monthIndex, eventId: eventId);
          }

          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => destinationPage,
            ),
          );
        }
      }
    });

    // FOR TESTING: Override trial status to active
    // Comment this out for production or to fix repeated subscription modal
    // await prefs.setBool('trial_active', true);
    // await prefs.setString('trial_end_date',
    //     DateTime.now().add(const Duration(days: 7)).toIso8601String());

    runApp(MyApp(hasSeenOnboarding: hasSeenOnboarding));
  } catch (e) {
    debugPrint('Initialization error: $e');
    runApp(const MyApp(hasSeenOnboarding: false));
  }
}

// Global navigator key to access navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> backgroundCallback(Uri? uri) async {
  if (uri?.host == 'updatewidget') {
    // Handle widget update
    await HomeWidget.updateWidget(
      androidName: 'VisionBoardWidget',
      iOSName: 'VisionBoardWidget',
    );
  }
}

class MyApp extends StatelessWidget {
  final bool hasSeenOnboarding;
  const MyApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Reconstruct',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: hasSeenOnboarding ? AuthWrapper() : const OnboardingScreen(),
        routes: {
          '/auth': (context) => AuthWrapper(),
          '/home': (context) => const HomePage(),
          '/login': (context) => const LoginPage(),
          '/register': (context) => const RegisterPage(),
          // Add activity page routes
          ColorMePage.routeName: (context) => const ColorMePage(),
          MemoryGamePage.routeName: (context) => const MemoryGamePage(),
          RiddleQuizPage.routeName: (context) => const RiddleQuizPage(),
          SlidingPuzzlePage.routeName: (context) => const SlidingPuzzlePage(),
          DailyNotesPage.routeName: (context) => const DailyNotesPage(),
          BreakThingsPage.routeName: (context) => const BreakThingsPage(),
          ThoughtShredderPage.routeName: (context) =>
              const ThoughtShredderPage(),
          MakeMeSmilePage.routeName: (context) => const MakeMeSmilePage(),
          BubbleWrapPopperPage.routeName: (context) =>
              const BubbleWrapPopperPage(),
          // Add annual planner routes
          AnimalThemeCalendarApp.routeName: (context) =>
              const AnimalThemeCalendarApp(monthIndex: 0),
          HappyCoupleThemeCalendarApp.routeName: (context) =>
              const HappyCoupleThemeCalendarApp(monthIndex: 0),
          SpanielThemeCalendarApp.routeName: (context) =>
              const SpanielThemeCalendarApp(monthIndex: 0),
          SummerThemeCalendarApp.routeName: (context) =>
              const SummerThemeCalendarApp(monthIndex: 0),
          FloralThemeAnnualPlanner.routeName: (context) =>
              const FloralThemeAnnualPlanner(monthIndex: 0),
          PostItThemeAnnualPlanner.routeName: (context) =>
              const PostItThemeAnnualPlanner(monthIndex: 0),
          PremiumThemeAnnualPlanner.routeName: (context) =>
              const PremiumThemeAnnualPlanner(monthIndex: 0),
          WatercolorThemeAnnualPlanner.routeName: (context) =>
              const WatercolorThemeAnnualPlanner(monthIndex: 0),
          // Add vision board routes
          VisionBoardDetailsPage.routeName: (context) =>
              const VisionBoardDetailsPage(title: 'Box Them Vision Board'),
          PostItThemeVisionBoard.routeName: (context) =>
              const PostItThemeVisionBoard(),
          CoffeeHuesThemeVisionBoard.routeName: (context) =>
              const CoffeeHuesThemeVisionBoard(),
          PremiumThemeVisionBoard.routeName: (context) =>
              const PremiumThemeVisionBoard(),
          RubyRedsThemeVisionBoard.routeName: (context) =>
              const RubyRedsThemeVisionBoard(),
          WinterWarmthThemeVisionBoard.routeName: (context) =>
              const WinterWarmthThemeVisionBoard(),
          PatternsThemeWeeklyPlanner.routeName: (context) =>
              const PatternsThemeWeeklyPlanner(dayIndex: 0),
          FloralThemeWeeklyPlanner.routeName: (context) =>
              const FloralThemeWeeklyPlanner(dayIndex: 0),
          WatercolorThemeWeeklyPlanner.routeName: (context) =>
              const WatercolorThemeWeeklyPlanner(dayIndex: 0),
          JapaneseThemeWeeklyPlanner.routeName: (context) =>
              const JapaneseThemeWeeklyPlanner(dayIndex: 0),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isInitializing = true;
  bool _hasSeenOnboarding = false;
  bool _isFetchingUserData = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _initializationAttempts = 0;
  static const int _maxInitializationAttempts = 2;
  bool _isPremiumChecked = false; // Add a flag to track premium status check

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
    checkUserAndSaveToken();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
    } finally {
      setState(() {
        _isInitializing = false;
      });
    }
  }

  Future<void> checkUserAndSaveToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User is logged in, get their token and save it
      try {
        setState(() => _isInitializing = true);
        final token = await user.getIdToken();
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);

          debugPrint('Authentication token saved, checking premium status...');

          // Check premium status from server
          final subscriptionManager = SubscriptionManager();
          final isPremium = await subscriptionManager.checkPremiumStatus(token);

          // Check if there's any pending trial data that needs to be synced with the server
          final needsTrialSync = prefs.getBool('needs_trial_sync') ?? false;
          if (needsTrialSync) {
            debugPrint(
                'Found pending trial data that needs to be synced with server on login');
            await subscriptionManager.checkAndSyncPremiumStatus(token);
          }

          // If the user is premium, force refresh premium features
          if (isPremium) {
            debugPrint('User is premium, preloading premium features...');
            // Update local storage immediately
            await prefs.setBool('has_completed_payment', true);
            await prefs.setBool('is_subscribed', true);
            await prefs.setBool('premium_features_enabled', true);

            // Refresh premium features to ensure they're immediately accessible
            await subscriptionManager.refreshPremiumFeatures();

            debugPrint('Premium features unlocked and refreshed on login');
          } else {
            debugPrint('User is not premium, ensuring features are locked');
            // Ensure premium is set to false in local storage
            await prefs.setBool('has_completed_payment', false);
            await prefs.setBool('is_subscribed', false);
            await prefs.setBool('premium_features_enabled', false);
          }

          // Mark premium status as checked
          _isPremiumChecked = true;
        }
      } catch (e) {
        debugPrint('Error during premium status check on login: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isInitializing = false;
            _isPremiumChecked = true; // Ensure we mark as checked even on error
          });
        }
      }
    } else {
      // No user is logged in, no need to check premium status
      setState(() {
        _isInitializing = false;
        _isPremiumChecked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
        'Building AuthWrapper: initializing=$_isInitializing, hasSeenOnboarding=$_hasSeenOnboarding, isPremiumChecked=$_isPremiumChecked');

    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasSeenOnboarding) {
      return const OnboardingScreen();
    }

    return StreamBuilder<User?>(
      stream: _auth.authStateChanges(),
      builder: (context, snapshot) {
        debugPrint('Firebase auth state: ${snapshot.connectionState}, '
            'has data: ${snapshot.hasData}, '
            'has error: ${snapshot.hasError}');

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          // Don't call setState here, just use the values
          _hasError = true;
          _errorMessage = 'Error connecting to Firebase: ${snapshot.error}';

          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Authentication Error: ${snapshot.error}'),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _errorMessage = '';
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final user = snapshot.data;
        if (user != null) {
          // If authenticated, get user MySQL data
          // Don't call setState inside build
          final authService = Provider.of<AuthService>(context, listen: false);

          // Use a flag to trigger data loading after build, with limits on attempts
          if (!_isFetchingUserData &&
              authService.userData == null &&
              !authService.isInitializing &&
              _initializationAttempts < _maxInitializationAttempts) {
            // Schedule the state change for after this build cycle
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _isFetchingUserData = true;
                _initializationAttempts++;
              });

              debugPrint(
                  'Initializing auth service to get MySQL data (attempt $_initializationAttempts)...');
              authService.initialize().then((_) {
                if (mounted) {
                  setState(() {
                    _isFetchingUserData = false;
                  });
                }
              }).catchError((e) {
                debugPrint('Error initializing auth service: $e');
                if (mounted) {
                  setState(() {
                    _isFetchingUserData = false;
                    if (_initializationAttempts >= _maxInitializationAttempts) {
                      // Just continue without showing error if we've reached max attempts
                      debugPrint(
                          'Max initialization attempts reached, continuing without MySQL data');
                    } else {
                      _hasError = true;
                      _errorMessage = 'Error retrieving user data: $e';
                    }
                  });
                }
              });
            });
          }

          if (_isFetchingUserData) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading your profile...'),
                  ],
                ),
              ),
            );
          }

          if (_hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(_errorMessage),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _errorMessage = '';
                          // Reset initialization attempts counter when retrying manually
                          _initializationAttempts = 0;
                        });
                        authService.initialize();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Wait for premium status check to complete before showing HomePage
          if (!_isPremiumChecked) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading your subscription details...'),
                  ],
                ),
              ),
            );
          }

          return const HomePage();
        }

        // Not authenticated, show login screen
        return LoginPage();
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _selectedIndex =
      2; // Changed from 0 to 2 to automatically go to the "+" tab
  bool _isPremium = false;
  late User? firebaseUser;
  List<Widget> _pages = [];
  Timer? _trialCheckTimer; // Timer to periodically check if trial has ended
  final String _hasCompletedPaymentKey = 'has_completed_payment';
  final String _firstLaunchKey = 'first_launch';

  bool _isInitializing = true; // Add flag to track initialization

  @override
  void initState() {
    super.initState();
    // Register as a lifecycle observer to handle app state changes
    WidgetsBinding.instance.addObserver(this);

    // Get current user
    try {
      firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        debugPrint('Firebase user logged in: ${firebaseUser!.email}');
      }
    } catch (e) {
      debugPrint('Error getting Firebase user: $e');
    }

    // Initialize premium status immediately
    _initializePremiumStatus();

    // Set up a timer to check trial status more frequently (every 20 seconds)
    // This is especially important for the 7-day trial
    _trialCheckTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      debugPrint('Timer triggered: checking trial status');

      // Get the last refresh time to prevent too frequent refreshes
      SharedPreferences.getInstance().then((prefs) {
        final lastRefreshTime = prefs.getInt('_last_premium_refresh_time') ?? 0;
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        final timeSinceLastRefresh = currentTime - lastRefreshTime;

        // Only check if it's been at least 30 seconds since the last refresh
        if (timeSinceLastRefresh > 30000) {
          _checkTrialStatus();
        } else {
          debugPrint(
              'Skipping trial check - last refresh was ${timeSinceLastRefresh}ms ago');
        }
      });
    });
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    _trialCheckTimer?.cancel();
    super.dispose();
  }

  // New method to initialize premium status synchronously at startup
  Future<void> _initializePremiumStatus() async {
    debugPrint('Initializing premium status on HomePage startup');
    setState(() => _isInitializing = true);

    try {
      // First, check SharedPreferences for premium flags
      final prefs = await SharedPreferences.getInstance();
      final isPremiumFromPrefs =
          prefs.getBool(_hasCompletedPaymentKey) ?? false;
      final premiumFeaturesEnabled =
          prefs.getBool('premium_features_enabled') ?? false;
      final isSubscribed = prefs.getBool('is_subscribed') ?? false;

      // Get auth token for server verification
      final authToken = prefs.getString('auth_token') ?? '';

      // Use any local premium flag if it's true
      bool localIsPremium =
          isPremiumFromPrefs || premiumFeaturesEnabled || isSubscribed;

      debugPrint('Initial premium check: ' +
          'isPremiumFromPrefs=$isPremiumFromPrefs, ' +
          'premiumFeaturesEnabled=$premiumFeaturesEnabled, ' +
          'isSubscribed=$isSubscribed');

      // If we have auth token and no local premium status, verify with server
      if (authToken.isNotEmpty && !localIsPremium) {
        debugPrint('Checking premium status with server using token');
        final subscriptionManager = SubscriptionManager();
        final serverIsPremium =
            await subscriptionManager.checkPremiumStatus(authToken);

        if (serverIsPremium) {
          debugPrint('Server confirmed premium status');
          // Update local flags
          await prefs.setBool(_hasCompletedPaymentKey, true);
          await prefs.setBool('is_subscribed', true);
          await prefs.setBool('premium_features_enabled', true);
          localIsPremium = true;
        }
      }

      // Check trial status
      final subscriptionManager = SubscriptionManager();
      final trialStarted = await subscriptionManager.isTrialStarted();
      final trialEnded = await subscriptionManager.hasTrialEnded();

      // User has premium if either they have a subscription or active trial
      final isPremium = localIsPremium || (trialStarted && !trialEnded);

      debugPrint('Final premium status after checks: $isPremium ' +
          '(localIsPremium=$localIsPremium, trialActive=${trialStarted && !trialEnded})');

      // Initialize pages with premium status
      setState(() {
        _isPremium = isPremium;
        _isInitializing = false;
      });

      // Initialize pages with premium status
      _initPages();

      // Check first launch only after premium status is determined
      if (!isPremium) {
        await _checkFirstLaunch();
      }
    } catch (e) {
      debugPrint('Error initializing premium status: $e');
      // On error, default to non-premium
      setState(() {
        _isPremium = false;
        _isInitializing = false;
      });
      _initPages();
    }
  }

  // Initialize pages method
  void _initPages() {
    _pages = [
      HomeContent(isPremium: _isPremium),
      const PlannersPage(),
      const ActiveDashboardPage(),
      const DashboardTrackerPage(),
      const ProfilePage(),
    ];
  }

  // Handle app lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App has come to the foreground
      debugPrint('App resumed - checking trial status immediately');
      _checkTrialStatus();
    }
  }

  // Method to check if trial has ended and update premium status
  Future<bool> _checkTrialStatus() async {
    debugPrint('Checking trial status...');
    final subscriptionManager = SubscriptionManager();

    // Check if features should be locked
    await subscriptionManager.lockFeaturesIfTrialEnded();

    // Get current access status
    final hasAccess = await subscriptionManager.hasAccess();

    // Get current trial state
    final trialEnded = await subscriptionManager.hasTrialEnded();
    final prefs = await SharedPreferences.getInstance();
    final hasShownEndPopup = prefs.getBool('trial_end_popup_shown') ?? false;

    debugPrint(
        'Trial status: ended=$trialEnded, popupShown=$hasShownEndPopup, hasAccess=$hasAccess');

    // Clear SharedPreferences premium status if trial has ended
    if (!hasAccess && _isPremium) {
      await prefs.setBool(_hasCompletedPaymentKey, false);
      await prefs.setBool('is_subscribed', false);
      await prefs.setBool('premium_features_enabled', false);

      // Trial has ended, update premium status only if still mounted
      if (mounted) {
        setState(() {
          _isPremium = false;
        });
        _updatePages();
        debugPrint('Trial ended or not active - premium features LOCKED');
      }

      // DO NOT cancel the timer - we want to keep checking even after the popup is shown
      // This allows the popup to show again if the user dismisses it without subscribing
    } else if (hasAccess && !_isPremium) {
      // User has access but premium flag is false, update it if still mounted
      if (mounted) {
        setState(() {
          _isPremium = true;
        });
        _updatePages();
        debugPrint('Trial active - premium features UNLOCKED');
      }
    }

    return hasAccess;
  }

  // Load premium status from SharedPreferences
  Future<void> loadPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPremiumFromPrefs =
          prefs.getBool(_hasCompletedPaymentKey) ?? false;

      // Only consider SharedPreferences value if a subscription manager check has also been made
      final subscriptionManager = SubscriptionManager();
      final trialStarted = await subscriptionManager.isTrialStarted();
      final trialEnded = await subscriptionManager.hasTrialEnded();

      debugPrint(
          'Premium status check: isPremiumFromPrefs=$isPremiumFromPrefs, trialStarted=$trialStarted, trialEnded=$trialEnded');

      // Determine actual premium status
      final hasAccess = isPremiumFromPrefs || (trialStarted && !trialEnded);

      // Update UI state if component is still mounted
      if (mounted) {
        setState(() {
          _isPremium = hasAccess;
        });

        // Ensure pages are updated with new premium status
        _updatePages();

        debugPrint('Updated premium status: $_isPremium - UI refreshed');
      }

      // If trial ended but premium flag was true, make sure we update SharedPreferences
      if (!hasAccess && isPremiumFromPrefs) {
        await prefs.setBool(_hasCompletedPaymentKey, false);
        debugPrint('Reset premium flag in SharedPreferences');
      }
    } catch (e) {
      // On error, default to non-premium to be safe
      debugPrint('Error checking premium status: $e');
      if (mounted) {
        setState(() {
          _isPremium = false;
        });
        _updatePages();
      }
    }
  }

  // Check if this is the first launch and show payment page
  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;

    if (isFirstLaunch && mounted) {
      // Mark first launch as completed
      await prefs.setBool(_firstLaunchKey, false);

      // First check if user is already premium from existing flags or server
      final isPremiumFromPrefs =
          prefs.getBool(_hasCompletedPaymentKey) ?? false;
      final premiumFeaturesEnabled =
          prefs.getBool('premium_features_enabled') ?? false;
      final isSubscribed = prefs.getBool('is_subscribed') ?? false;
      final subscriptionManager = SubscriptionManager();

      // If the user already has premium status (from any local flag), skip showing the trial page
      bool isPremiumUser =
          isPremiumFromPrefs || premiumFeaturesEnabled || isSubscribed;

      // Double-check with server only if not already premium locally
      if (!isPremiumUser) {
        final authToken = prefs.getString('auth_token') ?? '';
        if (authToken.isNotEmpty) {
          try {
            isPremiumUser =
                await subscriptionManager.checkPremiumStatus(authToken);
            debugPrint('Checked premium status with server: $isPremiumUser');
          } catch (e) {
            debugPrint('Error checking premium status with server: $e');
          }
        }
      }

      // Skip showing trial page for premium users
      if (isPremiumUser) {
        debugPrint(
            'User is premium, skipping trial offer page and unlocking all features');

        // Ensure all premium flags are consistently set
        await prefs.setBool(_hasCompletedPaymentKey, true);
        await prefs.setBool('is_subscribed', true);
        await prefs.setBool('premium_features_enabled', true);

        setState(() {
          _isPremium = true;
        });
        _updatePages();

        // If the user already has premium status, show a welcome snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Welcome back! Your premium features are ready to use.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Check if user already had a trial that ended
      final hasTrialStarted = await subscriptionManager.isTrialStarted();
      final trialHasEnded = await subscriptionManager.hasTrialEnded();

      if (hasTrialStarted && trialHasEnded) {
        debugPrint(
            'User had a free trial that has ended, showing subscription modal');
        // Show subscription modal instead of starting trial
        // Get user email
        final email = firebaseUser?.email ?? 'user@example.com';
        await subscriptionManager.startSubscriptionFlow(context, email: email);
        return;
      }

      // Check again if user is premium before starting free trial
      // This is to handle the case where a user might be premium from another source
      final isUserPremium = await subscriptionManager
          .checkPremiumStatus(prefs.getString('auth_token') ?? '');
      if (isUserPremium) {
        debugPrint('User confirmed premium from server check, skipping trial');
        await prefs.setBool(_hasCompletedPaymentKey, true);
        await prefs.setBool('is_subscribed', true);
        await prefs.setBool('premium_features_enabled', true);

        setState(() {
          _isPremium = true;
        });
        _updatePages();
        return;
      }

      // For new users or users with no prior trial, automatically start free trial
      try {
        debugPrint('Automatically starting free trial for new user');
        // Start the free trial
        await subscriptionManager.startFreeTrial();

        // Ensure trial data is flagged for syncing with server
        await prefs.setBool('needs_trial_sync', true);

        // Get auth token and try to sync trial data immediately if token is available
        final authToken = prefs.getString('auth_token') ?? '';
        if (authToken.isNotEmpty) {
          debugPrint(
              'Auth token available, syncing trial data with server immediately');
          await subscriptionManager.checkAndSyncPremiumStatus(authToken);
        } else {
          debugPrint(
              'No auth token available, trial data will sync when user logs in');
        }

        // Update premium status based on trial status
        setState(() {
          _isPremium = true;
        });
        // Update the pages to reflect the new premium status
        _updatePages();

        // Show a message about the free trial
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Your 7-day free trial has started! Enjoy all premium features.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error starting free trial: $e');
        // Ensure premium is set to false in case of error
        setState(() {
          _isPremium = false;
        });
        _updatePages();
      }
    }
  }

  // Add this getter to make premium status available to other parts of the app
  bool get isPremium => _isPremium;

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while initializing
    if (_isInitializing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your premium features...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        toolbarHeight: 60,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: Image.asset('assets/logo.png', height: 32),
            ),
          ],
        ),
        actions: [
          if (_isPremium)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Icon(
                Icons.verified,
                color: Colors.blue,
                size: 24,
              ),
            ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          // Always navigate to the selected tab, including the + tab
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Browse'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: '+'),
          BottomNavigationBarItem(
              icon: Icon(Icons.track_changes), label: 'Tracker'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        selectedItemColor:
            const Color(0xFF23C4F7), // Color for the selected icon
        selectedLabelStyle: TextStyle(color: Colors.black),
        unselectedItemColor: Colors.black, // Color for unselected icons
      ),
    );
  }

  void _updatePages() {
    setState(() {
      _pages[0] = HomeContent(isPremium: _isPremium);
    });
  }
}

class HomeContent extends StatefulWidget {
  final bool isPremium;

  const HomeContent({
    super.key,
    this.isPremium = false,
  });

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _visionBoardKey = GlobalKey();
  bool _isHovered = false;

  // Access premium status from widget
  bool get isPremium => widget.isPremium;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Digital tools for \noptimal everyday \nperformance',
                    style: TextStyle(
                      fontSize: 30, // Slightly smaller for better balance
                      fontWeight:
                          FontWeight.w700, // Less heavy for modern appeal
                      height: 1.2,
                      color: Colors.black87, // Softer black for better UX
                      letterSpacing: 0.4,
                    ),
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Gain control over your thoughts.',
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color.fromARGB(255, 39, 38, 38),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    final RenderBox renderBox = _visionBoardKey.currentContext
                        ?.findRenderObject() as RenderBox;
                    final position = renderBox.localToGlobal(Offset.zero);
                    _scrollController.animateTo(
                      position.dy,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Try Mind Tools',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  key: _visionBoardKey,
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '2025 Digital Planners & Calendars',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const SizedBox(width: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildPlannerCard(
                              context,
                              'assets/vision-board-plain.jpg',
                              'Vision Board',
                            ),
                            const SizedBox(width: 18),
                            _buildPlannerCard(
                              context,
                              'assets/calendar.jpg',
                              'Interactive Calendar',
                            ),
                            const SizedBox(width: 18),
                            _buildPlannerCard(
                              context,
                              'assets/watercolor_theme_annual_planner.png',
                              'Annual Planner',
                            ),
                            const SizedBox(width: 18),
                            _buildPlannerCard(
                              context,
                              'assets/weakly_planer.png',
                              'Weekly Planner',
                            ),
                            const SizedBox(width: 18),
                            _buildPlannerCard(
                              context,
                              'assets/Activity_Tools/notes.png',
                              'Daily Notes',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mind Tools',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const SizedBox(width: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildPlannerCard(
                              context,
                              'assets/Mind_tools/thought-shredder.png',
                              'Thought Shredder',
                            ),
                            const SizedBox(width: 18),
                            _buildPlannerCard(
                              context,
                              'assets/Mind_tools/make-me-smile.png',
                              'Make Me Smile',
                            ),
                            const SizedBox(width: 18),
                            _buildPlannerCard(
                              context,
                              'assets/Mind_tools/bubble-popper.png',
                              'Bubble Wrap Popper',
                            ),
                            const SizedBox(width: 18),
                            _buildPlannerCard(
                              context,
                              'assets/Mind_tools/break-things.png',
                              'Break Things',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Activity Tools',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const SizedBox(width: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildPlannerCard(
                              context,
                              'assets/Activity_Tools/memory-game.png',
                              'Memory Game',
                            ),
                            const SizedBox(width: 18),
                            _buildPlannerCard(
                              context,
                              'assets/Activity_Tools/coloring-sheet.png',
                              'Coloring Page',
                            ),
                            const SizedBox(width: 18),
                            _buildPlannerCard(
                              context,
                              'assets/Activity_Tools/riddles.png',
                              'Riddle Quiz',
                            ),
                            const SizedBox(width: 18),
                            _buildPlannerCard(
                              context,
                              'assets/Activity_Tools/sliding-puzzle.png',
                              'Sliding Puzzle',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Check if a tool is available for free users
  bool _isToolAvailableForFree(String title) {
    // If user is premium, all tools should be available
    if (widget.isPremium) {
      return true;
    }

    // For free users, only allow basic templates
    if (title == 'Vision Board' ||
        title == 'Interactive Calendar' ||
        title == 'Weekly Planner' ||
        title == 'Annual Planner' ||
        title == 'Daily Notes') {
      return true;
    }
    // Lock all Mind Tools and Activity Tools for free users
    return false;
  }

  Widget _buildPlannerCard(
      BuildContext context, String imagePath, String title) {
    // Directly use widget.isPremium rather than checking SharedPreferences again
    // This ensures we're using the current premium status from the parent widget
    final bool isToolLocked =
        !widget.isPremium && !_isToolAvailableForFree(title);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _isHovered
            ? (Matrix4.identity()..translate(0, -10))
            : Matrix4.identity(),
        child: GestureDetector(
          onTap: () {
            if (isToolLocked) {
              _showPremiumDialog(context);
              return;
            }

            if (title == 'Interactive Calendar') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnnualCalenderPage(),
                ),
              );
            } else if (title == 'Vision Board') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VisionBoardPage(),
                ),
              );
            } else if (title == 'Annual Planner') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AnnualPlannerPage(),
                ),
              );
            } else if (title == 'Weekly Planner') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WeeklyPlannerPage(),
                ),
              );
            } else if (title == 'Thought Shredder') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ThoughtShredderPage(),
                ),
              );
            } else if (title == 'Make Me Smile') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MakeMeSmilePage(),
                ),
              );
            } else if (title == 'Bubble Wrap Popper') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BubbleWrapPopperPage(),
                ),
              );
            } else if (title == 'Break Things') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BreakThingsPage(),
                ),
              );
            } else if (title == 'Memory Game') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MemoryGamePage(),
                ),
              );
            } else if (title == 'Coloring Page') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ColorMePage(),
                ),
              );
            } else if (title == 'Riddle Quiz') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RiddleQuizPage(),
                ),
              );
            } else if (title == 'Sliding Puzzle') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SlidingPuzzlePage(),
                ),
              );
            } else if (title == 'Daily Notes') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DailyNotesPage(),
                ),
              );
            }
          },
          child: Container(
            width: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        imagePath,
                        width: 260,
                        height: 350,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Show lock icon overlay for locked features
                    if (isToolLocked)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.black.withOpacity(0.4),
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
                Container(
                  width: double.infinity,
                  color: Colors.white, // Background color set to white
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Show small lock icon next to title for locked features
                          if (isToolLocked)
                            Icon(
                              Icons.lock,
                              size: 16,
                              color: Colors.grey,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Show premium dialog
  void _showPremiumDialog(BuildContext context) {
    // First check if trial has ended
    final subscriptionManager = SubscriptionManager();
    subscriptionManager.hasTrialEnded().then((trialEnded) {
      if (trialEnded) {
        // If trial ended, show the dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Trial Period Ended'),
              content: const Text(
                  'Your free trial has ended. Subscribe now to continue using all premium features.'),
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
                  child: const Text('Subscribe Now'),
                ),
              ],
            );
          },
        );
      } else {
        // If trial is still active, show the regular premium dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Premium Feature'),
              content: const Text(
                  'This feature is only available for premium users. '
                  'Upgrade to premium to unlock all features.'),
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
    });
  }

  // Method to show payment page again if user wants to upgrade
  Future<void> _showPaymentPage() async {
    final email =
        Provider.of<AuthService>(context, listen: false).userData?['email'] ??
            FirebaseAuth.instance.currentUser?.email ??
            'user@example.com';

    // Use SubscriptionManager to handle the complete payment flow
    final subscriptionManager = SubscriptionManager();
    await subscriptionManager.startSubscriptionFlow(context, email: email);

    // Update premium status after flow completes
    final isPremium = await subscriptionManager.isSubscribed();
    if (isPremium && !widget.isPremium) {
      // Find HomePage state and update premium status
      final homePageState = context.findAncestorStateOfType<_HomePageState>();
      if (homePageState != null) {
        homePageState.loadPremiumStatus();
      }
    }
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String? _profileImagePath;
  String? _displayName;
  String? _bio;
  final AuthService _authService = AuthService();
  String? _userEmail;
  String? _userId;
  bool _isLoading = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();

    // Immediately check premium status to avoid delay in showing premium features
    loadPremiumStatus();

    // Ensure we get fresh data when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureProfileDataLoaded();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This ensures we reload data when the page becomes visible
    _ensureProfileDataLoaded();
  }

  // Method to ensure profile data is loaded
  Future<void> _ensureProfileDataLoaded() async {
    if (_authService.userData == null) {
      // Try to initialize auth service to load MySQL data
      setState(() => _isLoading = true);
      try {
        await _authService.initialize();
        await _loadProfileData();
      } catch (e) {
        debugPrint('Error loading profile data: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else if (_userEmail == null || _displayName == null) {
      // If we have auth data but profile isn't loaded, reload it
      _loadProfileData();
    }
  }

  Future<void> _loadProfileData() async {
    // Get Firebase user (if available)
    final firebaseUser = FirebaseAuth.instance.currentUser;

    // Get MySQL user data (if available)
    final mysqlUserData = _authService.userData;

    debugPrint('ProfilePage: Loading profile data');
    debugPrint('Firebase user: ${firebaseUser?.email}');
    debugPrint(
        'MySQL user data: ${mysqlUserData != null ? 'Available' : 'Not available'}');
    if (mysqlUserData != null) {
      debugPrint('MySQL name: ${mysqlUserData['name']}');
    }

    // Determine which user data to use
    if (mysqlUserData != null) {
      // Use MySQL user data
      _userEmail = mysqlUserData['email'];
      _userId = mysqlUserData['id']?.toString() ?? 'mysql_user';

      // Set display name from MySQL data
      final name = mysqlUserData['name'];
      if (name != null && name.toString().trim().isNotEmpty) {
        _displayName = name.toString().trim();
        _nameController.text = _displayName ?? '';
        debugPrint('Using MySQL name: $_displayName');
      } else {
        // If name is missing from MySQL data but we have an email, use a better name
        if (_userEmail != null) {
          // Use a properly formatted version of the email prefix
          String emailPrefix = _userEmail!.split('@')[0];
          // Capitalize the first letter and format with spaces
          emailPrefix = emailPrefix
              .replaceAllMapped(RegExp(r'[_\-.]'), (match) => ' ')
              .split(' ')
              .map((word) {
                if (word.isNotEmpty) {
                  return '${word[0].toUpperCase()}${word.substring(1)}';
                }
                return '';
              })
              .join(' ')
              .trim();

          _displayName = emailPrefix;
          _nameController.text = _displayName ?? '';
          debugPrint('Using formatted email prefix as name: $_displayName');
        }
      }

      debugPrint('Using MySQL user data: $_userEmail');
    } else if (firebaseUser != null) {
      // Fall back to Firebase user data
      _userEmail = firebaseUser.email;
      _userId = firebaseUser.uid;

      // Try to get display name from Firebase first
      if (firebaseUser.displayName != null &&
          firebaseUser.displayName!.trim().isNotEmpty) {
        _displayName = firebaseUser.displayName!.trim();
        debugPrint('Using Firebase displayName: $_displayName');
      } else if (_userEmail != null) {
        // Format email prefix if no display name available
        String emailPrefix = _userEmail!.split('@')[0];
        // Capitalize the first letter and format with spaces
        emailPrefix = emailPrefix
            .replaceAllMapped(RegExp(r'[_\-.]'), (match) => ' ')
            .split(' ')
            .map((word) {
              if (word.isNotEmpty) {
                return '${word[0].toUpperCase()}${word.substring(1)}';
              }
              return '';
            })
            .join(' ')
            .trim();

        _displayName = emailPrefix;
        debugPrint('Using formatted email prefix as name: $_displayName');
      }

      _nameController.text = _displayName ?? '';
      debugPrint('Using Firebase user data: $_userEmail');
    }

    // Load additional profile data from SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    if (_userId != null) {
      setState(() {
        // Try to load display name from shared preferences if not set above
        if (_displayName == null || _displayName!.isEmpty) {
          _displayName = prefs.getString('displayName_$_userId');
          debugPrint('Using displayName from SharedPreferences: $_displayName');
        }

        _bio = prefs.getString('bio_$_userId');
        _profileImagePath = prefs.getString('profileImage_$_userId') ??
            (firebaseUser?.photoURL);

        _nameController.text = _displayName ?? '';
        _bioController.text = _bio ?? '';
      });
    }
  }

  // Load premium status from SharedPreferences
  Future<void> loadPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isPremiumFromPrefs =
          prefs.getBool(_hasCompletedPaymentKey) ?? false;

      // Only consider SharedPreferences value if a subscription manager check has also been made
      final subscriptionManager = SubscriptionManager();
      final trialStarted = await subscriptionManager.isTrialStarted();
      final trialEnded = await subscriptionManager.hasTrialEnded();

      debugPrint(
          'Premium status check: isPremiumFromPrefs=$isPremiumFromPrefs, trialStarted=$trialStarted, trialEnded=$trialEnded');

      // Determine actual premium status
      final hasAccess = isPremiumFromPrefs || (trialStarted && !trialEnded);

      // Update UI state if component is still mounted
      if (mounted) {
        setState(() {
          _isPremium = hasAccess;
        });

        debugPrint('Updated premium status: $_isPremium');
      }

      // If trial ended but premium flag was true, make sure we update SharedPreferences
      if (!hasAccess && isPremiumFromPrefs) {
        await prefs.setBool(_hasCompletedPaymentKey, false);
        debugPrint('Reset premium flag in SharedPreferences');
      }
    } catch (e) {
      // On error, default to non-premium to be safe
      debugPrint('Error checking premium status: $e');
      if (mounted) {
        setState(() {
          _isPremium = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40),
                          ),
                        ),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundImage: _getProfileImage(),
                                  child: _profileImagePath == null
                                      ? const Icon(Icons.person, size: 60)
                                      : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: CircleAvatar(
                                    backgroundColor: theme.colorScheme.primary,
                                    radius: 20,
                                    child: IconButton(
                                      icon: const Icon(Icons.camera_alt,
                                          size: 20),
                                      color: Colors.white,
                                      onPressed: _pickImage,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            if (_displayName?.isNotEmpty ?? false)
                              Text(
                                _displayName!,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else if (_userEmail != null)
                              // Show formatted email as fallback if no name available
                              Text(
                                _userEmail!
                                    .split('@')[0]
                                    .replaceAllMapped(
                                        RegExp(r'[_\-.]'), (match) => ' ')
                                    .split(' ')
                                    .map((word) {
                                      if (word.isNotEmpty) {
                                        return '${word[0].toUpperCase()}${word.substring(1)}';
                                      }
                                      return '';
                                    })
                                    .join(' ')
                                    .trim(),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              _userEmail ?? 'No email available',
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            // Place premium status widget here (already implemented)
                            _buildPremiumStatus(),
                            Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.celebration,
                                            color: theme.colorScheme.primary),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'Welcome to Reconstruct',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Thanks for creating your Reconstruct account.\n\n'
                                      'Your personalised dashboard is getting ready and will be available shortly. '
                                      'Save, edit and download calendars, coloring sheets and planners. '
                                      'Use the daily activity tracker to build new habits and more!',
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const PlannersPage(),
                                              ),
                                            );
                                          },
                                          child: const Text('Explore Features'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            backgroundColor:
                                                theme.colorScheme.primary,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const UserSettingsPage(),
                                              ),
                                            );
                                          },
                                          child: const Text('My Active Boards'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const DashboardTrackerPage(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.dashboard),
                                      label: const Text('Activity Dashboard'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF4A9F68),
                                        foregroundColor: Colors.white,
                                        minimumSize:
                                            const Size(double.infinity, 48),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[700],
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _signOut,
                                icon: const Icon(Icons.logout),
                                label: const Text('Sign Out'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  ImageProvider? _getProfileImage() {
    if (_profileImagePath == null) return null;
    if (_profileImagePath!.startsWith('http')) {
      return NetworkImage(_profileImagePath!);
    }
    return FileImage(File(_profileImagePath!));
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImagePath = image.path;
      });

      if (_userId != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImage_$_userId', image.path);
        debugPrint('Profile image saved for user ID: $_userId');
      } else {
        debugPrint('No user ID available to save profile image');
      }
    }
  }

  Future<void> _signOut() async {
    bool confirm = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Sign Out'),
              content: const Text('Are you sure you want to sign out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Sign Out'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirm) {
      try {
        // Clear local data
        await _clearProfileData();

        // Use AuthService to properly sign out from both MySQL and Firebase
        await _authService.signOut();
        debugPrint('User signed out successfully');

        // Navigate to auth wrapper
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/auth', (route) => false);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _clearProfileData() async {
    if (_userId != null) {
      // Clear ALL SharedPreferences data when signing out
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('displayName_$_userId');
      await prefs.remove('bio_$_userId');
      await prefs.remove('profileImage_$_userId');
      debugPrint('Profile data cleared for user ID: $_userId');
      await prefs.clear();
      debugPrint('All SharedPreferences data cleared during sign out');

      // Keep the onboarding flag set to true so user doesn't see onboarding again
      await prefs.setBool('hasSeenOnboarding', true);
    }
  }

  // Add a widget to show premium status in the profile page
  Widget _buildPremiumStatus() {
    return FutureBuilder<bool>(
        future: _isUserOnTrial(),
        builder: (context, snapshot) {
          final bool isOnTrial = snapshot.data ?? false;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isPremium
                  ? (isOnTrial ? Colors.amber.shade50 : Colors.blue.shade50)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isPremium
                    ? (isOnTrial ? Colors.amber.shade200 : Colors.blue.shade200)
                    : Colors.grey.shade300,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isPremium
                      ? (isOnTrial
                          ? Colors.amber.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1))
                      : Colors.transparent,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isPremium
                            ? (isOnTrial
                                ? Colors.amber.shade100
                                : Colors.blue.shade100)
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPremium
                            ? (isOnTrial ? Icons.access_time : Icons.verified)
                            : Icons.lock,
                        color: _isPremium
                            ? (isOnTrial
                                ? Colors.amber.shade700
                                : Colors.blue.shade700)
                            : Colors.grey.shade700,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isPremium
                                ? (isOnTrial
                                    ? 'Trial Member'
                                    : 'Premium Member')
                                : 'Free Account',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _isPremium
                                  ? (isOnTrial
                                      ? Colors.amber.shade800
                                      : Colors.blue.shade800)
                                  : Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FutureBuilder<String>(
                              future: _getTrialEndDate(),
                              builder: (context, dateSnapshot) {
                                final String trialEndDate =
                                    dateSnapshot.data ?? '';
                                return Text(
                                  _isPremium
                                      ? (isOnTrial
                                          ? 'Your trial ends on $trialEndDate'
                                          : 'You have full access to all premium features')
                                      : 'Upgrade to premium for full access',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _isPremium
                                        ? (isOnTrial
                                            ? Colors.amber.shade700
                                            : Colors.blue.shade700)
                                        : Colors.grey.shade600,
                                  ),
                                );
                              }),
                        ],
                      ),
                    ),
                    if (!_isPremium)
                      ElevatedButton(
                        onPressed: () => _showPaymentPage(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Upgrade',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                // Add cancellation text only for paid premium users (not for free or trial users)
                if (_isPremium && !isOnTrial)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600]),
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
                                text:
                                    " anytime, no charges after current billing cycle.",
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        });
  }

  // Helper method to check if user is on trial
  Future<bool> _isUserOnTrial() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if trial is active
    final trialStarted = prefs.getBool('trial_started') ?? false;

    if (trialStarted) {
      // Check if trial has ended
      final trialEndDateStr = prefs.getString('trial_end_date');
      if (trialEndDateStr != null) {
        final trialEndDate = DateTime.parse(trialEndDateStr);
        final now = DateTime.now();

        // If trial end date is in the future, user is on trial
        if (now.isBefore(trialEndDate)) {
          return true;
        }
      }
    }

    return false;
  }

  // Helper method to get formatted trial end date
  Future<String> _getTrialEndDate() async {
    try {
      // Get the auth token to check server
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token') ?? '';
      final subscriptionManager = SubscriptionManager();

      // Try to get the most current trial end date from server
      if (authToken.isNotEmpty) {
        try {
          // Check for pending trial sync first
          final needsTrialSync = prefs.getBool('needs_trial_sync') ?? false;
          if (needsTrialSync) {
            debugPrint(
                'Found pending trial sync, syncing before displaying end date');
            await subscriptionManager.checkAndSyncPremiumStatus(authToken);
          }

          // Make a direct API call to get the latest trial status
          final response = await http.get(
            Uri.parse('https://reconstrect-api.onrender.com/auth/trial-status'),
            headers: {
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/json',
            },
          ).timeout(const Duration(seconds: 3));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data['trial_end_date'] != null) {
              final serverEndDate = DateTime.parse(data['trial_end_date']);
              // If server has trial end date, update local storage and use it
              await prefs.setString(
                  'trial_end_date', serverEndDate.toIso8601String());
              return "${serverEndDate.day} ${_getMonthName(serverEndDate.month)} ${serverEndDate.year}";
            }
          }
        } catch (e) {
          debugPrint('Error getting trial end date from server: $e');
          // Fall back to local storage
        }
      }

      // If we get here, use local storage
      final trialEndDateStr = prefs.getString('trial_end_date');
      if (trialEndDateStr != null) {
        final trialEndDate = DateTime.parse(trialEndDateStr);
        // Format date as "Day Month Year" (e.g., "27 March 2023")
        return "${trialEndDate.day} ${_getMonthName(trialEndDate.month)} ${trialEndDate.year}";
      }
    } catch (e) {
      debugPrint('Error retrieving trial end date: $e');
    }

    return "soon";
  }

  // Helper method to convert month number to name
  String _getMonthName(int month) {
    const monthNames = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return monthNames[month - 1];
  }

  // Method to show payment page when user wants to upgrade
  Future<void> _showPaymentPage() async {
    final email = _userEmail ??
        FirebaseAuth.instance.currentUser?.email ??
        'user@example.com';

    // Use SubscriptionManager to handle the complete payment flow
    final subscriptionManager = SubscriptionManager();
    await subscriptionManager.startSubscriptionFlow(context, email: email);

    // Update premium status after flow completes
    final isPremium = await subscriptionManager.isSubscribed();
    if (isPremium && !_isPremium) {
      // Update local state
      setState(() {
        _isPremium = true;
      });

      // Find HomePage state and update premium status globally
      final homePageState = context.findAncestorStateOfType<_HomePageState>();
      if (homePageState != null) {
        homePageState.loadPremiumStatus();
      }
    }
  }
}

class UserSettingsPage extends StatelessWidget {
  const UserSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ActiveTasksPage();
  }
}
