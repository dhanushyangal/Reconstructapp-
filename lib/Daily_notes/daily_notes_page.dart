import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui' as ui;
import '../services/notes_service.dart';
import '../services/user_service.dart';

class DailyNotesPage extends StatefulWidget {
  static const routeName = '/daily-notes';

  const DailyNotesPage({Key? key}) : super(key: key);

  @override
  State<DailyNotesPage> createState() => _DailyNotesPageState();
}

class _DailyNotesPageState extends State<DailyNotesPage> {
  List<NoteData> _notes = [];
  List<NoteData> _filteredNotes = [];
  bool _isLoading = true;
  bool _isGridView = true;
  TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final NotesService _notesService = NotesService.instance;
  Map<String, String>? _userInfo;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadNotes();

    // Initialize HomeWidget
    HomeWidget.setAppGroupId('group.com.reconstrect.visionboard');
    HomeWidget.registerBackgroundCallback(backgroundCallback);

    // Set up method channel for widget interactions
    const platform = MethodChannel('com.reconstrect.visionboard/widget');
    platform.setMethodCallHandler(_handleMethodCall);

    _searchController.addListener(_filterNotes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterNotes() async {
    if (_searchController.text.isEmpty) {
      setState(() {
        _filteredNotes = List.from(_notes);
        _isSearching = false;
      });
      return;
    }

    if (_userInfo != null &&
        _userInfo!['userName']!.isNotEmpty &&
        _userInfo!['email']!.isNotEmpty) {
      try {
        final result = await _notesService.searchNotes(
          userName: _userInfo!['userName']!,
          email: _userInfo!['email']!,
          query: _searchController.text,
        );

        if (result['success'] == true) {
          final List<dynamic> dbNotes = result['data'] ?? [];
          setState(() {
            _isSearching = true;
            _filteredNotes = dbNotes.map((dbNote) {
              final noteData = _notesService.convertDbNoteToNoteData(dbNote);
              return NoteData(
                id: noteData['id'],
                title: noteData['title'],
                content: noteData['content'],
                color: Colors.white,
                lastEdited: noteData['lastEdited'],
                isPinned: noteData['isPinned'],
                checklistItems:
                    (noteData['checklistItems'] as List<Map<String, dynamic>>)
                        .map((item) => ChecklistItem(
                              id: item['id'],
                              text: item['text'],
                              isChecked: item['isChecked'],
                            ))
                        .toList(),
              );
            }).toList();
          });
        }
      } catch (e) {
        debugPrint('Error searching notes: $e');
        // Fallback to local search
        setState(() {
          _isSearching = true;
          _filteredNotes = _notes.where((note) {
            return note.title
                    .toLowerCase()
                    .contains(_searchController.text.toLowerCase()) ||
                note.content
                    .toLowerCase()
                    .contains(_searchController.text.toLowerCase()) ||
                note.checklistItems.any((item) => item.text
                    .toLowerCase()
                    .contains(_searchController.text.toLowerCase()));
          }).toList();
        });
      }
    } else {
      // Local search if user not logged in
      setState(() {
        _isSearching = true;
        _filteredNotes = _notes.where((note) {
          return note.title
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()) ||
              note.content
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()) ||
              note.checklistItems.any((item) => item.text
                  .toLowerCase()
                  .contains(_searchController.text.toLowerCase()));
        }).toList();
      });
    }
  }

  // Background callback for widget updates
  static Future<void> backgroundCallback(Uri? uri) async {
    if (uri?.host == 'updatewidget') {
      // Get data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? data = prefs.getString('daily_notes_data_legacy');

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

  Future<void> _initializeAndLoadNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user info first
      _userInfo = await UserService.instance.getUserInfo();

      if (_userInfo != null &&
          _userInfo!['userName']!.isNotEmpty &&
          _userInfo!['email']!.isNotEmpty) {
        await _loadNotesFromDatabase();
      } else {
        debugPrint('User not logged in, showing welcome note');
        _showWelcomeNote();
      }
    } catch (e) {
      debugPrint('Error initializing notes: $e');
      _showWelcomeNote();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNotesFromDatabase() async {
    try {
      final result = await _notesService.loadUserNotes(
        userName: _userInfo!['userName']!,
        email: _userInfo!['email']!,
      );

      if (result['success'] == true) {
        final List<dynamic> dbNotes = result['data'] ?? [];
        setState(() {
          _notes = dbNotes.map((dbNote) {
            final noteData = _notesService.convertDbNoteToNoteData(dbNote);
            return NoteData(
              id: noteData['id'],
              title: noteData['title'],
              content: noteData['content'],
              color: Colors.white,
              lastEdited: noteData['lastEdited'],
              isPinned: noteData['isPinned'],
              checklistItems:
                  (noteData['checklistItems'] as List<Map<String, dynamic>>)
                      .map((item) => ChecklistItem(
                            id: item['id'],
                            text: item['text'],
                            isChecked: item['isChecked'],
                          ))
                      .toList(),
            );
          }).toList();
          _filteredNotes = List.from(_notes);
        });

        // Update widget with latest data
        await _updateWidget();
        debugPrint('Loaded ${_notes.length} notes from database');
      } else {
        debugPrint('Failed to load notes: ${result['message']}');
        _showWelcomeNote();
      }
    } catch (e) {
      debugPrint('Error loading notes from database: $e');
      _showWelcomeNote();
    }
  }

  void _showWelcomeNote() {
    setState(() {
      _notes = [
        NoteData(
          id: const Uuid().v4(),
          title: 'Welcome to Notes!',
          content: 'Tap to edit this note or create a new one.',
          color: Colors.white,
          lastEdited: DateTime.now(),
        )
      ];
      _filteredNotes = List.from(_notes);
    });
  }

  Future<void> _saveNoteToDatabase(NoteData note, {bool isNew = false}) async {
    try {
      if (_userInfo == null ||
          _userInfo!['userName']!.isEmpty ||
          _userInfo!['email']!.isEmpty) {
        debugPrint('Cannot save note: User not logged in');
        return;
      }

      String noteType = 'text';
      if (note.checklistItems.isNotEmpty) {
        noteType = 'checklist';
      }

      // Convert checklist items to database format
      final checklistItems = note.checklistItems
          .map((item) => {
                'text': item.text,
                'isChecked': item.isChecked,
              })
          .toList();

      // Check if this is truly a new note (UUID format) or existing (numeric ID)
      bool isActuallyNew = isNew || !RegExp(r'^\d+$').hasMatch(note.id);

      Map<String, dynamic> result;
      if (isActuallyNew) {
        // Only create new note if title or content is not empty
        if (note.title.trim().isEmpty &&
            note.content.trim().isEmpty &&
            note.checklistItems.isEmpty) {
          debugPrint('Skipping save: Note is empty');
          return;
        }

        result = await _notesService.saveNote(
          userName: _userInfo!['userName']!,
          email: _userInfo!['email']!,
          title: note.title,
          content: note.content,
          noteType: noteType,
          isPinned: note.isPinned,
          checklistItems: checklistItems,
          imagePath: note.imagePath,
        );
      } else {
        result = await _notesService.updateNote(
          noteId: int.parse(note.id),
          userName: _userInfo!['userName']!,
          email: _userInfo!['email']!,
          title: note.title,
          content: note.content,
          noteType: noteType,
          isPinned: note.isPinned,
          checklistItems: checklistItems,
          imagePath: note.imagePath,
        );
      }

      if (result['success'] == true) {
        if (isActuallyNew && result['data'] != null) {
          // Update the note ID with the database-generated ID
          final newId = result['data']['id'].toString();
          debugPrint('Note ID updated from ${note.id} to $newId');
          note.id = newId;
        }
        // Update widget when notes are saved
        await _updateWidget();
        debugPrint('Note saved successfully to database');
      } else {
        debugPrint('Failed to save note: ${result['message']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to save note: ${result['message']}')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving note to database: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save note: $e')),
        );
      }
    }
  }

  // Update the widget with latest notes data
  Future<void> _updateWidget() async {
    try {
      // Get the most important note to display (pinned or most recent)
      NoteData? noteToDisplay;
      String displayText = '';

      // First try to find a pinned note
      if (_notes.isNotEmpty) {
        noteToDisplay = _notes.firstWhere((note) => note.isPinned,
            orElse: () => _notes.first);
      }

      if (noteToDisplay != null) {
        // Format note for display
        if (noteToDisplay.title.isNotEmpty) {
          displayText = noteToDisplay.title;
          if (noteToDisplay.content.isNotEmpty) {
            displayText +=
                '\n${noteToDisplay.content.length > 80 ? '${noteToDisplay.content.substring(0, 80)}...' : noteToDisplay.content}';
          }
        } else if (noteToDisplay.content.isNotEmpty) {
          displayText = noteToDisplay.content.length > 100
              ? '${noteToDisplay.content.substring(0, 100)}...'
              : noteToDisplay.content;
        } else if (noteToDisplay.checklistItems.isNotEmpty) {
          displayText =
              '📋 Checklist with ${noteToDisplay.checklistItems.length} items';
        } else {
          displayText = 'Tap to add notes...';
        }
      } else {
        displayText = 'Tap to add notes...';
      }

      // Save the display text to the widget
      await HomeWidget.saveWidgetData('daily_notes_display_text', displayText);

      // Save simplified notes data for widget (just IDs and titles)
      final widgetData = _notes
          .take(5)
          .map((note) => {
                'id': note.id,
                'title': note.title.isNotEmpty ? note.title : 'Untitled',
                'isPinned': note.isPinned,
              })
          .toList();
      await HomeWidget.saveWidgetData(
          'daily_notes_data', json.encode(widgetData));

      // Update widget
      await HomeWidget.updateWidget(
        androidName: 'DailyNotesWidget',
        iOSName: 'DailyNotesWidget',
      );

      debugPrint('Widget updated with notes data: $displayText');
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }

  void _createNewNote() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Create new',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.text_fields),
            title: const Text('Text note'),
            onTap: () {
              Navigator.pop(context);
              _showNoteEditor(
                NoteData(
                  id: const Uuid().v4(),
                  title: '',
                  content: '',
                  color: Colors.white,
                  lastEdited: DateTime.now(),
                ),
                isNew: true,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_box_outlined),
            title: const Text('Checklist'),
            onTap: () {
              Navigator.pop(context);
              // Create a note with checklist item already added
              final note = NoteData(
                id: const Uuid().v4(),
                title: '',
                content: '',
                color: Colors.white,
                lastEdited: DateTime.now(),
              );
              note.checklistItems.add(ChecklistItem(
                id: const Uuid().v4(),
                text: '',
                isChecked: false,
              ));
              _showNoteEditor(note, isNew: true);
            },
          ),
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Note with image'),
            onTap: () async {
              Navigator.pop(context);
              // Create a new note
              final note = NoteData(
                id: const Uuid().v4(),
                title: '',
                content: '',
                color: Colors.white,
                lastEdited: DateTime.now(),
              );

              // Create the editor and show image picker immediately
              final imagePicker = ImagePicker();
              try {
                final pickedFile =
                    await imagePicker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  // Copy image to app directory
                  final directory = await getApplicationDocumentsDirectory();
                  final fileName =
                      '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
                  final savedImagePath = '${directory.path}/$fileName';

                  final File imageFile = File(pickedFile.path);
                  await imageFile.copy(savedImagePath);

                  note.imagePath = savedImagePath;
                }
              } catch (e) {
                debugPrint('Error picking image: $e');
              }

              // Show the editor with or without the image
              _showNoteEditor(note, isNew: true);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _editNote(NoteData note) {
    _showNoteEditor(note);
  }

  void _showNoteEditor(NoteData note, {bool isNew = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(
          note: note,
          onSave: (updatedNote) {
            setState(() {
              // Handle new notes
              if (isNew) {
                // If this is a new note and it's empty, don't add it
                if (updatedNote.title.isEmpty &&
                    updatedNote.content.isEmpty &&
                    updatedNote.checklistItems.isEmpty &&
                    updatedNote.imagePath == null) {
                  return; // Skip saving empty notes
                }

                // Check for duplicates before adding
                if (!_notes.any((n) => n.id == updatedNote.id)) {
                  _notes.add(updatedNote);
                }
              } else {
                // Update existing note
                final index = _notes.indexWhere((n) => n.id == updatedNote.id);
                if (index != -1) {
                  _notes[index] = updatedNote;
                }
              }

              // Sort notes - pinned first, then by last edited date
              _notes.sort((a, b) {
                if (a.isPinned && !b.isPinned) return -1;
                if (!a.isPinned && b.isPinned) return 1;
                return b.lastEdited.compareTo(a.lastEdited);
              });

              _filterNotes();
            });
            _saveNoteToDatabase(updatedNote);
          },
          onDelete: isNew
              ? null
              : (noteId) async {
                  try {
                    if (_userInfo != null) {
                      final result = await _notesService.deleteNote(
                        noteId: int.parse(noteId),
                        userName: _userInfo!['userName']!,
                        email: _userInfo!['email']!,
                      );

                      if (result['success'] == true) {
                        setState(() {
                          _notes.removeWhere((n) => n.id == noteId);
                          _filterNotes();
                        });
                      }
                    }
                  } catch (e) {
                    debugPrint('Error deleting note: $e');
                  }
                  Navigator.of(context).pop();
                },
        ),
      ),
    );
  }

  // Handle method calls from the native side
  Future<void> _handleMethodCall(MethodCall call) async {
    if (call.method == 'openDailyNotes') {
      final args = call.arguments as Map<dynamic, dynamic>;
      final createNew = args['create_new'] as bool? ?? false;

      if (createNew) {
        // Small delay to ensure the UI is ready
        await Future.delayed(const Duration(milliseconds: 300));
        _createNewNote();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                ),
                autofocus: true,
                style: TextStyle(color: Colors.grey.shade800),
              )
            : Text(
                'Notes',
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 20,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.grey.shade600,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list : Icons.grid_view,
              color: Colors.grey.shade600,
            ),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildNotesView(),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewNote,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNotesView() {
    if (_filteredNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _isSearching ? 'No matching notes' : 'No notes yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            if (!_isSearching) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Create your first note'),
                onPressed: _createNewNote,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (_isGridView) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: MasonryGridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          itemCount: _filteredNotes.length,
          itemBuilder: (context, index) {
            return _buildNoteCard(_filteredNotes[index]);
          },
        ),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(12.0),
        itemCount: _filteredNotes.length,
        itemBuilder: (context, index) {
          return _buildNoteCard(_filteredNotes[index], isGrid: false);
        },
      );
    }
  }

  Widget _buildNoteCard(NoteData note, {bool isGrid = true}) {
    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image if available
        if (note.imagePath != null && note.imagePath!.isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Image.file(
              File(note.imagePath!),
              fit: BoxFit.cover,
              width: double.infinity,
              height: 140,
            ),
          ),

        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title with pin indicator
              Row(
                children: [
                  if (note.title.isNotEmpty)
                    Expanded(
                      child: Text(
                        note.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),

              if (note.title.isNotEmpty) const SizedBox(height: 8),

              // Content
              if (note.content.isNotEmpty)
                Text(
                  note.content,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                  maxLines: isGrid ? 8 : 2,
                  overflow: TextOverflow.ellipsis,
                ),

              // Checklist items
              if (note.checklistItems.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: note.checklistItems
                      .take(isGrid ? 5 : 2)
                      .map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  item.isChecked
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.text,
                                    style: TextStyle(
                                      fontSize: 14,
                                      decoration: item.isChecked
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color:
                                          item.isChecked ? Colors.grey : null,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),

              if (note.checklistItems.length > (isGrid ? 5 : 2))
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '+ ${note.checklistItems.length - (isGrid ? 5 : 2)} more items',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),

              // Last edited date
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Edited ${_formatDate(note.lastEdited)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: () => _editNote(note),
      child: Stack(
        children: [
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: const DecorationImage(
                  image: AssetImage('assets/floral_weekly/floral_1.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white.withOpacity(0.1),
                ),
                child: cardContent,
              ),
            ),
          ),
          // Quick action buttons - positioned at the top-right corner
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Pin button
                Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: Icon(
                      note.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      setState(() {
                        note.isPinned = !note.isPinned;
                        // Sort notes - pinned first, then by last edited date
                        _notes.sort((a, b) {
                          if (a.isPinned && !b.isPinned) return -1;
                          if (!a.isPinned && b.isPinned) return 1;
                          return b.lastEdited.compareTo(a.lastEdited);
                        });
                        _filterNotes();
                      });
                      _saveNoteToDatabase(note);
                    },
                    tooltip: note.isPinned ? 'Unpin' : 'Pin',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ),
                // Delete button
                Material(
                  color: Colors.transparent,
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.grey.shade600,
                    ),
                    onPressed: () {
                      // Show confirmation dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete note?'),
                          content: const Text('This action cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('CANCEL'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                setState(() {
                                  _notes.removeWhere((n) => n.id == note.id);
                                  _filterNotes();
                                });
                                // Delete from database
                                if (_userInfo != null) {
                                  _notesService.deleteNote(
                                    noteId: int.parse(note.id),
                                    userName: _userInfo!['userName']!,
                                    email: _userInfo!['email']!,
                                  );
                                }
                              },
                              child: const Text('DELETE'),
                            ),
                          ],
                        ),
                      );
                    },
                    tooltip: 'Delete',
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${DateFormat('h:mm a').format(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(date); // Day name
    } else {
      return DateFormat('MMM d').format(date); // Month and day
    }
  }
}

