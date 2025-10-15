import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:convert';
import '../services/annual_calendar_service.dart';
import '../services/user_service.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../pages/active_dashboard_page.dart';
import '../utils/activity_tracker_mixin.dart';
import '../utils/platform_features.dart';
import '../pages/active_tasks_page.dart';

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

class AnnualPlannerTheme {
  final String name;
  final String storageKey;
  final String displayName;
  final List<Color>? cardColors;
  final List<String>? backgroundImages;
  final Color textColor;
  final Color placeholderColor;

  AnnualPlannerTheme({
    required this.name,
    required this.storageKey,
    required this.displayName,
    this.cardColors,
    this.backgroundImages,
    this.textColor = Colors.black87,
    this.placeholderColor = const Color.fromARGB(255, 117, 117, 117),
  });

  static AnnualPlannerTheme getTheme(String themeName) {
    switch (themeName) {
      case 'Floral theme 2025 Planner':
      case 'Floral theme Monthly Planner':
      case 'Floral Monthly Planner':
        return AnnualPlannerTheme(
          name: 'Floral',
          storageKey: 'AnnualFloral',
          displayName: 'Floral Monthly Planner',
          backgroundImages: [
            'assets/floral_weekly/floral_1.png',
            'assets/floral_weekly/floral_2.png',
            'assets/floral_weekly/floral_3.png',
            'assets/floral_weekly/floral_4.png',
            'assets/floral_weekly/floral_5.png',
            'assets/floral_weekly/floral_6.png',
            'assets/floral_weekly/floral_7.png',
            'assets/floral_weekly/floral_1.png',
            'assets/floral_weekly/floral_2.png',
            'assets/floral_weekly/floral_3.png',
            'assets/floral_weekly/floral_4.png',
            'assets/floral_weekly/floral_5.png',
          ],
        );

      case 'Watercolor them 2025 Planner':
      case 'Watercolor theme Monthly Planner':
      case 'Watercolor Monthly Planner':
        return AnnualPlannerTheme(
          name: 'Watercolor',
          storageKey: 'AnnualWatercolor',
          displayName: 'Watercolor Monthly Planner',
          backgroundImages: [
            'assets/watercolor/watercolor_1.png',
            'assets/watercolor/watercolor_2.png',
            'assets/watercolor/watercolor_3.png',
            'assets/watercolor/watercolor_4.png',
            'assets/watercolor/watercolor_5.png',
            'assets/watercolor/watercolor_6.png',
            'assets/watercolor/watercolor_7.png',
            'assets/watercolor/watercolor_1.png',
            'assets/watercolor/watercolor_2.png',
            'assets/watercolor/watercolor_3.png',
            'assets/watercolor/watercolor_4.png',
            'assets/watercolor/watercolor_5.png',
          ],
        );

      case 'PostIt theme 2025 Planner':
      case 'Post-it theme Monthly Planner':
      case 'Post-it Monthly Planner':
        return AnnualPlannerTheme(
          name: 'Postit',
          storageKey: 'AnnualPostit',
          displayName: 'Post-it Monthly Planner',
          cardColors: [
            Color(0xFFFF7F6A),
            Color(0xFFFFB347),
            Color(0xFFFFB5B5),
            Color(0xFF4169E1),
            Color(0xFF87CEEB),
            Color(0xFFFFF0F5),
            Color(0xFFFFFF00),
            Color(0xFFFF69B4),
            Color(0xFF00CED1),
            Color(0xFFFF69B4),
            Color(0xFF4169E1),
            Color(0xFFFF6B6B),
          ],
        );

      case 'Premium theme 2025 Planner':
      case 'Premium theme Monthly Planner':
      case 'Premium Monthly Planner':
        return AnnualPlannerTheme(
          name: 'Premium',
          storageKey: 'AnnualPremium',
          displayName: 'Premium Monthly Planner',
          cardColors: List.filled(12, Colors.black),
          textColor: Colors.white,
          placeholderColor: Colors.grey[300]!,
        );

      default:
        return AnnualPlannerTheme(
          name: 'Floral',
          storageKey: 'AnnualFloral',
          displayName: 'Floral Monthly Planner',
          backgroundImages: [
            'assets/floral_weekly/floral_1.png',
            'assets/floral_weekly/floral_2.png',
            'assets/floral_weekly/floral_3.png',
            'assets/floral_weekly/floral_4.png',
            'assets/floral_weekly/floral_5.png',
            'assets/floral_weekly/floral_6.png',
            'assets/floral_weekly/floral_7.png',
            'assets/floral_weekly/floral_1.png',
            'assets/floral_weekly/floral_2.png',
            'assets/floral_weekly/floral_3.png',
            'assets/floral_weekly/floral_4.png',
            'assets/floral_weekly/floral_5.png',
          ],
        );
    }
  }
}

