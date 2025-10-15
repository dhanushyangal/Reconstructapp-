import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../vision_bord/unified_vision_board_page.dart';
import '../services/journey_database_service.dart';
import '../services/user_service.dart';

class SelfCareJourney extends StatefulWidget {
  const SelfCareJourney({super.key});

  @override
  State<SelfCareJourney> createState() => _SelfCareJourneyState();
}

class _SelfCareJourneyState extends State<SelfCareJourney> {
  int currentStep = 1;
  String selectedHabit = 'Look Better';
  String selectedMonth = 'June';
  int currentHabitIndex = 0;
  int satisfactionRating = 0; // 0-4 for 5 emoji ratings
  String weeklyReflection = '';

  // New properties for modern UI
  final Map<String, String> notesMap = {};
  final Map<String, String> remindersMap = {};
  String? editingTaskId;
  TextEditingController editingTaskController = TextEditingController();

  // Add data structure for habit tasks with selection state
  final Map<int, List<SelfCareTask>> weeklyTasks = {1: [], 2: [], 3: [], 4: []};

  // Add a map to store selected tasks for each habit
  final Map<String, List<SelfCareTask>> selectedTasksByHabit = {};

  // Add a map to store selected tasks for each habit index
  final Map<int, Set<String>> selectedTasksByHabitIndex = {};

  // Add a map to store week dates
  final Map<int, DateTime> weekDates = {};

  // Add a map to store week dates for each habit
  final Map<int, Map<int, DateTime>> weekDatesByHabit = {};

  // Database service
  late final JourneyDatabaseService _journeyDatabaseService;

  // List of habits
  final List<String> habits = [
    'Look Better',
    'Dress Well',
    'Feel More Confident'
  ];

  @override
  void initState() {
    super.initState();
    _journeyDatabaseService = JourneyDatabaseService.instance;
    _initializeDefaultTasks();
    _initializeDefaultDates();
  }

