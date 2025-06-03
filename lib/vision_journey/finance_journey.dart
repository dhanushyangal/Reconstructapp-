import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../services/database_service.dart';
import '../services/calendar_database_service.dart';
import '../services/weekly_planner_service.dart';
import '../services/user_service.dart';
import '../config/api_config.dart';

// Define the FinanceTask class
class FinanceTask {
  final String description;
  final int weekNumber;
  final int goalIndex;
  bool isSelected;

  FinanceTask({
    required this.description,
    required this.weekNumber,
    required this.goalIndex,
    this.isSelected = false,
  });
}

class FinanceJourney extends StatefulWidget {
  const FinanceJourney({Key? key}) : super(key: key);

  @override
  State<FinanceJourney> createState() => _FinanceJourneyState();
}

class _FinanceJourneyState extends State<FinanceJourney> {
  int currentStep = 1;
  String selectedGoal = 'Be Aware';
  String selectedMonth = 'June';
  int currentGoalIndex = 0;
  double targetAmount = 5000;
  String selectedTimeline = '1 year';
  int satisfactionRating = 0; // 0-4 for 5 emoji ratings
  String weeklyReflection = '';

  // Database services
  late DatabaseService _databaseService;
  late CalendarDatabaseService _calendarDatabaseService;
  late WeeklyPlannerService _weeklyPlannerService;
  bool _isConnected = false;
  bool _isUserLoggedIn = false;

  // New properties for modern UI
  final Map<String, String> notesMap = {};
  final Map<String, String> remindersMap = {};
  String? editingTaskId;
  TextEditingController editingTaskController = TextEditingController();

  // Add data structure for financial tasks with selection state
  final Map<int, List<FinanceTask>> weeklyTasks = {1: [], 2: [], 3: [], 4: []};

  // Add a map to store selected tasks for each goal
  final Map<String, List<FinanceTask>> selectedTasksByGoal = {};

  // Add a map to store week dates
  final Map<int, DateTime> weekDates = {};

  // Add a map to store week dates for each goal
  final Map<int, Map<int, DateTime>> weekDatesByGoal = {};

  // List of financial goals
  final List<String> goals = ['Be Aware', 'Expand Portfolio', 'Build Wealth'];

  // Getter for current tasks based on selected goal
  List<FinanceTask> get currentTasks => selectedTasksByGoal[selectedGoal] ?? [];

