package com.reconstrect.visionboard

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import org.json.JSONArray
import org.json.JSONObject

/**
 * Activity for selecting which note to display in the widget
 * Launched when the circle button in the widget is clicked
 */
class DailyNotesWidgetSelectActivity : AppCompatActivity() {
    
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private lateinit var notesList: ListView
    private lateinit var backButton: Button
    private lateinit var refreshButton: Button
    private lateinit var emptyView: TextView
    private lateinit var loadingView: ProgressBar
    
    private val notesAdapter = NotesAdapter()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.daily_notes_widget_select)
        
        // Initialize views
        notesList = findViewById(R.id.notes_list)
        backButton = findViewById(R.id.back_button)
        refreshButton = findViewById(R.id.refresh_button)
        emptyView = findViewById(R.id.empty_view)
        loadingView = findViewById(R.id.loading_view)
        
        // Setup ListView
        notesList.adapter = notesAdapter
        notesList.emptyView = emptyView
        
        // Get the widget ID from the intent
        val extras = intent.extras
        if (extras != null) {
            appWidgetId = extras.getInt("widget_id", AppWidgetManager.INVALID_APPWIDGET_ID)
        }
        
        // Setup click listeners
        backButton.setOnClickListener { 
            // Go back to home screen
            val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(homeIntent)
            finish()
        }
        refreshButton.setOnClickListener { loadNotes() }
        
        notesList.setOnItemClickListener { _, _, position, _ ->
            val selectedNote = notesAdapter.getItem(position)
            val selectedNoteId = selectedNote?.getString("id")
            if (selectedNoteId != null) {
                selectNote(selectedNoteId)
            }
        }
        
        // Load notes
        loadNotes()
    }
    
    private fun loadNotes() {
        loadingView.visibility = View.VISIBLE
        notesList.visibility = View.GONE
        emptyView.visibility = View.GONE
        
        try {
            // Get notes data from SharedPreferences
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val notesDataString = prefs.getString("flutter.daily_notes_data", null)
            
            if (notesDataString != null && notesDataString.isNotEmpty()) {
                val notesArray = JSONArray(notesDataString)
                val notesList = mutableListOf<JSONObject>()
                
                for (i in 0 until notesArray.length()) {
                    val note = notesArray.getJSONObject(i)
                    notesList.add(note)
                }
                
                if (notesList.isNotEmpty()) {
                    notesAdapter.updateNotes(notesList)
                    this.notesList.visibility = View.VISIBLE
                    emptyView.visibility = View.GONE
                } else {
                    showEmptyState()
                }
            } else {
                showEmptyState()
            }
        } catch (e: Exception) {
            e.printStackTrace()
            showEmptyState()
        } finally {
            loadingView.visibility = View.GONE
        }
    }
    
    private fun showEmptyState() {
        notesList.visibility = View.GONE
        emptyView.visibility = View.VISIBLE
        emptyView.text = "No notes available.\n\nPlease open the Reconstruct app\nand create some notes first,\nthen try again."
    }
    
    private fun selectNote(noteId: String) {
        if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
            // Save the selected note ID for this widget
            val prefs = getSharedPreferences("widget_prefs", Context.MODE_PRIVATE)
            prefs.edit().putString("widget_note_$appWidgetId", noteId).apply()
            
            // Update the widget immediately
            val appWidgetManager = AppWidgetManager.getInstance(this)
            DailyNotesWidget.updateAppWidget(this, appWidgetManager, appWidgetId)
            
            // Also trigger a broadcast update to ensure all widgets refresh
            DailyNotesWidget.updateWidget(this)
            
            Toast.makeText(this, "Note selected for widget", Toast.LENGTH_SHORT).show()
        }
        
        // Close this activity and go back to home screen
        val homeIntent = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_HOME)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(homeIntent)
        
        // Finish this activity
        finish()
    }
    
    /**
     * Adapter for displaying notes in the ListView
     */
    private inner class NotesAdapter : BaseAdapter() {
        private var notes = mutableListOf<JSONObject>()
        
        fun updateNotes(newNotes: List<JSONObject>) {
            notes.clear()
            notes.addAll(newNotes)
            notifyDataSetChanged()
        }
        
        override fun getCount(): Int = notes.size
        
        override fun getItem(position: Int): JSONObject? = 
            if (position < notes.size) notes[position] else null
        
        override fun getItemId(position: Int): Long = position.toLong()
        
        override fun getView(position: Int, convertView: View?, parent: android.view.ViewGroup?): View {
            val view = convertView ?: layoutInflater.inflate(R.layout.note_list_item, parent, false)
            
            val note = notes[position]
            val titleView = view.findViewById<TextView>(R.id.note_title)
            val contentView = view.findViewById<TextView>(R.id.note_content)
            val pinIndicator = view.findViewById<ImageView>(R.id.pin_indicator)
            val checklistIndicator = view.findViewById<ImageView>(R.id.checklist_indicator)
            
            // Set title
            val title = note.optString("title", "")
            if (title.isNotEmpty()) {
                titleView.text = title
                titleView.visibility = View.VISIBLE
            } else {
                titleView.visibility = View.GONE
            }
            
            // Set content preview
            val content = note.optString("content", "")
            val hasChecklist = note.has("checklistItems") && note.getJSONArray("checklistItems").length() > 0
            
            when {
                hasChecklist -> {
                    val checklistItems = note.getJSONArray("checklistItems")
                    contentView.text = "📋 Checklist (${checklistItems.length()} items)"
                    checklistIndicator.visibility = View.VISIBLE
                }
                content.isNotEmpty() -> {
                    contentView.text = if (content.length > 80) "${content.substring(0, 80)}..." else content
                    checklistIndicator.visibility = View.GONE
                }
                else -> {
                    contentView.text = "Empty note"
                    checklistIndicator.visibility = View.GONE
                }
            }
            
            // Show pin indicator
            val isPinned = note.optBoolean("isPinned", false)
            pinIndicator.visibility = if (isPinned) View.VISIBLE else View.GONE
            
            return view
        }
    }
} 