class NoteEditorPage extends StatefulWidget {
  final NoteData note;
  final Function(NoteData) onSave;
  final Function(String)? onDelete;

  const NoteEditorPage({
    Key? key,
    required this.note,
    required this.onSave,
    this.onDelete,
  }) : super(key: key);

  @override
  _NoteEditorPageState createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late NoteData _editedNote;
  final _imagePicker = ImagePicker();
  bool _isChecklistMode = false;
  Timer? _autoSaveTimer;
  bool _isSaving = false;

  // Map to store persistent controllers for checklist items
  final Map<String, TextEditingController> _checklistControllers = {};

  @override
  void initState() {
    super.initState();
    _editedNote = widget.note.copy();
    _titleController = TextEditingController(text: _editedNote.title);
    _contentController = TextEditingController(text: _editedNote.content);

    // If note has checklist items, switch to checklist mode
    if (_editedNote.checklistItems.isNotEmpty) {
      _isChecklistMode = true;
    }

    // Set up auto-save listeners
    _titleController.addListener(_scheduleAutoSave);
    _contentController.addListener(_scheduleAutoSave);
  }

  @override
  void dispose() {
    _titleController.removeListener(_scheduleAutoSave);
    _contentController.removeListener(_scheduleAutoSave);
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();

    // Dispose all checklist controllers
    for (var controller in _checklistControllers.values) {
      controller.dispose();
    }
    _checklistControllers.clear();

    super.dispose();
  }

