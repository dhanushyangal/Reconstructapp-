import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_widget/home_widget.dart';
import 'dart:convert';
import '../services/vision_board_service.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        text: json['text'] ?? '',
        isDone: json['isDone'] ?? json['completed'] ?? false,
      );
}

class PostItThemeVisionBoard extends StatefulWidget {
  const PostItThemeVisionBoard({super.key});

  @override
  State<PostItThemeVisionBoard> createState() => _PostItThemeVisionBoardState();
}

class _PostItThemeVisionBoardState extends State<PostItThemeVisionBoard> {
  final screenshotController = ScreenshotController();
  final Map<String, TextEditingController> _controllers = {};
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

  final Map<String, List<TodoItem>> _todoLists = {};
  late VisionBoardService _visionBoardService;
  bool _isLoading = true;
  String? _userId;
  final String _theme = "post_it";

  @override
  void initState() {
    super.initState();
    _visionBoardService = VisionBoardService(baseUrl: ApiConfig.baseUrl);

    for (var category in visionCategories) {
      _controllers[category] = TextEditingController();
      _todoLists[category] = [];
    }

    _initializeData();
    HomeWidget.widgetClicked.listen((Uri? uri) => _loadDataFromDatabase());
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    // Get current user ID if logged in
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
    }

    // Try to load from database first
    await _loadDataFromDatabase();

    // If nothing was loaded from database, try local storage as fallback
    for (var category in visionCategories) {
      if (_todoLists[category]!.isEmpty) {
        await _loadSavedData(category);
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadDataFromDatabase() async {
    try {
      for (var category in visionCategories) {
        final result = await _visionBoardService.getVisionBoardTasks(
          category: category,
          theme: _theme,
          userId: _userId,
        );

        if (result['success'] == true && result['tasks'] != null) {
          final tasksList = result['tasks'] as List;
          if (tasksList.isNotEmpty) {
            final firstRecord = tasksList.first;
            final tasks = firstRecord['tasks'] as List;

            setState(() {
              _todoLists[category] =
                  tasks.map((task) => TodoItem.fromJson(task)).toList();
              _controllers[category]?.text = _formatDisplayText(category);
            });

            // Also save to local storage as backup
            await _saveToLocalStorage(category);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading tasks from database: $e');
      // Fallback to local storage if database load fails
      for (var category in visionCategories) {
        await _loadSavedData(category);
      }
    }
  }

  Future<void> _loadSavedData(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final savedTodos = prefs.getString('postit_todos_$category');
    if (savedTodos != null) {
      final List<dynamic> decoded = json.decode(savedTodos);
      setState(() {
        _todoLists[category] =
            decoded.map((item) => TodoItem.fromJson(item)).toList();
      });
    }
    setState(() {
      _controllers[category]?.text = _formatDisplayText(category);
    });
  }

  String _formatDisplayText(String category) {
    final todos = _todoLists[category];
    if (todos == null || todos.isEmpty) return '';

    return todos.map((item) => "• ${item.text}").join("\n");
  }

  Future<void> _saveToLocalStorage(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json
        .encode(_todoLists[category]?.map((item) => item.toJson()).toList());
    await prefs.setString('postit_todos_$category', encoded);
    await HomeWidget.saveWidgetData('postit_todos_$category', encoded);
    await HomeWidget.updateWidget(
      androidName: 'VisionBoardWidget',
      iOSName: 'VisionBoardWidget',
    );
  }

  Future<void> _saveTodoList(String category) async {
    // Save to local storage first as backup
    await _saveToLocalStorage(category);

    // Then save to database if possible
    try {
      await _visionBoardService.saveVisionBoardTasks(
        category: category,
        tasks: _todoLists[category] ?? [],
        theme: _theme,
        userId: _userId,
      );
    } catch (e) {
      debugPrint('Error saving to database: $e');
      // Already saved to local storage as backup, so no additional fallback needed
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
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
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
                  child: ElevatedButton.icon(
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
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.todoItems);
  }

  void _addItem() {
    if (_textController.text.isNotEmpty) {
      setState(() {
        _items.add(TodoItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
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

  Future<void> _saveItems() async {
    setState(() {
      _isSaving = true;
    });

    await widget.onSave(_items);

    setState(() {
      _isSaving = false;
    });

    Navigator.pop(context);
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
              _isSaving
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveItems,
                      child: const Text('Save'),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