  @override
  void initState() {
    super.initState();
    _initializeDefaultTasks();
    _initializeDefaultDates();
    _initializeServices();

    // Ensure all buttons are connected to the saveAndExit method
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('Finance Journey: Initialized and ready for saving');
    });
  }

  // Initialize database services
  Future<void> _initializeServices() async {
    _databaseService = DatabaseService.instance;
    _calendarDatabaseService =
        CalendarDatabaseService(baseUrl: ApiConfig.baseUrl);
    _weeklyPlannerService = WeeklyPlannerService.instance;

    // Check connectivity
    final result = await _databaseService.testConnection();
    setState(() {
      _isConnected = result['success'] == true;
    });

    // Check if user is logged in
    _isUserLoggedIn = await _databaseService.isUserLoggedIn();

    // Load user info into calendar service
    if (_isUserLoggedIn) {
      final userInfo = await UserService.instance.getUserInfo();
      if (userInfo['userName'] != null && userInfo['email'] != null) {
        _calendarDatabaseService.setUserInfo(
            userInfo['userName'] ?? '', userInfo['email'] ?? '');
      }
    }

    debugPrint(
        'Finance Journey: Database connectivity: $_isConnected, User logged in: $_isUserLoggedIn');
  }

  // Initialize default tasks for each week and goal
  void _initializeDefaultTasks() {
    // Structure: Map<GoalName, Map<WeekNumber, List<TaskDescriptions>>>
    final Map<String, Map<String, List<String>>> goalTasks = {
      'Be Aware': {
        'Week 1': [
          'Track daily expenses',
          'Categorize spending',
          'Review bank statements',
          'List subscriptions'
        ],
        'Week 2': [
          'Analyze monthly spending',
          'Identify hidden expenses',
          'Create budget categories',
          'Set spending limits'
        ],
        'Week 3': [
          'Use budgeting tool',
          'Track income sources',
          'Monitor savings',
          'Review financial goals'
        ],
        'Week 4': [
          'Final spending review',
          'Adjust budget',
          'Cut unnecessary expenses',
          'Plan next month'
        ]
      },
      'Expand Portfolio': {
        'Week 1': [
          'Learn mutual funds basics',
          'Study stocks fundamentals',
          'Understand SIPs',
          'Research index funds'
        ],
        'Week 2': [
          'Open demo account',
          'Practice mock investing',
          'Study market trends',
          'Learn risk management'
        ],
        'Week 3': [
          'Assess risk appetite',
          'Build sample portfolio',
          'Research companies',
          'Study market analysis'
        ],
        'Week 4': [
          'Calculate potential returns',
          'Read success stories',
          'Review portfolio',
          'Plan next steps'
        ]
      },
      'Build Wealth': {
        'Week 1': [
          'Create vision board',
          'Define wealth goals',
          'List assets',
          'Plan investments'
        ],
        'Week 2': [
          'Study compound interest',
          'Learn debt control',
          'Set financial discipline',
          'Track progress'
        ],
        'Week 3': [
          'Set 5-year goals',
          'Plan major purchases',
          'Create education fund',
          'Review insurance'
        ],
        'Week 4': [
          'Build daily habits',
          'Connect to long-term goals',
          'Review progress',
          'Adjust strategy'
        ]
      }
    };

    // Initialize weeks with default tasks
    for (int week = 1; week <= 4; week++) {
      weeklyTasks[week] = [];
      for (String goal in goals) {
        final weekTasks = goalTasks[goal]?['Week $week'] ?? [];
        for (String taskDesc in weekTasks) {
          weeklyTasks[week]!.add(
            FinanceTask(
              description: taskDesc,
              weekNumber: week,
              goalIndex: goals.indexOf(goal),
            ),
          );
        }
      }
    }
  }

  // Initialize default dates for each week
  void _initializeDefaultDates() {
    // Use the selected month
    if (selectedMonth.isNotEmpty) {
      try {
        final List<String> allMonths = [
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

        final monthIndex = allMonths.indexOf(selectedMonth);
        if (monthIndex != -1) {
          // Create a date from the selected month (middle of the month)
          final baseDate = DateTime(2025, monthIndex + 1, 15);

          // Set each week to be 7 days apart
          for (int week = 1; week <= 4; week++) {
            weekDates[week] = baseDate.add(Duration(days: (week - 1) * 7));
          }
          return;
        }
      } catch (e) {
        // Fallback to default if parsing fails
      }
    }

    // Fallback: Use current date if no month is selected
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    for (int week = 1; week <= 4; week++) {
      weekDates[week] = monday.add(Duration(days: (week - 1) * 7));
    }
  }

  // Helper method to get tasks for a specific week and goal
  List<FinanceTask> getTasksForWeekAndGoal(int week, int goalIndex) {
    if (goalIndex < 0 || goalIndex >= goals.length) {
      return [];
    }

    return weeklyTasks[week]
            ?.where(
                (task) => task.goalIndex == goalIndex || task.goalIndex == -1)
            .toList() ??
        [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FDF4), // green-50
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width > 768
                  ? 680
                  : MediaQuery.of(context).size.width * 0.92,
              margin: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  _buildStepper(),
                  const SizedBox(height: 16),
                  _buildCurrentStep(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.green),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'Finance Journey',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final stepNumber = index + 1;
            final isActive = stepNumber <= currentStep;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.green.shade500
                            : Colors.green.shade200,
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$stepNumber',
                          style: TextStyle(
                            color:
                                isActive ? Colors.white : Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStepTitle(stepNumber),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
                if (index < 4)
                  Container(
                    width: 40,
                    height: 2,
                    color: stepNumber < currentStep
                        ? Colors.green.shade500
                        : Colors.green.shade200,
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return 'Intro';
      case 2:
        return 'Goal';
      case 3:
        return 'Schedule';
      case 4:
        return 'Track';
      case 5:
        return 'Summary';
      default:
        return '';
    }
  }

  Widget _buildCurrentStep() {
    switch (currentStep) {
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      case 4:
        return _buildStep4();
      case 5:
        return _buildStep5();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '💸 Welcome to Your Finance Journey!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF16A34A), // green-600
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Design your personalized finance plan for the next month. You\'ll choose a financial goal to focus on, set a schedule, and track your progress along the way.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                currentStep = 2;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A), // green-600
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50), // Rounded full style
              ),
              elevation: 3,
            ),
            child: const Text(
              'Start',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Step 2: Choose a Financial Goal',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Select one goal to focus on for the next month:',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Goal selection grid
          LayoutBuilder(builder: (context, constraints) {
            return GridView.count(
              crossAxisCount: constraints.maxWidth > 600 ? 3 : 1,
              shrinkWrap: true,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildGoalCard('Be Aware', '📊',
                    'Track spending and create a sustainable budget'),
                _buildGoalCard('Expand Portfolio', '📈',
                    'Learn about investments and grow your portfolio'),
                _buildGoalCard('Build Wealth', '💰',
                    'Create a long-term wealth building strategy'),
              ],
            );
          }),

          const SizedBox(height: 24),
          _buildNavigationButtons(
            onBack: () {
              setState(() {
                currentStep = 1;
              });
            },
            onNext: () {
              setState(() {
                currentStep = 3;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(String title, String emoji, String description) {
    final isSelected = selectedGoal == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGoal = title;
          currentGoalIndex = goals.indexOf(title);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green.shade400 : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              margin: const EdgeInsets.only(bottom: 16),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 40),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Step 3: Pick a Start Month',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'When do you want to begin your finance journey?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Month selection
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.green.shade200),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Selected Goal: $selectedGoal',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A34A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                LayoutBuilder(builder: (context, constraints) {
                  // More responsive layout for small screens
                  if (constraints.maxWidth < 400) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Choose Month:',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildMonthDropdown(),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            '2025',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // Original layout for larger screens
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Choose Month:',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildMonthDropdown(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '2025',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _buildNavigationButtons(
            onBack: () {
              setState(() {
                currentStep = 2;
              });
            },
            onNext: () {
              setState(() {
                currentStep = 4;
                // Reset goal index when entering step 4
                currentGoalIndex = goals.indexOf(selectedGoal);
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.green.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.green.shade500, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      value: selectedMonth,
      items: const [
        DropdownMenuItem(value: 'January', child: Text('January')),
        DropdownMenuItem(value: 'February', child: Text('February')),
        DropdownMenuItem(value: 'March', child: Text('March')),
        DropdownMenuItem(value: 'April', child: Text('April')),
        DropdownMenuItem(value: 'May', child: Text('May')),
        DropdownMenuItem(value: 'June', child: Text('June')),
        DropdownMenuItem(value: 'July', child: Text('July')),
        DropdownMenuItem(value: 'August', child: Text('August')),
        DropdownMenuItem(value: 'September', child: Text('September')),
        DropdownMenuItem(value: 'October', child: Text('October')),
        DropdownMenuItem(value: 'November', child: Text('November')),
        DropdownMenuItem(value: 'December', child: Text('December')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            selectedMonth = value;
          });
        }
      },
      dropdownColor: Colors.white,
    );
  }

  Widget _buildStep4() {
    // Get the current goal name
    final goalName = selectedGoal;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Step 4: Weekly Preparation Plan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Plan your finance activities for $goalName:',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Selected goal card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade500,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    goalName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Weekly tasks
          _buildWeeklyPlan(),

          const SizedBox(height: 24),
          _buildNavigationButtons(
            onBack: () {
              setState(() {
                currentStep = 3;
              });
            },
            onNext: () {
              // Save selections before moving to summary
              _saveCurrentSelections();
              setState(() {
                currentStep = 5;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyPlan() {
    final int goalIndex = goals.indexOf(selectedGoal);

    // Restore dates for the current goal instead of refreshing
    _restoreDatesForCurrentGoal();

    return Column(
      children: List.generate(4, (weekIndex) {
        final weekNumber = weekIndex + 1;
        final tasksForWeek = getTasksForWeekAndGoal(weekNumber, goalIndex);
        final weekDate = weekDates[weekNumber] ?? DateTime.now();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 2,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$weekNumber',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Week $weekNumber',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade600,
                              ),
                            ),
                            Text(
                              '${weekDate.day}/${weekDate.month}/${weekDate.year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Date picker button
                    TextButton.icon(
                      onPressed: () async {
                        // Prepare the date parameters
                        DateTime initialDate = weekDate;
                        DateTime firstDate = DateTime.now();
                        DateTime lastDate = DateTime(2026);

                        // If a month is selected, use it to limit date selection
                        if (selectedMonth.isNotEmpty) {
                          try {
                            final List<String> allMonths = [
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

                            final monthIndex = allMonths.indexOf(selectedMonth);
                            if (monthIndex != -1) {
                              // Set the initial date to the selected month
                              initialDate =
                                  DateTime(2025, monthIndex + 1, weekDate.day);

                              // Set first and last date to constrain to the selected month
                              firstDate = DateTime(2025, monthIndex + 1, 1);

                              // Only allow selecting dates within the selected month
                              lastDate = DateTime(
                                  2025, monthIndex + 2, 0); // Last day of month
                            }
                          } catch (e) {
                            // Fallback to default values if parsing fails
                            debugPrint('Error parsing date: $e');
                          }
                        }

                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: initialDate,
                          firstDate: firstDate,
                          lastDate: lastDate,
                        );

                        if (picked != null) {
                          setState(() {
                            weekDates[weekNumber] = picked;

                            // Save the date change
                            _saveCurrentSelections();
                          });
                        }
                      },
                      icon: Icon(Icons.calendar_today,
                          color: Colors.green.shade600, size: 18),
                      label: Text(
                        'Change Date',
                        style: TextStyle(color: Colors.green.shade600),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Tasks for this week
              ...tasksForWeek.map((task) => _buildTaskItem(task)),

              // Add new task button
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Show dialog to add a new task
                    _showAddTaskDialog(weekNumber);
                  },
                  icon: const Icon(Icons.add),
                  label: Text('Add New Task for Week $weekNumber'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green.shade600,
                    elevation: 0,
                    side: BorderSide(color: Colors.green.shade300),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Task item layout with radio buttons instead of checkboxes
  Widget _buildTaskItem(FinanceTask task) {
    final String goalName = selectedGoal;
    final String taskId = "${task.weekNumber}-$goalName-${task.description}";
    final bool hasNotes = notesMap.containsKey(taskId);
    final bool hasReminder = remindersMap.containsKey(taskId);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio button instead of checkbox
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Radio<bool>(
                value: true,
                groupValue: task.isSelected ? true : null,
                onChanged: (value) {
                  setState(() {
                    task.isSelected = !task.isSelected;

                    // Add or remove from selectedTasksByGoal based on selection
                    if (!selectedTasksByGoal.containsKey(goalName)) {
                      selectedTasksByGoal[goalName] = [];
                    }

                    if (task.isSelected) {
                      if (!selectedTasksByGoal[goalName]!.contains(task)) {
                        selectedTasksByGoal[goalName]!.add(task);
                      }
                    } else {
                      selectedTasksByGoal[goalName]!.remove(task);
                    }
                  });
                },
                activeColor: Colors.green.shade500,
              ),
            ),

            // Task content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.description,
                    style: TextStyle(
                      color: task.isSelected
                          ? Colors.green.shade700
                          : Colors.grey.shade800,
                      fontWeight:
                          task.isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),

                  // Notes and reminders
                  if (hasNotes || hasReminder)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasNotes)
                            Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 14,
                                    color: Colors.green.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      notesMap[taskId]!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (hasReminder)
                            Row(
                              children: [
                                Icon(
                                  Icons.notifications_none,
                                  size: 14,
                                  color: Colors.green.shade400,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    remindersMap[taskId]!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Action buttons - wrap in a row that allows overflowing to be handled properly
            Wrap(
              spacing: 0,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () => _editTask(task, task.weekNumber, goalName),
                  color: Colors.grey.shade600,
                  tooltip: 'Edit task',
                  constraints: const BoxConstraints(maxWidth: 30),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  onPressed: () => _addNote(task, task.weekNumber, goalName),
                  color: Colors.grey.shade600,
                  tooltip: 'Add note',
                  constraints: const BoxConstraints(maxWidth: 30),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _deleteTask(task, task.weekNumber),
                  color: Colors.red.shade400,
                  tooltip: 'Delete task',
                  constraints: const BoxConstraints(maxWidth: 30),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for task management
  void _editTask(FinanceTask task, int weekNumber, String goalName) {
    TextEditingController controller =
        TextEditingController(text: task.description);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Task for Week $weekNumber'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter task description',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  // Get old taskId to update notes and reminders
                  final oldTaskId = '$weekNumber-$goalName-${task.description}';
                  final newTaskId = '$weekNumber-$goalName-${controller.text}';

                  setState(() {
                    // Create a new task with the updated description
                    final updatedTask = FinanceTask(
                      description: controller.text,
                      weekNumber: task.weekNumber,
                      goalIndex: task.goalIndex,
                      isSelected: task.isSelected,
                    );

                    // Replace the old task with the updated one in the list
                    final index = weeklyTasks[weekNumber]!.indexOf(task);
                    if (index != -1) {
                      weeklyTasks[weekNumber]![index] = updatedTask;
                    }

                    // Transfer notes and reminders to new task id
                    if (notesMap.containsKey(oldTaskId)) {
                      notesMap[newTaskId] = notesMap[oldTaskId]!;
                      notesMap.remove(oldTaskId);
                    }

                    if (remindersMap.containsKey(oldTaskId)) {
                      remindersMap[newTaskId] = remindersMap[oldTaskId]!;
                      remindersMap.remove(oldTaskId);
                    }
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _addNote(FinanceTask task, int weekNumber, String goalName) {
    final taskId = '$weekNumber-$goalName-${task.description}';
    TextEditingController controller = TextEditingController(
        text: notesMap.containsKey(taskId) ? notesMap[taskId] : '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Note'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter note...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (controller.text.isNotEmpty) {
                    notesMap[taskId] = controller.text;
                  } else {
                    notesMap.remove(taskId);
                  }
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Note'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTask(FinanceTask task, int weekNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content:
              Text('Are you sure you want to delete "${task.description}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  weeklyTasks[weekNumber]!.remove(task);

                  // Remove associated notes and reminders
                  final taskId =
                      '$weekNumber-$selectedGoal-${task.description}';
                  notesMap.remove(taskId);
                  remindersMap.remove(taskId);
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _showSetReminderDialog(int weekNumber, String goalName) {
    final TextEditingController dateController = TextEditingController();
    final TextEditingController messageController = TextEditingController(
        text: 'Complete tasks for Week $weekNumber in $goalName');

    // Set default date to tomorrow
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    dateController.text =
        '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Set Reminder for Week $weekNumber'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Date (YYYY-MM-DD)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Reminder Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final date = dateController.text;
                final message = messageController.text;

                if (date.isNotEmpty && message.isNotEmpty) {
                  final reminderText = '$date: $message';
                  final taskId = '$weekNumber-$selectedGoal-Week$weekNumber';

                  setState(() {
                    remindersMap[taskId] = reminderText;
                  });

                  Navigator.pop(context);

                  // Show confirmation
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reminder set for $date'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Reminder'),
            ),
          ],
        );
      },
    );
  }

  // Add method to show dialog for adding new tasks
  void _showAddTaskDialog(int weekNumber) {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Task for Week $weekNumber'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter task description',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    weeklyTasks[weekNumber]!.add(FinanceTask(
                      description: controller.text,
                      weekNumber: weekNumber,
                      goalIndex: currentGoalIndex,
                      isSelected: false,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Task'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStep5() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Step 5: Finance Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Show only the selected goal card
          _buildGoalSummaryCard(selectedGoal),

          // Weekly reflection
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Reflection',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Take time to reflect on your progress each week:',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How do you feel after Week 1?',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Share your thoughts on your progress...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: Colors.green.shade300),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        maxLines: 3,
                        onChanged: (value) {
                          setState(() {
                            weeklyReflection = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Rate your satisfaction:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildEmojiButton('😞', 0),
                          _buildEmojiButton('😐', 1),
                          _buildEmojiButton('🙂', 2),
                          _buildEmojiButton('😀', 3),
                          _buildEmojiButton('🤩', 4),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Badges and actions
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: LayoutBuilder(builder: (context, constraints) {
              // Use column layout for smaller screens
              if (constraints.maxWidth < 400) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            '+100 XP',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade500,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                '🏅 FINANCE PRO',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              currentStep = 4;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                          ),
                          child: const Text('Back'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            // Save the finance plan
                            saveAndExit();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade500,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          child: const Text('Save Plan'),
                        ),
                      ],
                    ),
                  ],
                );
              }

              // Original layout for larger screens
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          '+100 XP',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade500,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              '🏅 FINANCE MASTER',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            currentStep = 4;
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                        ),
                        child: const Text('Back'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          // Save the finance plan
                          saveAndExit();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade500,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Save Plan'),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalSummaryCard(String goalName) {
    final selectedTasks = selectedTasksByGoal[goalName] ?? [];

    String emoji = '📊';
    if (goalName == 'Expand Portfolio') {
      emoji = '📈';
    } else if (goalName == 'Build Wealth') {
      emoji = '💰';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Summary header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.green.shade500,
                  Colors.green.shade700,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Finance Focus: $goalName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Starting: $selectedMonth 2025',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Selected tasks content
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Tasks:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                // Task cards in a grid layout
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedTasks.map((task) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.green.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.radio_button_checked,
                            size: 16,
                            color: Colors.green.shade600,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              task.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                if (selectedTasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      'No tasks selected yet',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiButton(String emoji, int rating) {
    final isSelected = satisfactionRating == rating;

    return ElevatedButton(
      onPressed: () {
        setState(() {
          satisfactionRating = rating;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? Colors.green.shade300 : Colors.grey.shade100,
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(40, 40),
        shape: const CircleBorder(),
      ),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 20),
      ),
    );
  }

  Widget _buildNavigationButtons({
    required VoidCallback onBack,
    required VoidCallback onNext,
    String? nextLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: ElevatedButton(
              onPressed: onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                foregroundColor: Colors.grey.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 0,
              ),
              child: const Text('Back'),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                elevation: 2,
              ),
              child: Text(nextLabel ?? 'Continue'),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to save selections for selected goal
  void _saveCurrentSelections() {
    final goalName = selectedGoal;
    final goalIndex = goals.indexOf(goalName);

    if (goalIndex >= 0) {
      // Get all selected tasks for this goal
      for (var week in weeklyTasks.keys) {
        for (var task in weeklyTasks[week]!) {
          if (task.isSelected && task.goalIndex == goalIndex) {
            // Also save to selectedTasksByGoal for summary view
            if (!selectedTasksByGoal.containsKey(goalName)) {
              selectedTasksByGoal[goalName] = [];
            }
            if (!selectedTasksByGoal[goalName]!.contains(task)) {
              selectedTasksByGoal[goalName]!.add(task);
            }
          }
        }
      }

      // Also save the week dates for this goal
      if (!weekDatesByGoal.containsKey(goalIndex)) {
        weekDatesByGoal[goalIndex] = {};
      }

      // Copy the current week dates to the goal-specific map
      for (var entry in weekDates.entries) {
        weekDatesByGoal[goalIndex]![entry.key] = entry.value;
      }
    }
  }

  // Method to restore dates for the current goal
  void _restoreDatesForCurrentGoal() {
    final goalIndex = goals.indexOf(selectedGoal);

    // Restore saved week dates for current goal
    if (weekDatesByGoal.containsKey(goalIndex)) {
      final savedWeekDates = weekDatesByGoal[goalIndex]!;
      for (var entry in savedWeekDates.entries) {
        weekDates[entry.key] = entry.value;
      }
    } else {
      // If no saved dates, reinitialize them
      _initializeDefaultDates();
    }
  }

  Future<void> saveAndExit() async {
    try {
      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();

      // First, read existing data from SharedPreferences
      // Read existing vision board tasks
      List<Map<String, dynamic>> existingVisionBoardTasks = [];
      final existingVisionBoardStr = prefs.getString('BoxThem_todos_Invest');
      if (existingVisionBoardStr != null && existingVisionBoardStr.isNotEmpty) {
        try {
          final List<dynamic> decoded = json.decode(existingVisionBoardStr);
          existingVisionBoardTasks =
              decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        } catch (e) {
          debugPrint('Error parsing existing vision board tasks: $e');
        }
      }

      // Create a list for the selected finance tasks
      List<Map<String, dynamic>> financeTasks = [];
      final selectedTasks = selectedTasksByGoal[selectedGoal] ?? [];

      // Format tasks for vision board
      for (var task in selectedTasks) {
        final taskId = DateTime.now().millisecondsSinceEpoch.toString() +
            '_${task.description.hashCode}';
        financeTasks.add({
          "id": taskId,
          "text": "${task.description} for $selectedGoal in $selectedMonth",
          "isDone": false
        });
      }

      // If no tasks were selected, add default tasks
      if (financeTasks.isEmpty) {
        final defaultTasks = [
          "Daily finance routine for $selectedGoal",
          "Weekly check-in for $selectedMonth",
          "Finance progress review"
        ];

        for (var taskText in defaultTasks) {
          final taskId = DateTime.now().millisecondsSinceEpoch.toString() +
              '_${taskText.hashCode}';
          financeTasks.add({"id": taskId, "text": taskText, "isDone": false});
        }
      }

      // For vision board tasks, add new tasks to existing ones
      // First create a set of existing task texts to avoid duplicates
      final Set<String> existingTaskTexts = existingVisionBoardTasks
          .map((task) => task['text']?.toString() ?? '')
          .toSet();

      // Add only new tasks (avoid duplicates by text)
      for (var task in financeTasks) {
        final taskText = task['text']?.toString() ?? '';
        if (taskText.isNotEmpty && !existingTaskTexts.contains(taskText)) {
          existingVisionBoardTasks.add(task);
        }
      }

      // Save the combined vision board tasks
      await prefs.setString(
          'BoxThem_todos_Invest', json.encode(existingVisionBoardTasks));

      // Save to animal calendar format
      // First, read existing animal calendar data
      Map<String, dynamic> existingEvents = {};
      Map<String, dynamic> existingTheme = {};

      // Read existing animal calendar events
      final existingEventsStr = prefs.getString('animal.calendar_events');
      if (existingEventsStr != null && existingEventsStr.isNotEmpty) {
        try {
          existingEvents = json.decode(existingEventsStr);
        } catch (e) {
          debugPrint('Error parsing existing calendar events: $e');
        }
      }

      // Read existing animal calendar theme
      final existingThemeStr = prefs.getString('animal.calendar_theme_2025');
      if (existingThemeStr != null && existingThemeStr.isNotEmpty) {
        try {
          existingTheme = json.decode(existingThemeStr);
        } catch (e) {
          debugPrint('Error parsing existing calendar theme: $e');
        }
      }

      // Create format for animal calendar
      Map<String, dynamic> calendarEvents = {};
      Map<String, dynamic> calendarTheme = {};

      // Get selected tasks and their dates
      final tasksToSave = selectedTasksByGoal[selectedGoal] ?? [];

      if (tasksToSave.isNotEmpty) {
        // Use "Finance" category for finance journey
        const category = "Finance";

        // Create animal calendar format tasks
        for (var task in tasksToSave) {
          // Get the date for this task's week
          final weekDate = weekDates[task.weekNumber];
          if (weekDate != null) {
            // Format date in ISO8601 format for events
            final dateStr = weekDate.toIso8601String();

            // Format date for theme (YYYY-MM-DD)
            final themeDate =
                "${weekDate.year}-${weekDate.month.toString().padLeft(2, '0')}-${weekDate.day.toString().padLeft(2, '0')}";

            // Create task entry
            final taskEntry = {
              'category': category,
              'title': category,
              'type': task.description,
              'is_all_day': 'true',
              'event_hour': '9',
              'event_minute': '0',
              'has_custom_notification': 'false',
              'notification_hour': '9',
              'notification_minute': '0',
              'reminder_minutes': '0',
              'notification_day_offset': '0',
              'task_id': DateTime.now().millisecondsSinceEpoch.toString(),
            };

            // Add to calendar events and theme
            if (!calendarEvents.containsKey(dateStr)) {
              calendarEvents[dateStr] = [];
            }
            calendarEvents[dateStr]!.add(taskEntry);
            calendarTheme[themeDate] = category;
          }
        }
      }

      // Merge with existing data
      existingEvents.addAll(calendarEvents);
      existingTheme.addAll(calendarTheme);

      // Save to SharedPreferences
      await prefs.setString(
          'animal.calendar_events', json.encode(existingEvents));
      await prefs.setString(
          'animal.calendar_theme_2025', json.encode(existingTheme));
      await prefs.setString('animal.calendar_data', json.encode(existingTheme));

      // Also save to weekly planner format
      // First, read existing weekly planner tasks
      Map<String, List<Map<String, dynamic>>> weeklyPlannerTasks = {};
      for (int week = 1; week <= 4; week++) {
        final dayOfWeek = _getDayOfWeekFromWeekNumber(week);
        final tasks = getTasksForWeekAndGoal(week, currentGoalIndex)
            .where((task) => task.isSelected)
            .toList();

        if (tasks.isNotEmpty) {
          // Convert to weekly planner format
          List<Map<String, dynamic>> weekTasks = tasks
              .map((task) => {"text": task.description, "completed": false})
              .toList();

          weeklyPlannerTasks[dayOfWeek] = weekTasks;
        }
      }

      // Save to weekly planner format
      for (var entry in weeklyPlannerTasks.entries) {
        final day = entry.key;
        final tasks = entry.value;

        // Read existing weekly planner tasks
        List<Map<String, dynamic>> existingWeeklyTasks = [];
        final existingWeeklyStr = prefs.getString('WatercolorTheme_todos_$day');
        if (existingWeeklyStr != null && existingWeeklyStr.isNotEmpty) {
          try {
            final List<dynamic> decoded = json.decode(existingWeeklyStr);
            existingWeeklyTasks =
                decoded.map((item) => Map<String, dynamic>.from(item)).toList();
          } catch (e) {
            debugPrint('Error parsing existing weekly tasks: $e');
          }
        }

        // Merge with existing tasks
        final Set<String> existingTexts = existingWeeklyTasks
            .map((task) => task['text']?.toString() ?? '')
            .toSet();

        for (var task in tasks) {
          final taskText = task['text']?.toString() ?? '';
          if (taskText.isNotEmpty && !existingTexts.contains(taskText)) {
            existingWeeklyTasks.add(task);
          }
        }

        // Save merged tasks
        await prefs.setString(
            'WatercolorTheme_todos_$day', json.encode(existingWeeklyTasks));

        // Also create widget format
        List<Map<String, dynamic>> widgetTasks = existingWeeklyTasks
            .map((task) => {
                  "id": "${task['text'].hashCode}",
                  "text": task['text'],
                  "isDone": task['completed'] ?? false
                })
            .toList();

        await prefs.setString(
            'watercolor_widget_todos_$day', json.encode(widgetTasks));

        // Format display text
        final String displayText = existingWeeklyTasks.map((task) {
          final checkmark = task['completed'] == true ? '✓ ' : '• ';
          return "$checkmark${task['text']}";
        }).join('\n');

        await prefs.setString('watercolor_todo_text_$day', displayText);
      }

      // Update the widgets
      try {
        await HomeWidget.updateWidget(
          androidName: 'VisionBoardWidget',
          iOSName: 'VisionBoardWidget',
        );

        await HomeWidget.updateWidget(
          androidName: 'WeeklyPlannerWidget',
          iOSName: 'WeeklyPlannerWidget',
        );

        await HomeWidget.updateWidget(
          androidName: 'CalendarThemeWidget',
          iOSName: 'CalendarThemeWidget',
        );
      } catch (e) {
        debugPrint('Error updating widgets: $e');
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Finance plan saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Return to previous screen
      Navigator.pop(context);
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving finance plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to get day of week from week number
  String _getDayOfWeekFromWeekNumber(int weekNumber) {
    switch (weekNumber) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      default:
        return 'Monday';
    }
  }
}

// Add a TaskItem class to track task completion state
class TaskItem {
  final String task;
  bool isCompleted;

  TaskItem({required this.task, this.isCompleted = false});
}
