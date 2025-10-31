import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:convert';
import 'dart:io';
import '../services/database_service.dart';
import '../services/user_service.dart';
import '../services/ios_widget_service.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../pages/active_dashboard_page.dart';
import '../utils/activity_tracker_mixin.dart';
import '../utils/platform_features.dart';
import '../pages/active_tasks_page.dart';

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
        isDone: json['isDone'] ?? false,
      );
}

class VisionBoardTheme {
  final String name;
  final String storageKey;
  final String displayName;
  final Color? cardBackground;
  final List<Color>? cardColors;
  final String? backgroundImage;
  final Color textColor;
  final Color placeholderColor;

  VisionBoardTheme({
    required this.name,
    required this.storageKey,
    required this.displayName,
    this.cardBackground,
    this.cardColors,
    this.backgroundImage,
    this.textColor = Colors.black,
    this.placeholderColor = Colors.grey,
  });

  static VisionBoardTheme getTheme(String themeName) {
    switch (themeName) {
      case 'Box theme Vision Board':
      case 'Boxy theme board':
        return VisionBoardTheme(
          name: 'Box',
          storageKey: 'BoxThem',
          displayName: 'Box Theme Vision Board',
          cardBackground: Colors.white,
          backgroundImage: 'assets/vision-board-ruled.png',
          textColor: Colors.black,
          placeholderColor: Colors.grey,
        );

      case 'PostIt theme Vision Board':
      case 'Post it theme board':
        return VisionBoardTheme(
          name: 'PostIt',
          storageKey: 'PostIt',
          displayName: 'Post-It Theme Vision Board',
          cardColors: [
            Colors.orange,
            Color.fromARGB(255, 244, 118, 142),
            Color.fromRGBO(235, 196, 95, 1),
            Color.fromARGB(255, 55, 78, 49),
            Color.fromARGB(255, 164, 219, 117),
            Color.fromARGB(255, 170, 238, 217),
            Color.fromARGB(255, 64, 83, 162),
            Color.fromARGB(255, 98, 126, 138),
            Color.fromARGB(255, 67, 141, 204),
            Color.fromARGB(255, 253, 60, 5),
            Color.fromARGB(255, 255, 150, 38),
            Color.fromARGB(255, 62, 173, 154),
            Color.fromARGB(255, 254, 181, 89),
            Color.fromARGB(255, 255, 243, 208),
            Color.fromARGB(255, 207, 174, 203),
            Color.fromARGB(255, 250, 188, 139),
            Color.fromARGB(255, 45, 30, 99),
            Color.fromARGB(255, 251, 87, 86),
            Color.fromARGB(255, 240, 166, 225),
            Color.fromARGB(255, 255, 255, 255),
            Color.fromARGB(255, 34, 0, 201),
          ],
          textColor: Colors.black,
          placeholderColor: Colors.grey,
        );

      case 'Premium theme Vision Board':
      case 'Premium black board':
        return VisionBoardTheme(
          name: 'Premium',
          storageKey: 'Premium',
          displayName: 'Premium Theme Vision Board',
          cardBackground: Colors.black,
          textColor: Colors.white,
          placeholderColor: Colors.grey,
        );

      case 'Winter Warmth theme Vision Board':
      case 'Floral theme board':
        return VisionBoardTheme(
          name: 'WinterWarmth',
          storageKey: 'WinterWarmth',
          displayName: 'Winter Warmth Theme Vision Board',
          cardColors: [
            Color.fromARGB(255, 194, 183, 163),
            Color(0xFF330f0f),
            Color(0xFFb78c56),
            Color.fromARGB(255, 45, 41, 0),
            Color(0xFF929092),
            Color(0xFF741102),
            Color(0xFF9e8c66),
            Color(0xFF462a19),
            Color(0xFF929274),
            Color(0xFF8c5b3e),
            Color(0xFF513c17),
            Color(0xFF873c1c),
            Color(0xFFaf8264),
            Color(0xFF1b160a),
            Color(0xFF9aa09c),
            Color(0xFF233e48),
            Color(0xFF4e5345),
            Color(0xFF490001),
            Color.fromARGB(255, 253, 216, 168),
            Color.fromARGB(255, 147, 125, 104),
            Color.fromARGB(255, 37, 53, 63),
          ],
          textColor: Colors.white,
          placeholderColor: Color.fromARGB(255, 160, 171, 150),
        );

      case 'Ruby Reds theme Vision Board':
        return VisionBoardTheme(
          name: 'RubyReds',
          storageKey: 'RubyReds',
          displayName: 'Ruby Reds Theme Vision Board',
          cardColors: [
            Color(0xFF4A0404),
            Color(0xFF8B0000),
            Color(0xFFA91B0D),
            Color(0xFFB22222),
            Color(0xFFC41E3A),
            Color(0xFFDC143C),
            Color(0xFFE34234),
            Color(0xFFCD5C5C),
            Color(0xFFE35D6A),
            Color(0xFFFF6B6B),
            Color(0xFFDB7093),
            Color(0xFFDC143C),
            Color(0xFFB22222),
            Color(0xFFA91B0D),
            Color(0xFF8B0000),
            Color(0xFF800000),
            Color(0xFF4A0404),
            Color(0xFFCD5C5C),
            Color(0xFFE34234),
            Color(0xFFDC143C),
            Color(0xFFB22222),
          ],
          textColor: Colors.white,
          placeholderColor: Colors.grey,
        );

      case 'Coffee Hues theme Vision Board':
        return VisionBoardTheme(
          name: 'CoffeeHues',
          storageKey: 'CoffeeHues',
          displayName: 'Coffee Hues Theme Vision Board',
          cardColors: [
            Color(0xFF3C2A21),
            Color(0xFF765341),
            Color(0xFFBEA99B),
            Color(0xFFF5E6D3),
            Color(0xFF8B593E),
            Color(0xFFD2B48C),
            Color(0xFFBE9B7B),
            Color(0xFF6F4E37),
            Color(0xFFDEB887),
            Color(0xFF000000),
            Color(0xFFA87C5D),
            Color(0xFF967969),
            Color(0xFFB38B6D),
            Color(0xFFCBAC88),
            Color(0xFF8B7355),
            Color(0xFF483C32),
            Color(0xFF6B4423),
            Color(0xFF7B3F00),
            Color(0xFF8B4513),
            Color(0xFFD2B48C),
            Color(0xFF6F4E37),
          ],
          textColor: Colors.white,
          placeholderColor: Colors.grey,
        );

      default:
        return VisionBoardTheme(
          name: 'Box',
          storageKey: 'BoxThem',
          displayName: 'Box Theme Vision Board',
          cardBackground: Colors.white,
          backgroundImage: 'assets/vision-board-ruled.png',
          textColor: Colors.black,
          placeholderColor: Colors.grey,
        );
    }
  }
}

