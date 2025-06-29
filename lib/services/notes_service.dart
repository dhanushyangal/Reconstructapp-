import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../config/supabase_config.dart';
import 'dart:convert';

class NotesService {
  static final NotesService instance = NotesService._internal();

  // Supabase client instance
  late final supabase.SupabaseClient _client;

  NotesService._internal() {
    _client = SupabaseConfig.client;
  }

  // Helper method to handle errors and format response
  Map<String, dynamic> _formatResponse({
    required bool success,
    String? message,
    dynamic data,
  }) {
    return {
      'success': success,
      if (message != null) 'message': message,
      if (data != null) 'data': data,
    };
  }

  // Test Supabase connection
  Future<bool> testConnection() async {
    try {
      await _client.from('notes').select('id').limit(1);
      return true;
    } catch (e) {
      debugPrint('Error testing Supabase connection: $e');
      return false;
    }
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

      final response = await _client
          .from('notes')
          .select()
          .eq('user_name', userName)
          .eq('email', email)
          .order('is_pinned', ascending: false)
          .order('date_edited', ascending: false);

      debugPrint('Loaded ${response.length} notes from Supabase');
      return _formatResponse(
        success: true,
        data: response,
      );
    } catch (e) {
      debugPrint('Error loading notes from Supabase: $e');
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
          .single();

      debugPrint('Note saved successfully with ID: ${response['id']}');
      return _formatResponse(
        success: true,
        message: 'Note saved successfully',
        data: response,
      );
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
        } catch (e) {
          debugPrint('Error parsing checklist items: $e');
        }
      }

      return {
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
