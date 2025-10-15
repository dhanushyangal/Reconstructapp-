package com.reconstrect.visionboard

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import android.view.View
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import org.json.JSONArray
import org.json.JSONObject

/**
 * Configuration Activity for Daily Notes Widget
 * Allows users to select which note to display in the widget
 */
class DailyNotesWidgetConfigureActivity : AppCompatActivity() {
    
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private lateinit var notesList: ListView
    private lateinit var confirmButton: Button
    private lateinit var refreshButton: Button
    private lateinit var emptyView: TextView
    private lateinit var loadingView: ProgressBar
    
    private var selectedNoteId: String? = null
    private val notesAdapter = NotesAdapter()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Set the result to CANCELED. This will cause the widget host to cancel
        // out of the widget placement if the user presses the back button.
        setResult(Activity.RESULT_CANCELED)
        
        setContentView(R.layout.daily_notes_widget_configure)
        
        // Initialize views
        notesList = findViewById(R.id.notes_list)
        confirmButton = findViewById(R.id.confirm_button)
        refreshButton = findViewById(R.id.refresh_button)
        emptyView = findViewById(R.id.empty_view)
        loadingView = findViewById(R.id.loading_view)
        
        // Setup ListView
        notesList.adapter = notesAdapter
        notesList.emptyView = emptyView
        
        // Get the widget ID from the intent
        val extras = intent.extras
        if (extras != null) {
            appWidgetId = extras.getInt(
                AppWidgetManager.EXTRA_APPWIDGET_ID, 
                AppWidgetManager.INVALID_APPWIDGET_ID
            )
        }
        
        // If this activity was started with an intent without an app widget ID,
        // finish with an error.
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }
        
        // Setup click listeners
        confirmButton.setOnClickListener { confirmSelection() }
        refreshButton.setOnClickListener { loadNotes() }
        
        notesList.setOnItemClickListener { _, _, position, _ ->
            val selectedNote = notesAdapter.getItem(position)
            selectedNoteId = selectedNote?.getString("id")
            confirmButton.isEnabled = selectedNoteId != null
            notesAdapter.setSelectedPosition(position)
        }
        
        // Initially disable confirm button
        confirmButton.isEnabled = false
        
        // Load notes
        loadNotes()
    }
    
    private fun loadNotes() {
        loadingView.visibility = View.VISIBLE
        notesList.visibility = View.GONE
        emptyView.visibility = View.GONE
        
        try {
            // Get notes data and theme from SharedPreferences
            val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val notesDataString = prefs.getString("flutter.daily_notes_data", null)
            val currentTheme = prefs.getString("flutter.daily_notes_theme", "Post-it Daily Notes")
            
            // Apply theme background
            applyThemeBackground(currentTheme)
            
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
        emptyView.text = "No notes available.\nPlease create some notes in the app first."
    }
    
    private fun confirmSelection() {
        if (selectedNoteId == null) {
            Toast.makeText(this, "Please select a note", Toast.LENGTH_SHORT).show()
            return
        }
        
        // Save the selected note ID for this widget
        val prefs = getSharedPreferences("widget_prefs", Context.MODE_PRIVATE)
        prefs.edit().putString("widget_note_$appWidgetId", selectedNoteId).apply()
        
        // Update the widget
        val appWidgetManager = AppWidgetManager.getInstance(this)
        DailyNotesWidget.updateAppWidget(this, appWidgetManager, appWidgetId)
        
        // Make sure we pass back the original appWidgetId
        val resultValue = Intent()
        resultValue.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        setResult(Activity.RESULT_OK, resultValue)
        finish()
    }
    
    /**
     * Adapter for displaying notes in the ListView
     */
    private inner class NotesAdapter : BaseAdapter() {
        private var notes = mutableListOf<JSONObject>()
        private var selectedPosition = -1
        
        fun updateNotes(newNotes: List<JSONObject>) {
            notes.clear()
            notes.addAll(newNotes)
            notifyDataSetChanged()
        }
        
        fun setSelectedPosition(position: Int) {
            selectedPosition = position
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
            
            // Highlight selected item
            if (position == selectedPosition) {
                view.setBackgroundColor(resources.getColor(android.R.color.holo_blue_light, null))
            } else {
                view.setBackgroundColor(resources.getColor(android.R.color.transparent, null))
            }
            
            return view
        }
    }
    
    /**
     * Apply theme-based background to the activity
     */
    private fun applyThemeBackground(theme: String?) {
        val rootLayout = findViewById<android.view.View>(android.R.id.content)
        when (theme) {
            "Post-it Daily Notes" -> {
                // Light green background for Post-it theme
                rootLayout.setBackgroundColor(android.graphics.Color.parseColor("#C5E1A5"))
            }
            "Premium Daily Notes" -> {
                // Black background for Premium theme
                rootLayout.setBackgroundColor(android.graphics.Color.BLACK)
            }
            "Floral Daily Notes" -> {
                // White background for Floral theme (or you can set a floral image)
                rootLayout.setBackgroundColor(android.graphics.Color.WHITE)
            }
            else -> {
                // Default: white background
                rootLayout.setBackgroundColor(android.graphics.Color.WHITE)
            }
        }
    }
    
    companion object {
        /**
         * Get the selected note ID for a specific widget
         */
        fun getSelectedNoteId(context: Context, appWidgetId: Int): String? {
            val prefs = context.getSharedPreferences("widget_prefs", Context.MODE_PRIVATE)
            return prefs.getString("widget_note_$appWidgetId", null)
        }
        
        /**
         * Remove the selected note ID when widget is deleted
         */
        fun removeSelectedNoteId(context: Context, appWidgetId: Int) {
            val prefs = context.getSharedPreferences("widget_prefs", Context.MODE_PRIVATE)
            prefs.edit().remove("widget_note_$appWidgetId").apply()
        }
    }
} 