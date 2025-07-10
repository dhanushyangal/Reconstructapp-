import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
// Import for activity tracking

import '../services/annual_calendar_service.dart';
import '../services/user_service.dart';
import 'dart:async';
import '../utils/activity_tracker_mixin.dart';

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

class FloralThemeAnnualPlanner extends StatefulWidget {
  final int monthIndex;
  final String? eventId;
  final bool showEvents;

  const FloralThemeAnnualPlanner({
    super.key,
    required this.monthIndex,
    this.eventId,
    this.showEvents = false,
  });

  // Add route name to make navigation easier
  static const routeName = '/floral-theme-annual-planner';

  @override
  State<FloralThemeAnnualPlanner> createState() =>
      _FloralThemeAnnualPlannerState();
}

class _FloralThemeAnnualPlannerState extends State<FloralThemeAnnualPlanner>
    with ActivityTrackerMixin {
  final screenshotController = ScreenshotController();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, List<TodoItem>> _todoLists = {};
  bool _isSyncing = false;
  DateTime _lastSyncTime = DateTime.now().subtract(const Duration(days: 1));
  bool _hasNetworkConnectivity = true;
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

  @override
  void initState() {
    super.initState();
    for (var month in months) {
      _controllers[month] = TextEditingController();
      _todoLists[month] = [];
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

    // Track this page visit in recent activities
    trackUserInteraction('click', details: 'View Floral Theme Annual Planner');
  }

  // Load all data from local storage (fast operation)
  Future<void> _loadAllFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();

    for (var month in months) {
      try {
        final savedTodos = prefs.getString('FloralTheme_todos_$month');
        if (savedTodos != null) {
          final List<dynamic> decoded = json.decode(savedTodos);
          setState(() {
            _todoLists[month] =
                decoded.map((item) => TodoItem.fromJson(item)).toList();
            _controllers[month]?.text = _formatDisplayText(month);
          });
          debugPrint(
              'Loaded ${_todoLists[month]?.length ?? 0} tasks from local storage for $month');
        }
      } catch (e) {
        debugPrint('Error parsing local tasks for $month: $e');
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

      if (userInfo['userName']?.isNotEmpty == true &&
          userInfo['email']?.isNotEmpty == true) {
        final allTasksFromDb = await AnnualCalendarService.instance
            .loadUserTasks(userInfo, theme: 'floral');

        if (allTasksFromDb.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();

          for (var dbTask in allTasksFromDb) {
            final month = dbTask['card_id'];
            if (_todoLists.containsKey(month)) {
              try {
                final tasksJson = dbTask['tasks'] as String;
                final List<dynamic> decoded = json.decode(tasksJson);

                setState(() {
                  _todoLists[month] =
                      decoded.map((item) => TodoItem.fromJson(item)).toList();
                  _controllers[month]?.text = _formatDisplayText(month);
                });

                await prefs.setString('FloralTheme_todos_$month', tasksJson);
                await HomeWidget.saveWidgetData(
                    'FloralTheme_todos_$month', tasksJson);
                await HomeWidget.saveWidgetData(
                    'floral_todo_text_$month', _formatDisplayText(month));

                debugPrint(
                    'Updated local storage for $month with database data');
              } catch (e) {
                debugPrint('Error processing database tasks for $month: $e');
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

  void _showManualLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => const ManualLoginDialog(),
    ).then((_) => _syncWithDatabase());
  }

  Future<void> _saveTodoList(String month) async {
    try {
      // Save to local storage first as backup
      final prefs = await SharedPreferences.getInstance();
      final todos = _todoLists[month];

      if (todos == null) return;

      final encoded = json.encode(todos.map((item) => item.toJson()).toList());
      await prefs.setString('FloralTheme_todos_$month', encoded);

      // Save to HomeWidget
      await HomeWidget.saveWidgetData('FloralTheme_todos_$month', encoded);
      await HomeWidget.saveWidgetData(
          'floral_todo_text_$month', _formatDisplayText(month));

      // Update the widget
      await HomeWidget.updateWidget(
        androidName: 'AnnualPlannerWidget',
        iOSName: 'AnnualPlannerWidget',
      );

      // Try to save to database
      try {
        final userInfo = await UserService.instance.getUserInfo();
        if (userInfo['userName']?.isNotEmpty == true &&
            userInfo['email']?.isNotEmpty == true) {
          final success = await AnnualCalendarService.instance
              .saveTodoItem(userInfo, month, encoded);

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

  static Future<void> backgroundCallback(Uri? uri) async {
    // Handle background updates if needed
  }

  String _formatDisplayText(String month) {
    final todos = _todoLists[month];
    if (todos == null || todos.isEmpty) return '';

    // Format each todo item with a bullet point and handle completion status
    return todos.map((item) {
      final checkmark = item.completed ? '✓ ' : '• ';
      return "$checkmark${item.text}";
    }).join('\n');
  }

  Future<void> _takeScreenshotAndShare() async {
    try {
      final image = await screenshotController.capture();
      if (image == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/floral_annual_planner.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);

      await Share.shareXFiles([XFile(imagePath)],
          text: 'My Floral Theme Annual Planner for 2025');
    } catch (e) {
      debugPrint('Error sharing planner: $e');
    }
  }

  Widget _buildMonthCard(String month) {
    int monthIndex = months.indexOf(month);
    return GestureDetector(
      onTap: () => _showTodoDialog(month),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image:
                AssetImage('assets/floral_weekly/floral_${monthIndex + 1}.png'),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(50),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  month,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: _todoLists[month]?.isEmpty ?? true
                      ? const Text(
                          'Add events for this month',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        )
                      : Text.rich(
                          TextSpan(
                            children: _todoLists[month]?.map((todo) {
                                  return TextSpan(
                                    text: "• ${todo.text}\n",
                                    style: TextStyle(
                                      fontSize: 16,
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
            ],
          ),
        ),
      ),
    );
  }

  void _showTodoDialog(String month) {
    trackClick('Open $month tasks');
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: TodoListDialog(
          month: month,
          todoItems: _todoLists[month] ?? [],
          onSave: (updatedItems) async {
            setState(() {
              _todoLists[month] = updatedItems;
              _controllers[month]?.text = _formatDisplayText(month);
            });
            await _saveTodoList(month);

            // Trigger a sync after saving
            if (_hasNetworkConnectivity) {
              await _syncWithDatabase();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Floral Theme Annual Planner 2025'),
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
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: months.length,
                  itemBuilder: (context, index) =>
                      _buildMonthCard(months[index]),
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
                  label: const Text('Share Annual Planner'),
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
}

class TodoListDialog extends StatefulWidget {
  final String month;
  final List<TodoItem> todoItems;
  final Function(List<TodoItem>) onSave;

  const TodoListDialog({
    super.key,
    required this.month,
    required this.todoItems,
    required this.onSave,
  });

  @override
  TodoListDialogState createState() => TodoListDialogState();
}

class TodoListDialogState extends State<TodoListDialog>
    with ActivityTrackerMixin {
  late List<TodoItem> _items;
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.todoItems);
  }

  void _addItem() {
    if (_textController.text.isNotEmpty) {
      trackButtonTap('Add Task', additionalDetails: widget.month);
      setState(() {
        _items.add(TodoItem(
          text: _textController.text,
        ));
        _textController.clear();
      });
    }
  }

  void _toggleItem(TodoItem item) {
    trackClick(item.completed ? 'Uncheck task' : 'Complete task');
    setState(() {
      item.completed = !item.completed;
    });
  }

  void _removeItem(TodoItem item) {
    trackClick('Delete task');
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
            widget.month,
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
            onChanged: (value) {
              if (value.isNotEmpty && value.length % 10 == 0) {
                trackTextInput('Task text', value: value);
              }
            },
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
