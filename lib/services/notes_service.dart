import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../config/supabase_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class NotesService {
  static final NotesService instance = NotesService._internal();

  // Supabase client instance
  late final supabase.SupabaseClient _client;

  // Offline storage keys
  static const String _offlineNotesKey = 'offline_notes';
  static const String _pendingNotesKey = 'pending_notes';
  static const String _lastSyncKey = 'last_sync_timestamp';

  NotesService._internal() {
    _client = SupabaseConfig.client;
  }

  // Check network connectivity
  Future<bool> _hasNetworkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('Network connectivity check failed: $e');
      return false;
    }
  }

  // Test Supabase connection specifically
  Future<bool> _testSupabaseConnection() async {
    try {
      await _client.from('notes').select('id').limit(1).timeout(
            Duration(seconds: 5),
          );
      return true;
    } catch (e) {
      debugPrint('Supabase connection test failed: $e');
      return false;
    }
  }

  // Save note to local storage
  Future<bool> _saveNoteOffline(Map<String, dynamic> noteData) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing offline notes
      List<Map<String, dynamic>> offlineNotes = [];
      final offlineData = prefs.getString(_offlineNotesKey);
      if (offlineData != null && offlineData.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(offlineData);
        offlineNotes =
            decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      }

      // Add timestamp and offline flag
      noteData['offline_created'] = DateTime.now().toIso8601String();
      noteData['sync_status'] = 'pending';

      // Generate a temporary ID if none exists
      if (noteData['id'] == null) {
        noteData['id'] = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      }

      // Add to offline notes
      offlineNotes.add(noteData);

      // Save back to storage
      final success =
          await prefs.setString(_offlineNotesKey, jsonEncode(offlineNotes));
      debugPrint('Note saved offline with ID: ${noteData['id']}');
      return success;
    } catch (e) {
      debugPrint('Error saving note offline: $e');
      return false;
    }
  }

  // Load offline notes
  Future<List<Map<String, dynamic>>> _loadOfflineNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineData = prefs.getString(_offlineNotesKey);

      if (offlineData == null || offlineData.isEmpty) {
        return [];
      }

      final List<dynamic> decoded = jsonDecode(offlineData);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      debugPrint('Error loading offline notes: $e');
      return [];
    }
  }

  // Merge online and offline notes
  Future<List<Map<String, dynamic>>> _mergeOnlineAndOfflineNotes(
    List<Map<String, dynamic>> onlineNotes,
  ) async {
    final offlineNotes = await _loadOfflineNotes();

    // Combine both lists, with offline notes at the top
    final merged = <Map<String, dynamic>>[];
    merged.addAll(offlineNotes);
    merged.addAll(onlineNotes);

    return merged;
  }

  // Sync offline notes to Supabase
  Future<bool> syncOfflineNotes({
    required String userName,
    required String email,
  }) async {
    try {
      if (!await _hasNetworkConnection() || !await _testSupabaseConnection()) {
        debugPrint(
            'Cannot sync - no network connection or Supabase unavailable');
        return false;
      }

      final offlineNotes = await _loadOfflineNotes();
      if (offlineNotes.isEmpty) {
        debugPrint('No offline notes to sync');
        return true;
      }

      int syncedCount = 0;
      final remainingNotes = <Map<String, dynamic>>[];

      for (final note in offlineNotes) {
        try {
          // Try to save each note to Supabase
          final result = await saveNote(
            userName: userName,
            email: email,
            title: note['title'] ?? '',
            content: note['content'] ?? '',
            noteType: note['note_type'] ?? 'text',
            isPinned: note['is_pinned'] ?? false,
            checklistItems: note['checklist_items'] ?? [],
            forceOnline: true, // Force online save
          );

          if (result['success']) {
            syncedCount++;
            debugPrint('Synced offline note: ${note['title']}');
          } else {
            // Keep note for retry later
            remainingNotes.add(note);
          }
        } catch (e) {
          debugPrint('Failed to sync note ${note['title']}: $e');
          remainingNotes.add(note);
        }
      }

      // Update offline storage with remaining notes
      final prefs = await SharedPreferences.getInstance();
      if (remainingNotes.isEmpty) {
        await prefs.remove(_offlineNotesKey);
      } else {
        await prefs.setString(_offlineNotesKey, jsonEncode(remainingNotes));
      }

      // Update last sync timestamp
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      debugPrint(
          'Sync completed: $syncedCount notes synced, ${remainingNotes.length} remaining');
      return syncedCount > 0 || remainingNotes.isEmpty;
    } catch (e) {
      debugPrint('Error during offline sync: $e');
      return false;
    }
  }

  // Helper method to handle errors and format response
  Map<String, dynamic> _formatResponse({
    required bool success,
    String? message,
    dynamic data,
    bool isOffline = false,
  }) {
    return {
      'success': success,
      'isOffline': isOffline,
      if (message != null) 'message': message,
      if (data != null) 'data': data,
    };
  }

  // Test Supabase connection
  Future<bool> testConnection() async {
    return await _testSupabaseConnection();
  }

  // Load all notes for a user
  Future<Map<String, dynamic>> loadUserNotes({
    required String userName,
    required String email,
  }) async {
    try {
      if (userName.isEmpty || email.isEmpty) {
        debugPrint('Invalid user info for loading notes');
        return _formatResponse(
          success: false,
          message: 'User information is required',
          data: [],
        );
      }

      debugPrint('Loading notes for user: $userName ($email)');

      // Check network connectivity
      final hasNetwork = await _hasNetworkConnection();
      final hasSupabase = hasNetwork ? await _testSupabaseConnection() : false;

      if (hasSupabase) {
        try {
          final response = await _client
              .from('notes')
              .select()
              .eq('user_name', userName)
              .eq('email', email)
              .order('is_pinned', ascending: false)
              .order('date_edited', ascending: false)
              .timeout(Duration(seconds: 10));

          debugPrint('Loaded ${response.length} notes from Supabase');

          // Merge with offline notes
          final mergedNotes = await _mergeOnlineAndOfflineNotes(
              List<Map<String, dynamic>>.from(response));

          debugPrint(
              'Total notes after merge: ${mergedNotes.length} (${response.length} online, ${mergedNotes.length - response.length} offline)');

          // Sort notes properly
          mergedNotes.sort((a, b) {
            final aPinned = a['is_pinned'] ?? false;
            final bPinned = b['is_pinned'] ?? false;
            if (aPinned && !bPinned) return -1;
            if (!aPinned && bPinned) return 1;

            final aDate = DateTime.parse(a['date_edited']);
            final bDate = DateTime.parse(b['date_edited']);
            return bDate.compareTo(aDate);
          });

          return _formatResponse(
            success: true,
            data: mergedNotes,
          );
        } catch (e) {
          debugPrint(
              'Error loading notes from Supabase, falling back to offline: $e');
          // Fall through to offline mode
        }
      }

      // Offline mode - load only offline notes
      final offlineNotes = await _loadOfflineNotes();
      debugPrint('Loading ${offlineNotes.length} notes from offline storage');

      return _formatResponse(
        success: true,
        data: offlineNotes,
        isOffline: true,
        message: hasNetwork
            ? 'Unable to connect to server, showing offline notes'
            : 'No internet connection, showing offline notes',
      );
    } catch (e) {
      debugPrint('Error loading notes: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to load notes: $e',
        data: [],
      );
    }
  }

  // Save a new note
  Future<Map<String, dynamic>> saveNote({
    required String userName,
    required String email,
    required String title,
    required String content,
    required String noteType,
    required bool isPinned,
    required List<Map<String, dynamic>> checklistItems,
    String? imagePath,
    bool forceOnline = false,
  }) async {
    try {
      if (userName.isEmpty || email.isEmpty) {
        return _formatResponse(
          success: false,
          message: 'User information is required',
        );
      }

      // Convert checklist items to JSON string in the required format
      final checklistJson = jsonEncode(checklistItems
          .map((item) => {
                'text': item['text'] ?? '',
                'completed': item['isChecked'] ?? false,
              })
          .toList());

      debugPrint('Saving note for user: $userName');
      debugPrint('Note type: $noteType');
      debugPrint('Checklist items: $checklistJson');

      // Check if we should try online saving
      final hasNetwork = await _hasNetworkConnection();
      final hasSupabase = hasNetwork ? await _testSupabaseConnection() : false;

      if ((hasSupabase && !forceOnline) || (forceOnline && hasSupabase)) {
        try {
          final response = await _client
              .from('notes')
              .insert({
                'user_name': userName,
                'email': email,
                'title': title,
                'content': content,
                'note_type': noteType,
                'is_pinned': isPinned,
                'checklist_items': checklistJson,
              })
              .select()
              .single()
              .timeout(Duration(seconds: 10));

          debugPrint('Note saved successfully with ID: ${response['id']}');
          return _formatResponse(
            success: true,
            message: 'Note saved successfully',
            data: response,
          );
        } catch (e) {
          debugPrint('Error saving note online: $e');
          if (forceOnline) {
            // If forced online and failed, return error
            return _formatResponse(
              success: false,
              message: 'Failed to save note online: $e',
            );
          }
          // Fall through to offline save
        }
      }

      // Save offline
      final noteData = {
        'user_name': userName,
        'email': email,
        'title': title,
        'content': content,
        'note_type': noteType,
        'is_pinned': isPinned,
        'checklist_items': checklistItems, // Keep as list for offline
        'date_created': DateTime.now().toIso8601String(),
        'date_edited': DateTime.now().toIso8601String(),
      };

      final offlineSaved = await _saveNoteOffline(noteData);

      if (offlineSaved) {
        debugPrint('Note saved offline with ID: ${noteData['id']}');
        return _formatResponse(
          success: true,
          message: hasNetwork
              ? 'Saved offline - will sync when connection is restored'
              : 'Saved offline - no internet connection',
          data: noteData,
          isOffline: true,
        );
      } else {
        return _formatResponse(
          success: false,
          message: 'Failed to save note both online and offline',
        );
      }
    } catch (e) {
      debugPrint('Error saving note: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to save note: $e',
      );
    }
  }

  // Update an existing note
  Future<Map<String, dynamic>> updateNote({
    required int noteId,
    required String userName,
    required String email,
    String? title,
    String? content,
    String? noteType,
    bool? isPinned,
    List<Map<String, dynamic>>? checklistItems,
    String? imagePath,
  }) async {
    try {
      if (userName.isEmpty || email.isEmpty) {
        return _formatResponse(
          success: false,
          message: 'User information is required',
        );
      }

      // Prepare update data
      Map<String, dynamic> updateData = {};

      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (noteType != null) updateData['note_type'] = noteType;
      if (isPinned != null) updateData['is_pinned'] = isPinned;

      if (checklistItems != null) {
        // Convert checklist items to JSON string in the required format
        final checklistJson = jsonEncode(checklistItems
            .map((item) => {
                  'text': item['text'] ?? '',
                  'completed': item['isChecked'] ?? false,
                })
            .toList());
        updateData['checklist_items'] = checklistJson;
      }

      // Only update if there's data to update
      if (updateData.isEmpty) {
        return _formatResponse(
          success: false,
          message: 'No data to update',
        );
      }

      debugPrint('Updating note with ID: $noteId');

      final response = await _client
          .from('notes')
          .update(updateData)
          .eq('id', noteId)
          .eq('user_name', userName)
          .eq('email', email)
          .select()
          .single();

      debugPrint('Note updated successfully');
      return _formatResponse(
        success: true,
        message: 'Note updated successfully',
        data: response,
      );
    } catch (e) {
      debugPrint('Error updating note: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to update note: $e',
      );
    }
  }

  // Save or update note with smart duplicate prevention
  Future<Map<String, dynamic>> saveOrUpdateNote({
    String?
        noteId, // If null or UUID format, create new; if numeric, update existing
    required String userName,
    required String email,
    required String title,
    required String content,
    required String noteType,
    required bool isPinned,
    required List<Map<String, dynamic>> checklistItems,
    String? imagePath,
  }) async {
    try {
      // Check if this is a new note (UUID format) or existing note (numeric ID)
      bool isNewNote = noteId == null ||
          noteId.isEmpty ||
          !RegExp(r'^\d+$').hasMatch(noteId);

      if (isNewNote) {
        // Create new note
        return await saveNote(
          userName: userName,
          email: email,
          title: title,
          content: content,
          noteType: noteType,
          isPinned: isPinned,
          checklistItems: checklistItems,
          imagePath: imagePath,
        );
      } else {
        // Update existing note
        return await updateNote(
          noteId: int.parse(noteId),
          userName: userName,
          email: email,
          title: title,
          content: content,
          noteType: noteType,
          isPinned: isPinned,
          checklistItems: checklistItems,
          imagePath: imagePath,
        );
      }
    } catch (e) {
      debugPrint('Error in saveOrUpdateNote: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to save note: $e',
      );
    }
  }

  // Delete a note
  Future<Map<String, dynamic>> deleteNote({
    required int noteId,
    required String userName,
    required String email,
  }) async {
    try {
      if (userName.isEmpty || email.isEmpty) {
        return _formatResponse(
          success: false,
          message: 'User information is required',
        );
      }

      debugPrint('Deleting note with ID: $noteId');

      await _client
          .from('notes')
          .delete()
          .eq('id', noteId)
          .eq('user_name', userName)
          .eq('email', email);

      debugPrint('Note deleted successfully');
      return _formatResponse(
        success: true,
        message: 'Note deleted successfully',
      );
    } catch (e) {
      debugPrint('Error deleting note: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to delete note: $e',
      );
    }
  }

  // Toggle pin status of a note
  Future<Map<String, dynamic>> togglePinNote({
    required int noteId,
    required String userName,
    required String email,
    required bool isPinned,
  }) async {
    try {
      return await updateNote(
        noteId: noteId,
        userName: userName,
        email: email,
        isPinned: isPinned,
      );
    } catch (e) {
      debugPrint('Error toggling pin status: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to toggle pin status: $e',
      );
    }
  }

  // Search notes by query
  Future<Map<String, dynamic>> searchNotes({
    required String userName,
    required String email,
    required String query,
  }) async {
    try {
      if (userName.isEmpty || email.isEmpty) {
        return _formatResponse(
          success: false,
          message: 'User information is required',
          data: [],
        );
      }

      if (query.isEmpty) {
        return loadUserNotes(userName: userName, email: email);
      }

      final response = await _client
          .from('notes')
          .select()
          .eq('user_name', userName)
          .eq('email', email)
          .or('title.ilike.%$query%,content.ilike.%$query%,checklist_items.ilike.%$query%')
          .order('is_pinned', ascending: false)
          .order('date_edited', ascending: false);

      debugPrint('Found ${response.length} notes matching search query');
      return _formatResponse(
        success: true,
        data: response,
      );
    } catch (e) {
      debugPrint('Error searching notes: $e');
      return _formatResponse(
        success: false,
        message: 'Failed to search notes: $e',
        data: [],
      );
    }
  }

  // Convert database note to NoteData object
  Map<String, dynamic> convertDbNoteToNoteData(Map<String, dynamic> dbNote) {
    try {
      debugPrint(
          'Converting DB note: ID=${dbNote['id']}, Title=${dbNote['title']}');

      // Parse checklist items from JSON string
      List<Map<String, dynamic>> checklistItems = [];
      if (dbNote['checklist_items'] != null &&
          dbNote['checklist_items'].isNotEmpty) {
        try {
          final List<dynamic> items = jsonDecode(dbNote['checklist_items']);
          checklistItems = items
              .map((item) => {
                    'id': DateTime.now().millisecondsSinceEpoch.toString() +
                        items.indexOf(item).toString(),
                    'text': item['text'] ?? '',
                    'isChecked': item['completed'] ?? false,
                  })
              .toList();
          debugPrint('Parsed ${checklistItems.length} checklist items');
        } catch (e) {
          debugPrint('Error parsing checklist items: $e');
        }
      }

      final result = {
        'id': dbNote['id'].toString(),
        'title': dbNote['title'] ?? '',
        'content': dbNote['content'] ?? '',
        'noteType': dbNote['note_type'] ?? 'text',
        'isPinned': dbNote['is_pinned'] ?? false,
        'checklistItems': checklistItems,
        'lastEdited': DateTime.parse(dbNote['date_edited']),
        'created': DateTime.parse(dbNote['date_created']),
        'imagePath': null, // Not stored in DB for now
      };

      debugPrint(
          'Converted note: ${result['title']} (${result['content'].length} chars, ${checklistItems.length} checklist items)');
      return result;
    } catch (e) {
      debugPrint('Error converting DB note to NoteData: $e');
      return {
        'id': dbNote['id']?.toString() ?? '',
        'title': dbNote['title'] ?? '',
        'content': dbNote['content'] ?? '',
        'noteType': 'text',
        'isPinned': false,
        'checklistItems': <Map<String, dynamic>>[],
        'lastEdited': DateTime.now(),
        'created': DateTime.now(),
        'imagePath': null,
      };
    }
  }

  // Check if user is currently authenticated with Supabase
  bool get isAuthenticated => _client.auth.currentUser != null;

  // Get current user
  supabase.User? get currentUser => _client.auth.currentUser;

  // Get auth token from Supabase
  String? get authToken => _client.auth.currentSession?.accessToken;
}