  // Initialize default tasks for each week and habit
  void _initializeDefaultTasks() {
    // Structure: Map<HabitName, Map<WeekNumber, List<TaskDescriptions>>>
    final Map<String, Map<String, List<String>>> habitTasks = {
      'Look Better': {
        'Week 1': [
          'Daily showers',
          'Brushing teeth (twice a day)',
          'Trimmed nails',
          'Moisturized skin'
        ],
        'Week 2': ['Get a fresh haircut', 'Exfoliate skin', 'Visit a spa'],
        'Week 3': [
          'Style hair neatly',
          'Apply sunscreen daily',
          'Wear clean, pressed clothes'
        ],
        'Week 4': [
          'Get a facial treatment',
          'Upgrade your wardrobe',
          'Maintain good posture',
          'Stay hydrated'
        ]
      },
      'Dress Well': {
        'Week 1': ['Basic grooming: Showers, teeth, nails, moisturize'],
        'Week 2': ['Haircut & exfoliation', 'Spa day'],
        'Week 3': [
          'Daily sunscreen',
          'Styled hair',
          'Wear clean & pressed clothes'
        ],
        'Week 4': [
          'Facial treatment',
          'Wardrobe upgrade',
          'Posture check',
          'Drink lots of water'
        ]
      },
      'Feel More Confident': {
        'Week 1': ['Daily hygiene + grooming (teeth, skin, nails)'],
        'Week 2': ['Haircut', 'Spa / relaxation ritual'],
        'Week 3': ['Sunscreen & skin care', 'Maintain polished look'],
        'Week 4': [
          'Facial, wardrobe tweaks, posture improvement',
          'Hydration challenge'
        ]
      }
    };

    // Initialize weeks with default tasks
    for (int week = 1; week <= 4; week++) {
      weeklyTasks[week] = [];
      for (String habit in habits) {
        final weekTasks = habitTasks[habit]?['Week $week'] ?? [];
        for (String taskDesc in weekTasks) {
          weeklyTasks[week]!.add(
            SelfCareTask(
              description: taskDesc,
              weekNumber: week,
              habitIndex: habits.indexOf(habit),
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

  // Helper method to get tasks for a specific week and habit
  List<SelfCareTask> getTasksForWeekAndHabit(int week, int habitIndex) {
    if (habitIndex < 0 || habitIndex >= habits.length) {
      return [];
    }

    return weeklyTasks[week]
            ?.where((task) =>
                task.habitIndex == habitIndex || task.habitIndex == -1)
            .toList() ??
        [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF), // purple-50
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
            icon: const Icon(Icons.arrow_back, color: Colors.purple),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'Self-Care Journey',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
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
                            ? Colors.purple.shade500
                            : Colors.purple.shade200,
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.3),
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
                            color: isActive
                                ? Colors.white
                                : Colors.purple.shade700,
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
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ],
                ),
                if (index < 4)
                  Container(
                    width: 40,
                    height: 2,
                    color: stepNumber < currentStep
                        ? Colors.purple.shade500
                        : Colors.purple.shade200,
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
        return 'Habit';
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
            color: Colors.purple.withOpacity(0.1),
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
            '🌱 Welcome to Your Self-Care Journey!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7E22CE), // purple-600
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Design your personalized self-care plan for the next month. You\'ll choose a habit to focus on, set a schedule, and track your progress along the way.',
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
              backgroundColor: const Color(0xFF9333EA), // purple-500
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
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Step 2: Choose a Self-Care Habit',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Select one habit to focus on for the next month:',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Habit selection grid
          LayoutBuilder(builder: (context, constraints) {
            return GridView.count(
              crossAxisCount: constraints.maxWidth > 600 ? 3 : 1,
              shrinkWrap: true,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildHabitCard('Look Better', '💄',
                    'Enhance your appearance with consistent grooming'),
                _buildHabitCard('Dress Well', '👔',
                    'Refine your style to reflect your best self'),
                _buildHabitCard('Feel More Confident', '💪',
                    'Build confidence through physical care'),
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

  Widget _buildHabitCard(String title, String emoji, String description) {
    final isSelected = selectedHabit == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedHabit = title;
          currentHabitIndex = habits.indexOf(title);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.purple.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.purple.shade400 : Colors.grey.shade200,
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
                color: Colors.purple.shade100,
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
            color: Colors.purple.withOpacity(0.1),
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
              color: Colors.purple.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'When do you want to begin your self-care journey?',
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
              border: Border.all(color: Colors.purple.shade200),
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
                  'Selected Habit: $selectedHabit',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7E22CE),
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
                            color: Colors.purple.shade50,
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
                          color: Colors.purple.shade50,
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
                // Reset habit index when entering step 4
                currentHabitIndex = habits.indexOf(selectedHabit);
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
          borderSide: BorderSide(color: Colors.purple.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.purple.shade500, width: 2),
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
    // Get the current habit name
    final habitName = selectedHabit;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
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
              color: Colors.purple.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Plan your self-care activities for $habitName:',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Selected habit card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade500,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    habitName,
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
    final int habitIndex = habits.indexOf(selectedHabit);

    // Restore dates for the current habit instead of refreshing
    _restoreDatesForCurrentHabit();

    return Column(
      children: List.generate(4, (weekIndex) {
        final weekNumber = weekIndex + 1;
        final tasksForWeek = getTasksForWeekAndHabit(weekNumber, habitIndex);
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
                  color: Colors.purple.shade50,
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
                              color: Colors.purple.shade600,
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
                                color: Colors.purple.shade600,
                              ),
                            ),
                            Text(
                              '${weekDate.day}/${weekDate.month}/${weekDate.year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.purple.shade400,
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
                          color: Colors.purple.shade600, size: 18),
                      label: Text(
                        'Change Date',
                        style: TextStyle(color: Colors.purple.shade600),
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
                    foregroundColor: Colors.purple.shade600,
                    elevation: 0,
                    side: BorderSide(color: Colors.purple.shade300),
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
  Widget _buildTaskItem(SelfCareTask task) {
    final String habitName = selectedHabit;
    final String taskId = "${task.weekNumber}-$habitName-${task.description}";
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

                    // Add or remove from selectedTasksByHabit based on selection
                    if (!selectedTasksByHabit.containsKey(habitName)) {
                      selectedTasksByHabit[habitName] = [];
                    }

                    if (task.isSelected) {
                      if (!selectedTasksByHabit[habitName]!.contains(task)) {
                        selectedTasksByHabit[habitName]!.add(task);
                      }
                    } else {
                      selectedTasksByHabit[habitName]!.remove(task);
                    }
                  });
                },
                activeColor: Colors.purple.shade500,
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
                          ? Colors.purple.shade700
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
                                    color: Colors.purple.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      notesMap[taskId]!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.purple.shade400,
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
                                  color: Colors.purple.shade400,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    remindersMap[taskId]!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.purple.shade400,
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
                  onPressed: () => _editTask(task, task.weekNumber, habitName),
                  color: Colors.grey.shade600,
                  tooltip: 'Edit task',
                  constraints: const BoxConstraints(maxWidth: 30),
                  padding: EdgeInsets.zero,
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  onPressed: () => _addNote(task, task.weekNumber, habitName),
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
  void _editTask(SelfCareTask task, int weekNumber, String habitName) {
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
                  final oldTaskId =
                      '$weekNumber-$habitName-${task.description}';
                  final newTaskId = '$weekNumber-$habitName-${controller.text}';

                  setState(() {
                    // Create a new task with the updated description
                    final updatedTask = SelfCareTask(
                      description: controller.text,
                      weekNumber: task.weekNumber,
                      habitIndex: task.habitIndex,
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
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _addNote(SelfCareTask task, int weekNumber, String habitName) {
    final taskId = '$weekNumber-$habitName-${task.description}';
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
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Note'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTask(SelfCareTask task, int weekNumber) {
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
                      '$weekNumber-$selectedHabit-${task.description}';
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
            decoration: InputDecoration(
              hintText: 'Enter task description',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  setState(() {
                    weeklyTasks[weekNumber]!.add(SelfCareTask(
                      description: controller.text,
                      weekNumber: weekNumber,
                      habitIndex: currentHabitIndex,
                      isSelected: false,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: Text('Add Task'),
            ),
          ],
        );
      },
    );
  }

  // Helper method to save selections for selected habit
  void _saveCurrentSelections() {
    final habitName = selectedHabit;
    final habitIndex = habits.indexOf(habitName);

    if (habitIndex >= 0) {
      // Get all selected tasks for this habit
      final selectedTaskIds = <String>{};

      for (var week in weeklyTasks.keys) {
        for (var task in weeklyTasks[week]!) {
          if (task.isSelected && task.habitIndex == habitIndex) {
            selectedTaskIds.add('${task.weekNumber}-${task.description}');

            // Also save to selectedTasksByHabit for summary view
            if (!selectedTasksByHabit.containsKey(habitName)) {
              selectedTasksByHabit[habitName] = [];
            }
            if (!selectedTasksByHabit[habitName]!.contains(task)) {
              selectedTasksByHabit[habitName]!.add(task);
            }
          }
        }
      }

      // Save selected task IDs for this habit
      selectedTasksByHabitIndex[habitIndex] = selectedTaskIds;

      // Also save the week dates for this habit
      if (!weekDatesByHabit.containsKey(habitIndex)) {
        weekDatesByHabit[habitIndex] = {};
      }

      // Copy the current week dates to the habit-specific map
      for (var entry in weekDates.entries) {
        weekDatesByHabit[habitIndex]![entry.key] = entry.value;
      }
    }
  }

  // Method to restore dates for the current habit
  void _restoreDatesForCurrentHabit() {
    final habitIndex = habits.indexOf(selectedHabit);

    // Restore saved week dates for current habit
    if (weekDatesByHabit.containsKey(habitIndex)) {
      final savedWeekDates = weekDatesByHabit[habitIndex]!;
      for (var entry in savedWeekDates.entries) {
        weekDates[entry.key] = entry.value;
      }
    } else {
      // If no saved dates, reinitialize them
      _initializeDefaultDates();
    }
  }

  Widget _buildStep5() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Step 5: Self-Care Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Show only the selected habit card
          _buildHabitSummaryCard(selectedHabit),

          // Weekly reflection
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
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
                    color: Color(0xFF7E22CE),
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
                    border: Border.all(color: Colors.purple.shade200),
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
                                BorderSide(color: Colors.purple.shade300),
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

          // Badges and actions - fix layout for smaller screens
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
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
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            '+100 XP',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF7E22CE),
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
                            color: Colors.purple.shade500,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            children: [
                              Text(
                                '🏅 SELF-CARE PRO',
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
                            // Save the self-care plan
                            _saveSelfCarePlan();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade500,
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
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          '+100 XP',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF7E22CE),
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
                          color: Colors.purple.shade500,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              '🏅 SELF-CARE MASTER',
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
                          // Save the self-care plan
                          _saveSelfCarePlan();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade500,
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

  Widget _buildHabitSummaryCard(String habitName) {
    final selectedTasks = selectedTasksByHabit[habitName] ?? [];

    String emoji = '💄';
    if (habitName == 'Dress Well') {
      emoji = '👔';
    } else if (habitName == 'Feel More Confident') {
      emoji = '💪';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.1),
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
                  Colors.purple.shade500,
                  Colors.purple.shade700,
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
                      decoration: BoxDecoration(
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
                        'Self-Care Focus: $habitName',
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
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.purple.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.radio_button_checked,
                            size: 16,
                            color: Colors.purple.shade600,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              task.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.purple.shade700,
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
            isSelected ? Colors.purple.shade300 : Colors.grey.shade100,
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
                backgroundColor: Colors.purple.shade500,
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

  // Method to save self-care plan to database
  Future<void> _saveSelfCarePlan() async {
    try {
      debugPrint('Saving self-care plan to database...');

      // Check if user is logged in
      final isLoggedIn = await UserService.instance.isUserLoggedIn();
      if (!isLoggedIn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to save your self-care plan'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Save current selections before saving to database
      _saveCurrentSelections();

      // Prepare data for database saving
      final Map<String, List<dynamic>> tasksForDatabase = {};

      // Convert selectedTasksByHabit to the format expected by the database service
      for (var entry in selectedTasksByHabit.entries) {
        final habitName = entry.key;
        final tasks = entry.value;
        tasksForDatabase[habitName] = tasks.cast<dynamic>();
      }

      // Save to database using the journey database service (excluding annual calendar)
      final result =
          await _journeyDatabaseService.saveSelfCareJourneyWithoutAnnual(
        selectedHabit: selectedHabit,
        selectedMonth: selectedMonth,
        selectedTasksByHabit: tasksForDatabase,
        weekDates: weekDates,
      );

      if (result['success'] == true) {
        // Also save to local storage for widget support
        await _saveToLocalStorage();

        // Update home widgets
        await _updateWidgets();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Self-care plan saved successfully to database!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to Vision Board page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const UnifiedVisionBoardPage(themeName: 'Box theme Vision Board'),
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? 'Unknown database error');
      }
    } catch (e) {
      debugPrint('ERROR SAVING SELF-CARE PLAN: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving self-care plan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper method to save to local storage for widget support
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Create self-care tasks for widgets
      List<Map<String, dynamic>> selfCareTasks = [];
      final selectedTasks = selectedTasksByHabit[selectedHabit] ?? [];

      // Format tasks for vision board
      for (var task in selectedTasks) {
        final taskId = '${DateTime.now().millisecondsSinceEpoch}_${task.description.hashCode}';
        selfCareTasks.add({
          "id": taskId,
          "text": "${task.description} for $selectedHabit in $selectedMonth",
          "isDone": false
        });
      }

      // If no tasks were selected, add default tasks
      if (selfCareTasks.isEmpty) {
        final defaultTasks = [
          "Daily self-care routine for $selectedHabit",
          "Weekly check-in for $selectedMonth",
          "Self-care progress review"
        ];

        for (var taskText in defaultTasks) {
          final taskId = '${DateTime.now().millisecondsSinceEpoch}_${taskText.hashCode}';
          selfCareTasks.add({"id": taskId, "text": taskText, "isDone": false});
        }
      }

      // Save to local storage for widgets
      await prefs.setString(
          'BoxThem_todos_Self Care', jsonEncode(selfCareTasks));

      debugPrint('Self-care data saved to local storage for widgets');
    } catch (e) {
      debugPrint('Error saving self-care data to local storage: $e');
    }
  }

  // Helper method to update widgets
  Future<void> _updateWidgets() async {
    try {
      await HomeWidget.updateWidget(
        androidName: 'VisionBoardWidget',
        iOSName: 'VisionBoardWidget',
      );

      await HomeWidget.updateWidget(
        androidName: 'WeeklyPlannerWidget',
        iOSName: 'WeeklyPlannerWidget',
      );

      debugPrint('Widgets updated successfully');
    } catch (e) {
      debugPrint('Error updating widgets: $e');
    }
  }
}

// Add a class to track habit task completion
class SelfCareTask {
  final String description;
  final int weekNumber;
  final int habitIndex; // Index in the habits list
  bool isSelected;

  SelfCareTask({
    required this.description,
    required this.weekNumber,
    this.habitIndex = -1,
    this.isSelected = false,
  });
}
