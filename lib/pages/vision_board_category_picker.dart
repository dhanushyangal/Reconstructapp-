import 'package:flutter/material.dart';
import '../services/ios_widget_service.dart';

class VisionBoardCategoryPickerPage extends StatefulWidget {
  static const routeName = '/visionboard/category-picker';
  const VisionBoardCategoryPickerPage({super.key});

  @override
  State<VisionBoardCategoryPickerPage> createState() => _VisionBoardCategoryPickerPageState();
}

class _VisionBoardCategoryPickerPageState extends State<VisionBoardCategoryPickerPage> {
  final List<String> _allCategories = const [
    'Travel','Self Care','Forgive','Love','Family','Career','Health','Hobbies','Knowledge','Social','Reading','Food','Music','Tech','DIY','Luxury','Income','BMI','Invest','Inspiration','Help'
  ];
  final Set<String> _selected = {};
  String? _theme;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final t = await IOSWidgetService.getCurrentTheme();
    setState(() => _theme = t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Categories (max 5)')),
      body: Column(
        children: [
          if (_theme != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text('Theme: $_theme', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _allCategories.length,
              itemBuilder: (context, index) {
                final c = _allCategories[index];
                final selected = _selected.contains(c);
                return CheckboxListTile(
                  title: Text(c),
                  value: selected,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        if (_selected.length < 5) _selected.add(c);
                      } else {
                        _selected.remove(c);
                      }
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _theme == null || _selected.isEmpty ? null : () async {
                  final theme = _theme!;
                  final categories = _selected.toList();
                  // Send empty todos initially; app pages will fill later
                  await IOSWidgetService.updateVisionBoardWidget(
                    theme: theme,
                    categories: categories,
                    todosByCategoryJson: { for (final c in categories) c: '[]' },
                  );
                  if (mounted) Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ),
          )
        ],
      ),
    );
  }
}


