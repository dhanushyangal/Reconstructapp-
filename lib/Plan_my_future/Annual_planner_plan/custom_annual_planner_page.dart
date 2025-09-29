import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:convert';
import '../../services/annual_calendar_service.dart';
import '../../services/user_service.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/activity_tracker_mixin.dart';
import '../../utils/platform_features.dart';
import '../../pages/active_tasks_page.dart';
import '../../components/nav_logpage.dart';

class TodoItem {
  String text;
  bool completed;

  TodoItem({
    required this.text,
    this.completed = false,
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'completed': completed,
      };

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
        text: json['text'],
        completed: json['completed'] ?? false,
      );
}

class CustomAnnualPlannerPage extends StatefulWidget {
  final String template;
  final String imagePath;
  final List<String> selectedAreas;

  const CustomAnnualPlannerPage({
    super.key,
    required this.template,
    required this.imagePath,
    required this.selectedAreas,
  });

  @override
  State<CustomAnnualPlannerPage> createState() => _CustomAnnualPlannerPageState();
}

class _CustomAnnualPlannerPageState extends State<CustomAnnualPlannerPage>
    with ActivityTrackerMixin, TickerProviderStateMixin {
  final screenshotController = ScreenshotController();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, List<TodoItem>> _todoLists = {};
  bool _isSyncing = false;
  DateTime _lastSyncTime = DateTime.now().subtract(const Duration(days: 1));
  bool _hasNetworkConnectivity = true;

  String get pageName => 'Custom Monthly Planner - ${widget.template}';

  // Theme-specific colors and styles for monthly planners
  Map<String, dynamic> get _themeConfig {
    switch (widget.template) {
      case 'Floral Monthly Planner':
        return {
          'type': 'floral',
          'cardColors': [
            Color(0xFFE8F5E8), // Light green
            Color(0xFFF0E8FF), // Light purple
            Color(0xFFFFE8F0), // Light pink
            Color(0xFFE8F8FF), // Light blue
            Color(0xFFFFF8E8), // Light yellow
            Color(0xFFF8E8FF), // Light lavender
            Color(0xFFE8FFE8), // Light mint
            Color(0xFFFFF0E8), // Light peach
            Color(0xFFE8E8FF), // Light periwinkle
          ],
          'textColor': Colors.black87,
          'placeholderColor': Colors.grey[600]!,
          'storagePrefix': 'AnnualFloral',
        };
      case 'Watercolor Monthly Planner':
        return {
          'type': 'watercolor',
          'cardColors': [
            Color(0xFFB8E6B8), // Watercolor green
            Color(0xFFD4B8E6), // Watercolor purple
            Color(0xFFE6B8D4), // Watercolor pink
            Color(0xFFB8D4E6), // Watercolor blue
            Color(0xFFE6D4B8), // Watercolor yellow
            Color(0xFFD4B8E6), // Watercolor lavender
            Color(0xFFB8E6D4), // Watercolor mint
            Color(0xFFE6B8B8), // Watercolor peach
            Color(0xFFB8B8E6), // Watercolor periwinkle
          ],
          'textColor': Colors.black87,
          'placeholderColor': Colors.grey[600]!,
          'storagePrefix': 'AnnualWatercolor',
        };
      case 'Post-it Monthly Planner':
        return {
          'type': 'postit',
          'cardColors': [
            Color(0xFFFF7F6A), // Coral
            Color(0xFFFFB347), // Orange
            Color(0xFFFFB5B5), // Pink
            Color(0xFF4169E1), // Royal Blue
            Color(0xFF87CEEB), // Sky Blue
            Color(0xFFFFF0F5), // Light Pink
            Color(0xFFFFFF00), // Yellow
            Color(0xFFFF69B4), // Hot Pink
            Color(0xFF00CED1), // Turquoise
            Color(0xFFFF69B4), // Pink Purple
            Color(0xFF4169E1), // Royal Blue
            Color(0xFFFF6B6B), // Red Orange
          ],
          'textColor': Colors.black87,
          'placeholderColor': Colors.grey[600]!,
          'storagePrefix': 'AnnualPostit',
        };
      case 'Premium Monthly Planner':
        return {
          'type': 'premium',
          'cardColors': [
            Color.fromARGB(255, 0, 0, 0), // Black
            Color.fromARGB(255, 0, 0, 0), // Black
            Color.fromARGB(255, 0, 0, 0), // Black
            Color.fromARGB(255, 0, 0, 0), // Black
            Color.fromARGB(255, 0, 0, 0), // Black
            Color.fromARGB(255, 0, 0, 0), // Black
            Color.fromARGB(255, 0, 0, 0), // Black
            Color.fromARGB(255, 0, 0, 0), // Black
            Color.fromARGB(255, 0, 0, 0), // Black
            Color.fromARGB(255, 0, 0, 0), // Black
            Color.fromARGB(255, 0, 0, 0), // Black
            Color.fromARGB(255, 0, 0, 0), // Black
          ],
          'textColor': Colors.white,
          'placeholderColor': Colors.grey[300]!,
          'storagePrefix': 'AnnualPremium',
        };
      default:
        return {
          'type': 'floral',
          'cardColors': [
            Color(0xFFE8F5E8),
            Color(0xFFF0E8FF),
            Color(0xFFFFE8F0),
            Color(0xFFE8F8FF),
            Color(0xFFFFF8E8),
            Color(0xFFF8E8FF),
            Color(0xFFE8FFE8),
            Color(0xFFFFF0E8),
            Color(0xFFE8E8FF),
          ],
          'textColor': Colors.black87,
          'placeholderColor': Colors.grey[600]!,
          'storagePrefix': 'AnnualDefault',
        };
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers and todo lists for selected areas only
    for (var category in widget.selectedAreas) {
      _controllers[category] = TextEditingController();
      _todoLists[category] = [];
    }

    // Load all data from local storage first (fast)
    _loadAllFromLocalStorage().then((_) {
      // Then check database connectivity
      _checkDatabaseConnectivity().then((hasConnectivity) {
        setState(() {
          _hasNetworkConnectivity = hasConnectivity;
        });

        // If we have connectivity, sync with the database (background)
        if (hasConnectivity) {
          _syncWithDatabase();
        }
      });
    });

    // Set up periodic sync
    Timer.periodic(const Duration(minutes: 15), (timer) {
      if (mounted) {
        _checkAndSyncIfNeeded();
      } else {
        timer.cancel();
      }
    });

    // Track activity
    _trackActivity();
  }

  // Load all data from local storage (fast operation)
  Future<void> _loadAllFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final themeConfig = _themeConfig;
    final storagePrefix = themeConfig['storagePrefix'] as String;

    for (var category in widget.selectedAreas) {
      try {
        final savedTodos = prefs.getString('${storagePrefix}_todos_$category');
        if (savedTodos != null) {
          final List<dynamic> decoded = json.decode(savedTodos);
          setState(() {
            _todoLists[category] =
                decoded.map((item) => TodoItem.fromJson(item)).toList();
            _controllers[category]?.text = _formatDisplayText(category);
          });
          debugPrint(
              'Loaded ${_todoLists[category]?.length ?? 0} monthly tasks from local storage for $category');
        }
      } catch (e) {
        debugPrint('Error parsing local monthly tasks for $category: $e');
      }
    }
  }

  // Check database connectivity
  Future<bool> _checkDatabaseConnectivity() async {
    try {
      return await AnnualCalendarService.instance.testConnection();
    } catch (e) {
      debugPrint('Database connectivity check failed: $e');
      return false;
    }
  }

  // Sync with database in background (only if conditions are right)
  Future<void> _checkAndSyncIfNeeded() async {
    if (_isSyncing || DateTime.now().difference(_lastSyncTime).inMinutes < 5) {
      return;
    }

    final hasConnectivity = await _checkDatabaseConnectivity();

    if (hasConnectivity) {
      await _syncWithDatabase();
    }
  }

  // Sync all data with database at once
  Future<void> _syncWithDatabase() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final userInfo = await UserService.instance.getUserInfo();
      final themeConfig = _themeConfig;
      final storagePrefix = themeConfig['storagePrefix'] as String;

      if (userInfo['userName']?.isNotEmpty == true &&
          userInfo['email']?.isNotEmpty == true) {
        final allTasksFromDb =
            await AnnualCalendarService.instance.loadUserTasks(userInfo, theme: themeConfig['type']);

        if (allTasksFromDb.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();

          for (var dbTask in allTasksFromDb) {
            final category = dbTask['card_id'];
            debugPrint('Processing database task for category: $category');
            debugPrint('Database task data: $dbTask');
            if (_todoLists.containsKey(category)) {
              try {
                final tasksJson = dbTask['tasks'] as String?;
                debugPrint('Tasks JSON for $category: $tasksJson');
                if (tasksJson == null || tasksJson.isEmpty) {
                  debugPrint('No tasks data for $category, skipping');
                  continue;
                }
                final List<dynamic> decoded = json.decode(tasksJson);

                setState(() {
                  _todoLists[category] =
                      decoded.map((item) => TodoItem.fromJson(item)).toList();
                  _controllers[category]?.text = _formatDisplayText(category);
                });

                await prefs.setString('${storagePrefix}_todos_$category', tasksJson);
                await HomeWidget.saveWidgetData(
                    '${storagePrefix}_todos_$category', tasksJson);

                debugPrint(
                    'Updated local storage for $category with database data');
              } catch (e) {
                debugPrint('Error processing database tasks for $category: $e');
              }
            }
          }

          // Update the widget after syncing
          await HomeWidget.updateWidget(
            androidName: 'AnnualPlannerWidget',
            iOSName: 'AnnualPlannerWidget',
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Synced with cloud'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        }

        _lastSyncTime = DateTime.now();
      } else {
        debugPrint('No user info found');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please set user information to sync'),
              action: SnackBarAction(
                label: 'Set Info',
                onPressed: () => _showManualLoginDialog(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error syncing with database: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error syncing with cloud'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  // Improved to prioritize local storage
  Future<void> _saveTodoList(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json
        .encode(_todoLists[category]?.map((item) => item.toJson()).toList());
    final themeConfig = _themeConfig;
    final storagePrefix = themeConfig['storagePrefix'] as String;

    // Always save locally first (fast operation)
    await prefs.setString('${storagePrefix}_todos_$category', encoded);
    await HomeWidget.saveWidgetData('${storagePrefix}_todos_$category', encoded);

    // Update the widget
    await HomeWidget.updateWidget(
      androidName: 'AnnualPlannerWidget',
      iOSName: 'AnnualPlannerWidget',
    );

    // Only try to save to database if we have network connectivity
    if (!_hasNetworkConnectivity) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Monthly task saved locally (offline mode)'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Try to save to database in the background
    try {
      final userInfo = await UserService.instance.getUserInfo();
      final isLoggedIn = userInfo['userName']?.isNotEmpty == true;

      if (isLoggedIn) {

        AnnualCalendarService.instance
            .saveTodoItem(userInfo, category, encoded, theme: themeConfig['type'])
            .then((success) {
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Monthly task synced to cloud'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        }).catchError((e) {
          debugPrint('Background save to database failed: $e');
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please log in to save tasks to the cloud'),
            action: SnackBarAction(
              label: 'Login',
              onPressed: () {
                Navigator.of(context).pushNamed('/login');
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error in database save preparation: $e');
    }
  }

  String _formatDisplayText(String category) {
    final todos = _todoLists[category];
    if (todos == null || todos.isEmpty) return '';

    return todos.map((item) => "• ${item.text}").join("\n");
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildAnnualPlannerCard(String title, int index) {
    final themeConfig = _themeConfig;
    final cardColors = themeConfig['cardColors'] as List<Color>?;
    final textColor = themeConfig['textColor'] as Color;
    final placeholderColor = themeConfig['placeholderColor'] as Color;

    Color cardColor = Colors.white;
    if (cardColors != null && index < cardColors.length) {
      cardColor = cardColors[index];
    }

    // Check if this theme uses images or colors
    final themeType = themeConfig['type'] as String;
    final useImages = themeType == 'floral' || themeType == 'watercolor';

    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: useImages ? Colors.white.withOpacity(0.2) : cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              if (_isCustomCreatedCard(title)) ...[
                Icon(
                  Icons.star,
                  color: themeConfig['type'] == 'premium' ? Colors.white : Colors.black,
                  size: 20,
                ),
                SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: themeConfig['type'] == 'premium' ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: GestureDetector(
                onTap: () => _showTodoDialog(title),
                child: _todoLists[title]?.isEmpty ?? true
                    ? Text(
                        _isCustomCreatedCard(title) ? 'Create your\nmonthly goals' : 'Plan your\nmonthly goals',
                        style: TextStyle(
                          color: placeholderColor,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      )
                    : Text.rich(
                        TextSpan(
                          children: _todoLists[title]?.map((todo) {
                                return TextSpan(
                                  text: "• ${todo.text}\n",
                                  style: TextStyle(
                                    fontSize: 16,
                                    decoration: todo.completed == true
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    color: todo.completed == true
                                        ? Colors.grey
                                        : textColor,
                                  ),
                                );
                              }).toList() ??
                              [],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: () => _showTodoDialog(title),
      onLongPress: () async {
        await HomeWidget.saveWidgetData('edit_mode', title);
        await HomeWidget.updateWidget(
          androidName: 'AnnualPlannerWidget',
          iOSName: 'AnnualPlannerWidget',
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: useImages ? null : cardColor,
          borderRadius: BorderRadius.circular(12),
          image: useImages ? DecorationImage(
            image: AssetImage(_getCardImagePath(themeType, index)),
            fit: BoxFit.fill,
          ) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(50),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: useImages ? Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: cardContent,
        ) : cardContent,
      ),
    );
  }

  void _showTodoDialog(String category) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: TodoListDialog(
          category: category,
          todoItems: _todoLists[category] ?? [],
          onSave: (updatedItems) async {
            setState(() {
              _todoLists[category] = updatedItems;
              _controllers[category]?.text = _formatDisplayText(category);
            });
            await _saveTodoList(category);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavLogPage(
      title: widget.template,
      showBackButton: false,
      selectedIndex: 2, // Dashboard index
      actions: [
        _isSyncing
            ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.sync),
                tooltip: 'Sync with cloud',
                onPressed: _syncWithDatabase,
              ),
      ],
      onNavigationTap: (index) {
        // Navigate to different pages based on index
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
      body: Column(
        children: [
          if (!_hasNetworkConnectivity)
            Container(
              width: double.infinity,
              color: Colors.amber.shade100,
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.offline_bolt, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  const Text(
                    'Offline mode - monthly changes saved locally',
                    style: TextStyle(fontSize: 12),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final result = await _checkDatabaseConnectivity();
                      setState(() {
                        _hasNetworkConnectivity = result;
                      });
                      if (result) {
                        _syncWithDatabase();
                      }
                    },
                    child: const Text('Check', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Screenshot(
                controller: screenshotController,
                child: Container(
                  color: Colors.grey[100],
                  padding: const EdgeInsets.all(12.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getOptimalCrossAxisCount(widget.selectedAreas.length),
                      childAspectRatio: _getOptimalAspectRatio(widget.selectedAreas.length),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: widget.selectedAreas.length,
                    itemBuilder: (context, index) =>
                        _buildAnnualPlannerCard(widget.selectedAreas[index], index),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                PlatformFeatureWidget(
                  featureName: 'add_widgets',
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final url =
                          'https://youtube.com/shorts/IAeczaEygUM?feature=share';
                      final uri = Uri.parse(url);
                      if (!await launchUrl(uri,
                          mode: LaunchMode.externalApplication)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Could not open YouTube shorts: $url')),
                        );
                      }
                    },
                    icon: const Icon(Icons.widgets, color: Colors.blue),
                    label: const Text(
                      'Add Widgets',
                      style: TextStyle(fontSize: 18, color: Colors.blue),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const ActiveTasksPage()),
                    );
                  },
                  icon: const Icon(Icons.save, color: Colors.blue),
                  label: const Text(
                    'Save Monthly Planner',
                    style: TextStyle(fontSize: 18, color: Colors.blue),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (_isSyncing)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey.shade600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Syncing monthly planner with cloud...',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
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
  }

  void _trackActivity() {
    trackClick('Custom Monthly Planner - ${widget.template}');
  }

  // Helper method to detect if a card is custom created (not in predefined list)
  bool _isCustomCreatedCard(String title) {
    // List of predefined monthly goal areas
    final predefinedAreas = [
      'Custom Card', // Add custom card option
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
    return !predefinedAreas.contains(title);
  }

  // Helper method to get the correct image path based on theme and card index
  String _getCardImagePath(String themeType, int index) {
    switch (themeType) {
      case 'floral':
        return 'assets/floral_weekly/floral_${index + 1}.png';
      case 'watercolor':
        return 'assets/watercolor/watercolor_${index + 1}.png';
      case 'patterns':
        return 'assets/pattern_weekly/pattern${index + 1}.png';
      case 'japanese':
        return 'assets/japanese_weekly/japanese_${index + 1}.png';
      default:
        return 'assets/floral_weekly/floral_${index + 1}.png'; // fallback
    }
  }

  // Dynamic grid layout methods
  int _getOptimalCrossAxisCount(int areaCount) {
    if (areaCount == 1) return 1;
    if (areaCount <= 4) return 2;
    if (areaCount <= 9) return 3;
    if (areaCount <= 16) return 4;
    return 5; // For more than 16 areas
  }

  double _getOptimalAspectRatio(int areaCount) {
    if (areaCount == 1) return 1.2; // Single card - more rectangular
    if (areaCount <= 4) return 0.8; // 2x2 grid
    if (areaCount <= 9) return 0.7; // 3x3 grid
    if (areaCount <= 16) return 0.6; // 4x4 grid
    return 0.5; // For more than 16 areas
  }

  void _showManualLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => const ManualLoginDialog(),
    ).then((_) => _syncWithDatabase());
  }
}

class TodoListDialog extends StatefulWidget {
  final String category;
  final List<TodoItem> todoItems;
  final Function(List<TodoItem>) onSave;

  const TodoListDialog({
    super.key,
    required this.category,
    required this.todoItems,
    required this.onSave,
  });

  @override
  TodoListDialogState createState() => TodoListDialogState();
}

class TodoListDialogState extends State<TodoListDialog> {
  late List<TodoItem> _items;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.todoItems);
  }

  void _addItem() {
    if (_textController.text.isNotEmpty) {
      setState(() {
        _items.add(TodoItem(
          text: _textController.text,
        ));
        _textController.clear();
      });
    }
  }

  void _toggleItem(TodoItem item) {
    setState(() {
      item.completed = !item.completed;
    });
  }

  void _removeItem(TodoItem item) {
    setState(() {
      _items.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.category,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: 'Add a new monthly goal',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addItem,
              ),
            ),
            onSubmitted: (_) => _addItem(),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  leading: Checkbox(
                    value: item.completed,
                    onChanged: (value) {
                      _toggleItem(item);
                    },
                  ),
                  title: Text(
                    item.text,
                    style: TextStyle(
                      decoration:
                          item.completed ? TextDecoration.lineThrough : null,
                      color: item.completed ? Colors.grey : Colors.black,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeItem(item),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  widget.onSave(_items);
                  await HomeWidget.updateWidget(
                    androidName: 'AnnualPlannerWidget',
                    iOSName: 'AnnualPlannerWidget',
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ManualLoginDialog extends StatefulWidget {
  const ManualLoginDialog({super.key});

  @override
  State<ManualLoginDialog> createState() => _ManualLoginDialogState();
}

class _ManualLoginDialogState extends State<ManualLoginDialog> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentUserInfo();
  }

  Future<void> _loadCurrentUserInfo() async {
    final userInfo = await UserService.instance.getUserInfo();
    setState(() {
      _usernameController.text = userInfo['userName'] ?? '';
      _emailController.text = userInfo['email'] ?? '';
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set User Information'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Username'),
          ),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await UserService.instance.clearUserInfo();
            if (!mounted) return;
            Navigator.pop(context);
          },
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_usernameController.text.isNotEmpty &&
                _emailController.text.isNotEmpty) {
              await UserService.instance.setManualUserInfo(
                userName: _usernameController.text,
                email: _emailController.text,
              );
              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User information saved'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter both username and email'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
