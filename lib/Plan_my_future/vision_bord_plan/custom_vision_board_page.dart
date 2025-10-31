import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:convert';
import 'dart:io';
import '../../services/database_service.dart';
import '../../services/user_service.dart';
import '../../services/ios_widget_service.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/activity_tracker_mixin.dart';
import '../../utils/platform_features.dart';
import '../../pages/active_tasks_page.dart';
import '../../components/nav_logpage.dart';

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

class CustomVisionBoardPage extends StatefulWidget {
  final String template;
  final String imagePath;
  final List<String> selectedAreas;

  const CustomVisionBoardPage({
    super.key,
    required this.template,
    required this.imagePath,
    required this.selectedAreas,
  });

  @override
  State<CustomVisionBoardPage> createState() => _CustomVisionBoardPageState();
}

class _CustomVisionBoardPageState extends State<CustomVisionBoardPage>
    with ActivityTrackerMixin, TickerProviderStateMixin {
  final screenshotController = ScreenshotController();
  // Different task list per category (same across all themes)
  final Map<String, List<TodoItem>> _todoLists = {};
  bool _isSyncing = false;
  DateTime _lastSyncTime = DateTime.now().subtract(const Duration(days: 1));
  bool _hasNetworkConnectivity = true;

  String get pageName => 'Custom Vision Board - ${widget.template}';

  // Theme-specific colors and styles
  Map<String, dynamic> get _themeConfig {
    switch (widget.template) {
      case 'Boxy theme board':
        return {
          'type': 'box',
          'backgroundImage': 'assets/vision-board-ruled.png',
          'cardBackground': Colors.white,
          'textColor': Colors.black,
          'placeholderColor': Colors.grey,
          'storagePrefix': 'BoxThem',
        };
      case 'Post it theme board':
        return {
          'type': 'postit',
          'cardColors': [
            Colors.orange,
            Color.fromARGB(255, 244, 118, 142),
            Color.fromRGBO(235, 196, 95, 1),
            Color.fromARGB(255, 55, 78, 49),
            Color.fromARGB(255, 164, 219, 117),
            Color.fromARGB(255, 170, 238, 217),
            Color.fromARGB(255, 64, 83, 162),
            Color.fromARGB(255, 98, 126, 138),
            Color.fromARGB(255, 67, 141, 204),
          ],
          'textColor': Colors.black,
          'placeholderColor': Colors.grey,
          'storagePrefix': 'BoxThem',
        };
      case 'Premium black board':
        return {
          'type': 'premium',
          'cardBackground': Colors.black,
          'textColor': Colors.white,
          'placeholderColor': Colors.grey,
          'storagePrefix': 'BoxThem',
        };
      case 'Floral theme board':
        return {
          'type': 'winter',
          'cardColors': [
            Color.fromARGB(255, 194, 183, 163),
            Color(0xFF330f0f),
            Color(0xFFb78c56),
            Color.fromARGB(255, 45, 41, 0),
            Color(0xFF929092),
            Color(0xFF741102),
            Color(0xFF9e8c66),
            Color(0xFF462a19),
            Color(0xFF929274),
          ],
          'textColor': Colors.white,
          'placeholderColor': Color.fromARGB(255, 160, 171, 150),
          'storagePrefix': 'BoxThem',
        };
      // Keep the old names for backward compatibility
      case 'Box theme Vision Board':
        return {
          'type': 'box',
          'backgroundImage': 'assets/vision-board-ruled.png',
          'cardBackground': Colors.white,
          'textColor': Colors.black,
          'placeholderColor': Colors.grey,
          'storagePrefix': 'BoxThem',
        };
      case 'PostIt theme Vision Board':
        return {
          'type': 'postit',
          'cardColors': [
            Colors.orange,
            Color.fromARGB(255, 244, 118, 142),
            Color.fromRGBO(235, 196, 95, 1),
            Color.fromARGB(255, 55, 78, 49),
            Color.fromARGB(255, 164, 219, 117),
            Color.fromARGB(255, 170, 238, 217),
            Color.fromARGB(255, 64, 83, 162),
            Color.fromARGB(255, 98, 126, 138),
            Color.fromARGB(255, 67, 141, 204),
          ],
          'textColor': Colors.black,
          'placeholderColor': Colors.grey,
          'storagePrefix': 'BoxThem',
        };
      case 'Premium theme Vision Board':
        return {
          'type': 'premium',
          'cardBackground': Colors.black,
          'textColor': Colors.white,
          'placeholderColor': Colors.grey,
          'storagePrefix': 'BoxThem',
        };
      case 'Winter Warmth theme Vision Board':
        return {
          'type': 'winter',
          'cardColors': [
            Color.fromARGB(255, 194, 183, 163),
            Color(0xFF330f0f),
            Color(0xFFb78c56),
            Color.fromARGB(255, 45, 41, 0),
            Color(0xFF929092),
            Color(0xFF741102),
            Color(0xFF9e8c66),
            Color(0xFF462a19),
            Color(0xFF929274),
          ],
          'textColor': Colors.white,
          'placeholderColor': Color.fromARGB(255, 160, 171, 150),
          'storagePrefix': 'BoxThem',
        };
      default:
        return {
          'type': 'box',
          'backgroundImage': 'assets/vision-board-ruled.png',
          'cardBackground': Colors.white,
          'textColor': Colors.black,
          'placeholderColor': Colors.grey,
          'storagePrefix': 'BoxThem',
        };
    }
  }

  @override
  void initState() {
    super.initState();
    _saveCurrentTheme(); // Save theme for widget auto-detection

    // Load shared data from local storage first (fast)
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

  Future<void> _saveCurrentTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Save with both flutter. prefix and without (like Notes page)
      await prefs.setString('flutter.vision_board_current_theme', widget.template);
      await prefs.setString('vision_board_current_theme', widget.template);
      await HomeWidget.saveWidgetData('vision_board_current_theme', widget.template);
      await HomeWidget.saveWidgetData('widget_theme', widget.template); // Fallback key
      debugPrint('Saved current vision board theme: ${widget.template}');
    } catch (e) {
      debugPrint('Error saving theme: $e');
    }
  }

  // Load data per category from local storage (fast operation)
  Future<void> _loadAllFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // Load tasks for each selected area (category) using universal keys
      for (var category in widget.selectedAreas) {
        final savedTodos = prefs.getString('vision_board_$category');
        if (savedTodos != null) {
          final List<dynamic> decoded = json.decode(savedTodos);
          _todoLists[category] = decoded.map((item) => TodoItem.fromJson(item)).toList();
        } else {
          _todoLists[category] = [];
        }
      }
      setState(() {});
      debugPrint('Loaded tasks for ${_todoLists.length} categories from local storage');
    } catch (e) {
      debugPrint('Error parsing local vision board tasks: $e');
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

  // Sync shared data with database
  Future<void> _syncWithDatabase() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final userInfo = await UserService.instance.getUserInfo();

      if (userInfo['userName']?.isNotEmpty == true &&
          userInfo['email']?.isNotEmpty == true) {
        // Load tasks for each selected area (category)
      for (var category in widget.selectedAreas) {
        final tasksJson = await DatabaseService.instance.loadUserTasks(userInfo, category);

        if (tasksJson != null && tasksJson.isNotEmpty) {
          try {
            final List<dynamic> decoded = json.decode(tasksJson);
            final prefs = await SharedPreferences.getInstance();

            // Update the specific category's task list
            _todoLists[category] = decoded.map((item) => TodoItem.fromJson(item)).toList();

            // Save to both local storage AND widget storage
            // Save with both flutter. prefix and without (like Notes page)
            await prefs.setString('vision_board_$category', tasksJson);
            await prefs.setString('flutter.vision_board_$category', tasksJson);
            await HomeWidget.saveWidgetData('vision_board_$category', tasksJson);

            debugPrint('Updated local storage for category: $category');
          } catch (e) {
            debugPrint('Error processing database tasks for $category: $e');
          }
        }
      }

        _lastSyncTime = DateTime.now();
        
        // Save categories list after sync
        final prefs = await SharedPreferences.getInstance();
        final categoriesJson = json.encode(widget.selectedAreas);
        await prefs.setString('vision_board_categories', categoriesJson);
        await prefs.setString('flutter.vision_board_categories', categoriesJson);
        await HomeWidget.saveWidgetData('vision_board_categories', categoriesJson);
        
        // Update iOS widget after sync
        if (Platform.isIOS) {
          try {
            final todosByCategoryJson = <String, String>{};
            for (var cat in widget.selectedAreas) {
              final todos = _todoLists[cat] ?? [];
              todosByCategoryJson[cat] = json.encode(todos.map((item) => item.toJson()).toList());
            }
            
            await IOSWidgetService.updateVisionBoardWidget(
              theme: widget.template,
              categories: widget.selectedAreas,
              todosByCategoryJson: todosByCategoryJson,
            );
            debugPrint('iOS Vision Board widget updated after sync');
          } catch (e) {
            debugPrint('Error updating iOS widget after sync: $e');
          }
        }
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

  // Save todo list for a specific category
  Future<void> _saveTodoList(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final todoList = _todoLists[category] ?? [];
    final encoded = json.encode(todoList.map((item) => item.toJson()).toList());

    // Always save locally AND to widget storage first (fast operation)
    // Save with both flutter. prefix and without (like Notes page)
    await prefs.setString('vision_board_$category', encoded);
    await prefs.setString('flutter.vision_board_$category', encoded);
    await HomeWidget.saveWidgetData('vision_board_$category', encoded);

    // Save categories list for widget
    final categoriesJson = json.encode(widget.selectedAreas);
    await prefs.setString('vision_board_categories', categoriesJson);
    await prefs.setString('flutter.vision_board_categories', categoriesJson);
    await HomeWidget.saveWidgetData('vision_board_categories', categoriesJson);

    // Update the widget
    await HomeWidget.updateWidget(
      androidName: 'VisionBoardWidget',
      iOSName: 'VisionBoardWidget',
    );

    // Update iOS widget specifically (like Notes page)
    if (Platform.isIOS) {
      try {
        // Build todosByCategoryJson map
        final todosByCategoryJson = <String, String>{};
        for (var cat in widget.selectedAreas) {
          final todos = _todoLists[cat] ?? [];
          todosByCategoryJson[cat] = json.encode(todos.map((item) => item.toJson()).toList());
        }
        
        await IOSWidgetService.updateVisionBoardWidget(
          theme: widget.template,
          categories: widget.selectedAreas,
          todosByCategoryJson: todosByCategoryJson,
        );
        debugPrint('iOS Vision Board widget updated successfully');
      } catch (e) {
        debugPrint('Error updating iOS Vision Board widget: $e');
      }
    }

    // Only try to save to database if we have network connectivity
    if (!_hasNetworkConnectivity) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task saved locally (offline mode)'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Try to save to database in the background
    try {
      final isLoggedIn = await DatabaseService.instance.isUserLoggedIn();

      if (isLoggedIn) {
        final userInfo = await UserService.instance.getUserInfo();

        DatabaseService.instance
            .saveTodoItem(userInfo, encoded, category)
            .then((success) {
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Task synced to cloud'),
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

  @override
  void dispose() {
    super.dispose();
  }


  Widget _buildVisionCard(String title, int index) {
    final themeConfig = _themeConfig;
    final cardColors = themeConfig['cardColors'] as List<Color>?;
    final cardBackground = themeConfig['cardBackground'] as Color?;
    final backgroundImage = themeConfig['backgroundImage'] as String?;
    final textColor = themeConfig['textColor'] as Color;
    final placeholderColor = themeConfig['placeholderColor'] as Color;

    Color cardColor;
    if (cardColors != null && index < cardColors.length) {
      cardColor = cardColors[index];
    } else if (cardBackground != null) {
      cardColor = cardBackground;
    } else {
      cardColor = Colors.white;
    }

    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
            child: Row(
              children: [
                if (_isCustomCreatedCard(title)) ...[
                  Icon(
                    Icons.star,
                    color: themeConfig['type'] == 'premium' || themeConfig['type'] == 'winter'
                        ? Colors.white
                        : Colors.black,
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
                      color: themeConfig['type'] == 'premium' || themeConfig['type'] == 'winter'
                          ? Colors.white
                          : Colors.black,
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
                child: (_todoLists[title] ?? []).isEmpty
                    ? Text(
                        _isCustomCreatedCard(title) ? 'Create your\ncustom vision' : 'Write your\nvision here',
                        style: TextStyle(
                          color: placeholderColor,
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
                                    decoration: todo.isDone == true
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    color: todo.isDone == true
                                        ? Colors.grey
                                        : textColor,
                                  ),
                                );
                              }).toList(),
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
          androidName: 'VisionBoardWidget',
          iOSName: 'VisionBoardWidget',
        );
      },
      child: Container(
        decoration: BoxDecoration(
          image: backgroundImage != null
              ? DecorationImage(
                  image: AssetImage(backgroundImage),
                  fit: BoxFit.cover,
                )
              : null,
          color: backgroundImage == null ? cardColor : null,
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
        child: backgroundImage != null
            ? cardContent
            : cardContent,
      ),
    );
  }

  void _showTodoDialog(String category) {
    trackClick('Open $category tasks');
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
      // Using default navigation handler from NavLogPage
      // No need to provide onNavigationTap - NavLogPage handles it
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
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _getOptimalCrossAxisCount(widget.selectedAreas.length),
                      childAspectRatio: _getOptimalAspectRatio(widget.selectedAreas.length),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemCount: widget.selectedAreas.length,
                    itemBuilder: (context, index) =>
                        _buildVisionCard(widget.selectedAreas[index], index),
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
                    'Save Vision Board',
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
                          'Syncing with cloud...',
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
    trackClick('Custom Vision Board - ${widget.template}');
  }

  // Helper method to detect if a card is custom created (not in predefined list)
  bool _isCustomCreatedCard(String title) {
    // List of predefined life areas
    final predefinedAreas = [
      'Travel', 'Career', 'Family', 'Income', 'Health', 'Fitness',
      'Social life', 'Self care', 'Skill', 'Education', 'Relationships',
      'Spirituality', 'Hobbies', 'Personal Growth', 'Financial Planning',
      'Home & Living', 'Technology', 'Environment', 'Community',
      'Creativity', 'Adventure', 'Wellness', 'Custom Card'
    ];
    return !predefinedAreas.contains(title);
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
