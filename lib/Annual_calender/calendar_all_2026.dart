import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/nav_logpage.dart';
import '../utils/activity_tracker_mixin.dart';
import '../services/subscription_manager.dart';

enum CalendarTheme {
  animal,
  spaniel,
  summer,
  happyCouple,
}

class CalendarAll2026 extends StatefulWidget {
  final CalendarTheme? initialTheme;
  final int? initialMonthIndex;

  const CalendarAll2026({
    super.key,
    this.initialTheme,
    this.initialMonthIndex,
  });

  @override
  State<CalendarAll2026> createState() => _CalendarAll2026State();
}

class _CalendarAll2026State extends State<CalendarAll2026>
    with ActivityTrackerMixin, TickerProviderStateMixin {
  late CalendarTheme _selectedTheme;
  int _currentMonthIndex = DateTime.now().month - 1;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  bool _isLoading = true;

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  // Days in month for 2026 (2026 is not a leap year)
  final Map<int, int> daysInMonth2026 = {
    1: 31,
    2: 28, // 2026 is not a leap year
    3: 31,
    4: 30,
    5: 31,
    6: 30,
    7: 31,
    8: 31,
    9: 30,
    10: 31,
    11: 30,
    12: 31
  };

  final Map<String, Color> categoryColors = {
    'Personal': const Color(0xFFff6f61), // Coral
    'Professional': const Color(0xFF1b998b), // Teal
    'Finance': const Color(0xFFfddb3a), // Yellow
    'Health': const Color(0xFF8360c3), // Purple
  };

  // Theme image paths
  String _getThemeImagePath(int monthIndex) {
    switch (_selectedTheme) {
      case CalendarTheme.animal:
        return 'assets/animal_calendar/animaltheme-${monthIndex + 1}.png';
      case CalendarTheme.spaniel:
        return 'assets/spaniel_calender/cocker${monthIndex + 1}.png';
      case CalendarTheme.summer:
        return 'assets/summer_calender/summer${monthIndex + 1}.png';
      case CalendarTheme.happyCouple:
        return 'assets/couple_calender/couple${monthIndex + 1}.png';
    }
  }

  String _getThemeName() {
    switch (_selectedTheme) {
      case CalendarTheme.animal:
        return 'Animal theme';
      case CalendarTheme.spaniel:
        return 'Spaniel Calendar';
      case CalendarTheme.summer:
        return 'Summer theme';
      case CalendarTheme.happyCouple:
        return 'Happy Couple theme';
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Set initial theme
    _selectedTheme = widget.initialTheme ?? CalendarTheme.animal;
    
    // Set initial month
    if (widget.initialMonthIndex != null) {
      _currentMonthIndex = widget.initialMonthIndex!;
    } else {
      _currentMonthIndex = DateTime.now().month - 1;
    }

    // Initialize progress animation (75% complete)
    _progressAnimationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 0.75, // 75% progress
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
      final subscriptionManager = SubscriptionManager();
      await subscriptionManager.hasAccess();
    } catch (e) {
      debugPrint('Error checking premium status: $e');
      final prefs = await SharedPreferences.getInstance();
      prefs.getBool('has_completed_payment');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _previousMonth() {
    setState(() {
      if (_currentMonthIndex > 0) {
        _currentMonthIndex--;
      } else {
        _currentMonthIndex = 11; // Go to December
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_currentMonthIndex < 11) {
        _currentMonthIndex++;
      } else {
        _currentMonthIndex = 0; // Go to January
      }
    });
  }

  Widget _buildCalendarGrid() {
    final monthNumber = _currentMonthIndex + 1;
    final firstDay = DateTime(2026, monthNumber, 1);
    final offset = firstDay.weekday % 7; // 0 = Sunday, 1 = Monday, etc.
    final daysInMonth = daysInMonth2026[monthNumber] ?? 31;

    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 1,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 42, // 6 weeks * 7 days
      itemBuilder: (context, index) {
        final adjustedIndex = index - offset;

        if (adjustedIndex < 0 || adjustedIndex >= daysInMonth) {
          return SizedBox(); // Empty cell
        }

        final day = adjustedIndex + 1;
        final date = DateTime(2026, monthNumber, day);
        final isToday = date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day;

        return Container(
          decoration: BoxDecoration(
            color: isToday ? categoryColors['Personal']!.withOpacity(0.3) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: isToday ? categoryColors['Personal'] : Colors.black87,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
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

            // Main instruction text
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                'Colorcode important dates & get reminders',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            // Calendar widget
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Theme selector
                      Container(
                        margin: EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildThemeButton(CalendarTheme.animal, 'Animal'),
                            _buildThemeButton(CalendarTheme.spaniel, 'Spaniel'),
                            _buildThemeButton(CalendarTheme.summer, 'Summer'),
                            _buildThemeButton(CalendarTheme.happyCouple, 'Couple'),
                          ],
                        ),
                      ),

                      // Calendar card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Theme image and plus icon
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(16),
                                  ),
                                  child: Container(
                                    height: 120,
                                    width: double.infinity,
                                    child: Image.asset(
                                      _getThemeImagePath(_currentMonthIndex),
                                      fit: BoxFit.cover,
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
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      color: Colors.black87,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Month and year
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                '${months[_currentMonthIndex]} 2026',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),

                            // Days of week
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                                    .map((day) => Expanded(
                                          child: Center(
                                            child: Text(
                                              day,
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),

                            SizedBox(height: 8),

                            // Calendar grid
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: _buildCalendarGrid(),
                            ),

                            SizedBox(height: 16),
                          ],
                        ),
                      ),

                      SizedBox(height: 24),

                      // Navigation arrows
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: _previousMonth,
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF23C4F7).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_back,
                                color: Color(0xFF23C4F7),
                                size: 24,
                              ),
                            ),
                          ),
                          SizedBox(width: 40),
                          GestureDetector(
                            onTap: _nextMonth,
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF23C4F7).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.arrow_forward,
                                color: Color(0xFF23C4F7),
                                size: 24,
                              ),
                            ),
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

  Widget _buildThemeButton(CalendarTheme theme, String label) {
    final isSelected = _selectedTheme == theme;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTheme = theme;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF23C4F7) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  String get pageName => '2026 Calendar - ${_getThemeName()}';
}

