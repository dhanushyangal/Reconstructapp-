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

  const DailyNotesPage({super.key});

  @override
  State<DailyNotesPage> createState() => _DailyNotesPageState();
}

class _DailyNotesPageState extends State<DailyNotesPage> {
  List<NoteData> _notes = [];
  List<NoteData> _filteredNotes = [];
  bool _isLoading = true;
  bool _isGridView = true;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  final NotesService _notesService = NotesService.instance;
  Map<String, String>? _userInfo;
  String? _currentWidgetNoteId;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadNotes();
    _loadCurrentWidgetNoteId();

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

  Future<void> _loadCurrentWidgetNoteId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _currentWidgetNoteId = prefs.getString('widget_selected_note_id');
      });
    } catch (e) {
      debugPrint('Error loading current widget note ID: $e');
    }
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

        debugPrint('Loaded ${_notes.length} notes from database');

        // Update widget with latest data immediately after loading
        await _updateWidget();

        // Also trigger a delayed update to ensure widget refreshes properly
        await Future.delayed(Duration(milliseconds: 500));
        await _updateWidget();

        debugPrint('Widget updated with database notes');
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

    // Update widget with welcome note data
    _updateWidget();
  }

  Future<void> _saveNoteToDatabase(NoteData note, {bool isNew = false}) async {
    try {
      if (_userInfo == null ||
          _userInfo!['userName']!.isEmpty ||
          _userInfo!['email']!.isEmpty) {
        debugPrint('Cannot save note: User not logged in');
        throw Exception('User not logged in. Please log in to save notes.');
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

        // Reload notes from database to ensure widget has latest data
        if (_userInfo != null &&
            _userInfo!['userName']!.isNotEmpty &&
            _userInfo!['email']!.isNotEmpty) {
          await _loadNotesFromDatabase();
        } else {
          // Update widget when notes are saved
          await _updateWidget();
        }

        // Handle offline vs online save messaging
        if (result['isOffline'] == true) {
          debugPrint('Note saved offline: ${result['message']}');
        } else {
          debugPrint('Note saved successfully to database');
        }
      } else {
        final errorMessage = result['message'] ?? 'Unknown error occurred';
        debugPrint('Failed to save note: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Error saving note to database: $e');
      // Provide more user-friendly error messages
      String userMessage = e.toString();

      if (userMessage.contains('Failed host lookup') ||
          userMessage.contains('SocketException') ||
          userMessage.contains('NetworkException')) {
        userMessage =
            'No internet connection. Note will be saved offline and synced when connection is restored.';

        // Try to save offline as a fallback
        try {
          String fallbackNoteType = 'text';
          if (note.checklistItems.isNotEmpty) {
            fallbackNoteType = 'checklist';
          }

          final fallbackChecklistItems = note.checklistItems
              .map((item) => {
                    'text': item.text,
                    'isChecked': item.isChecked,
                  })
              .toList();

          final result = await _notesService.saveNote(
            userName: _userInfo!['userName']!,
            email: _userInfo!['email']!,
            title: note.title,
            content: note.content,
            noteType: fallbackNoteType,
            isPinned: note.isPinned,
            checklistItems: fallbackChecklistItems,
            imagePath: note.imagePath,
          );

          if (result['success'] == true && result['isOffline'] == true) {
            debugPrint('Note saved offline as fallback');
            await _updateWidget();
            return; // Success - saved offline
          }
        } catch (offlineError) {
          debugPrint('Failed to save offline as fallback: $offlineError');
        }
      } else if (userMessage.contains('AuthRetryableFetchException')) {
        userMessage =
            'Authentication error. Please check your internet connection and try again.';
      }

      throw Exception(userMessage);
    }
  }

  // Update the widget with latest notes data
  Future<void> _updateWidget() async {
    try {
      debugPrint('=== WIDGET UPDATE DEBUG ===');
      debugPrint('Total notes to update: ${_notes.length}');

      // Ensure we have notes to save
      if (_notes.isEmpty) {
        debugPrint('No notes available to save to widget');
        await HomeWidget.saveWidgetData('daily_notes_data', '[]');
        await HomeWidget.saveWidgetData(
            'daily_notes_display_text', 'No notes available');

        // Also save to Android SharedPreferences with correct keys
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('flutter.daily_notes_data', '[]');
        await prefs.setString(
            'flutter.daily_notes_display_text', 'No notes available');
        return;
      }

      // Save comprehensive notes data for widget configuration
      final widgetData = _notes.map((note) {
        final noteData = {
          'id': note.id,
          'title': note.title,
          'content': note.content,
          'isPinned': note.isPinned,
          'lastEdited': note.lastEdited.toIso8601String(),
          'imagePath': note.imagePath,
          'colorValue': note.color.value,
          'checklistItems': note.checklistItems
              .map((item) => {
                    'id': item.id,
                    'text': item.text,
                    'isChecked': item.isChecked,
                  })
              .toList(),
        };

        debugPrint(
            'Note ${note.id}: "${note.title}" - ${note.content.length} chars, ${note.checklistItems.length} checklist items');
        return noteData;
      }).toList();

      final widgetDataJson = json.encode(widgetData);

      // Save to HomeWidget (for iOS and some Android functionality)
      await HomeWidget.saveWidgetData('daily_notes_data', widgetDataJson);
      debugPrint('HomeWidget data saved: ${widgetDataJson.length} characters');

      // Generate display text for fallback scenarios
      String displayText = 'Tap to add notes...';
      if (_notes.isNotEmpty) {
        final noteToDisplay = _notes.firstWhere((note) => note.isPinned,
            orElse: () => _notes.first);

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
              'Checklist with ${noteToDisplay.checklistItems.length} items';
        }
      }

      await HomeWidget.saveWidgetData('daily_notes_display_text', displayText);
      debugPrint('HomeWidget display text saved: "$displayText"');

      // CRITICAL: Save to Android SharedPreferences with the EXACT keys the widget expects
      final prefs = await SharedPreferences.getInstance();

      // Save with flutter. prefix (FlutterSharedPreferences format)
      await prefs.setString('flutter.daily_notes_data', widgetDataJson);
      await prefs.setString('flutter.daily_notes_display_text', displayText);

      // ALSO save without flutter. prefix in case widget expects that
      await prefs.setString('daily_notes_data', widgetDataJson);
      await prefs.setString('daily_notes_display_text', displayText);

      debugPrint(
          'SharedPreferences data saved with both flutter. and without prefix');
      debugPrint('Data length: ${widgetDataJson.length} characters');

      // Verify data was saved correctly
      final savedFlutterData = prefs.getString('flutter.daily_notes_data');
      final savedDirectData = prefs.getString('daily_notes_data');
      debugPrint(
          'Verification - Flutter prefixed data: ${savedFlutterData != null && savedFlutterData.isNotEmpty}');
      debugPrint(
          'Verification - Direct data: ${savedDirectData != null && savedDirectData.isNotEmpty}');

      // Force immediate widget update on Android using platform channel
      if (Platform.isAndroid) {
        try {
          const platform = MethodChannel('com.reconstrect.visionboard/widget');

          // First, sync the data directly to Android SharedPreferences
          await platform.invokeMethod('syncWidgetData', {
            'notesData': widgetDataJson,
            'displayText': displayText,
            'selectedNoteId': _currentWidgetNoteId,
          });
          debugPrint('Widget data synced to Android SharedPreferences');

          // Then force widget update
          await platform.invokeMethod('forceWidgetUpdate');
          debugPrint('Android platform channel widget update triggered');
        } catch (e) {
          debugPrint('Error with Android platform channel: $e');
        }
      }

      // Update widget with multiple attempts to ensure it works
      await HomeWidget.updateWidget(
        androidName: 'DailyNotesWidget',
        iOSName: 'DailyNotesWidget',
      );

      debugPrint('Widget update completed with ${_notes.length} notes');
    } catch (e) {
      debugPrint('Error updating widget: $e');
    }
  }

  // Manual widget refresh method for debugging
  Future<void> _manualRefreshWidget() async {
    try {
      debugPrint('=== MANUAL WIDGET REFRESH ===');
      debugPrint('Current notes count: ${_notes.length}');

      // Force reload notes from database
      if (_userInfo != null &&
          _userInfo!['userName']!.isNotEmpty &&
          _userInfo!['email']!.isNotEmpty) {
        await _loadNotesFromDatabase();
      }

      // Update widget
      await _updateWidget();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Widget refreshed with ${_notes.length} notes'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error in manual widget refresh: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh widget: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
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
          onSave: (updatedNote) async {
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
            await _saveNoteToDatabase(updatedNote, isNew: isNew);
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

                        // Update widget after successful deletion
                        await _updateWidget();
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

  Future<void> _syncOfflineNotes() async {
    try {
      if (_userInfo == null ||
          _userInfo!['userName']!.isEmpty ||
          _userInfo!['email']!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to sync notes'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 16),
              Text('Syncing offline notes...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      final success = await _notesService.syncOfflineNotes(
        userName: _userInfo!['userName']!,
        email: _userInfo!['email']!,
      );

      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (success) {
        // Reload notes after successful sync
        await _loadNotesFromDatabase();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notes synced successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Unable to sync - please check your internet connection'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _addNoteToWidget(NoteData note) async {
    try {
      debugPrint('=== WIDGET SELECTION DEBUG ===');
      debugPrint('Adding note to widget: ${note.id}');
      debugPrint('Note title: "${note.title}"');
      debugPrint('Note content length: ${note.content.length}');
      debugPrint('Note has ${note.checklistItems.length} checklist items');

      // First, ensure widget data is up to date with all notes
      await _updateWidget();

      // Store the note as the selected widget note using both HomeWidget and SharedPreferences
      await HomeWidget.saveWidgetData('widget_selected_note_id', note.id);

      // CRITICAL: Save to the exact SharedPreferences key the Android widget expects
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('flutter.widget_selected_note_id', note.id);
      await prefs.setString('widget_selected_note_id',
          note.id); // Also save without flutter prefix

      // Update local state
      setState(() {
        _currentWidgetNoteId = note.id;
      });

      debugPrint('Widget selected note ID saved: ${note.id}');
      debugPrint(
          'Saved to flutter.widget_selected_note_id and widget_selected_note_id');

      // Trigger an immediate data refresh to ensure everything is synced
      await _updateWidget();

      // Force immediate widget update on Android using platform channel
      if (Platform.isAndroid) {
        try {
          const platform = MethodChannel('com.reconstrect.visionboard/widget');

          // First, sync the widget data including the selected note ID
          final currentNotesData =
              prefs.getString('flutter.daily_notes_data') ?? '[]';
          final currentDisplayText =
              prefs.getString('flutter.daily_notes_display_text') ??
                  'Tap to add notes...';

          await platform.invokeMethod('syncWidgetData', {
            'notesData': currentNotesData,
            'displayText': currentDisplayText,
            'selectedNoteId': note.id,
          });
          debugPrint(
              'Widget data with selected note synced to Android SharedPreferences');

          // Then force widget update
          await platform.invokeMethod('forceWidgetUpdate');
          debugPrint('Android platform channel widget update triggered');
        } catch (e) {
          debugPrint('Error with platform channel: $e');
        }
      }

      // Trigger widget update via home_widget with multiple attempts
      for (int i = 0; i < 3; i++) {
        await HomeWidget.updateWidget(
          androidName: 'DailyNotesWidget',
          iOSName: 'DailyNotesWidget',
        );
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
      }

      debugPrint('Widget updates completed');

      // Verify the data was saved correctly
      final savedHomeWidget =
          await HomeWidget.getWidgetData('daily_notes_data');
      final savedNoteId =
          await HomeWidget.getWidgetData('widget_selected_note_id');
      final savedFlutterPrefixNoteId =
          prefs.getString('flutter.widget_selected_note_id');
      debugPrint('Verification - Saved note ID (HomeWidget): $savedNoteId');
      debugPrint(
          'Verification - Saved note ID (flutter.prefix): $savedFlutterPrefixNoteId');
      debugPrint(
          'Verification - Widget data exists: ${savedHomeWidget != null}');

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.widgets, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '"${note.title.isNotEmpty ? note.title : 'Note'}" added to widget!',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () {
                // Go to home screen to see the widget
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding note to widget: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add note to widget: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _removeNoteFromWidget() async {
    try {
      // Remove the note from widget using HomeWidget to clear the flutter. prefixed key
      await HomeWidget.saveWidgetData('widget_selected_note_id', null);

      // Also remove locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('widget_selected_note_id');

      // Update local state
      setState(() {
        _currentWidgetNoteId = null;
      });

      // Update widget data
      await _updateWidget();

      // Force immediate widget update on Android using platform channel
      if (Platform.isAndroid) {
        try {
          const platform = MethodChannel('com.reconstrect.visionboard/widget');
          await platform.invokeMethod('forceWidgetUpdate');
        } catch (e) {
          debugPrint('Error with platform channel: $e');
        }
      }

      // Trigger widget update via home_widget
      await HomeWidget.updateWidget(
        androidName: 'DailyNotesWidget',
        iOSName: 'DailyNotesWidget',
      );

      // Show confirmation message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.widgets_outlined, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text(
                  'Note removed from widget',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error removing note from widget: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove note from widget: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Check current widget data for debugging
  Future<void> _checkWidgetData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check all possible keys the widget might be looking for
      final flutterNotesData = prefs.getString('flutter.daily_notes_data');
      final directNotesData = prefs.getString('daily_notes_data');
      final flutterDisplayText =
          prefs.getString('flutter.daily_notes_display_text');
      final directDisplayText = prefs.getString('daily_notes_display_text');
      final flutterSelectedNoteId =
          prefs.getString('flutter.widget_selected_note_id');
      final directSelectedNoteId = prefs.getString('widget_selected_note_id');

      // Also check HomeWidget data
      final homeWidgetNotesData =
          await HomeWidget.getWidgetData('daily_notes_data');
      final homeWidgetDisplayText =
          await HomeWidget.getWidgetData('daily_notes_display_text');
      final homeWidgetSelectedNoteId =
          await HomeWidget.getWidgetData('widget_selected_note_id');

      debugPrint('=== COMPLETE WIDGET DATA CHECK ===');
      debugPrint('--- SharedPreferences (flutter. prefix) ---');
      debugPrint(
          'flutter.daily_notes_data: ${flutterNotesData != null ? '${flutterNotesData.length} chars' : 'NULL'}');
      debugPrint('flutter.daily_notes_display_text: "$flutterDisplayText"');
      debugPrint('flutter.widget_selected_note_id: "$flutterSelectedNoteId"');

      debugPrint('--- SharedPreferences (direct) ---');
      debugPrint(
          'daily_notes_data: ${directNotesData != null ? '${directNotesData.length} chars' : 'NULL'}');
      debugPrint('daily_notes_display_text: "$directDisplayText"');
      debugPrint('widget_selected_note_id: "$directSelectedNoteId"');

      debugPrint('--- HomeWidget Data ---');
      debugPrint(
          'HomeWidget daily_notes_data: ${homeWidgetNotesData != null ? '${homeWidgetNotesData.length} chars' : 'NULL'}');
      debugPrint(
          'HomeWidget daily_notes_display_text: "$homeWidgetDisplayText"');
      debugPrint(
          'HomeWidget widget_selected_note_id: "$homeWidgetSelectedNoteId"');

      // Parse and show notes if available
      if (flutterNotesData != null) {
        try {
          final List<dynamic> notes = json.decode(flutterNotesData);
          debugPrint('--- Notes in flutter.daily_notes_data ---');
          debugPrint('Number of notes: ${notes.length}');
          for (int i = 0; i < notes.length; i++) {
            final note = notes[i];
            debugPrint(
                'Note $i: ID=${note['id']}, Title="${note['title']}", Content length=${note['content'].length}');
          }
        } catch (e) {
          debugPrint('Error parsing flutter notes data: $e');
        }
      }

      // Show summary to user
      String summary = 'Widget Debug:\n';
      summary +=
          'Flutter notes: ${flutterNotesData != null ? '✅ ${json.decode(flutterNotesData).length} notes' : '❌ No data'}\n';
      summary += 'Selected note: ${flutterSelectedNoteId ?? 'None'}\n';
      summary += 'HomeWidget data: ${homeWidgetNotesData != null ? '✅' : '❌'}';

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Widget Debug Info'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(summary),
                SizedBox(height: 16),
                Text('Options:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    // Test sync functionality
                    if (Platform.isAndroid && flutterNotesData != null) {
                      try {
                        const platform =
                            MethodChannel('com.reconstrect.visionboard/widget');
                        await platform.invokeMethod('syncWidgetData', {
                          'notesData': flutterNotesData,
                          'displayText': flutterDisplayText ?? 'Test sync',
                          'selectedNoteId': flutterSelectedNoteId,
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Manual sync completed! Check widget.'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sync failed: $e'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  },
                  child: Text('Force Sync to Widget'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking widget data: $e');
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
              Icons.info_outline,
              color: Colors.grey.shade600,
            ),
            onPressed: _checkWidgetData,
            tooltip: 'Check widget data',
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.grey.shade600,
            ),
            onPressed: _manualRefreshWidget,
            tooltip: 'Refresh widget',
          ),
          IconButton(
            icon: Icon(
              Icons.sync,
              color: Colors.grey.shade600,
            ),
            onPressed: _syncOfflineNotes,
          ),
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

        // Content section - no padding here since it's handled by the Stack
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with widget indicator
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
                // Widget indicator - simplified
                if (_currentWidgetNoteId == note.id)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(
                      'WIDGET',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade600,
                      ),
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
                                    color: item.isChecked ? Colors.grey : null,
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
      ],
    );

    return GestureDetector(
      onTap: () => _editNote(note),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
          image: DecorationImage(
            image: AssetImage('assets/floral_weekly/floral_1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // If note has an image, show it at the top
              if (note.imagePath != null && note.imagePath!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(
                    File(note.imagePath!),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 140,
                  ),
                ),
              // Overlay for readability
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row with WIDGET label
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            note.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_currentWidgetNoteId == note.id)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Text(
                              'WIDGET',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Action buttons row (widget, pin, delete)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(
                            _currentWidgetNoteId == note.id
                                ? Icons.widgets
                                : Icons.widgets_outlined,
                            size: 18,
                            color: _currentWidgetNoteId == note.id
                                ? Colors.green.shade600
                                : Colors.grey.shade600,
                          ),
                          onPressed: () => _currentWidgetNoteId == note.id
                              ? _removeNoteFromWidget()
                              : _addNoteToWidget(note),
                          tooltip: _currentWidgetNoteId == note.id
                              ? 'Remove from widget'
                              : 'Add to widget',
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          icon: Icon(
                            note.isPinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined,
                            size: 18,
                            color: note.isPinned
                                ? Colors.orange.shade600
                                : Colors.grey.shade600,
                          ),
                          onPressed: () {
                            setState(() {
                              note.isPinned = !note.isPinned;
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
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red.shade400,
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete note?'),
                                content:
                                    const Text('This action cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('CANCEL'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(context);
                                      setState(() {
                                        _notes.removeWhere(
                                            (n) => n.id == note.id);
                                        _filterNotes();
                                      });
                                      if (_userInfo != null) {
                                        try {
                                          await _notesService.deleteNote(
                                            noteId: int.parse(note.id),
                                            userName: _userInfo!['userName']!,
                                            email: _userInfo!['email']!,
                                          );
                                          await _updateWidget();
                                        } catch (e) {
                                          debugPrint('Error deleting note: $e');
                                        }
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
                      ],
                    ),
                    // Content
                    if (note.content.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          note.content,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: isGrid ? 8 : 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    // Checklist items
                    if (note.checklistItems.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: note.checklistItems
                              .take(isGrid ? 5 : 2)
                              .map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                              color: item.isChecked
                                                  ? Colors.grey
                                                  : Colors.black87,
                                              decoration: item.isChecked
                                                  ? TextDecoration.lineThrough
                                                  : null,
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
          ),
        ),
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
  final Future<void> Function(NoteData) onSave;
  final Function(String)? onDelete;

  const NoteEditorPage({
    super.key,
    required this.note,
    required this.onSave,
    this.onDelete,
  });

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
  bool _hasUnsavedChanges = false;

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

    // Set up change listeners
    _titleController.addListener(_markAsChanged);
    _contentController.addListener(_markAsChanged);

    // For existing notes, mark as not having unsaved changes initially
    if (_editedNote.title.isNotEmpty ||
        _editedNote.content.isNotEmpty ||
        _editedNote.checklistItems.isNotEmpty) {
      _hasUnsavedChanges = false;
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_markAsChanged);
    _contentController.removeListener(_markAsChanged);
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

  void _markAsChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Update content from controllers
      _editedNote.title = _titleController.text.trim();
      _editedNote.content = _contentController.text.trim();
      _editedNote.lastEdited = DateTime.now();

      // Save the updated note and wait for completion
      await widget.onSave(_editedNote);

      setState(() {
        _hasUnsavedChanges = false;
      });

      // Show save confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note saved successfully!'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      final errorMessage = e.toString();

      if (mounted) {
        // Show different colors/messages based on error type
        Color backgroundColor = Colors.red;
        Duration duration = Duration(seconds: 3);

        if (errorMessage.contains('offline') ||
            errorMessage.contains('internet connection') ||
            errorMessage.contains('sync when connection')) {
          backgroundColor = Colors.orange;
          duration = Duration(seconds: 4);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage.replaceAll('Exception: ', '')),
            duration: duration,
            backgroundColor: backgroundColor,
            action: errorMessage.contains('offline')
                ? SnackBarAction(
                    label: 'OK',
                    textColor: Colors.white,
                    onPressed: () {},
                  )
                : null,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
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
        _markAsChanged(); // Mark as changed after adding image
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
    _markAsChanged(); // Mark as changed after adding checklist item
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
      _markAsChanged(); // Mark as changed when checkbox is toggled
    }
    // Text changes will trigger change detection via the listener
  }

  void _removeChecklistItem(String id) {
    setState(() {
      _editedNote.checklistItems.removeWhere((item) => item.id == id);
    });
    _markAsChanged(); // Mark as changed after removing checklist item
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
    _markAsChanged(); // Mark as changed after converting to checklist
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
    _markAsChanged(); // Mark as changed after converting to text
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasUnsavedChanges) {
          // Show dialog asking if user wants to save before leaving
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Unsaved Changes'),
              content: const Text(
                  'You have unsaved changes. Do you want to save before leaving?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context)
                      .pop(false), // Don't save, just leave
                  child: const Text('DISCARD'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null), // Cancel
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () async {
                    await _saveNote();
                    if (mounted) {
                      Navigator.of(context).pop(true); // Save and leave
                    }
                  },
                  child: const Text('SAVE'),
                ),
              ],
            ),
          );

          if (result == null) return false; // User cancelled
          if (result == true) return true; // User saved
          return true; // User discarded changes
        }
        return true; // No unsaved changes
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
            // Save button
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    )
                  : Icon(
                      Icons.save,
                      color: _hasUnsavedChanges ? Colors.blue : Colors.grey,
                    ),
              onPressed: _hasUnsavedChanges && !_isSaving ? _saveNote : null,
              tooltip: 'Save note',
            ),
            IconButton(
              icon: Icon(
                _editedNote.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              ),
              onPressed: () {
                setState(() {
                  _editedNote.isPinned = !_editedNote.isPinned;
                  _markAsChanged();
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
                                _markAsChanged(); // Mark as changed after removing image
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
        // Floating save button for easier access
        floatingActionButton: _hasUnsavedChanges
            ? FloatingActionButton(
                onPressed: _isSaving ? null : _saveNote,
                backgroundColor: Colors.blue,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.save, color: Colors.white),
                tooltip: 'Save note',
              )
            : null,
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
          _markAsChanged(); // Mark as changed when checklist text is modified
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