class UnifiedVisionBoardPage extends StatefulWidget {
  final String themeName;

  const UnifiedVisionBoardPage({super.key, required this.themeName});

  @override
  State<UnifiedVisionBoardPage> createState() => _UnifiedVisionBoardPageState();
}

class _UnifiedVisionBoardPageState extends State<UnifiedVisionBoardPage>
    with ActivityTrackerMixin {
  final screenshotController = ScreenshotController();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, List<TodoItem>> _todoLists = {}; // Different list per category
  bool _isSyncing = false;
  DateTime _lastSyncTime = DateTime.now().subtract(const Duration(days: 1));
  bool _hasNetworkConnectivity = true;
  late VisionBoardTheme theme;

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

  String get pageName => theme.displayName;

  @override
  void initState() {
    super.initState();
    theme = VisionBoardTheme.getTheme(widget.themeName);
    _saveCurrentTheme(); // Save theme for widget auto-detection

    for (var category in visionCategories) {
      _controllers[category] = TextEditingController();
    }

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

    _trackActivity();
  }

  Future<void> _saveCurrentTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Save with both flutter. prefix and without (like Notes page)
      await prefs.setString('flutter.vision_board_current_theme', theme.displayName);
      await prefs.setString('vision_board_current_theme', theme.displayName);
      await HomeWidget.saveWidgetData('vision_board_current_theme', theme.displayName);
      await HomeWidget.saveWidgetData('widget_theme', theme.displayName); // Fallback key
      debugPrint('Saved current vision board theme: ${theme.displayName}');
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  Future<void> _loadAllFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      // Load tasks per category using universal keys (same across all themes)
      for (var category in visionCategories) {
        final savedTodos = prefs.getString('vision_board_$category');
        if (savedTodos != null) {
          final List<dynamic> decoded = json.decode(savedTodos);
          _todoLists[category] =
              decoded.map((item) => TodoItem.fromJson(item)).toList();
        } else {
          _todoLists[category] = [];
        }
      }
      setState(() {});
      debugPrint('Loaded tasks for ${_todoLists.length} categories');
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }

  Future<bool> _checkDatabaseConnectivity() async {
    try {
      final result = await DatabaseService.instance.testConnection();
      return result['success'] == true;
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
        
        // Load tasks for each category using category as cardId
        for (var category in visionCategories) {
          final tasksJson = await DatabaseService.instance
              .loadUserTasks(userInfo, category);

          if (tasksJson != null && tasksJson.isNotEmpty) {
            final List<dynamic> decoded = json.decode(tasksJson);
            _todoLists[category] =
                decoded.map((item) => TodoItem.fromJson(item)).toList();
            
            // Save to local storage AND widget storage with universal key
            // Save with both flutter. prefix and without (like Notes page)
            await prefs.setString('vision_board_$category', tasksJson);
            await prefs.setString('flutter.vision_board_$category', tasksJson);
            await HomeWidget.saveWidgetData('vision_board_$category', tasksJson);
          }
        }
        
        setState(() {});
        _lastSyncTime = DateTime.now();
        
        // Save categories list after sync
        final categoriesJson = json.encode(visionCategories);
        await prefs.setString('vision_board_categories', categoriesJson);
        await prefs.setString('flutter.vision_board_categories', categoriesJson);
        await HomeWidget.saveWidgetData('vision_board_categories', categoriesJson);
        
        // Update iOS widget after sync
        if (Platform.isIOS) {
          try {
            final todosByCategoryJson = <String, String>{};
            for (var cat in visionCategories) {
              final todos = _todoLists[cat] ?? [];
              todosByCategoryJson[cat] = json.encode(todos.map((item) => item.toJson()).toList());
            }
            
            await IOSWidgetService.updateVisionBoardWidget(
              theme: theme.displayName,
              categories: visionCategories,
              todosByCategoryJson: todosByCategoryJson,
            );
            debugPrint('iOS Vision Board widget updated after sync');
          } catch (e) {
            debugPrint('Error updating iOS widget after sync: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _saveTodoList(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final todoList = _todoLists[category] ?? [];
    final encoded = json.encode(todoList.map((item) => item.toJson()).toList());

    // Save to local storage with universal key (same across all themes)
    // Save with both flutter. prefix and without (like Notes page)
    await prefs.setString('vision_board_$category', encoded);
    await prefs.setString('flutter.vision_board_$category', encoded);
    await HomeWidget.saveWidgetData('vision_board_$category', encoded);

    // Save categories list for widget
    final categoriesJson = json.encode(visionCategories);
    await prefs.setString('vision_board_categories', categoriesJson);
    await prefs.setString('flutter.vision_board_categories', categoriesJson);
    await HomeWidget.saveWidgetData('vision_board_categories', categoriesJson);

    await HomeWidget.updateWidget(
      androidName: 'VisionBoardWidget',
      iOSName: 'VisionBoardWidget',
    );

    // Update iOS widget specifically (like Notes page)
    if (Platform.isIOS) {
      try {
        // Build todosByCategoryJson map
        final todosByCategoryJson = <String, String>{};
        for (var cat in visionCategories) {
          final todos = _todoLists[cat] ?? [];
          todosByCategoryJson[cat] = json.encode(todos.map((item) => item.toJson()).toList());
        }
        
        await IOSWidgetService.updateVisionBoardWidget(
          theme: theme.displayName,
          categories: visionCategories,
          todosByCategoryJson: todosByCategoryJson,
        );
        debugPrint('iOS Vision Board widget updated successfully');
      } catch (e) {
        debugPrint('Error updating iOS Vision Board widget: $e');
      }
    }

    if (!_hasNetworkConnectivity) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved locally (offline)')),
        );
      }
      return;
    }

    try {
      final isLoggedIn = await DatabaseService.instance.isUserLoggedIn();
      if (isLoggedIn) {
        final userInfo = await UserService.instance.getUserInfo();
        // Save with category as theme (so all visual themes access same category data)
        DatabaseService.instance
            .saveTodoItem(userInfo, encoded, category)
            .then((success) {
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Synced to cloud'), duration: Duration(seconds: 1)),
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Save error: $e');
    }
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
            setState(() => _todoLists[category] = updatedItems);
            await _saveTodoList(category);
          },
        ),
      ),
    );
  }

  Widget _buildVisionCard(String title, int index) {
    Color cardColor;
    if (theme.cardColors != null && index < theme.cardColors!.length) {
      cardColor = theme.cardColors![index];
    } else if (theme.cardBackground != null) {
      cardColor = theme.cardBackground!;
    } else {
      cardColor = Colors.white;
    }

    return GestureDetector(
      onTap: () => _showTodoDialog(title),
      child: Container(
        decoration: BoxDecoration(
          color: theme.backgroundImage == null ? cardColor : null,
          image: theme.backgroundImage != null
              ? DecorationImage(
                  image: AssetImage(theme.backgroundImage!),
                  fit: BoxFit.cover,
                )
              : null,
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
                color: cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Text(
                title,
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
                child: (_todoLists[title] ?? []).isEmpty
                    ? Text(
                        'Write your\nvision here',
                        style: TextStyle(
                          color: theme.placeholderColor,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      )
                    : Text.rich(
                        TextSpan(
                          children: (_todoLists[title] ?? []).map((todo) {
                            return TextSpan(
                              text: "• ${todo.text}\n",
                              style: TextStyle(
                                fontSize: 16,
                                decoration: todo.isDone
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: todo.isDone ? Colors.grey : theme.textColor,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ),
          ],
        ),
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
                    itemCount: visionCategories.length,
                    itemBuilder: (context, index) =>
                        _buildVisionCard(visionCategories[index], index),
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
                  label: const Text('Save Vision Board',
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
        routeName: '/unified-vision-board',
      );
      await ActivityTracker().trackActivity(activity);
    } catch (e) {
      debugPrint('Activity tracking error: $e');
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
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
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: 'Add a new task',
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
                    value: item.isDone,
                    onChanged: (value) => _toggleItem(item),
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