  void _scheduleAutoSave() {
    if (_isSaving) return; // Don't schedule if already saving

    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), _autoSave);
  }

  void _autoSave() {
    if (_isSaving) return; // Prevent duplicate saves

    _isSaving = true; // Set flag to indicate saving in progress

    try {
      // Update content from controllers
      _editedNote.title = _titleController.text.trim();
      _editedNote.content = _contentController.text.trim();
      _editedNote.lastEdited = DateTime.now();

      // Save the updated note
      widget.onSave(_editedNote);
    } finally {
      // Add a small delay before allowing new saves to prevent rapid succession
      Future.delayed(const Duration(milliseconds: 100), () {
        _isSaving = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile =
          await _imagePicker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        // Copy image to app directory
        final directory = await getApplicationDocumentsDirectory();
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
        final savedImagePath = '${directory.path}/$fileName';

        final File imageFile = File(pickedFile.path);
        await imageFile.copy(savedImagePath);

        setState(() {
          _editedNote.imagePath = savedImagePath;
        });
        _scheduleAutoSave(); // Schedule save after adding image
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  void _addChecklistItem() {
    setState(() {
      _editedNote.checklistItems.add(ChecklistItem(
        id: const Uuid().v4(),
        text: '',
        isChecked: false,
      ));
    });
    _scheduleAutoSave(); // Schedule save after adding checklist item
  }

  void _updateChecklistItem(String id, {String? text, bool? isChecked}) {
    setState(() {
      final index =
          _editedNote.checklistItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        if (text != null) {
          _editedNote.checklistItems[index].text = text;
        }
        if (isChecked != null) {
          _editedNote.checklistItems[index].isChecked = isChecked;
        }
      }
    });
    if (isChecked != null) {
      _scheduleAutoSave(); // Schedule save when checkbox is toggled
    }
    // Text changes will trigger auto-save via the timer
  }

  void _removeChecklistItem(String id) {
    setState(() {
      _editedNote.checklistItems.removeWhere((item) => item.id == id);
    });
    _scheduleAutoSave(); // Schedule save after removing checklist item
  }

  void _convertToChecklist() {
    // Convert text content to checklist items
    final contentLines = _contentController.text
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    setState(() {
      _isChecklistMode = true;

      // Create checklist items from content if any
      if (contentLines.isNotEmpty) {
        _editedNote.checklistItems = contentLines
            .map((line) => ChecklistItem(
                  id: const Uuid().v4(),
                  text: line.trim(),
                  isChecked: false,
                ))
            .toList();
        _contentController.clear();
      } else if (_editedNote.checklistItems.isEmpty) {
        // Add an empty item if no content and no existing items
        _editedNote.checklistItems.add(ChecklistItem(
          id: const Uuid().v4(),
          text: '',
          isChecked: false,
        ));
      }
    });
  }

  void _convertToText() {
    // Convert checklist items to text
    if (_editedNote.checklistItems.isNotEmpty) {
      final StringBuffer contentBuffer = StringBuffer();

      for (var item in _editedNote.checklistItems) {
        if (item.text.trim().isNotEmpty) {
          if (contentBuffer.isNotEmpty) {
            contentBuffer.write('\n');
          }
          contentBuffer.write(item.text);
        }
      }

      setState(() {
        _contentController.text = contentBuffer.toString();
        _isChecklistMode = false;
        _editedNote.checklistItems = [];
      });
    } else {
      setState(() {
        _isChecklistMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _autoSave();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(
            color: Colors.grey.shade800,
          ),
          actions: [
            IconButton(
              icon: Icon(
                _editedNote.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              ),
              onPressed: () {
                setState(() {
                  _editedNote.isPinned = !_editedNote.isPinned;
                  _autoSave();
                });
              },
              tooltip: _editedNote.isPinned ? 'Unpin' : 'Pin',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'delete':
                    if (widget.onDelete != null) {
                      widget.onDelete!(_editedNote.id);
                    }
                    break;
                  case 'image':
                    _pickImage();
                    break;
                  case 'convert_to_checklist':
                    _convertToChecklist();
                    break;
                  case 'convert_to_text':
                    _convertToText();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (!_isChecklistMode)
                  const PopupMenuItem(
                    value: 'convert_to_checklist',
                    child: Row(
                      children: [
                        Icon(Icons.check_box_outlined),
                        SizedBox(width: 8),
                        Text('Convert to checklist'),
                      ],
                    ),
                  ),
                if (_isChecklistMode)
                  const PopupMenuItem(
                    value: 'convert_to_text',
                    child: Row(
                      children: [
                        Icon(Icons.subject),
                        SizedBox(width: 8),
                        Text('Convert to text'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'image',
                  child: Row(
                    children: [
                      Icon(Icons.image),
                      SizedBox(width: 8),
                      Text('Add image'),
                    ],
                  ),
                ),
                if (widget.onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            // Background image fills the whole screen
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/floral_weekly/floral_1.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Semi-transparent overlay (optional, for readability)
            Container(
              color: Colors.white.withOpacity(0.1),
            ),
            // The scrollable content
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image preview
                  if (_editedNote.imagePath != null &&
                      _editedNote.imagePath!.isNotEmpty)
                    Stack(
                      children: [
                        Image.file(
                          File(_editedNote.imagePath!),
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            radius: 16,
                            child: IconButton(
                              icon: const Icon(Icons.close,
                                  size: 16, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _editedNote.imagePath = null;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Title field
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Content - either text or checklist
                  if (!_isChecklistMode)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          hintText: 'Note',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 16),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Checklist items
                          for (var i = 0;
                              i < _editedNote.checklistItems.length;
                              i++)
                            _buildChecklistItem(_editedNote.checklistItems[i]),

                          // Add item button
                          TextButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add item'),
                            onPressed: _addChecklistItem,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(ChecklistItem item) {
    // Get or create a persistent controller for this item
    if (!_checklistControllers.containsKey(item.id)) {
      _checklistControllers[item.id] = TextEditingController(text: item.text);

      // Add listener only once when controller is created
      _checklistControllers[item.id]!.addListener(() {
        if (_checklistControllers[item.id]!.text != item.text) {
          _updateChecklistItem(item.id,
              text: _checklistControllers[item.id]!.text);
        }
      });
    } else if (_checklistControllers[item.id]!.text != item.text) {
      // Update controller text if it doesn't match item text (avoid cursor jumps)
      _checklistControllers[item.id]!.value = TextEditingValue(
        text: item.text,
        selection: _checklistControllers[item.id]!.selection,
      );
    }

    final textController = _checklistControllers[item.id]!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          Checkbox(
            value: item.isChecked,
            onChanged: (value) {
              if (value != null) {
                _updateChecklistItem(item.id, isChecked: value);
              }
            },
          ),
          // Text field
          Expanded(
            child: TextField(
              controller: textController,
              textDirection:
                  ui.TextDirection.ltr, // Explicitly set text direction
              decoration: const InputDecoration(
                hintText: 'List item',
                border: InputBorder.none,
              ),
              style: TextStyle(
                fontSize: 16,
                decoration: item.isChecked ? TextDecoration.lineThrough : null,
                color: item.isChecked ? Colors.grey : null,
              ),
            ),
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => _removeChecklistItem(item.id),
          ),
        ],
      ),
    );
  }
}

class NoteData {
  String id;
  String title;
  String content;
  String? imagePath;
  Color color;
  List<ChecklistItem> checklistItems;
  bool isPinned;
  DateTime lastEdited;

  NoteData({
    required this.id,
    this.title = '',
    this.content = '',
    this.imagePath,
    this.color = Colors.white,
    List<ChecklistItem>? checklistItems,
    this.isPinned = false,
    required this.lastEdited,
  }) : checklistItems = checklistItems ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'imagePath': imagePath,
        'colorValue': color.value,
        'checklistItems': checklistItems.map((item) => item.toJson()).toList(),
        'isPinned': isPinned,
        'lastEdited': lastEdited.toIso8601String(),
      };

  factory NoteData.fromJson(Map<String, dynamic> json) {
    return NoteData(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      imagePath: json['imagePath'] as String?,
      color: Color(json['colorValue'] as int? ?? 0xFFFFFFFF),
      checklistItems: (json['checklistItems'] as List<dynamic>?)
              ?.map((item) => ChecklistItem.fromJson(item))
              .toList() ??
          [],
      isPinned: json['isPinned'] as bool? ?? false,
      lastEdited: json['lastEdited'] != null
          ? DateTime.parse(json['lastEdited'] as String)
          : DateTime.now(),
    );
  }

  NoteData copy() {
    return NoteData(
      id: id,
      title: title,
      content: content,
      imagePath: imagePath,
      color: color,
      checklistItems: checklistItems.map((item) => item.copy()).toList(),
      isPinned: isPinned,
      lastEdited: lastEdited,
    );
  }
}

class ChecklistItem {
  final String id;
  String text;
  bool isChecked;

  ChecklistItem({
    required this.id,
    required this.text,
    required this.isChecked,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isChecked': isChecked,
      };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String,
      text: json['text'] as String,
      isChecked: json['isChecked'] as bool,
    );
  }

  ChecklistItem copy() {
    return ChecklistItem(
      id: id,
      text: text,
      isChecked: isChecked,
    );
  }
}
