import 'package:flutter/material.dart';
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
import 'services/auth_service.dart';
import 'services/subscription_manager.dart';
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
import 'Annual_planner/floral_theme_annual_planner.dart';
import 'Annual_planner/postit_theme_annual_planner.dart';
import 'Annual_planner/premium_theme_annual_planner.dart';
import 'Annual_planner/watercolor_theme_annual_planner.dart';
import 'weekly_planners/patterns_theme_weekly_planner.dart';
import 'weekly_planners/floral_theme_weekly_planner.dart';
import 'weekly_planners/watercolor_theme_weekly_planner.dart';
import 'weekly_planners/japanese_theme_weekly_planner.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'utils/platform_features.dart';

import 'dart:developer';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'config/supabase_config.dart';
import 'services/database_service.dart';
import 'services/user_service.dart';
import 'services/supabase_database_service.dart';
import 'package:firebase_core/firebase_core.dart';

// Constants
const String _hasCompletedPaymentKey = 'has_completed_payment';
const String _firstLaunchKey = 'first_launch';

// Global variables
bool isOffline = false;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Connectivity monitoring
Future<void> initConnectivity() async {
  try {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      log('Device has no network connectivity');
      isOffline = true;
      return;
    }

    // Check Supabase connectivity
    try {
      await supabase.Supabase.instance.client
          .from('user')
          .select('id')
          .limit(1);
      isOffline = false;
      log('Supabase connectivity check successful');
    } catch (e) {
      log('Supabase connectivity check failed: $e');
      isOffline = true;
    }

    // Listen for connectivity changes
    Connectivity().onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        isOffline = true;
      } else {
        _checkSupabaseReachability();
      }
    });
  } catch (e) {
    log('Error initializing connectivity monitoring: $e');
    isOffline = false;
  }
}

Future<void> _checkSupabaseReachability() async {
  try {
    await supabase.Supabase.instance.client.from('user').select('id').limit(1);
    isOffline = false;
  } catch (e) {
    isOffline = true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // Initialize core services
  await _initializeApp();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
      ChangeNotifierProvider<SubscriptionManager>(
          create: (_) => SubscriptionManager()),
    ],
    child: const MyApp(),
  ));
}

Future<void> _initializeApp() async {
  try {
    // Initialize Supabase
    await SupabaseConfig.initialize();
    debugPrint('Supabase initialized successfully');

    // Initialize connectivity monitoring
    await initConnectivity();

    // Load guest state from SharedPreferences
    await AuthService.loadGuestState();

    // In-app purchases are automatically configured for Android in newer versions

    // Set up home widget communication
    HomeWidget.setAppGroupId('group.com.reconstrect.app');
    HomeWidget.registerBackgroundCallback(backgroundCallback);
  } catch (e) {
    debugPrint('Error during app initialization: $e');
  }
}

