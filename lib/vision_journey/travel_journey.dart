import 'package:flutter/material.dart';

class TravelJourney extends StatefulWidget {
  const TravelJourney({Key? key}) : super(key: key);

  @override
  State<TravelJourney> createState() => _TravelJourneyState();
}

class _TravelJourneyState extends State<TravelJourney> {
  int currentStep = 1;
  List<String> selectedLocations = [];
  List<String> selectedMonths = [];
  int currentCityIndex = 0;

  // Add a data structure for weekly tasks with completion state
  final Map<int, List<TravelTask>> weeklyTasks = {1: [], 2: [], 3: [], 4: []};

  @override
  void initState() {
    super.initState();
    _initializeDefaultTasks();
  }

  // Initialize default tasks for each week
  void _initializeDefaultTasks() {
    final defaultTasks = [
      'Book flight tickets',
      'Reserve hotel',
      'Research local transport',
      'Create sightseeing list',
      'Check visa requirements',
    ];

    // Initialize weeks with default tasks
    for (int week = 1; week <= 4; week++) {
      weeklyTasks[week] = defaultTasks
          .map((task) => TravelTask(description: task, weekNumber: week))
          .toList();
    }
  }

  // Add a method to get tasks for a specific week and city
  List<TravelTask> getTasksForWeekAndCity(int week, int cityIndex) {
    // Filter tasks by week and city
    return weeklyTasks[week]
            ?.where(
                (task) => task.cityIndex == cityIndex || task.cityIndex == -1)
            .toList() ??
        [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      body: SafeArea(
        child: Stack(
          children: [
            // Background decorative elements
            Positioned(
              right: -100,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              left: -80,
              bottom: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.15),
                ),
              ),
            ),

            // Main content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildHeader(),
                    _buildStepper(),
                    const SizedBox(height: 16),
                    _buildCurrentStep(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.blue),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'Travel Journey',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: List.generate(5, (index) {
          final stepNumber = index + 1;
          final isActive = stepNumber <= currentStep;

          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.blue : Colors.blue.shade100,
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 8,
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
                                isActive ? Colors.white : Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getStepTitle(stepNumber),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isActive
                            ? Colors.blue.shade700
                            : Colors.blue.shade300,
                      ),
                    ),
                  ],
                ),
                if (index < 4)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: stepNumber < currentStep
                          ? Colors.blue
                          : Colors.blue.shade200,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 1:
        return 'Intro';
      case 2:
        return 'Destinations';
      case 3:
        return 'Schedule';
      case 4:
        return 'Checklist';
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
    return Card(
      elevation: 4,
      shadowColor: Colors.blue.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Text(
              '🌎 Welcome to Your Travel Journey!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D4ED8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Text(
                'Design your personalized travel plan for 2025. You\'ll select your dream destinations, plan the best times to visit, and create a complete travel roadmap.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 16,
                  height: 1.5,
                ),
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
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
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
      ),
    );
  }

  Widget _buildStep2() {
    return Card(
      elevation: 4,
      shadowColor: Colors.blue.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Text(
                    'Step 2: Select 3 Dream Travel Destinations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4ED8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Search and select 3 cities you want to visit this year:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Simplified destination inputs for demo
            _buildDestinationInput(1),
            _buildDestinationInput(2),
            _buildDestinationInput(3),

            const SizedBox(height: 24),
            _buildNavigationButtons(
              onBack: () {
                setState(() {
                  currentStep = 1;
                });
              },
              onNext: () {
                // For demo purposes, we'll just move forward
                setState(() {
                  // Prefill some locations if empty
                  if (selectedLocations.isEmpty) {
                    selectedLocations = [
                      'Paris, France',
                      'Tokyo, Japan',
                      'New York, USA',
                    ];
                  }
                  currentStep = 3;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationInput(int destinationNum) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Destination $destinationNum:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search for a city...',
              prefixIcon: const Icon(Icons.search, color: Colors.blue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue.shade500, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
            onChanged: (value) {
              // In a real app, you would filter and show autocomplete suggestions
              // For this demo, we'll just save the value
              if (selectedLocations.length < destinationNum) {
                // Add empty placeholders if needed
                while (selectedLocations.length < destinationNum - 1) {
                  selectedLocations.add('');
                }
                selectedLocations.add(value);
              } else {
                selectedLocations[destinationNum - 1] = value;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Card(
      elevation: 4,
      shadowColor: Colors.blue.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Text(
                    'Step 3: Pick a Travel Month for Each City',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4ED8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Choose the best time to visit each destination:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Month selection for each city
            ...List.generate(selectedLocations.length, (index) {
              return _buildMonthSelection(index);
            }),

            const SizedBox(height: 24),
            _buildNavigationButtons(
              onBack: () {
                setState(() {
                  currentStep = 2;
                });
              },
              onNext: () {
                // For demo purposes, we'll just move forward
                setState(() {
                  // Prefill some months if empty
                  if (selectedMonths.isEmpty) {
                    selectedMonths = [
                      'June 2025',
                      'August 2025',
                      'October 2025',
                    ];
                  }
                  currentStep = 4;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelection(int cityIndex) {
    final city =
        selectedLocations.isNotEmpty && cityIndex < selectedLocations.length
            ? selectedLocations[cityIndex].split(',').first
            : 'City ${cityIndex + 1}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade100,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(
              Icons.location_on,
              color: Colors.blue.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$city:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              hint: const Text('Select month'),
              items: [
                'January 2025',
                'February 2025',
                'March 2025',
                'April 2025',
                'May 2025',
                'June 2025',
                'July 2025',
                'August 2025',
                'September 2025',
                'October 2025',
                'November 2025',
                'December 2025',
              ].map((month) {
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(month),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    if (selectedMonths.length <= cityIndex) {
                      while (selectedMonths.length < cityIndex) {
                        selectedMonths.add('');
                      }
                      selectedMonths.add(value);
                    } else {
                      selectedMonths[cityIndex] = value;
                    }
                  });
                }
              },
              value:
                  selectedMonths.isNotEmpty && cityIndex < selectedMonths.length
                      ? selectedMonths[cityIndex]
                      : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    return Card(
      elevation: 4,
      shadowColor: Colors.blue.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Text(
                    'Step 4: Weekly Preparation Plan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1D4ED8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Plan your preparation activities for each city:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // City navigation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: currentCityIndex > 0
                        ? () {
                            setState(() {
                              currentCityIndex--;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue.shade700,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      selectedLocations.isNotEmpty &&
                              currentCityIndex < selectedLocations.length
                          ? '${selectedLocations[currentCityIndex].split(',').first} (${currentCityIndex + 1}/${selectedLocations.length})'
                          : 'City ${currentCityIndex + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: currentCityIndex < selectedLocations.length - 1
                        ? () {
                            setState(() {
                              currentCityIndex++;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue.shade700,
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
                setState(() {
                  currentStep = 5;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyPlan() {
    return Column(
      children: List.generate(4, (weekIndex) {
        final weekNumber = weekIndex + 1;
        final tasksForWeek =
            getTasksForWeekAndCity(weekNumber, currentCityIndex);

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
                  color: Colors.blue.shade50,
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
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$weekNumber',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Week $weekNumber',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () {
                        // Would show reminder dialog in a real app
                      },
                      color: Colors.blue.shade600,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Tasks for this week
              ...tasksForWeek.map((task) => _buildTaskItem(task)),
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
                    foregroundColor: Colors.blue.shade600,
                    side: BorderSide(color: Colors.blue.shade300),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Update task item to handle checkbox state
  Widget _buildTaskItem(TravelTask task) {
    return CheckboxListTile(
      title: Text(
        task.description,
        style: TextStyle(
          decoration: task.isCompleted
              ? TextDecoration.lineThrough
              : TextDecoration.none,
        ),
      ),
      value: task.isCompleted,
      onChanged: (value) {
        setState(() {
          task.isCompleted = value ?? false;
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      activeColor: Colors.blue,
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
                    weeklyTasks[weekNumber]!.add(TravelTask(
                      description: controller.text,
                      weekNumber: weekNumber,
                      cityIndex: currentCityIndex,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text('Add Task'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStep5() {
    return Card(
      elevation: 4,
      shadowColor: Colors.blue.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Step 5: Travel Plan Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D4ED8),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // Travel summaries
            ...List.generate(selectedLocations.length, (index) {
              final city = selectedLocations.isNotEmpty &&
                      index < selectedLocations.length
                  ? selectedLocations[index].split(',').first
                  : 'City ${index + 1}';
              final month =
                  selectedMonths.isNotEmpty && index < selectedMonths.length
                      ? selectedMonths[index].split(' ').first
                      : 'Month';

              // Get completed tasks for this city
              final allTasksForCity = _getAllTasksForCity(index);
              final completedTasks =
                  allTasksForCity.where((task) => task.isCompleted).toList();

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade400,
                      Colors.blue.shade600,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
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
                          child: const Icon(
                            Icons.flight_takeoff,
                            color: Colors.blue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Travel Focus: $city',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Travel Month: $month 2025',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Progress: ',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: allTasksForCity.isEmpty
                          ? 0
                          : completedTasks.length / allTasksForCity.length,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      color: Colors.white,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your 4-Week Plan:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Show completed tasks for this city
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tasks (${completedTasks.length}/${allTasksForCity.length})',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              Text(
                                '${(allTasksForCity.isEmpty ? 0 : (completedTasks.length / allTasksForCity.length * 100)).toStringAsFixed(0)}% complete',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (completedTasks.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'No tasks completed yet',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            )
                          else
                            ...completedTasks.map((task) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        size: 16, color: Colors.blue),
                                    SizedBox(width: 4),
                                    Expanded(child: Text(task.description)),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Badges
            Container(
              margin: const EdgeInsets.only(top: 16, bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
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
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          '+100 XP',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1D4ED8),
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
                          color: Colors.blue.shade500,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              '🏅 GLOBAL EXPLORER',
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
                        child: const Text('Back'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          // In a real app, this would save the plan
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save Plan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to get all tasks for a specific city
  List<TravelTask> _getAllTasksForCity(int cityIndex) {
    List<TravelTask> result = [];

    weeklyTasks.forEach((week, tasks) {
      result.addAll(tasks.where(
          (task) => task.cityIndex == cityIndex || task.cityIndex == -1));
    });

    return result;
  }

  Widget _buildNavigationButtons({
    required VoidCallback onBack,
    required VoidCallback onNext,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: onBack,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 3,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}

// Add a class to track task completion state
class TravelTask {
  final String description;
  final int weekNumber;
  final int cityIndex; // -1 for all cities, 0+ for specific city
  bool isCompleted;

  TravelTask({
    required this.description,
    required this.weekNumber,
    this.cityIndex = -1,
    this.isCompleted = false,
  });
}
