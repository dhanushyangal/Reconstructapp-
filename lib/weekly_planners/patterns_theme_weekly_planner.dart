import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../pages/active_dashboard_page.dart'; // Import for activity tracking

import '../services/weekly_planner_service.dart';
import '../services/user_service.dart';

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

  // Helper method to convert to widget-compatible format
  Map<String, dynamic> toWidgetJson() => {
        'id': text.hashCode.toString(), // Generate pseudo-id from text
        'text': text,
        'isDone': completed,
      };
}

class PatternsThemeWeeklyPlanner extends StatefulWidget {
  final int dayIndex;
  final String? eventId;
  final bool showEvents;

  const PatternsThemeWeeklyPlanner({
    super.key,
    required this.dayIndex,
    this.eventId,
    this.showEvents = false,
  });

  // Add route name to make navigation easier
  static const routeName = '/patterns-theme-weekly-planner';

  @override
  State<PatternsThemeWeeklyPlanner> createState() =>
      _PatternsThemeWeeklyPlannerState();
}

class _PatternsThemeWeeklyPlannerState
    extends State<PatternsThemeWeeklyPlanner> {
  final screenshotController = ScreenshotController();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, List<TodoItem>> _todoLists = {};
  bool _isSyncing = false;
  DateTime _lastSyncTime = DateTime.now().subtract(const Duration(days: 1));
  bool _hasNetworkConnectivity = true;
  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    for (var day in days) {
      _controllers[day] = TextEditingController();
      _todoLists[day] = [];
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

    // Initialize HomeWidget
    HomeWidget.setAppGroupId('group.com.reconstrect.visionboard');
    HomeWidget.registerBackgroundCallback(backgroundCallback);

    // Track activity
    _trackActivity();
  }

  static Future<void> backgroundCallback(Uri? uri) async {
    // Handle background updates if needed
  }

  // Load all data from local storage (fast operation)
  Future<void> _loadAllFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();

    for (var day in days) {
      try {
        final savedTodos = prefs.getString('PatternsTheme_todos_$day');
        if (savedTodos != null) {
          final List<dynamic> decoded = json.decode(savedTodos);
          setState(() {
            _todoLists[day] =
                decoded.map((item) => TodoItem.fromJson(item)).toList();
            _controllers[day]?.text = _formatDisplayText(day);
          });
          debugPrint(
              'Loaded ${_todoLists[day]?.length ?? 0} tasks from local storage for $day');
        }

        // Also check widget data to ensure it's in sync
        try {
          final widgetTodos =
              await HomeWidget.getWidgetData('PatternsTheme_todos_$day');
          if (widgetTodos != null) {
            debugPrint('Found widget data for $day: $widgetTodos');

            // If we have widget data but no local data, try to use widget data
            if (savedTodos == null) {
              try {
                final List<dynamic> widgetDecoded = json.decode(widgetTodos);
                // Convert widget format (with id, isDone) to our format (with completed)
                final List<TodoItem> convertedItems = widgetDecoded
                    .map((item) => TodoItem(
                          text: item['text'],
                          completed: item['isDone'] ?? false,
                        ))
                    .toList();

                setState(() {
                  _todoLists[day] = convertedItems;
                  _controllers[day]?.text = _formatDisplayText(day);
                });

                debugPrint(
                    'Loaded ${convertedItems.length} tasks from widget data for $day');
              } catch (decodeError) {
                debugPrint('Error decoding widget data: $decodeError');
              }
            }
          } else {
            debugPrint('No widget data found for $day');
          }
        } catch (widgetError) {
          debugPrint('Error accessing widget data: $widgetError');
        }

        // Ensure widget text is updated
        if (_todoLists[day]?.isNotEmpty == true) {
          await HomeWidget.saveWidgetData(
              'patterns_todo_text_$day', _formatDisplayText(day));
        }
      } catch (e) {
        debugPrint('Error parsing local tasks for $day: $e');
      }
    }

    // Update the widget right after loading data
    await HomeWidget.updateWidget(
      androidName: 'WeeklyPlannerWidget',
      iOSName: 'WeeklyPlannerWidget',
    );
  }

  // Check database connectivity
  Future<bool> _checkDatabaseConnectivity() async {
    try {
      return await WeeklyPlannerService.instance.testConnection();
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

      if (userInfo['userName']?.isNotEmpty == true &&
          userInfo['email']?.isNotEmpty == true) {
        // Explicitly request patterns theme tasks only
        final allTasksFromDb = await WeeklyPlannerService.instance
            .loadUserTasks(userInfo, theme: 'patterns');

        if (allTasksFromDb.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();

          // Process only tasks that belong to the patterns theme
          for (var dbTask in allTasksFromDb) {
            if (dbTask['theme'] != 'patterns')
              continue; // Skip tasks from other themes

            final cardId = dbTask['card_id'] as String;
            String day;

            // Handle both formats - with prefix and without prefix
            if (cardId.startsWith('patterns_')) {
              // New format with theme prefix
              day = cardId.substring('patterns_'.length);
            } else if (days.contains(cardId)) {
              // Old format without prefix
              day = cardId;
            } else {
              continue; // Skip tasks with invalid day
            }

            if (_todoLists.containsKey(day)) {
              try {
                final tasksJson = dbTask['tasks'] as String;
                final List<dynamic> decoded = json.decode(tasksJson);

                setState(() {
                  _todoLists[day] =
                      decoded.map((item) => TodoItem.fromJson(item)).toList();
                  _controllers[day]?.text = _formatDisplayText(day);
                });

                await prefs.setString('PatternsTheme_todos_$day', tasksJson);

                // Convert to widget format for HomeWidget
                final widgetEncoded = json.encode(_todoLists[day]!
                    .map((item) => item.toWidgetJson())
                    .toList());
                await HomeWidget.saveWidgetData(
                    'PatternsTheme_todos_$day', widgetEncoded);
                await HomeWidget.saveWidgetData(
                    'patterns_todo_text_$day', _formatDisplayText(day));

                debugPrint(
                    'Updated widget data for $day with ${_todoLists[day]?.length ?? 0} tasks');
              } catch (e) {
                debugPrint('Error processing database tasks for $day: $e');
              }
            }
          }

          // Update the widget after syncing
          await HomeWidget.updateWidget(
            androidName: 'WeeklyPlannerWidget',
            iOSName: 'WeeklyPlannerWidget',
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

  String _formatDisplayText(String day) {
    final todos = _todoLists[day];
    if (todos == null || todos.isEmpty) return '';

    // Format each todo item with a bullet point and handle completion status
    return todos.map((item) {
      final checkmark = item.completed ? '✓ ' : '• ';
      return "$checkmark${item.text}";
    }).join('\n');
  }

  Future<void> _saveTodoList(String day) async {
    try {
      // Use day directly as the card_id without theme prefix
      final cardId = day;

      // Save to local storage first as backup
      final prefs = await SharedPreferences.getInstance();
      final todos = _todoLists[day];

      if (todos == null) return;

      final encoded = json.encode(todos.map((item) => item.toJson()).toList());
      await prefs.setString('PatternsTheme_todos_$day', encoded);

      // Convert to widget format for HomeWidget
      final widgetEncoded =
          json.encode(todos.map((item) => item.toWidgetJson()).toList());

      // Save to HomeWidget
      await HomeWidget.saveWidgetData(
          'PatternsTheme_todos_$day', widgetEncoded);
      await HomeWidget.saveWidgetData(
          'patterns_todo_text_$day', _formatDisplayText(day));

      debugPrint('Saved ${todos.length} tasks for $day to widget data');

      // Update the widget
      await HomeWidget.updateWidget(
        androidName: 'WeeklyPlannerWidget',
        iOSName: 'WeeklyPlannerWidget',
      );

      // Try to save to database
      try {
        final userInfo = await UserService.instance.getUserInfo();
        if (userInfo['userName']?.isNotEmpty == true &&
            userInfo['email']?.isNotEmpty == true) {
          final success = await WeeklyPlannerService.instance
              .saveTodoItem(userInfo, cardId, encoded, theme: 'patterns');

          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Task saved to cloud'),
                duration: Duration(seconds: 1),
              ),
            );
          }
        } else {
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
        debugPrint('Error saving to database: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task saved locally only'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving todo list: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error saving tasks'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takeScreenshotAndShare() async {
    try {
      final image = await screenshotController.capture();
      if (image == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/patterns_weekly_planner.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);

      await Share.shareXFiles([XFile(imagePath)],
          text: 'My Patterns Theme Weekly Planner');
    } catch (e) {
      debugPrint('Error sharing planner: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patterns Theme Weekly Planner'),
        actions: [
          // Add a sync button
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
      ),
      body: Column(
        children: [
          // Connection status indicator
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
                    'Offline mode - changes saved locally',
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
            child: Screenshot(
              controller: screenshotController,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(12.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.7,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: days.length,
                  itemBuilder: (context, index) => _buildDayCard(days[index]),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton.icon(
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
                  icon: const Icon(Icons.widgets),
                  label: const Text('Add Widgets'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _takeScreenshotAndShare,
                  icon: const Icon(Icons.share),
                  label: const Text('Share Weekly Planner'),
                  style: ElevatedButton.styleFrom(
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

  Widget _buildDayCard(String day) {
    int dayIndex = days.indexOf(day);
    return GestureDetector(
      onTap: () => _showTodoDialog(day),
      child: Container(
        decoration: BoxDecoration(
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/pattern_weekly/pattern${dayIndex + 1}.png',
                  fit: BoxFit.cover,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    width: double.infinity,
                    color: Colors.white.withOpacity(0.4),
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      width: double.infinity,
                      color: Colors.white.withOpacity(0.2),
                      child: _todoLists[day]?.isEmpty ?? true
                          ? const Text(
                              'Add events',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            )
                          : SingleChildScrollView(
                              child: Text.rich(
                                TextSpan(
                                  children: _todoLists[day]?.map((todo) {
                                        return TextSpan(
                                          text: "• ${todo.text}\n",
                                          style: TextStyle(
                                            fontSize: 14,
                                            decoration: todo.completed
                                                ? TextDecoration.lineThrough
                                                : TextDecoration.none,
                                            color: todo.completed
                                                ? Colors.grey
                                                : Colors.black,
                                          ),
                                        );
                                      }).toList() ??
                                      [],
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTodoDialog(String day) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: TodoListDialog(
          day: day,
          todoItems: _todoLists[day] ?? [],
          onSave: (updatedItems) async {
            setState(() {
              _todoLists[day] = updatedItems;
              _controllers[day]?.text = _formatDisplayText(day);
            });
            await _saveTodoList(day);
          },
        ),
      ),
    );
  }

  Future<void> _showManualLoginDialog() async {
    final emailController = TextEditingController();
    final usernameController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set User Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (usernameController.text.isNotEmpty &&
                  emailController.text.isNotEmpty) {
                await UserService.instance.setManualUserInfo(
                  userName: usernameController.text,
                  email: emailController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  _syncWithDatabase();
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Method to track activity in recent activities
  Future<void> _trackActivity() async {
    try {
      final activity = RecentActivityItem(
        name: 'Patterns Theme Weekly Planner',
        imagePath: 'assets/patterns_theme_weekly_planner.png',
        timestamp: DateTime.now(),
        routeName: PatternsThemeWeeklyPlanner.routeName,
      );

      await ActivityTracker().trackActivity(activity);
    } catch (e) {
      print('Error tracking activity: $e');
    }
  }
}

class TodoListDialog extends StatefulWidget {
  final String day;
  final List<TodoItem> todoItems;
  final Function(List<TodoItem>) onSave;

  const TodoListDialog({
    super.key,
    required this.day,
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
            widget.day,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: 'Add a new task',
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
                onPressed: () {
                  widget.onSave(_items);
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
