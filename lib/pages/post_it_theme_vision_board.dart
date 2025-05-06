import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:convert';
import '../services/database_service.dart';
import '../services/user_service.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

class TodoItem {
  String id;
  String text;
  bool isDone;

  TodoItem({
    required this.id,
    required this.text,
    this.isDone = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isDone': isDone,
      };

  factory TodoItem.fromJson(Map<String, dynamic> json) => TodoItem(
        id: json['id'],
        text: json['text'],
        isDone: json['isDone'],
      );
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

class PostItThemeVisionBoard extends StatefulWidget {
  const PostItThemeVisionBoard({super.key});

  @override
  State<PostItThemeVisionBoard> createState() => _PostItThemeVisionBoardState();
}

class _PostItThemeVisionBoardState extends State<PostItThemeVisionBoard> {
  final screenshotController = ScreenshotController();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, List<TodoItem>> _todoLists = {};
  bool _isSyncing = false;
  DateTime _lastSyncTime = DateTime.now().subtract(const Duration(days: 1));
  bool _hasNetworkConnectivity = true;
  final List<String> visionCategories = [
    'Travel',
    'Self Care',
    'Forgive',
    'Love',
    'Family',
    'Career',
    'Health',
    'Hobbies',
    'Knowledge',
    'Social',
    'Reading',
    'Food',
    'Music',
    'Tech',
    'DIY',
    'Luxury',
    'Income',
    'BMI',
    'Invest',
    'Inspiration',
    'Help'
  ];

  final List<Color> cardColors = [
    Colors.orange, // Travel
    Color.fromARGB(255, 244, 118, 142), // Self Care
    Color.fromRGBO(235, 196, 95, 1), // Forgive
    Color.fromARGB(255, 55, 78, 49), // Love
    Color.fromARGB(255, 164, 219, 117), // Family
    Color.fromARGB(255, 170, 238, 217), // Career
    Color.fromARGB(255, 64, 83, 162), // Health
    Color.fromARGB(255, 98, 126, 138), // Hobbies
    Color.fromARGB(255, 67, 141, 204), // Knowledge
    Color.fromARGB(255, 253, 60, 5), // Social
    Color.fromARGB(255, 255, 150, 38), // Reading
    Color.fromARGB(255, 62, 173, 154), // Food
    Color.fromARGB(255, 254, 181, 89), // Music
    Color.fromARGB(255, 255, 243, 208), // Tech
    Color.fromARGB(255, 207, 174, 203), // DIY
    Color.fromARGB(255, 250, 188, 139), // Luxury
    Color.fromARGB(255, 45, 30, 99), // Income
    Color.fromARGB(255, 251, 87, 86), // BMI (default to pink if null)
    Color.fromARGB(255, 240, 166, 225), // Invest (default to purple if null)
    Color.fromARGB(255, 255, 255, 255), // Inspiration (default to blue if null)
    Color.fromARGB(255, 34, 0, 201) // Help
  ];

  @override
  void initState() {
    super.initState();
    for (var category in visionCategories) {
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
  }

  // Load all data from local storage (fast operation)
  Future<void> _loadAllFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();

    for (var category in visionCategories) {
      try {
        final savedTodos = prefs.getString('postit_todos_$category');
        if (savedTodos != null) {
          final List<dynamic> decoded = json.decode(savedTodos);
          setState(() {
            _todoLists[category] =
                decoded.map((item) => TodoItem.fromJson(item)).toList();
            _controllers[category]?.text = _formatDisplayText(category);
          });
          debugPrint(
              'Loaded ${_todoLists[category]?.length ?? 0} tasks from local storage for $category');
        }
      } catch (e) {
        debugPrint('Error parsing local tasks for $category: $e');
      }
    }
  }

  // Check database connectivity
  Future<bool> _checkDatabaseConnectivity() async {
    try {
      final result = await DatabaseService.instance.testConnection();
      return result['success'] == true;
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
        final allTasksFromDb =
            await DatabaseService.instance.loadUserTasks(userInfo, 'PostIt');

        if (allTasksFromDb.isNotEmpty) {
          final prefs = await SharedPreferences.getInstance();

          for (var dbTask in allTasksFromDb) {
            final category = dbTask['card_id'];
            if (_todoLists.containsKey(category)) {
              try {
                final tasksJson = dbTask['tasks'] as String;
                final List<dynamic> decoded = json.decode(tasksJson);

                setState(() {
                  _todoLists[category] =
                      decoded.map((item) => TodoItem.fromJson(item)).toList();
                  _controllers[category]?.text = _formatDisplayText(category);
                });

                await prefs.setString('postit_todos_$category', tasksJson);
                await HomeWidget.saveWidgetData(
                    'postit_todos_$category', tasksJson);

                debugPrint(
                    'Updated local storage for $category with database data');
              } catch (e) {
                debugPrint('Error processing database tasks for $category: $e');
              }
            }
          }
        }

        _lastSyncTime = DateTime.now();
      }
    } catch (e) {
      debugPrint('Error syncing with database: $e');
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

    // Always save locally first (fast operation)
    await prefs.setString('postit_todos_$category', encoded);
    await HomeWidget.saveWidgetData('postit_todos_$category', encoded);

    // Update the widget
    await HomeWidget.updateWidget(
      androidName: 'VisionBoardWidget',
      iOSName: 'VisionBoardWidget',
    );

    // Try to save to database immediately
    try {
      final isLoggedIn = await DatabaseService.instance.isUserLoggedIn();

      if (isLoggedIn) {
        final userInfo = await UserService.instance.getUserInfo();

        final success = await DatabaseService.instance
            .saveTodoItem(userInfo, category, encoded, 'PostIt');

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task saved to cloud'),
              duration: Duration(seconds: 1),
            ),
          );
        }
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
  }

  String _formatDisplayText(String category) {
    final todos = _todoLists[category];
    if (todos == null || todos.isEmpty) return '';

    return todos.map((item) => "• ${item.text}").join("\n");
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

  Future<void> loadData() async {
    try {
      final data = await HomeWidget.getWidgetData<String>('vision_data');
      if (data != null) {
        setState(() {
          // Update your state based on widget data
        });
      }
    } catch (e) {
      debugPrint('Error loading widget data: $e');
    }
  }

  Future<void> updateWidget() async {
    try {
      await HomeWidget.saveWidgetData<String>(
          'vision_data', 'Your vision data here');
      await HomeWidget.updateWidget(
        androidName: 'VisionBoardWidget',
        iOSName: 'VisionBoardWidget',
      );
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _takeScreenshotAndShare() async {
    try {
      final image = await screenshotController.capture();
      if (image == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final imagePath = '${directory.path}/postit_vision_board.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(image);

      await Share.shareXFiles([XFile(imagePath)],
          text: 'My Post-It Vision Board for 2025');
    } catch (e) {
      debugPrint('Error sharing vision board: $e');
    }
  }

  Widget _buildVisionCard(String title, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: GestureDetector(
                  onTap: () {
                    _showTodoDialog(title);
                  },
                  child: _todoLists[title]?.isEmpty ?? true
                      ? const Text(
                          'Write your\nvision here',
                          style: TextStyle(
                            color: Colors.grey,
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
                                      decoration: todo.isDone == true
                                          ? TextDecoration.lineThrough
                                          : TextDecoration.none,
                                      color: todo.isDone == true
                                          ? Colors.grey
                                          : (title == 'Love' ||
                                                  title == 'Invest' ||
                                                  title == 'Help'
                                              ? const Color.fromARGB(
                                                  255, 255, 255, 255)
                                              : Colors.black),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post-It Theme Vision Board'),
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
                    itemCount: visionCategories.length,
                    itemBuilder: (context, index) => _buildVisionCard(
                        visionCategories[index], cardColors[index]),
                  ),
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
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _takeScreenshotAndShare,
                  icon: const Icon(Icons.share, color: Colors.blue),
                  label: const Text(
                    'Share Vision Board',
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
              ],
            ),
          ),
        ],
      ),
    );
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
          id: DateTime.now().toString(),
          text: _textController.text,
        ));
        _textController.clear();
      });
    }
  }

  void _toggleItem(TodoItem item) {
    setState(() {
      item.isDone = !item.isDone;
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
                    value: item.isDone,
                    onChanged: (value) {
                      _toggleItem(item);
                    },
                  ),
                  title: Text(
                    item.text,
                    style: TextStyle(
                      decoration:
                          item.isDone ? TextDecoration.lineThrough : null,
                      color: item.isDone ? Colors.grey : Colors.black,
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
                    androidName: 'VisionBoardWidget',
                    iOSName: 'VisionBoardWidget',
                  );
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
