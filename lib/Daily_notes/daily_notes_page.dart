import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:home_widget/home_widget.dart';

class DailyNotesPage extends StatefulWidget {
  static const routeName = '/daily-notes';

  const DailyNotesPage({Key? key}) : super(key: key);

  @override
  State<DailyNotesPage> createState() => _DailyNotesPageState();
}

class _DailyNotesPageState extends State<DailyNotesPage> {
  List<NoteData> _notes = [];
  bool _isLoading = true;
  final String _saveKey = 'daily_notes_data';

  @override
  void initState() {
    super.initState();
    _loadNotes();

    // Initialize HomeWidget
    HomeWidget.setAppGroupId('group.com.reconstrect.visionboard');
    HomeWidget.registerBackgroundCallback(backgroundCallback);
  }

  // Background callback for widget updates
  static Future<void> backgroundCallback(Uri? uri) async {
    if (uri?.host == 'updatewidget') {
      // Get data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('daily_notes_data');

      if (data != null) {
        // Save data to widget
        await HomeWidget.saveWidgetData('daily_notes_data', data);
      }

      await HomeWidget.updateWidget(
        androidName: 'DailyNotesWidget',
        iOSName: 'DailyNotesWidget',
      );
    }
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_saveKey);

      if (notesJson != null) {
        final List<dynamic> decodedList = json.decode(notesJson);
        setState(() {
          _notes = decodedList.map((item) => NoteData.fromJson(item)).toList();
        });

        // Update widget with latest data
        await _updateWidget();
      } else {
        // Add a default note if none exist
        setState(() {
          _notes = [
            NoteData(
                id: DateTime.now().millisecondsSinceEpoch.toString(), text: '')
          ];
        });
      }
    } catch (e) {
      debugPrint('Error loading notes: $e');
      // Reset to a default note if there's an error
      setState(() {
        _notes = [
          NoteData(
              id: DateTime.now().millisecondsSinceEpoch.toString(), text: '')
        ];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson =
          json.encode(_notes.map((note) => note.toJson()).toList());
      await prefs.setString(_saveKey, notesJson);

      // Update widget when notes are saved
      await _updateWidget();
    } catch (e) {
      debugPrint('Error saving notes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save notes: $e')),
      );
    }
  }

  // Update the widget with latest notes data
  Future<void> _updateWidget() async {
    try {
      // Format the first note for widget display
      String displayText = '';
      if (_notes.isNotEmpty && _notes[0].text.isNotEmpty) {
        // Limit the display text to 100 characters for the widget
        displayText = _notes[0].text.length > 100
            ? '${_notes[0].text.substring(0, 100)}...'
            : _notes[0].text;
      } else {
        displayText = 'Tap to add notes...';
      }

      // Save the display text to the widget
      await HomeWidget.saveWidgetData('daily_notes_display_text', displayText);

      // Save full notes data for when the widget opens the app
      final notesJson =
          json.encode(_notes.map((note) => note.toJson()).toList());
      await HomeWidget.saveWidgetData('daily_notes_data', notesJson);

      // Update widget
      await HomeWidget.updateWidget(
        androidName: 'DailyNotesWidget',
        iOSName: 'DailyNotesWidget',
      );

      debugPrint('Widget updated with notes data');
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }

  void _addNewNote() {
    setState(() {
      _notes.add(NoteData(
          id: DateTime.now().millisecondsSinceEpoch.toString(), text: ''));
    });
    _saveNotes();
  }

  void _deleteNote(int index) {
    if (_notes.length > 1) {
      setState(() {
        _notes.removeAt(index);
      });
      _saveNotes();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must have at least one note')),
      );
    }
  }

  void _resetNote(int index) {
    setState(() {
      _notes[index].text = '';
    });
    _saveNotes();
  }

  void _updateNoteText(int index, String text) {
    _notes[index].text = text;
    _saveNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Notes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download Notes',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saving notes feature enabled')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Update Widget',
            onPressed: () async {
              await _updateWidget();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Widget updated')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Daily Notes',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _notes.length,
                      itemBuilder: (context, index) {
                        return _buildNoteCard(_notes[index], index);
                      },
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: IconButton(
                        iconSize: 40,
                        icon: const Icon(Icons.add_circle),
                        color: const Color.from(
                            alpha: 1, red: 0.129, green: 0.588, blue: 0.953),
                        onPressed: _addNewNote,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your notes are displayed on your home screen widget',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNoteCard(NoteData note, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: const DecorationImage(
            image: AssetImage('assets/Activity_Tools/daily-notes.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: TextEditingController(text: note.text),
                          onChanged: (text) => _updateNoteText(index, text),
                          maxLines: 12,
                          minLines: 8,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Enter text here...',
                            hintStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 40,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child:
                      const Icon(Icons.refresh, color: Colors.white, size: 16),
                ),
                onPressed: () => _resetNote(index),
                tooltip: 'Reset',
              ),
            ),
            Positioned(
              top: 8,
              right: 4,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child:
                      const Icon(Icons.delete, color: Colors.white, size: 16),
                ),
                onPressed: () => _deleteNote(index),
                tooltip: 'Delete',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoteData {
  final String id;
  String text;

  NoteData({required this.id, required this.text});

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
      };

  factory NoteData.fromJson(Map<String, dynamic> json) {
    return NoteData(
      id: json['id'] as String,
      text: json['text'] as String,
    );
  }
}