Future<void> backgroundCallback(Uri? uri) async {
  if (uri?.host == 'updatewidget') {
    await HomeWidget.updateWidget(
      androidName: 'VisionBoardWidget',
      iOSName: 'VisionBoardWidget',
    );
    await HomeWidget.updateWidget(
      androidName: 'DailyNotesWidget',
      iOSName: 'DailyNotesWidget',
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _hasSeenOnboarding = false;
  bool _isCheckingOnboarding = true;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

      if (mounted) {
        setState(() {
          _hasSeenOnboarding = hasSeenOnboarding;
          _isCheckingOnboarding = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      if (mounted) {
        setState(() {
          _hasSeenOnboarding = false;
          _isCheckingOnboarding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingOnboarding) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Reconstruct',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: _hasSeenOnboarding ? const AuthWrapper() : const OnboardingScreen(),
      routes: _buildRoutes(),
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      '/auth': (context) => const AuthWrapper(),
      '/home': (context) => const HomePage(),
      '/login': (context) => const LoginPage(),
      '/register': (context) => const RegisterPage(),
      // Activity pages
      ColorMePage.routeName: (context) => const ColorMePage(),
      MemoryGamePage.routeName: (context) => const MemoryGamePage(),
      RiddleQuizPage.routeName: (context) => const RiddleQuizPage(),
      SlidingPuzzlePage.routeName: (context) => const SlidingPuzzlePage(),
      DailyNotesPage.routeName: (context) => const DailyNotesPage(),
      BreakThingsPage.routeName: (context) => const BreakThingsPage(),
      ThoughtShredderPage.routeName: (context) => const ThoughtShredderPage(),
      MakeMeSmilePage.routeName: (context) => const MakeMeSmilePage(),
      BubbleWrapPopperPage.routeName: (context) => const BubbleWrapPopperPage(),
      // Annual planner routes
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
      // Vision board routes
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
      // Weekly planner routes
      PatternsThemeWeeklyPlanner.routeName: (context) =>
          const PatternsThemeWeeklyPlanner(dayIndex: 0),
      FloralThemeWeeklyPlanner.routeName: (context) =>
          const FloralThemeWeeklyPlanner(dayIndex: 0),
      WatercolorThemeWeeklyPlanner.routeName: (context) =>
          const WatercolorThemeWeeklyPlanner(dayIndex: 0),
      JapaneseThemeWeeklyPlanner.routeName: (context) =>
          const JapaneseThemeWeeklyPlanner(dayIndex: 0),
    };
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService.instance;
  bool _isInitializing = true;
  bool _hasSeenOnboarding = false;
  String _errorMessage = '';
  int _initializationAttempts = 0;
  static const int _maxInitializationAttempts = 2;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _checkOnboardingStatus();
      await _initializeAuth();
    } catch (e) {
      debugPrint('Error during AuthWrapper initialization: $e');
      _handleInitializationError(e.toString());
    }
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
  }

  Future<void> _initializeAuth() async {
    if (!_authService.isAuthenticated) {
      setState(() => _isInitializing = false);
      return;
    }

    try {
      // Save auth token and check premium status
      final token = _authService.authToken;
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        // Fast premium status check using cache first
        final hasAccess = await _fastPremiumCheck();

        // Update local storage
        await _updatePremiumFlags(prefs, hasAccess);

        debugPrint('Premium access status: $hasAccess');

        // Refresh premium status in background for accuracy
        _refreshPremiumStatusInBackground();
      }
    } catch (e) {
      debugPrint('Error during auth initialization: $e');
      _handleInitializationError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<bool> _fastPremiumCheck() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check cache first for immediate response
      final lastCheckTime = prefs.getInt('last_premium_check') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeSinceLastCheck = currentTime - lastCheckTime;
      final cacheExpired = timeSinceLastCheck > (5 * 60 * 1000); // 5 minutes

      if (!cacheExpired && lastCheckTime > 0) {
        final cachedIsPremium = prefs.getBool('is_premium') ?? false;
        final cachedTrialStart = prefs.getString('trial_start_date');
        final cachedTrialEnd = prefs.getString('trial_end_date');

        if (cachedIsPremium) {
          debugPrint('Premium status (cached): true');
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
      }

      // If no cache or expired, do a quick database check
      final subscriptionManager = SubscriptionManager();
      final hasAccess = await subscriptionManager.hasAccess();

      debugPrint('Premium status (fresh): $hasAccess');
      return hasAccess;
    } catch (e) {
      debugPrint('Error in fast premium check: $e');
      // Fallback to cached value
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('is_premium') ?? false;
    }
  }

  void _refreshPremiumStatusInBackground() async {
    try {
      // Wait a bit to let the UI load first
      await Future.delayed(const Duration(milliseconds: 500));

      final subscriptionManager = SubscriptionManager();
      final hasAccess = await subscriptionManager.hasAccess();

      final prefs = await SharedPreferences.getInstance();
      await _updatePremiumFlags(prefs, hasAccess);

      debugPrint('Premium status refreshed in background: $hasAccess');
    } catch (e) {
      debugPrint('Error refreshing premium status in background: $e');
    }
  }

  Future<void> _updatePremiumFlags(
      SharedPreferences prefs, bool hasAccess) async {
    await prefs.setBool(_hasCompletedPaymentKey, hasAccess);
    await prefs.setBool('is_subscribed', hasAccess);
    await prefs.setBool('premium_features_enabled', hasAccess);
  }

  void _handleInitializationError(String error) {
    _initializationAttempts++;
    if (_initializationAttempts < _maxInitializationAttempts) {
      // Retry initialization
      Future.delayed(const Duration(seconds: 1), _initializeAuth);
    } else {
      setState(() {
        _errorMessage = error;
        _isInitializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your account...'),
            ],
          ),
        ),
      );
    }

    if (!_hasSeenOnboarding) {
      return const OnboardingScreen();
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorScreen();
    }

    // Allow guest access
    if (AuthService.isGuest) {
      return const HomePage();
    }

    return _authService.isAuthenticated ? const HomePage() : const LoginPage();
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = '';
                  _initializationAttempts = 0;
                });
                _initializeAuth();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _selectedIndex = 2;
  bool _isPremium = false;
  late dynamic supabaseUser;
  List<Widget> _pages = [];
  Timer? _trialCheckTimer;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initializeHomePage();
    _setupTrialTimer();
    _setupMethodChannel();
  }

  void _setupMethodChannel() {
    const platform = MethodChannel('com.reconstrct.visionboard/widget');
    platform.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'openDailyNotes':
        // Navigate to Daily Notes page
        if (mounted) {
          Navigator.pushNamed(context, DailyNotesPage.routeName,
              arguments: {'create_new': true});
        }
        break;
      default:
        // Method not implemented
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _trialCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeHomePage() async {
    try {
      // Get current user
      final authService = AuthService.instance;
      supabaseUser = authService.currentUser;

      // Fast premium status initialization
      await _loadPremiumStatusFast();

      // Check first launch for new users
      if (!_isPremium) {
        await _handleFirstLaunch();
      }
    } catch (e) {
      debugPrint('Error initializing home page: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _loadPremiumStatusFast() async {
    try {
      // For iOS users, automatically set premium status to true (free access)
      if (PlatformFeatures.isIOSFreeAccess) {
        debugPrint('HomePage: iOS user detected - setting free access');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_hasCompletedPaymentKey, true);
        await prefs.setBool('is_subscribed', true);
        await prefs.setBool('premium_features_enabled', true);
        await prefs.setBool('is_premium_user', true);

        if (mounted) {
          setState(() {
            _isPremium = true;
          });
          _initPages();
        }
        debugPrint(
            'HomePage: iOS user premium status set to true (free access)');
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      // Check cache first for immediate response
      final lastCheckTime = prefs.getInt('last_premium_check') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeSinceLastCheck = currentTime - lastCheckTime;
      final cacheExpired = timeSinceLastCheck > (5 * 60 * 1000); // 5 minutes

      if (!cacheExpired && lastCheckTime > 0) {
        final cachedIsPremium = prefs.getBool('is_premium') ?? false;
        final cachedTrialStart = prefs.getString('trial_start_date');
        final cachedTrialEnd = prefs.getString('trial_end_date');

        if (cachedIsPremium) {
          debugPrint('HomePage: Premium status (cached): true');
          if (mounted) {
            setState(() {
              _isPremium = true;
            });
            _initPages();
          }
          return;
        }

        if (cachedTrialStart != null && cachedTrialEnd != null) {
          final trialEndDate = DateTime.parse(cachedTrialEnd);
          final now = DateTime.now();
          final hasActiveTrial =
              now.isBefore(trialEndDate) || now.isAtSameMomentAs(trialEndDate);

          debugPrint(
              'HomePage: Trial status (cached): ${hasActiveTrial ? "Active" : "Expired"}');
          if (mounted) {
            setState(() {
              _isPremium = hasActiveTrial;
            });
            _initPages();
          }
          return;
        }
      }

      // If no cache or expired, do a quick database check
      final subscriptionManager = SubscriptionManager();
      final hasAccess = await subscriptionManager.hasAccess();

      debugPrint('HomePage: Premium status (fresh): $hasAccess');
      if (mounted) {
        setState(() {
          _isPremium = hasAccess;
        });
        _initPages();
      }
    } catch (e) {
      debugPrint('Error loading premium status fast: $e');
      if (mounted) {
        setState(() {
          _isPremium = false;
        });
        _initPages();
      }
    }
  }

  void _setupTrialTimer() {
    _trialCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkTrialStatusPeriodically();
    });
  }

  Future<void> _checkTrialStatusPeriodically() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRefreshTime = prefs.getInt('_last_premium_refresh_time') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;

      // Increase interval to 5 minutes to reduce database calls
      if (currentTime - lastRefreshTime > 300000) {
        // 5 minutes instead of 30 seconds
        await _checkTrialStatus();
        await prefs.setInt('_last_premium_refresh_time', currentTime);
      }
    } catch (e) {
      debugPrint('Error in periodic trial check: $e');
    }
  }

  Future<void> _loadPremiumStatus() async {
    try {
      final subscriptionManager = SubscriptionManager();
      final hasAccess = await subscriptionManager.hasAccess();

      if (mounted) {
        setState(() {
          _isPremium = hasAccess;
        });
        _initPages();
      }
    } catch (e) {
      debugPrint('Error loading premium status: $e');
      if (mounted) {
        setState(() {
          _isPremium = false;
        });
        _initPages();
      }
    }
  }

  void _initPages() {
    _pages = [
      HomeContent(isPremium: _isPremium),
      const PlannersPage(),
      const ActiveDashboardPage(),
      const DashboardTrackerPage(),
      const ProfilePage(),
    ];
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkTrialStatus();
    }
  }

  Future<bool> _checkTrialStatus() async {
    try {
      // For iOS users, always return true (free access)
      if (PlatformFeatures.isIOSFreeAccess) {
        debugPrint(
            'HomePage: iOS user - trial status check returns true (free access)');
        if (mounted) {
          setState(() {
            _isPremium = true;
          });
          _updatePages();
        }
        return true;
      }

      final prefs = await SharedPreferences.getInstance();

      // Check cache first
      final lastCheckTime = prefs.getInt('last_premium_check') ?? 0;
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeSinceLastCheck = currentTime - lastCheckTime;
      final cacheExpired = timeSinceLastCheck > (5 * 60 * 1000); // 5 minutes

      if (!cacheExpired && lastCheckTime > 0) {
        final cachedIsPremium = prefs.getBool('is_premium') ?? false;
        final cachedTrialStart = prefs.getString('trial_start_date');
        final cachedTrialEnd = prefs.getString('trial_end_date');

        if (cachedIsPremium) {
          if (mounted) {
            setState(() {
              _isPremium = true;
            });
            _updatePages();
          }
          return true;
        }

        if (cachedTrialStart != null && cachedTrialEnd != null) {
          final trialEndDate = DateTime.parse(cachedTrialEnd);
          final now = DateTime.now();
          final hasActiveTrial =
              now.isBefore(trialEndDate) || now.isAtSameMomentAs(trialEndDate);

          if (mounted) {
            setState(() {
              _isPremium = hasActiveTrial;
            });
            _updatePages();
          }
          return hasActiveTrial;
        }
      }

      // Only fetch from database if cache is expired
      final subscriptionManager = SubscriptionManager();
      final hasAccess = await subscriptionManager.hasAccess();
      final trialEnded = await subscriptionManager.hasTrialEnded();

      if (mounted) {
        setState(() {
          _isPremium = hasAccess;
        });
        _updatePages();

        if (!hasAccess && trialEnded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showTrialExpiredDialog();
          });
        }
      }

      return hasAccess;
    } catch (e) {
      debugPrint('Error checking trial status: $e');
      return false;
    }
  }

  Future<void> _handleFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool(_firstLaunchKey) ?? true;

    if (!isFirstLaunch || !mounted) return;

    await prefs.setBool(_firstLaunchKey, false);

    // For iOS users, skip trial setup and set free access
    if (PlatformFeatures.isIOSFreeAccess) {
      debugPrint('HomePage: iOS user first launch - setting free access');
      await _updatePremiumFlags(prefs, true);
      setState(() => _isPremium = true);
      _updatePages();
      return;
    }

    // Check if user already has premium or active trial
    final currentUser = AuthService.instance.currentUser;
    final userEmail = currentUser?.email;

    if (userEmail == null) return;

    final databaseService = SupabaseDatabaseService();
    final trialStatusResponse =
        await databaseService.checkTrialStatus(email: userEmail);

    if (trialStatusResponse['success'] == true) {
      final trialData = trialStatusResponse['data'];
      final isPremiumUser = trialData['is_premium'] ?? false;
      final hasActiveAccess = trialData['has_active_access'] ?? false;
      final hasTrialHistory = trialData['trial_start_date'] != null;

      // Skip trial setup for premium users or users with active access
      if (isPremiumUser || hasActiveAccess) {
        await _updatePremiumFlags(prefs, hasActiveAccess);
        setState(() => _isPremium = hasActiveAccess);
        _updatePages();
        return;
      }

      // Start trial for new users without trial history
      if (!hasTrialHistory) {
        await _startNewUserTrial();
      }
    }
  }

  Future<void> _startNewUserTrial() async {
    try {
      final subscriptionManager = SubscriptionManager();
      await subscriptionManager.startFreeTrial();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('needs_trial_sync', true);

      // Sync with server if auth token available
      final authToken = prefs.getString('auth_token') ?? '';
      if (authToken.isNotEmpty) {
        await subscriptionManager.checkAndSyncPremiumStatus(authToken);
      }

      setState(() => _isPremium = true);
      _updatePages();

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
    }
  }

  Future<void> loadPremiumStatus() async {
    await _loadPremiumStatus();
  }

  Future<void> _updatePremiumFlags(
      SharedPreferences prefs, bool hasAccess) async {
    await prefs.setBool(_hasCompletedPaymentKey, hasAccess);
    await prefs.setBool('is_subscribed', hasAccess);
    await prefs.setBool('premium_features_enabled', hasAccess);
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your premium features...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.verified, color: Colors.blue, size: 24),
          ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Browse'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: '+'),
        BottomNavigationBarItem(
            icon: Icon(Icons.track_changes), label: 'Tracker'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      selectedItemColor: const Color(0xFF23C4F7),
      selectedLabelStyle: const TextStyle(color: Colors.black),
      unselectedItemColor: Colors.black,
    );
  }

  void _updatePages() {
    setState(() {
      _pages[0] = HomeContent(isPremium: _isPremium);
    });
  }

  void _showTrialExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Trial Period Ended'),
          content: const Text(
            'Your 7-day free trial has ended. Subscribe now to continue using all premium features.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
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
  }

  Future<void> _showPaymentPage() async {
    final email = supabaseUser?.email ?? 'user@example.com';
    final subscriptionManager = SubscriptionManager();
    await subscriptionManager.startSubscriptionFlow(context, email: email);
    await _loadPremiumStatus();
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
                              'assets/activity_tools/daily-note.png',
                              'Daily Notes',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                PlatformFeatureBuilder(
                  featureName: 'mind_tools_section',
                  builder: (context) => SizedBox(
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
                              // Thought Shredder - available on both platforms
                              _buildPlannerCard(
                                context,
                                'assets/Mind_tools/thought-shredder.png',
                                'Thought Shredder',
                              ),
                              const SizedBox(width: 18),
                              // Make Me Smile - available on both platforms
                              _buildPlannerCard(
                                context,
                                'assets/Mind_tools/make-me-smile.png',
                                'Make Me Smile',
                              ),
                              const SizedBox(width: 18),
                              // Bubble Wrap Popper - Android only
                              PlatformFeatureWidget(
                                featureName: 'bubble_wrap_popper',
                                child: _buildPlannerCard(
                                  context,
                                  'assets/Mind_tools/bubble-popper.png',
                                  'Bubble Wrap Popper',
                                ),
                              ),
                              // Break Things - Android only
                              PlatformFeatureWidget(
                                featureName: 'break_things_tool',
                                child: _buildPlannerCard(
                                  context,
                                  'assets/Mind_tools/break-things.png',
                                  'Break Things',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                              'assets/activity_tools/memory-game.png',
                              'Memory Game',
                            ),
                            const SizedBox(width: 18),
                            _buildPlannerCard(
                              context,
                              'assets/activity_tools/coloring-sheet.png',
                              'Coloring Page',
                            ),
                            const SizedBox(width: 18),
                            _buildPlannerCard(
                              context,
                              'assets/activity_tools/riddles.png',
                              'Riddle Quiz',
                            ),
                            const SizedBox(width: 18),
                            _buildPlannerCard(
                              context,
                              'assets/activity_tools/sliding-puzzle.png',
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
    final bool isGuest = AuthService.isGuest;
    
    // For guest users, show sign in dialog
    if (isGuest) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Sign In Required'),
            content: const Text(
                'This feature requires you to sign in or create an account. '
                'Sign in to save your progress and access all features.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to login page for guest users
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
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
    
    // For regular users, check if trial has ended
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
                    // Navigate to payment flow
                    _navigateToPayment();
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
                    // Navigate to payment flow
                    _navigateToPayment();
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

  // Navigate to payment flow
  Future<void> _navigateToPayment() async {
    final email = AuthService.instance.currentUser?.email ?? 'user@example.com';

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
  final AuthService _authService = AuthService.instance;
  String? _userEmail;
  String? _userId;
  bool _isLoading = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();

    // Immediately check premium status from database to ensure accuracy
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
    debugPrint('ProfilePage: Loading profile data');

    // Check if user is guest
    if (AuthService.isGuest) {
      _userEmail = null;
      _userId = 'guest';
      _displayName = 'Guest';
      _nameController.text = _displayName ?? '';
      debugPrint('Using guest user data');
      return;
    }

    // Get current user from AuthService (Firebase/Supabase)
    final currentUser = AuthService.instance.currentUser;
    
    if (currentUser?.email != null) {
      _userEmail = currentUser!.email;
      _userId = currentUser.id;

      // Priority order for display name:
      // 1. Firebase displayName (for Google sign-in users)
      // 2. userMetadata name
      // 3. userMetadata username  
      // 4. Formatted email prefix
      
      String? displayName;
      
      // Check Firebase displayName first (for Google sign-in)
      if (currentUser.userMetadata != null) {
        displayName = currentUser.userMetadata!['name'] ??
                     currentUser.userMetadata!['username'] ??
                     currentUser.userMetadata!['displayName'];
      }
      
      // If no name found in metadata, format email prefix
      if (displayName == null || displayName.trim().isEmpty) {
        String emailPrefix = currentUser.email!.split('@')[0];
        displayName = emailPrefix
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
      }

      _displayName = displayName.trim();
      _nameController.text = _displayName ?? '';
      debugPrint('Using Firebase/Supabase user data: $_userEmail, name: $_displayName');
    } else {
      // Fallback to MySQL user data if available
      final mysqlUserData = _authService.userData;
      if (mysqlUserData != null) {
        _userEmail = mysqlUserData['email'];
        _userId = mysqlUserData['id']?.toString() ?? 'mysql_user';

        final name = mysqlUserData['name'];
        if (name != null && name.toString().trim().isNotEmpty) {
          _displayName = name.toString().trim();
          _nameController.text = _displayName ?? '';
          debugPrint('Using MySQL name: $_displayName');
        } else {
          // Format email prefix as fallback
          if (_userEmail != null) {
            String emailPrefix = _userEmail!.split('@')[0];
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
      } else {
        debugPrint('No user data available');
      }
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

        // Get profile image from local storage or Supabase user metadata
        String? supabaseProfileImage;
        final currentUser = AuthService.instance.currentUser;
        if (currentUser?.userMetadata != null) {
          supabaseProfileImage = currentUser!.userMetadata!['avatar_url'] ??
              currentUser.userMetadata!['picture'] ??
              currentUser.userMetadata!['profile_image_url'];
        }

        _profileImagePath =
            prefs.getString('profileImage_$_userId') ?? supabaseProfileImage;

        _nameController.text = _displayName ?? '';
        _bioController.text = _bio ?? '';
      });
    }
  }

  // Load premium status from database first, then SharedPreferences as fallback
  Future<void> loadPremiumStatus() async {
    try {
      // For iOS users, automatically set premium status to true (free access)
      if (PlatformFeatures.isIOSFreeAccess) {
        debugPrint('iOS user detected - setting free access');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_hasCompletedPaymentKey, true);
        await prefs.setBool('is_subscribed', true);
        await prefs.setBool('premium_features_enabled', true);
        await prefs.setBool('is_premium_user', true);

        if (mounted) {
          setState(() {
            _isPremium = true;
          });
          debugPrint('iOS user premium status set to true (free access)');
        }
        return;
      }

      // For Android users, check database first for authoritative data
      final currentUser = AuthService.instance.currentUser;
      final userEmail = currentUser?.email;

      if (userEmail != null) {
        debugPrint('Refreshing premium status from database for: $userEmail');

        final databaseService = SupabaseDatabaseService();
        final trialStatusResponse =
            await databaseService.checkTrialStatus(email: userEmail);

        if (trialStatusResponse['success'] == true) {
          final trialData = trialStatusResponse['data'];
          final isPremiumUser = trialData['is_premium'] ?? false;
          final hasActiveAccess = trialData['has_active_access'] ?? false;
          final isOnTrial = trialData['is_on_trial'] ?? false;

          debugPrint(
              'Database refresh - isPremium: $isPremiumUser, hasAccess: $hasActiveAccess, isOnTrial: $isOnTrial');

          // Update local preferences to match database
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_hasCompletedPaymentKey, hasActiveAccess);
          await prefs.setBool('is_subscribed', hasActiveAccess);
          await prefs.setBool('premium_features_enabled', hasActiveAccess);
          await prefs.setBool('is_premium_user', isPremiumUser);

          // Update trial dates if available
          if (trialData['trial_start_date'] != null &&
              trialData['trial_end_date'] != null) {
            await prefs.setString(
                'trial_start_date', trialData['trial_start_date']);
            await prefs.setString(
                'trial_end_date', trialData['trial_end_date']);
            await prefs.setBool('trial_started', true);
          }

          // Update UI state if component is still mounted
          if (mounted) {
            setState(() {
              _isPremium = hasActiveAccess;
            });
            debugPrint('Premium status updated from database: $_isPremium');
          }

          return;
        }
      }

      // Fallback to local storage check if database check fails
      debugPrint('Database check failed, falling back to local storage');
      final prefs = await SharedPreferences.getInstance();
      final isPremiumFromPrefs =
          prefs.getBool(_hasCompletedPaymentKey) ?? false;

      final subscriptionManager = SubscriptionManager();
      final trialStarted = await subscriptionManager.isTrialStarted();
      final trialEnded = await subscriptionManager.hasTrialEnded();

      // Determine actual premium status
      final hasAccess = isPremiumFromPrefs || (trialStarted && !trialEnded);

      // Update UI state if component is still mounted
      if (mounted) {
        setState(() {
          _isPremium = hasAccess;
        });
        debugPrint('Premium status updated from local storage: $_isPremium');
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
                            if (AuthService.isGuest)
                              Text(
                                'Guest',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else if (_displayName?.isNotEmpty ?? false)
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
                              AuthService.isGuest ? 'Guest Account' : (_userEmail ?? 'No email available'),
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
                                    Text(
                                      AuthService.isGuest 
                                        ? 'Welcome to Reconstruct! You\'re currently using the app as a guest.\n\n'
                                          'Sign in or create an account to save your progress, access premium features, '
                                          'and sync your data across devices. Enjoy exploring our free features!'
                                        : 'Thanks for creating your Reconstruct account.\n\n'
                                      'Your personalised dashboard is getting ready and will be available shortly. '
                                      'Save, edit and download calendars, coloring sheets and planners. '
                                      'Use the daily activity tracker to build new habits and more!',
                                      style: TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Column(
                                      children: [
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 12),
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
                                            child:
                                                const Text('Explore Features'),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 24,
                                                      vertical: 12),
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
                                            child:
                                                const Text('My Active Boards'),
                                          ),
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
                                  backgroundColor: AuthService.isGuest ? Colors.blue[700] : Colors.red[700],
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: AuthService.isGuest ? _signInAsGuest : _signOut,
                                icon: Icon(AuthService.isGuest ? Icons.login : Icons.logout),
                                label: Text(AuthService.isGuest ? 'Sign In' : 'Sign Out'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[900],
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: _deleteAccount,
                                icon: const Icon(Icons.delete_forever),
                                label: const Text('Delete Account'),
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

  Future<void> _signInAsGuest() async {
    // Navigate to login page for guest users
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
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
        debugPrint('Starting sign out process...');
        
        // Clear local data first
        await _clearProfileData();
        debugPrint('Profile data cleared');

        // Clear database service cached data
        await DatabaseService.instance.clearUserData();
        debugPrint('Database service data cleared');

        // Clear user service data
        await UserService.instance.clearUserInfo();
        debugPrint('User service data cleared');

        // Use AuthService to properly sign out from both MySQL and Firebase
        await _authService.signOut();
        debugPrint('AuthService sign out completed');

        // Navigate to login page instead of auth wrapper
        if (mounted) {
        Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
          debugPrint('Navigated to login page');
        }
      } catch (e) {
        debugPrint('Error during sign out: $e');
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

  Future<void> _deleteAccount() async {
    // Show a more serious confirmation dialog for account deletion
    bool confirm = await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text(
                'Delete Account',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Are you sure you want to delete your account?',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This action will:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  const Text('• Permanently delete all your data'),
                  const Text('• Remove all your vision boards and tasks'),
                  const Text('• Delete your activity history'),
                  const Text('• Cancel any active subscriptions'),
                  const Text('• Sign you out of the application'),
                  const SizedBox(height: 8),
                  const Text(
                    'This action cannot be undone.',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your account and all data will be permanently deleted from our system.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirm) {
      // Show email confirmation dialog
      final TextEditingController emailController = TextEditingController();
      bool emailConfirmed = await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text(
                  'Confirm Email Address',
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To delete your account, please enter your email address:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _userEmail ?? 'No email available',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Enter your email address',
                        border: OutlineInputBorder(),
                        hintText: 'example@email.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      enableSuggestions: false,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This is your final confirmation. Once you proceed, your account will be permanently deleted.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      final enteredEmail = emailController.text.trim();
                      final userEmail = _userEmail?.trim();

                      if (enteredEmail.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter your email address'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (enteredEmail.toLowerCase() !=
                          userEmail?.toLowerCase()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email address does not match'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      Navigator.of(context).pop(true);
                    },
                    child: const Text('Delete Account'),
                  ),
                ],
              );
            },
          ) ??
          false;

      if (!emailConfirmed) {
        return; // User cancelled the email confirmation
      }

      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Deleting your account...'),
                ],
              ),
            );
          },
        );

        // Clear local data first
        await _clearProfileData();

        // Clear database service cached data
        await DatabaseService.instance.clearUserData();

        // Clear user service data
        await UserService.instance.clearUserInfo();

        // Delete account from AuthService
        final result = await _authService.deleteAccount();

        // Close loading dialog
        if (mounted) {
          Navigator.of(context).pop();
        }

        if (result['success'] == true) {
          debugPrint('Account deleted successfully');

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account and all data deleted successfully'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }

          // Navigate to auth wrapper
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/auth', (route) => false);
        } else {
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete account: ${result['message']}'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }
        }
      } catch (e) {
        // Close loading dialog if still open
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: $e'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _clearProfileData() async {
    debugPrint('Starting to clear profile data for logout...');

    final prefs = await SharedPreferences.getInstance();

    // Get all keys to identify what we're clearing
    final allKeys = prefs.getKeys();
    debugPrint(
        'Found ${allKeys.length} SharedPreferences keys before clearing');

    // Clear user-specific data
    if (_userId != null) {
      await prefs.remove('displayName_$_userId');
      await prefs.remove('bio_$_userId');
      await prefs.remove('profileImage_$_userId');
      debugPrint('Profile data cleared for user ID: $_userId');
    }

    // Clear all vision board data for all themes
    final visionBoardCategories = [
      'Travel',
      'Self Care',
      'Forgive',
      'Love',
      'Family',
      'Career',
      'Health',
      'Hobbies',
      'Knowledge',
      'Social',
      'Reading',
      'Food',
      'Music',
      'Tech',
      'DIY',
      'Luxury',
      'Income',
      'BMI',
      'Invest',
      'Inspiration',
      'Help'
    ];

    // Clear BoxThem vision board data
    for (var category in visionBoardCategories) {
      await prefs.remove('BoxThem_todos_$category');
      // Also clear from HomeWidget storage
      await HomeWidget.saveWidgetData('BoxThem_todos_$category', null);
      debugPrint('Cleared BoxThem_todos_$category');
    }

    // Clear other theme vision board data
    final themes = [
      'PostIt',
      'Premium',
      'CoffeeHues',
      'RubyReds',
      'WinterWarmth'
    ];
    for (var theme in themes) {
      for (var category in visionBoardCategories) {
        await prefs.remove('${theme}_todos_$category');
        // Also clear from HomeWidget storage
        await HomeWidget.saveWidgetData('${theme}_todos_$category', null);
        debugPrint('Cleared ${theme}_todos_$category');
      }
    }

    // Clear daily notes data
    await prefs.remove('daily_notes_data');
    await prefs.remove('daily_notes_last_save_date');
    debugPrint('Cleared daily notes data');

    // Clear auth and premium data
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    await prefs.remove('has_completed_payment');
    await prefs.remove('is_subscribed');
    await prefs.remove('premium_features_enabled');
    await prefs.remove('trial_started');
    await prefs.remove('trial_start_date');
    await prefs.remove('trial_end_date');
    await prefs.remove('trial_end_popup_shown');
    await prefs.remove('needs_trial_sync');
    debugPrint('Cleared auth and premium data');

    // Clear any remaining user-specific data by pattern matching
    for (var key in allKeys) {
      if (key.contains('_todos_') ||
          key.contains('user_') ||
          key.contains('auth_') ||
          key.startsWith('displayName_') ||
          key.startsWith('bio_') ||
          key.startsWith('profileImage_')) {
        await prefs.remove(key);
        debugPrint('Cleared additional key: $key');
      }
    }

    // Keep essential app settings
    await prefs.setBool('hasSeenOnboarding', true);
    await prefs.setBool('first_launch', false);

    // Update widgets to reflect the cleared data
    try {
      await HomeWidget.updateWidget(
        androidName: 'VisionBoardWidget',
        iOSName: 'VisionBoardWidget',
      );
      await HomeWidget.updateWidget(
        androidName: 'DailyNotesWidget',
        iOSName: 'DailyNotesWidget',
      );
      debugPrint('Widgets updated after data clearing');
    } catch (e) {
      debugPrint('Error updating widgets after data clearing: $e');
    }

    debugPrint('Profile data clearing completed - kept essential app settings');
  }

  // Add a widget to show premium status in the profile page
  Widget _buildPremiumStatus() {
    // For guest users, show guest status
    if (AuthService.isGuest) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.orange.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_outline,
                color: Colors.orange.shade700,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Guest Mode',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to save progress and access premium features',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            Flexible(
              child: ElevatedButton(
                onPressed: () => _signInAsGuest(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // For iOS users, show free access status instead of premium/trial
    if (PlatformFeatures.isIOSFreeAccess) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.green.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Free Access',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'All features are free for iOS users',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // For Android users, show the original premium/trial status
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        mainAxisSize: MainAxisSize.min,
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
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                );
                              }),
                        ],
                      ),
                    ),
                    if (!_isPremium)
                      Flexible(
                        child: ElevatedButton(
                          onPressed: () => _showPaymentPage(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Upgrade',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
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
                        Flexible(
                          child: RichText(
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
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        });
  }

  // Helper method to check if user is on trial - checks database first
  Future<bool> _isUserOnTrial() async {
    try {
      // For iOS users, always return false (no trial needed for free access)
      if (PlatformFeatures.isIOSFreeAccess) {
        debugPrint(
            'ProfilePage: iOS user - trial check returns false (free access)');
        return false;
      }

      // Get current user email for database check
      final currentUser = AuthService.instance.currentUser;
      final userEmail = currentUser?.email;

      if (userEmail != null) {
        // Check database first for authoritative trial status
        final databaseService = SupabaseDatabaseService();
        final trialStatusResponse =
            await databaseService.checkTrialStatus(email: userEmail);

        if (trialStatusResponse['success'] == true) {
          final trialData = trialStatusResponse['data'];
          final isOnTrial = trialData['is_on_trial'] ?? false;
          debugPrint('Database trial check: isOnTrial=$isOnTrial');
          return isOnTrial;
        }
      }

      // Fallback to local storage check
      final prefs = await SharedPreferences.getInstance();
      final trialStarted = prefs.getBool('trial_started') ?? false;

      if (trialStarted) {
        final trialEndDateStr = prefs.getString('trial_end_date');
        if (trialEndDateStr != null) {
          // Handle both database format (YYYY-MM-DD) and ISO format
          DateTime trialEndDate;
          if (trialEndDateStr.contains('T')) {
            // ISO format
            trialEndDate = DateTime.parse(trialEndDateStr);
          } else {
            // Database format (YYYY-MM-DD)
            trialEndDate = DateTime.parse('${trialEndDateStr}T23:59:59');
          }

          final now = DateTime.now();
          return now.isBefore(trialEndDate) ||
              now.isAtSameMomentAs(trialEndDate);
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking trial status: $e');
      return false;
    }
  }

  // Helper method to get formatted trial end date - checks database first
  Future<String> _getTrialEndDate() async {
    try {
      // For iOS users, return empty string (no trial end date needed)
      if (PlatformFeatures.isIOSFreeAccess) {
        debugPrint('ProfilePage: iOS user - no trial end date needed');
        return '';
      }

      // Get current user email for database check
      final currentUser = AuthService.instance.currentUser;
      final userEmail = currentUser?.email;

      if (userEmail != null) {
        // Check database first for authoritative trial end date
        final databaseService = SupabaseDatabaseService();
        final trialStatusResponse =
            await databaseService.checkTrialStatus(email: userEmail);

        if (trialStatusResponse['success'] == true) {
          final trialData = trialStatusResponse['data'];
          final trialEndDateStr = trialData['trial_end_date'];

          if (trialEndDateStr != null) {
            // Database stores dates in YYYY-MM-DD format
            final trialEndDate = DateTime.parse('${trialEndDateStr}T23:59:59');
            debugPrint(
                'Database trial end date: $trialEndDateStr -> formatted: ${trialEndDate.day} ${_getMonthName(trialEndDate.month)} ${trialEndDate.year}');
            return "${trialEndDate.day} ${_getMonthName(trialEndDate.month)} ${trialEndDate.year}";
          }
        }
      }

      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final trialEndDateStr = prefs.getString('trial_end_date');

      if (trialEndDateStr != null) {
        DateTime trialEndDate;

        // Handle both database format (YYYY-MM-DD) and ISO format
        if (trialEndDateStr.contains('T')) {
          // ISO format
          trialEndDate = DateTime.parse(trialEndDateStr);
        } else {
          // Database format (YYYY-MM-DD)
          trialEndDate = DateTime.parse('${trialEndDateStr}T23:59:59');
        }

        debugPrint(
            'Local trial end date: $trialEndDateStr -> formatted: ${trialEndDate.day} ${_getMonthName(trialEndDate.month)} ${trialEndDate.year}');
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
    try {
      // For iOS users, show message that all features are already free
      if (PlatformFeatures.isIOSFreeAccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All features are already free for iOS users!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final email = _userEmail ??
          AuthService.instance.currentUser?.email ??
          'user@example.com';

      debugPrint('Profile: Starting upgrade flow for user: $email');

      // Store the initial premium status before payment flow
      final initialPremiumStatus = _isPremium;

      final subscriptionManager = SubscriptionManager();

      // Use the new upgrade flow that always shows payment options
      await subscriptionManager.startUpgradeFlow(context, email: email);

      debugPrint('Profile: Payment flow completed, checking new status...');

      // After the payment flow completes, check the database for the updated premium status
      await _checkPremiumStatusFromDatabase();

      // Only show success message if premium status actually changed from database
      if (!initialPremiumStatus && _isPremium) {
        debugPrint('Profile: User successfully upgraded to premium');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Welcome to Premium! All features are now unlocked.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 4),
            ),
          );
        }

        // Refresh the home page to reflect new premium status
        final homePageState = context.findAncestorStateOfType<_HomePageState>();
        if (homePageState != null) {
          await homePageState.loadPremiumStatus();
        }
      }
    } catch (e) {
      debugPrint('Error in payment flow: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment flow error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Method to check premium status from database and update local state
  Future<void> _checkPremiumStatusFromDatabase() async {
    try {
      final currentUser = AuthService.instance.currentUser;
      final userEmail = currentUser?.email;

      if (userEmail != null) {
        debugPrint(
            'Profile: Checking database for premium status after payment: $userEmail');

        final databaseService = SupabaseDatabaseService();
        final trialStatusResponse =
            await databaseService.checkTrialStatus(email: userEmail);

        if (trialStatusResponse['success'] == true) {
          final trialData = trialStatusResponse['data'];
          final isPremiumUser = trialData['is_premium'] ?? false;
          final hasActiveAccess = trialData['has_active_access'] ?? false;

          debugPrint(
              'Profile: Database check after payment - isPremium: $isPremiumUser, hasActiveAccess: $hasActiveAccess');

          // Update local preferences to match database
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_hasCompletedPaymentKey, hasActiveAccess);
          await prefs.setBool('is_subscribed', hasActiveAccess);
          await prefs.setBool('premium_features_enabled', hasActiveAccess);
          await prefs.setBool('is_premium_user', isPremiumUser);

          // Update UI state based on database values
          if (mounted) {
            setState(() {
              _isPremium = hasActiveAccess;
            });
            debugPrint(
                'Profile: Premium status updated from database: $_isPremium');
          }
        } else {
          debugPrint('Profile: Failed to get updated status from database');
        }
      }
    } catch (e) {
      debugPrint('Error checking premium status from database: $e');
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
