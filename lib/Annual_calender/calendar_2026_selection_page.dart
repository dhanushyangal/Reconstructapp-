import 'package:flutter/material.dart';
import 'calendar_all_2026.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/subscription_manager.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../utils/activity_tracker_mixin.dart';
import '../components/nav_logpage.dart';

class Calendar2026SelectionPage extends StatefulWidget {
  const Calendar2026SelectionPage({super.key});

  @override
  State<Calendar2026SelectionPage> createState() => _Calendar2026SelectionPageState();
}

class _Calendar2026SelectionPageState extends State<Calendar2026SelectionPage>
    with ActivityTrackerMixin, TickerProviderStateMixin {
  bool _isPremium = false;
  bool _isLoading = true;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize progress animation (50% complete)
    _progressAnimationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5, // 50% progress
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Start the animation
    _progressAnimationController.forward();
    
    _loadPremiumStatus();
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadPremiumStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasCompletedPayment =
          prefs.getBool('has_completed_payment') ?? false;
      final premiumFeaturesEnabled =
          prefs.getBool('premium_features_enabled') ?? false;

      // Check if we have an active trial through the subscription manager
      final subscriptionManager = SubscriptionManager();
      final hasAccess = await subscriptionManager.hasAccess();

      if (mounted) {
        setState(() {
          _isPremium =
              hasCompletedPayment || premiumFeaturesEnabled || hasAccess;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error checking premium status: $e');
      final prefs = await SharedPreferences.getInstance();
      final isPremium = prefs.getBool('has_completed_payment') ?? false;

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

    // Only Animal theme is free
    return title != 'Animal theme';
  }

  // Method to show payment page
  Future<void> _showPaymentPage() async {
    final email =
        Provider.of<AuthService>(context, listen: false).userData?['email'] ??
            AuthService.instance.currentUser?.email ??
            'user@example.com';

    final subscriptionManager = SubscriptionManager();
    await subscriptionManager.startSubscriptionFlow(context, email: email);

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
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                } else {
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

  Widget _buildThemeCard(String imagePath, String title) {
    final bool isLocked = _isTemplateLocked(title);

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          _showPremiumDialog(context);
          return;
        }
        
        // Navigate to the unified calendar page with selected theme
        CalendarTheme theme;
        if (title == 'Animal theme') {
          theme = CalendarTheme.animal;
        } else if (title == 'Summer theme') {
          theme = CalendarTheme.summer;
        } else if (title == 'Spaniel Calendar') {
          theme = CalendarTheme.spaniel;
        } else if (title == 'Happy Couple theme') {
          theme = CalendarTheme.happyCouple;
        } else {
          theme = CalendarTheme.animal; // Default
        }
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CalendarAll2026(
              initialTheme: theme,
              initialMonthIndex: 0,
            ),
          ),
        );
      },
      child: Column(
        children: [
          // Calendar preview image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.image_not_supported,
                            size: 40,
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
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black.withOpacity(0.3),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.lock,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
          // Label button
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey[300] ?? Colors.grey,
                width: 1,
              ),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isLocked ? Colors.grey : Colors.black87,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
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
      title: '',
      showBackButton: true,
      selectedIndex: 2,
      onNavigationTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            break;
          case 1:
            Navigator.pushNamedAndRemoveUntil(context, '/browse', (route) => false);
            break;
          case 2:
            Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
            break;
          case 3:
            Navigator.pushNamedAndRemoveUntil(context, '/tracker', (route) => false);
            break;
          case 4:
            Navigator.pushNamedAndRemoveUntil(context, '/profile', (route) => false);
            break;
        }
      },
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFE8FAFF)],
          ),
        ),
        child: Column(
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
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return LinearProgressIndicator(
                              value: _progressAnimation.value,
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
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return Text(
                        '${(_progressAnimation.value * 100).toInt()}% complete',
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
            
            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'Choose a 2026 Calendar theme',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 24),
                      
                      // 2x2 Grid of calendar themes
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.75,
                        children: [
                          _buildThemeCard(
                            'assets/spaniel_theme_calendar.png',
                            'Spaniel Calendar',
                          ),
                          _buildThemeCard(
                            'assets/animal_theme_calendar.png',
                            'Animal theme',
                          ),
                          _buildThemeCard(
                            'assets/summer_theme_calendar.png',
                            'Summer theme',
                          ),
                          _buildThemeCard(
                            'assets/happy_couple_theme_calendar.png',
                            'Happy Couple theme',
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get pageName => '2026 Calendar Selection';
}

