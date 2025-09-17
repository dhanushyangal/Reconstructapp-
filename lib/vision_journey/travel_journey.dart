import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import '../vision_bord/box_them_vision_board.dart';
import '../services/journey_database_service.dart';
import '../services/user_service.dart';

class TravelJourney extends StatefulWidget {
  const TravelJourney({super.key});

  @override
  State<TravelJourney> createState() => _TravelJourneyState();
}

class _TravelJourneyState extends State<TravelJourney> {
  int currentStep = 1;
  List<String> selectedLocations = [];
  List<String> selectedMonths = [];
  int currentCityIndex = 0;

  // New properties for modern UI
  final Map<String, String> notesMap = {};
  final Map<String, String> remindersMap = {};
  String? editingTaskId;
  TextEditingController editingTaskController = TextEditingController();

  // Add a data structure for weekly tasks with completion state
  final Map<int, List<TravelTask>> weeklyTasks = {1: [], 2: [], 3: [], 4: []};

  // Add a map to store completed tasks for each city
  final Map<String, List<TravelTask>> completedTasksByCity = {};

  // Add a map to store selected tasks for each city index
  final Map<int, Set<String>> selectedTasksByCity = {};

  // Add a map to store week dates
  final Map<int, DateTime> weekDates = {};

  // Add a map to store week dates for each city
  final Map<int, Map<int, DateTime>> weekDatesByCity = {};

  // Database service
  late final JourneyDatabaseService _journeyDatabaseService;

  // List of months for date formatting
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

  // List of city data for autocomplete
  final List<Map<String, String>> citiesData = [
    {"name": "New York", "country": "USA", "countryCode": "US"},
    {"name": "London", "country": "UK", "countryCode": "GB"},
    {"name": "Tokyo", "country": "Japan", "countryCode": "JP"},
    {"name": "Paris", "country": "France", "countryCode": "FR"},
    {"name": "Sydney", "country": "Australia", "countryCode": "AU"},
    {"name": "Berlin", "country": "Germany", "countryCode": "DE"},
    {"name": "Toronto", "country": "Canada", "countryCode": "CA"},
    {"name": "Dubai", "country": "UAE", "countryCode": "AE"},
    {"name": "Mumbai", "country": "India", "countryCode": "IN"},
    {"name": "Bangkok", "country": "Thailand", "countryCode": "TH"},
    {"name": "Singapore", "country": "Singapore", "countryCode": "SG"},
    {"name": "Cape Town", "country": "South Africa", "countryCode": "ZA"},
    {"name": "Rome", "country": "Italy", "countryCode": "IT"},
    {"name": "Barcelona", "country": "Spain", "countryCode": "ES"},
    {"name": "Amsterdam", "country": "Netherlands", "countryCode": "NL"},
    {"name": "Cairo", "country": "Egypt", "countryCode": "EG"},
  ];

  @override
  void initState() {
    super.initState();
    _journeyDatabaseService = JourneyDatabaseService.instance;
    _initializeDefaultTasks();
    _initializeDefaultDates();
    // Load any previously saved travel plans
    _loadSavedTravelPlans();
  }

  // Initialize default tasks for each week
  void _initializeDefaultTasks() {
    // Base tasks for all destinations
    final Map<int, List<String>> defaultTasks = {
      1: [
        "Book Flight Tickets",
        "Reserve Hotel",
        "Research Local Transport",
        "Pack winter clothes (if applicable)",
        "Check for winter festivals (if applicable)",
        "Learn basic local phrases"
      ],
      2: [
        "Create Sightseeing List",
        "Check Visa Requirements",
        "Plan Day Trips",
        "Visit City Landmark 1",
        "Visit City Landmark 2"
      ],
      3: [
        "Research Local Customs",
        "Download Offline Maps",
        "Book Restaurants",
        "Visit City Landmark 3"
      ],
      4: [
        "Finalize Itinerary",
        "Check Weather Forecast",
        "Pack Essentials",
        "Book New Year's Eve experiences (if applicable)",
        "Research holiday markets (if applicable)"
      ]
    };

    // Initialize weeks with default tasks
    for (int week = 1; week <= 4; week++) {
      weeklyTasks[week] = defaultTasks[week]!
          .map((task) => TravelTask(description: task, weekNumber: week))
          .toList();
    }
  }

