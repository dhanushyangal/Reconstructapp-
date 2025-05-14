import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
    } catch (e) {
      debugPrint('Error saving notes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save notes: $e')),
      );
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
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF7520), Color(0xFFFF8C42)],
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
                      const RotatedBox(
                        quarterTurns: -1,
                        child: Text(
                          'Notes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
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