class UnifiedAnnualPlannerPage extends StatefulWidget {
  final String themeName;

  const UnifiedAnnualPlannerPage({super.key, required this.themeName});

  @override
  State<UnifiedAnnualPlannerPage> createState() =>
      _UnifiedAnnualPlannerPageState();
}

class _UnifiedAnnualPlannerPageState extends State<UnifiedAnnualPlannerPage>
    with ActivityTrackerMixin {
  final screenshotController = ScreenshotController();
  final Map<String, List<TodoItem>> _todoLists = {}; // Different list per month
  bool _isSyncing = false;
  DateTime _lastSyncTime = DateTime.now().subtract(const Duration(days: 1));
  bool _hasNetworkConnectivity = true;
  late AnnualPlannerTheme theme;

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

  String get pageName => theme.displayName;

  @override
  void initState() {
    super.initState();
    theme = AnnualPlannerTheme.getTheme(widget.themeName);
    _saveCurrentTheme(); // Save theme for widget auto-detection

    _loadAllFromLocalStorage().then((_) {
      _checkDatabaseConnectivity().then((hasConnectivity) {
        setState(() {
          _hasNetworkConnectivity = hasConnectivity;
        });
        if (hasConnectivity) {
          _syncWithDatabase();
        }
      });
    });

    Timer.periodic(const Duration(minutes: 15), (timer) {
      if (mounted) {
        _checkAndSyncIfNeeded();
      } else {
        timer.cancel();
      }
    });

    HomeWidget.setAppGroupId('group.com.reconstrect.visionboard');
    _trackActivity();
  }

  Future<void> _saveCurrentTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('flutter.annual_planner_current_theme', theme.displayName);
      await prefs.setString('annual_planner_current_theme', theme.displayName);
      await HomeWidget.saveWidgetData('annual_planner_current_theme', theme.displayName);
      debugPrint('Saved current annual planner theme: ${theme.displayName}');
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  Future<void> _loadAllFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      // Load tasks per month using universal keys (same across all themes)
      for (var month in months) {
        final savedTodos = prefs.getString('annual_planner_$month');
        if (savedTodos != null) {
          final List<dynamic> decoded = json.decode(savedTodos);
          _todoLists[month] =
              decoded.map((item) => TodoItem.fromJson(item)).toList();
        } else {
          _todoLists[month] = [];
        }
      }
      setState(() {});
      debugPrint('Loaded tasks for ${_todoLists.length} months');
    } catch (e) {
      debugPrint('Error loading monthly tasks: $e');
    }
  }

  Future<bool> _checkDatabaseConnectivity() async {
    try {
      return await AnnualCalendarService.instance.testConnection();
    } catch (e) {
      return false;
    }
  }

  Future<void> _checkAndSyncIfNeeded() async {
    if (_isSyncing || DateTime.now().difference(_lastSyncTime).inMinutes < 5) {
      return;
    }
    final hasConnectivity = await _checkDatabaseConnectivity();
    if (hasConnectivity) {
      await _syncWithDatabase();
    }
  }

  Future<void> _syncWithDatabase() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    try {
      final userInfo = await UserService.instance.getUserInfo();
      if (userInfo['userName']?.isNotEmpty == true &&
          userInfo['email']?.isNotEmpty == true) {
        final prefs = await SharedPreferences.getInstance();
        
        // Load tasks for each month using month as theme
        for (var month in months) {
          final tasksJson = await AnnualCalendarService.instance
              .loadUserTasks(userInfo, theme: month);

          if (tasksJson != null && tasksJson.isNotEmpty) {
            final List<dynamic> decoded = json.decode(tasksJson);
            _todoLists[month] =
                decoded.map((item) => TodoItem.fromJson(item)).toList();
            
            // Save to local storage AND widget storage with universal key
            await prefs.setString('annual_planner_$month', tasksJson);
            await HomeWidget.saveWidgetData('annual_planner_$month', tasksJson);
          }
        }
        
        setState(() {});
        _lastSyncTime = DateTime.now();
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _saveTodoList(String month) async {
    final prefs = await SharedPreferences.getInstance();
    final todoList = _todoLists[month] ?? [];
    final encoded = json.encode(todoList.map((item) => item.toJson()).toList());

    // Save to local storage with universal key (same across all themes)
    await prefs.setString('annual_planner_$month', encoded);
    await HomeWidget.saveWidgetData('annual_planner_$month', encoded);
    await HomeWidget.updateWidget(
      androidName: 'AnnualPlannerWidget',
      iOSName: 'AnnualPlannerWidget',
    );

    if (!_hasNetworkConnectivity) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved locally (offline)')),
        );
      }
      return;
    }

    try {
      final userInfo = await UserService.instance.getUserInfo();
      if (userInfo['userName']?.isNotEmpty == true) {
        // Save with month as theme (so all visual themes access same month data)
        AnnualCalendarService.instance
            .saveTodoItem(userInfo, encoded, theme: month)
            .then((success) {
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Synced to cloud'),
                  duration: Duration(seconds: 1)),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Save error: $e');
    }
  }

  void _showTodoDialog(String month) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: TodoListDialog(
          category: month,
          todoItems: _todoLists[month] ?? [],
          onSave: (updatedItems) async {
            setState(() => _todoLists[month] = updatedItems);
            await _saveTodoList(month);
          },
        ),
      ),
    );
  }

  Widget _buildMonthCard(String month, int index) {
    final useImages = theme.backgroundImages != null;
    Color cardColor = Colors.white;

    if (theme.cardColors != null && index < theme.cardColors!.length) {
      cardColor = theme.cardColors![index];
    }

    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: useImages ? Colors.white.withOpacity(0.4) : cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Text(
            month,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: theme.textColor,
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: (_todoLists[month] ?? []).isEmpty
                ? Text(
                    'Plan your\nmonthly goals',
                    style: TextStyle(
                      color: theme.placeholderColor,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  )
                : Text.rich(
                    TextSpan(
                      children: (_todoLists[month] ?? []).map((todo) {
                        return TextSpan(
                          text: "• ${todo.text}\n",
                          style: TextStyle(
                            fontSize: 16,
                            decoration: todo.completed
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: todo.completed ? Colors.grey : theme.textColor,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: () => _showTodoDialog(month),
      child: Container(
        decoration: BoxDecoration(
          color: useImages ? null : cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(50),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: useImages
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        theme.backgroundImages![index % theme.backgroundImages!.length],
                        fit: BoxFit.fill,
                      ),
                    ),
                    cardContent,
                  ],
                ),
              )
            : cardContent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(theme.displayName),
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
                  onPressed: _syncWithDatabase,
                ),
        ],
      ),
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
                  const Text('Offline mode', style: TextStyle(fontSize: 12)),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final result = await _checkDatabaseConnectivity();
                      setState(() => _hasNetworkConnectivity = result);
                      if (result) _syncWithDatabase();
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.7,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: months.length,
                    itemBuilder: (context, index) =>
                        _buildMonthCard(months[index], index),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (PlatformFeatures.isFeatureAvailable('add_widgets'))
                  ElevatedButton.icon(
                    onPressed: () async {
                      final url =
                          'https://youtube.com/shorts/IAeczaEygUM?feature=share';
                      if (!await launchUrl(Uri.parse(url),
                          mode: LaunchMode.externalApplication)) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not open: $url')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.widgets, color: Colors.blue),
                    label: const Text('Add Widgets',
                        style: TextStyle(fontSize: 18, color: Colors.blue)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const ActiveTasksPage()),
                    );
                  },
                  icon: const Icon(Icons.save, color: Colors.blue),
                  label: const Text('Save Monthly Planner',
                      style: TextStyle(fontSize: 18, color: Colors.blue)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Future<void> _trackActivity() async {
    try {
      final activity = RecentActivityItem(
        name: theme.displayName,
        imagePath: 'assets/images/${theme.name.toLowerCase()}.png',
        timestamp: DateTime.now(),
        routeName: '/unified-annual-planner',
      );
      await ActivityTracker().trackActivity(activity);
    } catch (e) {
      debugPrint('Activity tracking error: $e');
    }
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Add a new monthly goal',
                  ),
                  onSubmitted: (_) => _addItem(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addItem,
                child: const Text('Add'),
              ),
            ],
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
                    onChanged: (value) => _toggleItem(item),
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