  // Initialize default dates for each week
  void _initializeDefaultDates() {
    // Use the selected date for the current city if available
    if (selectedMonths.isNotEmpty && currentCityIndex < selectedMonths.length) {
      final selectedDate = selectedMonths[currentCityIndex];
      if (selectedDate.isNotEmpty) {
        try {
          final date = DateTime.parse(selectedDate);
          // Set each week to be 7 days apart
          for (int week = 1; week <= 4; week++) {
            weekDates[week] = date.add(Duration(days: (week - 1) * 7));
          }
          return;
        } catch (e) {
          debugPrint('Error parsing date: $e');
          // Fall through to default date handling
        }
      }
    }

    // Fallback: Use current date if no date is selected
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));

    for (int week = 1; week <= 4; week++) {
      weekDates[week] = monday.add(Duration(days: (week - 1) * 7));
    }
  }

  // Helper method to get tasks for a specific week and city
  List<TravelTask> getTasksForWeekAndCity(int week, int cityIndex) {
    if (cityIndex < 0 || cityIndex >= selectedLocations.length) {
      return weeklyTasks[week] ?? [];
    }

    final cityName = selectedLocations[cityIndex].split(',').first;
    final tasks = List<TravelTask>.from(weeklyTasks[week] ?? []);

    // Add city-specific landmarks
    if (week == 2 || week == 3) {
      final landmarks = _getCityLandmarks(cityName);
      if (landmarks.isNotEmpty) {
        final landmarkIndex =
            week == 2 ? 0 : 2; // Week 2 gets first landmark, Week 3 gets third
        if (landmarkIndex < landmarks.length) {
          tasks.add(TravelTask(
            description: "Visit ${landmarks[landmarkIndex]}",
            weekNumber: week,
            cityIndex: cityIndex,
          ));
        }
      }
    }

    return tasks;
  }

  // Helper method to get landmarks for a city
  List<String> _getCityLandmarks(String cityName) {
    final Map<String, List<String>> cityLandmarks = {
      "New York": ["Times Square", "Central Park", "Statue of Liberty"],
      "London": ["Big Ben", "London Eye", "Buckingham Palace"],
      "Paris": ["Eiffel Tower", "Louvre Museum", "Notre Dame"],
      "Tokyo": ["Tokyo Tower", "Shibuya Crossing", "Senso-ji Temple"],
      "Rome": ["Colosseum", "Vatican City", "Trevi Fountain"],
      "Barcelona": ["Sagrada Familia", "Park Güell", "La Rambla"],
      "Sydney": ["Sydney Opera House", "Bondi Beach", "Harbour Bridge"],
      "Dubai": ["Burj Khalifa", "Dubai Mall", "Palm Jumeirah"],
      "Amsterdam": ["Anne Frank House", "Van Gogh Museum", "Rijksmuseum"],
      "Bangkok": ["Grand Palace", "Wat Arun", "Chatuchak Market"],
      "Cairo": ["Pyramids of Giza", "Egyptian Museum", "Khan el-Khalili"],
      "Singapore": ["Marina Bay Sands", "Gardens by the Bay", "Sentosa Island"]
    };

    // Find the matching city (case-insensitive)
    for (var entry in cityLandmarks.entries) {
      if (cityName.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    return [];
  }

  // Helper method to get city-specific tasks based on city name
  List<TravelTask> getTasksForDestination(int week, String cityName) {
    // Month-specific tasks
    final Map<String, List<String>> monthTasks = {
      "January": ["Pack winter clothes", "Check for winter festivals"],
      "February": [
        "Book Valentine's day experiences",
        "Research indoor activities"
      ],
      "March": [
        "Look for spring break deals",
        "Check for shoulder season discounts"
      ],
      "April": ["Research spring festivals", "Pack for variable weather"],
      "May": ["Book outdoor activities", "Research local farmer's markets"],
      "June": ["Book beach activities", "Research summer festivals"],
      "July": ["Pack lightweight clothing", "Book cooling accommodations"],
      "August": ["Research local summer events", "Book water activities"],
      "September": ["Look for fall foliage tours", "Pack light layers"],
      "October": [
        "Research harvest festivals",
        "Check for shoulder season deals"
      ],
      "November": [
        "Research local Thanksgiving events",
        "Pack for cooler weather"
      ],
      "December": [
        "Research holiday markets",
        "Book New Year's Eve experiences"
      ]
    };

    // City-specific tasks
    final Map<String, List<String>> citySpecificTasks = {
      "New York": [
        "Visit Times Square",
        "See a Broadway show",
        "Walk in Central Park"
      ],
      "London": [
        "Visit Buckingham Palace",
        "Ride the London Eye",
        "Tour the British Museum"
      ],
      "Paris": [
        "Visit the Eiffel Tower",
        "Explore the Louvre",
        "Stroll along the Seine"
      ],
      "Tokyo": [
        "Visit Shibuya Crossing",
        "Experience a capsule hotel",
        "Try authentic sushi"
      ],
      "Rome": [
        "Visit the Colosseum",
        "Throw a coin in Trevi Fountain",
        "Tour the Vatican"
      ],
      "Barcelona": [
        "Visit Sagrada Familia",
        "Explore Park Güell",
        "Walk down La Rambla"
      ],
      "Sydney": [
        "Visit Sydney Opera House",
        "Explore Bondi Beach",
        "Take a harbor cruise"
      ],
      "Dubai": [
        "Visit Burj Khalifa",
        "Shop at Dubai Mall",
        "Experience desert safari"
      ],
      "Amsterdam": [
        "Tour the canals",
        "Visit Anne Frank House",
        "Explore the Rijksmuseum"
      ],
      "Bangkok": [
        "Visit the Grand Palace",
        "Experience floating markets",
        "Try street food"
      ],
      "Cairo": [
        "Visit the Pyramids",
        "Explore the Egyptian Museum",
        "Cruise the Nile"
      ],
      "Singapore": [
        "Visit Gardens by the Bay",
        "Experience Marina Bay Sands",
        "Explore Sentosa Island"
      ]
    };

    // Get month name from selectedMonths
    String? monthName;
    if (currentCityIndex < selectedMonths.length &&
        selectedMonths[currentCityIndex].isNotEmpty) {
      monthName = selectedMonths[currentCityIndex].split(' ').first;
    }

    // Base tasks for this week
    List<String> tasks =
        weeklyTasks[week]?.map((task) => task.description).toList() ?? [];

    // Add city-specific tasks
    for (var city in citySpecificTasks.keys) {
      if (cityName.contains(city)) {
        tasks.addAll(citySpecificTasks[city]!);
        break;
      }
    }

    // Add month-specific tasks
    if (monthName != null && monthTasks.containsKey(monthName)) {
      tasks.addAll(monthTasks[monthName]!);
    }

    return tasks
        .map((task) => TravelTask(
            description: task, weekNumber: week, cityIndex: currentCityIndex))
        .toList();
  }

  // Helper method to get all tasks for a specific city

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF), // Blue-50 equivalent
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
                            ? Colors.blue.shade500
                            : Colors.blue.shade200,
                        shape: BoxShape.circle,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
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
                                isActive ? Colors.white : Colors.blue.shade700,
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
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                if (index < 4)
                  Container(
                    width: 40,
                    height: 2,
                    color: stepNumber < currentStep
                        ? Colors.blue.shade500
                        : Colors.blue.shade200,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
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
            '🌎 Welcome to Your Travel Journey!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2563EB), // blue-600
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Design your personalized travel plan for 2025. You\'ll select your dream destinations, plan the best times to visit, and create a complete travel roadmap.',
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
              backgroundColor: const Color(0xFF3B82F6), // blue-500
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
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Step 2: Select 3 Dream Travel Destinations',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Enter 3 cities you want to visit this year:',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Destination inputs with autocomplete
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
              // Check if we have exactly 3 cities and none are empty
              if (selectedLocations.length == 3 &&
                  selectedLocations.every((city) => city.trim().isNotEmpty)) {
                setState(() {
                  currentStep = 3;
                });
              } else {
                _showErrorDialog('Please enter all three cities.');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationInput(int destinationNum) {
    // Track if we should show suggestions
    final ValueNotifier<bool> showSuggestions = ValueNotifier<bool>(false);
    // Track current search query
    final TextEditingController controller = TextEditingController();

    // Initialize controller with existing selection if any
    if (selectedLocations.length >= destinationNum) {
      controller.text = selectedLocations[destinationNum - 1];
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Destination $destinationNum:',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          StatefulBuilder(builder: (context, setState) {
            return Column(
              children: [
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Enter city name...',
                    prefixIcon: const Icon(Icons.search, color: Colors.blue),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Colors.blue.shade500, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (value) {
                    // Show suggestions if there's any input
                    setState(() {
                      showSuggestions.value = value.isNotEmpty;
                    });

                    // Update selected locations
                    if (selectedLocations.length < destinationNum) {
                      while (selectedLocations.length < destinationNum - 1) {
                        selectedLocations.add('');
                      }
                      selectedLocations.add(value);
                    } else {
                      selectedLocations[destinationNum - 1] = value;
                    }
                  },
                  onTap: () {
                    setState(() {
                      showSuggestions.value = controller.text.isNotEmpty;
                    });
                  },
                ),
                if (showSuggestions.value && controller.text.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(
                      maxHeight: 250,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _getFilteredCities(controller.text).length,
                        itemBuilder: (context, index) {
                          final city =
                              _getFilteredCities(controller.text)[index];
                          return ListTile(
                            dense: true,
                            leading: Container(
                              width: 30,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: city["countryCode"] != null
                                  ? Center(
                                      child: Text(
                                        city["countryCode"]!,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            title: Text(
                              city["name"]!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              city["country"]!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            onTap: () {
                              final cityName = city["name"]!;
                              final countryName = city["country"]!;
                              final fullName = '$cityName, $countryName';

                              setState(() {
                                controller.text = fullName;

                                // Update selected locations
                                if (selectedLocations.length < destinationNum) {
                                  while (selectedLocations.length <
                                      destinationNum - 1) {
                                    selectedLocations.add('');
                                  }
                                  selectedLocations.add(fullName);
                                } else {
                                  selectedLocations[destinationNum - 1] =
                                      fullName;
                                }

                                showSuggestions.value = false;
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // Helper method to filter cities based on search query
  List<Map<String, String>> _getFilteredCities(String query) {
    if (query.isEmpty) return [];

    final lowerQuery = query.toLowerCase();
    return citiesData
        .where((city) =>
            city["name"]!.toLowerCase().contains(lowerQuery) ||
            city["country"]!.toLowerCase().contains(lowerQuery))
        .take(10)
        .toList();
  }

  Widget _buildDateSelection(int cityIndex) {
    final city =
        selectedLocations.isNotEmpty && cityIndex < selectedLocations.length
            ? selectedLocations[cityIndex].split(',').first
            : 'City ${cityIndex + 1}';

    // Get previously selected dates to enforce 2-month gap rule
    final Set<String> disabledMonths =
        {}; // Track disabled months in format YYYY-MM

    for (int i = 0; i < selectedMonths.length; i++) {
      if (i != cityIndex &&
          selectedMonths.length > i &&
          selectedMonths[i].isNotEmpty) {
        try {
          final date = DateTime.parse(selectedMonths[i]);

          // Only disable the exact month (not 1 month before and after)
          // This allows more flexible scheduling while still avoiding same-month trips
          disabledMonths
              .add('${date.year}-${date.month.toString().padLeft(2, '0')}');

          // Only apply the strict 2-month gap rule if this is a consecutive city
          // This ensures we can still select dates for all cities
          if (i == cityIndex - 1 || i == cityIndex + 1) {
            // Add month before for consecutive cities only
            final monthBefore = DateTime(
                date.month == 1 ? date.year - 1 : date.year,
                date.month == 1 ? 12 : date.month - 1);
            disabledMonths.add(
                '${monthBefore.year}-${monthBefore.month.toString().padLeft(2, '0')}');

            // Add month after for consecutive cities only
            final monthAfter = DateTime(
                date.month == 12 ? date.year + 1 : date.year,
                date.month == 12 ? 1 : date.month + 1);
            disabledMonths.add(
                '${monthAfter.year}-${monthAfter.month.toString().padLeft(2, '0')}');
          }
        } catch (e) {
          debugPrint('Error parsing date: $e');
        }
      }
    }

    // Get the selected date for display
    String displayDate = '';
    if (selectedMonths.isNotEmpty &&
        cityIndex < selectedMonths.length &&
        selectedMonths[cityIndex].isNotEmpty) {
      try {
        final date = DateTime.parse(selectedMonths[cityIndex]);
        displayDate =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      } catch (e) {
        debugPrint('Error parsing date for display: $e');
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // City name
          Text(
            '$city:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          // Date selection - Make the entire field tappable, not just the icon
          InkWell(
            onTap: () async {
              final DateTime now = DateTime.now();
              DateTime initialDate = now;

              if (displayDate.isNotEmpty) {
                try {
                  initialDate = DateTime.parse(displayDate);
                } catch (e) {
                  debugPrint('Error parsing date: $e');
                }
              }

              // Find valid initial date if the current one is disabled
              final String initialMonthKey =
                  '${initialDate.year}-${initialDate.month.toString().padLeft(2, '0')}';
              if (disabledMonths.contains(initialMonthKey)) {
                // Try to find a valid month
                for (int monthOffset = 1; monthOffset <= 12; monthOffset++) {
                  final testDate = DateTime(
                      initialDate.year, initialDate.month + monthOffset, 1);
                  final testMonthKey =
                      '${testDate.year}-${testDate.month.toString().padLeft(2, '0')}';
                  if (!disabledMonths.contains(testMonthKey)) {
                    initialDate = testDate;
                    break;
                  }
                }
              }

              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: initialDate,
                firstDate: now,
                lastDate: DateTime(2026),
                selectableDayPredicate: (DateTime date) {
                  // Check if the date's month is in the disabled months list
                  final monthKey =
                      '${date.year}-${date.month.toString().padLeft(2, '0')}';
                  return !disabledMonths.contains(monthKey);
                },
              );

              if (picked != null) {
                setState(() {
                  if (selectedMonths.length <= cityIndex) {
                    while (selectedMonths.length < cityIndex) {
                      selectedMonths.add('');
                    }
                    selectedMonths.add(picked.toIso8601String());
                  } else {
                    selectedMonths[cityIndex] = picked.toIso8601String();
                  }
                });
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: InputDecorator(
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: Icon(Icons.calendar_today, color: Colors.blue),
              ),
              child: Text(
                displayDate.isNotEmpty ? displayDate : 'Select date',
                style: TextStyle(
                  color: displayDate.isNotEmpty
                      ? Colors.black
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ),
        ],
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
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Step 3: Pick Travel Dates for Each City',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the best dates to visit each destination:',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Date selection for each city
          ...List.generate(selectedLocations.length, (index) {
            return _buildDateSelection(index);
          }),

          // Info about 2-month gap rule
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'To avoid travel fatigue, a 2-month gap is required between trips. Some dates may be disabled accordingly.',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
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
              if (selectedMonths.length == selectedLocations.length &&
                  selectedMonths.every((date) => date.isNotEmpty)) {
                setState(() {
                  currentStep = 4;
                  // Reset city index when entering step 4
                  currentCityIndex = 0;
                });
              } else {
                _showErrorDialog(
                    'Please select dates for each destination before continuing.');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep4() {
    // Get the current city name
    final cityName = selectedLocations.isNotEmpty &&
            currentCityIndex < selectedLocations.length
        ? selectedLocations[currentCityIndex].split(',').first
        : 'City ${currentCityIndex + 1}';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
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
              color: Colors.blue.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Plan your preparation activities for $cityName:',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // City navigation controls
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // City info - centered
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade500,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    '$cityName (${currentCityIndex + 1}/${selectedLocations.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Navigation buttons - in a row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: currentCityIndex > 0
                            ? () {
                                setState(() {
                                  // Save current dates before switching
                                  if (!weekDatesByCity
                                      .containsKey(currentCityIndex)) {
                                    weekDatesByCity[currentCityIndex] = {};
                                  }
                                  for (var entry in weekDates.entries) {
                                    weekDatesByCity[currentCityIndex]![
                                        entry.key] = entry.value;
                                  }

                                  // Save current selections before switching
                                  _saveCurrentSelections();

                                  // Switch to previous city
                                  currentCityIndex--;

                                  // Restore selections for the new current city
                                  _restoreSelectionsForCurrentCity();
                                });
                              }
                            : null,
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Previous'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue.shade700,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          textStyle:
                              const TextStyle(fontWeight: FontWeight.w500),
                          disabledBackgroundColor:
                              Colors.white.withOpacity(0.5),
                          disabledForegroundColor: Colors.blue.shade200,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            currentCityIndex < selectedLocations.length - 1
                                ? () {
                                    setState(() {
                                      // Save current dates before switching
                                      if (!weekDatesByCity
                                          .containsKey(currentCityIndex)) {
                                        weekDatesByCity[currentCityIndex] = {};
                                      }
                                      for (var entry in weekDates.entries) {
                                        weekDatesByCity[currentCityIndex]![
                                            entry.key] = entry.value;
                                      }

                                      // Save current selections before switching
                                      _saveCurrentSelections();

                                      // Switch to next city
                                      currentCityIndex++;

                                      // Restore selections for the new current city
                                      _restoreSelectionsForCurrentCity();
                                    });
                                  }
                                : null,
                        label: const Text('Next'),
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue.shade700,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          textStyle:
                              const TextStyle(fontWeight: FontWeight.w500),
                          disabledBackgroundColor:
                              Colors.white.withOpacity(0.5),
                          disabledForegroundColor: Colors.blue.shade200,
                        ),
                      ),
                    ),
                  ],
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
    // Refresh week dates based on current city's selected month
    _initializeDefaultDates();

    // After initializing dates, restore any saved dates for this city
    if (weekDatesByCity.containsKey(currentCityIndex)) {
      final savedDates = weekDatesByCity[currentCityIndex]!;
      for (var entry in savedDates.entries) {
        weekDates[entry.key] = entry.value;
      }
    }

    return Column(
      children: List.generate(4, (weekIndex) {
        final weekNumber = weekIndex + 1;
        final tasksForWeek =
            getTasksForWeekAndCity(weekNumber, currentCityIndex);
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Week $weekNumber',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade600,
                              ),
                            ),
                            Text(
                              '${weekDate.day}/${weekDate.month}/${weekDate.year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Date picker button
                    TextButton.icon(
                      onPressed: () async {
                        // Get the selected month for this city
                        DateTime initialDate = weekDate;
                        DateTime firstDate = DateTime.now();
                        DateTime lastDate = DateTime(2026);

                        // If a month is selected for this city, use it to limit date selection
                        if (selectedMonths.isNotEmpty &&
                            currentCityIndex < selectedMonths.length) {
                          final selectedDate = selectedMonths[currentCityIndex];
                          if (selectedDate.isNotEmpty) {
                            try {
                              final date = DateTime.parse(selectedDate);
                              // Set the initial date to the selected date
                              initialDate = date;

                              // Set first and last date to constrain to the selected month
                              firstDate = DateTime(date.year, date.month, 1);

                              // Only allow selecting dates within the selected month
                              lastDate = DateTime(date.year, date.month + 1,
                                  0); // Last day of month
                            } catch (e) {
                              // Fallback to default values if parsing fails
                              debugPrint('Error parsing date: $e');
                            }
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
                            // Update the date in weekDates
                            weekDates[weekNumber] = picked;

                            // Make sure the weekDatesByCity map has an entry for this city
                            if (!weekDatesByCity
                                .containsKey(currentCityIndex)) {
                              weekDatesByCity[currentCityIndex] = {};
                            }

                            // Save this date in the city-specific map
                            weekDatesByCity[currentCityIndex]![weekNumber] =
                                picked;
                          });
                        }
                      },
                      icon: Icon(Icons.calendar_today,
                          color: Colors.blue.shade600, size: 18),
                      label: Text(
                        'Change Date',
                        style: TextStyle(color: Colors.blue.shade600),
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
                    foregroundColor: Colors.blue.shade600,
                    elevation: 0,
                    side: BorderSide(color: Colors.blue.shade300),
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

  // Update task item to handle radio button state
  Widget _buildTaskItem(TravelTask task) {
    final String cityName = selectedLocations.isNotEmpty &&
            currentCityIndex < selectedLocations.length
        ? selectedLocations[currentCityIndex].split(',').first
        : 'Unknown City';
    final String taskId = "${task.weekNumber}-$cityName-${task.description}";
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
        child: Column(
          children: [
            Row(
              children: [
                // Radio button instead of checkbox
                Radio<bool>(
                  value: true,
                  groupValue: task.isSelected ? true : null,
                  onChanged: (value) {
                    setState(() {
                      task.isSelected = !task.isSelected;

                      // Add or remove from completedTasksByCity based on selection
                      if (!completedTasksByCity.containsKey(cityName)) {
                        completedTasksByCity[cityName] = [];
                      }

                      if (task.isSelected) {
                        if (!completedTasksByCity[cityName]!.contains(task)) {
                          completedTasksByCity[cityName]!.add(task);
                        }
                      } else {
                        completedTasksByCity[cityName]!.remove(task);
                      }
                    });
                  },
                  activeColor: Colors.blue.shade500,
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
                              ? Colors.blue.shade700
                              : Colors.grey.shade800,
                          fontWeight: task.isSelected
                              ? FontWeight.w500
                              : FontWeight.normal,
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
                                        color: Colors.blue.shade400,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          notesMap[taskId]!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade400,
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
                                      color: Colors.blue.shade400,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        remindersMap[taskId]!,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade400,
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

                // Action buttons - convert to small icon buttons to save space
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 20),
                  onPressed: () {
                    _showTaskActions(task, task.weekNumber, cityName);
                  },
                  color: Colors.grey.shade600,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints.tightFor(width: 28, height: 28),
                  tooltip: 'Task options',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Add a new method to show task actions as a modal bottom sheet
  void _showTaskActions(TravelTask task, int weekNumber, String cityName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  task.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Task'),
                onTap: () {
                  Navigator.pop(context);
                  _editTask(task, weekNumber, cityName);
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Add Note'),
                onTap: () {
                  Navigator.pop(context);
                  _addNote(task, weekNumber, cityName);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red.shade400),
                title: Text(
                  'Delete Task',
                  style: TextStyle(color: Colors.red.shade400),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteTask(task, weekNumber);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // Helper methods for task management
  void _editTask(TravelTask task, int weekNumber, String cityName) {
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
                  final oldTaskId = '$weekNumber-$cityName-${task.description}';
                  final newTaskId = '$weekNumber-$cityName-${controller.text}';

                  setState(() {
                    // Create a new task with the updated description
                    final updatedTask = TravelTask(
                      description: controller.text,
                      weekNumber: task.weekNumber,
                      cityIndex: task.cityIndex,
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
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _addNote(TravelTask task, int weekNumber, String cityName) {
    final taskId = '$weekNumber-$cityName-${task.description}';
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
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Note'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTask(TravelTask task, int weekNumber) {
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
                      '$weekNumber-${selectedLocations[currentCityIndex].split(',').first}-${task.description}';
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
                    weeklyTasks[weekNumber]!.add(TravelTask(
                      description: controller.text,
                      weekNumber: weekNumber,
                      cityIndex: currentCityIndex,
                      isSelected: false,
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Step 5: Travel Plan Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Travel summaries for each location
          ...List.generate(selectedLocations.length, (index) {
            final city = selectedLocations[index].split(',').first;
            final month =
                selectedMonths.isNotEmpty && index < selectedMonths.length
                    ? selectedMonths[index].split(' ').first
                    : 'Month';

            // Get selected tasks for this city
            final selectedTasks = completedTasksByCity[city] ?? [];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
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
                          Colors.blue.shade500,
                          Colors.blue.shade700,
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
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.radio_button_checked,
                                    size: 16,
                                    color: Colors.blue.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    task.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
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
          }),

          // Badges and actions
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                // Badges row - wrap in SingleChildScrollView to handle overflow
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
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
                ),
                const SizedBox(height: 12),
                // Buttons row
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
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
                        // Save the plan with SharedPreferences
                        _saveTravelPlan();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade500,
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
            ),
          ),
        ],
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
                backgroundColor: Colors.blue.shade500,
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

  // Helper dialog to show errors
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Notice'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Helper method to save selections for current city
  void _saveCurrentSelections() {
    if (currentCityIndex < selectedLocations.length) {
      // Get all selected tasks for this city
      final selectedTaskIds = <String>{};

      for (var week in weeklyTasks.keys) {
        for (var task in weeklyTasks[week]!) {
          if (task.isSelected) {
            selectedTaskIds.add('${task.weekNumber}-${task.description}');

            // Also save to completedTasksByCity for summary view
            final cityName =
                selectedLocations[currentCityIndex].split(',').first;
            if (!completedTasksByCity.containsKey(cityName)) {
              completedTasksByCity[cityName] = [];
            }
            if (!completedTasksByCity[cityName]!.contains(task)) {
              completedTasksByCity[cityName]!.add(task);
            }
          }
        }
      }

      // Save selected task IDs for this city
      selectedTasksByCity[currentCityIndex] = selectedTaskIds;

      // Also save the week dates for this city
      // We'll store these in a new map to keep track of dates per city
      if (!weekDatesByCity.containsKey(currentCityIndex)) {
        weekDatesByCity[currentCityIndex] = {};
      }

      // Copy the current week dates to the city-specific map
      for (var entry in weekDates.entries) {
        weekDatesByCity[currentCityIndex]![entry.key] = entry.value;
      }
    }
  }

  // Helper method to restore selections for current city
  void _restoreSelectionsForCurrentCity() {
    // First reset all selections
    for (var week in weeklyTasks.keys) {
      for (var task in weeklyTasks[week]!) {
        task.isSelected = false;
      }
    }

    // Then restore saved selections for current city
    if (selectedTasksByCity.containsKey(currentCityIndex)) {
      final selectedTaskIds = selectedTasksByCity[currentCityIndex]!;

      for (var week in weeklyTasks.keys) {
        for (var task in weeklyTasks[week]!) {
          final taskId = '${task.weekNumber}-${task.description}';
          if (selectedTaskIds.contains(taskId)) {
            task.isSelected = true;
          }
        }
      }
    }

    // Restore saved week dates for current city
    // First initialize with default dates based on selected month
    _initializeDefaultDates();

    // Then override with any saved dates for this city
    if (weekDatesByCity.containsKey(currentCityIndex)) {
      final savedWeekDates = weekDatesByCity[currentCityIndex]!;
      for (var entry in savedWeekDates.entries) {
        weekDates[entry.key] = entry.value;
      }
    }
  }

  // Method to save travel plan to database
  Future<void> _saveTravelPlan() async {
    try {
      debugPrint('Saving travel plan to database...');

      // Check if user is logged in
      final isLoggedIn = await UserService.instance.isUserLoggedIn();
      if (!isLoggedIn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to save your travel plan'),
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

      // Convert completedTasksByCity to the format expected by the database service
      for (var entry in completedTasksByCity.entries) {
        final cityName = entry.key;
        final tasks = entry.value;
        tasksForDatabase[cityName] = tasks.cast<dynamic>();
      }

      // Save to database using the journey database service
      final result = await _journeyDatabaseService.saveTravelJourney(
        selectedLocations: selectedLocations,
        selectedMonths: selectedMonths,
        completedTasksByCity: tasksForDatabase,
        weekDatesByCity: weekDatesByCity,
      );

      if (result['success'] == true) {
        // Also save to local storage for widget support
        await _saveToLocalStorage();

        // Update home widgets
        await _updateWidgets();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Travel plan saved successfully to database!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to Vision Board page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  VisionBoardDetailsPage(title: 'Box Theme Vision Board'),
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? 'Unknown database error');
      }
    } catch (e) {
      debugPrint('ERROR SAVING TRAVEL PLAN: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving travel plan: $e'),
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

      // Create vision board tasks for widgets
      List<Map<String, dynamic>> allVisionBoardTasks = [];

      for (int i = 0; i < selectedLocations.length; i++) {
        final cityName = selectedLocations[i].split(',').first;
        final monthName = selectedMonths.isNotEmpty && i < selectedMonths.length
            ? _getMonthName(selectedMonths[i])
            : 'Month ${i + 1}';

        allVisionBoardTasks.add({
          "id": "${DateTime.now().millisecondsSinceEpoch + i}",
          "text": "Travel to $cityName in $monthName",
          "isDone": false
        });
      }

      // Save to local storage for widgets
      await prefs.setString(
          'BoxThem_todos_Travel', jsonEncode(allVisionBoardTasks));

      debugPrint('Travel data saved to local storage for widgets');
    } catch (e) {
      debugPrint('Error saving travel data to local storage: $e');
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
        androidName: 'AnnualPlannerWidget',
        iOSName: 'AnnualPlannerWidget',
      );

      debugPrint('Widgets updated successfully');
    } catch (e) {
      debugPrint('Error updating widgets: $e');
    }
  }

  // Helper method to extract month name from date string
  String _getMonthName(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return months[date.month - 1];
    } catch (e) {
      debugPrint('Error parsing date: $e');
      return 'Unknown Month';
    }
  }

  // Method to load saved travel plans from SharedPreferences
  Future<void> _loadSavedTravelPlans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedEvents = prefs.getString('animal.calendar_events');

      if (savedEvents != null && savedEvents.isNotEmpty) {
        debugPrint(
            'Found saved travel plans in animal calendar data, parsing...');

        // For this app, we just load them but don't display them
        // In a real app, you'd parse and display them in the UI

        // Show a message that plans were loaded
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Previous plans loaded from animal calendar'),
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading saved travel plans: $e');
    }
  }
}

// Add a class to track task completion state
class TravelTask {
  final String description;
  final int weekNumber;
  final int cityIndex; // -1 for all cities, 0+ for specific city
  bool isSelected; // Changed from isCompleted to isSelected

  TravelTask({
    required this.description,
    required this.weekNumber,
    this.cityIndex = -1,
    this.isSelected = false,
  });
}
