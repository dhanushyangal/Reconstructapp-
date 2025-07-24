package com.reconstrect.visionboard

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.text.TextUtils
import android.util.Log
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.io.File

/**
 * Implementation of the Daily Notes widget provider.
 * This widget displays the most recent or pinned note on the home screen.
 */
class DailyNotesWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Update each widget instance
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        // Clean up stored preferences when widgets are deleted
        val prefs = context.getSharedPreferences("widget_prefs", Context.MODE_PRIVATE)
        val editor = prefs.edit()
        for (appWidgetId in appWidgetIds) {
            editor.remove("widget_note_$appWidgetId")
        }
        editor.apply()
        super.onDeleted(context, appWidgetIds)
    }

    companion object {
        private const val MAX_CHECKLIST_ITEMS = 3
        
        // Update the widget when the app updates the data
        fun updateWidget(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context.packageName, DailyNotesWidget::class.java.name)
            )
            
            if (appWidgetIds.isNotEmpty()) {
                // Update all widgets directly for immediate refresh
                val widget = DailyNotesWidget()
                for (appWidgetId in appWidgetIds) {
                    widget.updateAppWidget(context, appWidgetManager, appWidgetId)
                }
                
                // Also send broadcast for good measure
                val intent = Intent(context, DailyNotesWidget::class.java)
                intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
                context.sendBroadcast(intent)
            }
        }
        
        // Force immediate widget update when a note is selected from app
        fun forceWidgetUpdate(context: Context) {
            try {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    ComponentName(context.packageName, DailyNotesWidget::class.java.name)
                )
                
                if (appWidgetIds.isNotEmpty()) {
                    val widget = DailyNotesWidget()
                    for (appWidgetId in appWidgetIds) {
                        widget.updateAppWidget(context, appWidgetManager, appWidgetId)
                    }
                }
            } catch (e: Exception) {
                // Handle any exceptions gracefully
                e.printStackTrace()
            }
        }
        
        // Static method to update a specific widget instance
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val widget = DailyNotesWidget()
            widget.updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    /**
     * Update a single widget instance with the latest note data
     */
    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        // Get a new RemoteViews object for the app widget layout
        val views = RemoteViews(context.packageName, R.layout.daily_notes_widget)

        // Get the selected note ID - first check for app-selected note, then widget-specific
        val widgetPrefs = context.getSharedPreferences("widget_prefs", Context.MODE_PRIVATE)
        val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        
        // Priority: 1) App-selected note 2) Widget-specific note 
        val selectedNoteId = flutterPrefs.getString("flutter.widget_selected_note_id", null) 
            ?: widgetPrefs.getString("widget_note_$appWidgetId", null)
        
        // Load the saved notes data
        val notesData = flutterPrefs.getString("flutter.daily_notes_data", null)
        val displayText = flutterPrefs.getString("flutter.daily_notes_display_text", "Tap to add notes...")

        // Debug logging
        Log.d("DailyNotesWidget", "=== WIDGET UPDATE DEBUG ===")
        Log.d("DailyNotesWidget", "Selected note ID: $selectedNoteId")
        Log.d("DailyNotesWidget", "Notes data available: ${notesData != null}")
        Log.d("DailyNotesWidget", "Notes data length: ${notesData?.length ?: 0}")
        if (notesData != null) {
            try {
                val jsonArray = JSONArray(notesData)
                Log.d("DailyNotesWidget", "Number of notes in data: ${jsonArray.length()}")
                for (i in 0 until jsonArray.length()) {
                    val note = jsonArray.getJSONObject(i)
                    Log.d("DailyNotesWidget", "Note $i: ID=${note.optString("id")}, Title=${note.optString("title")}")
                }
            } catch (e: Exception) {
                Log.e("DailyNotesWidget", "Error parsing notes data", e)
            }
        }

        if (notesData != null && selectedNoteId != null) {
            try {
                // Parse the notes data
                val jsonArray = JSONArray(notesData)
                var noteToDisplay: JSONObject? = null
                
                // Find the specific note with the selected ID
                for (i in 0 until jsonArray.length()) {
                    val note = jsonArray.getJSONObject(i)
                    if (note.optString("id") == selectedNoteId) {
                        noteToDisplay = note
                        break
                    }
                }
                
                if (noteToDisplay != null) {
                    updateWidgetFromNote(context, views, noteToDisplay, displayText)
                } else {
                    // Selected note not found, clear the selection and show message
                    val widgetPrefs = context.getSharedPreferences("widget_prefs", Context.MODE_PRIVATE)
                    val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    
                    // Clear both possible selections
                    widgetPrefs.edit().remove("widget_note_$appWidgetId").apply()
                    flutterPrefs.edit().remove("flutter.widget_selected_note_id").apply()
                    
                    setEmptyState(views, "Note no longer exists.\nTap app to select another note")
                }
            } catch (e: Exception) {
                // Error parsing data
                setEmptyState(views, "Error loading note")
            }
        } else {
            // No specific note selected, show message to select a note
            setEmptyState(views, "Open the Reconstruct app\nand tap the widget icon (📱) on any note\nto display it here")
        }

        // Create the intent for opening the Daily Notes page directly
        val openAppIntent = Intent().apply {
            action = Intent.ACTION_VIEW
            data = Uri.parse("reconstrect://dailynotes")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            component = ComponentName(context.packageName, context.packageName + ".MainActivity")
        }
        
        val openPendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.getActivity(context, appWidgetId + 2000, openAppIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)
        } else {
            PendingIntent.getActivity(context, appWidgetId + 2000, openAppIntent, PendingIntent.FLAG_UPDATE_CURRENT)
        }
        
        // Hide the add note button since we're using app-based selection now
        views.setViewVisibility(R.id.add_note_button, View.GONE)
        
        // Set the click listener - entire widget opens the app
        views.setOnClickPendingIntent(R.id.widget_container, openPendingIntent)

        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
    
    /**
     * Update the widget with data from a specific note
     */
    private fun updateWidgetFromNote(context: Context, views: RemoteViews, noteJson: JSONObject, displayText: String?) {
        // Get note data
        val title = noteJson.optString("title", "")
        val content = noteJson.optString("content", "")
        val imagePath = noteJson.optString("imagePath", "")
        val colorValue = noteJson.optInt("colorValue", Color.WHITE)
        val hasChecklistItems = noteJson.has("checklistItems") && noteJson.getJSONArray("checklistItems").length() > 0
        
        // Set widget background to background image
        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.daily_notes_background)
        
        // Hide the title view since we include it in the content
        views.setViewVisibility(R.id.note_title, View.GONE)
        
        // Handle image if available
        if (imagePath.isNotEmpty()) {
            try {
                val imageFile = File(imagePath)
                if (imageFile.exists()) {
                    val options = BitmapFactory.Options().apply {
                        // First decode with inJustDecodeBounds=true to check dimensions
                        inJustDecodeBounds = true
                    }
                    BitmapFactory.decodeFile(imagePath, options)
                    
                    // Calculate inSampleSize
                    options.inSampleSize = calculateInSampleSize(options, 800, 800)
                    
                    // Decode bitmap with inSampleSize set
                    options.inJustDecodeBounds = false
                    val bitmap = BitmapFactory.decodeFile(imagePath, options)
                    if (bitmap != null) {
                        // Scale the bitmap to fit perfectly in the widget
                        val maxHeight = 300 // Increased max height for better visibility
                        val displayMetrics = context.resources.displayMetrics
                        val screenWidth = displayMetrics.widthPixels
                        
                        // Calculate optimal dimensions while maintaining aspect ratio
                        val ratio = bitmap.width.toFloat() / bitmap.height.toFloat()
                        val newHeight = maxHeight.coerceAtMost(bitmap.height)
                        val newWidth = minOf((newHeight * ratio).toInt(), screenWidth - 32) // Account for padding
                        
                        val scaledBitmap = Bitmap.createScaledBitmap(
                            bitmap,
                            newWidth,
                            newHeight,
                            true
                        )
                        views.setImageViewBitmap(R.id.note_image, scaledBitmap)
                        views.setViewVisibility(R.id.note_image, View.VISIBLE)
                        
                        // Recycle the original bitmap to free memory
                        if (scaledBitmap != bitmap) {
                            bitmap.recycle()
                        }
                    } else {
                        views.setViewVisibility(R.id.note_image, View.GONE)
                    }
                } else {
                    views.setViewVisibility(R.id.note_image, View.GONE)
                }
            } catch (e: Exception) {
                views.setViewVisibility(R.id.note_image, View.GONE)
            }
        } else {
            views.setViewVisibility(R.id.note_image, View.GONE)
        }
        
        // Handle content or checklist
        if (hasChecklistItems) {
            // We have checklist items - display them
            val checklistItems = noteJson.getJSONArray("checklistItems")
            val checklistText = StringBuilder()
            
            // Add title if available
            if (title.isNotEmpty()) {
                checklistText.append("📋 $title\n\n")
            } else {
                checklistText.append("📋 Checklist\n\n")
            }
            
            // Build a formatted string of checklist items
            val itemsToShow = Math.min(checklistItems.length(), MAX_CHECKLIST_ITEMS)
            for (i in 0 until itemsToShow) {
                val item = checklistItems.getJSONObject(i)
                val isChecked = item.optBoolean("isChecked", false)
                val itemText = item.optString("text", "")
                
                if (itemText.isNotEmpty()) {
                    checklistText.append(if (isChecked) "✅ " else "⭕ ")
                    checklistText.append(itemText)
                    if (i < itemsToShow - 1) checklistText.append("\n")
                }
            }
            
            // If there are more items, add indication
            if (checklistItems.length() > MAX_CHECKLIST_ITEMS) {
                checklistText.append("\n📌 +${checklistItems.length() - MAX_CHECKLIST_ITEMS} more items...")
            }
            
            views.setTextViewText(R.id.note_content, checklistText.toString().trim())
            views.setTextColor(R.id.note_content, Color.WHITE)
            views.setViewVisibility(R.id.note_content, View.VISIBLE)
        } else if (content.isNotEmpty()) {
            // We have regular text content
            val displayContent = StringBuilder()
            
            // Add title if available and different from content
            if (title.isNotEmpty() && !content.startsWith(title)) {
                displayContent.append("📝 $title\n\n")
            }
            
            // Add content with length limit for widget display
            val maxContentLength = 200
            if (content.length > maxContentLength) {
                displayContent.append(content.substring(0, maxContentLength))
                displayContent.append("...")
            } else {
                displayContent.append(content)
            }
            
            views.setTextViewText(R.id.note_content, displayContent.toString())
            views.setTextColor(R.id.note_content, Color.WHITE)
            views.setViewVisibility(R.id.note_content, View.VISIBLE)
        } else if (title.isNotEmpty()) {
            // Only title, no content
            views.setTextViewText(R.id.note_content, "📝 $title")
            views.setTextColor(R.id.note_content, Color.WHITE)
            views.setViewVisibility(R.id.note_content, View.VISIBLE)
        } else if (displayText != null && displayText.isNotEmpty()) {
            // Use display text if available
            views.setTextViewText(R.id.note_content, displayText)
            views.setTextColor(R.id.note_content, Color.WHITE)
            views.setViewVisibility(R.id.note_content, View.VISIBLE)
        } else {
            // Empty note
            views.setTextViewText(R.id.note_content, "📝 Empty note")
            views.setTextColor(R.id.note_content, Color.WHITE)
            views.setViewVisibility(R.id.note_content, View.VISIBLE)
        }
    }
    
    /**
     * Set the widget to show an empty state
     */
    private fun setEmptyState(views: RemoteViews, message: String = "Tap to add notes...") {
        views.setViewVisibility(R.id.note_image, View.GONE)
        views.setViewVisibility(R.id.note_title, View.GONE)
        views.setTextViewText(R.id.note_content, message)
        views.setTextColor(R.id.note_content, Color.WHITE)
        views.setViewVisibility(R.id.note_content, View.VISIBLE)
        views.setViewVisibility(R.id.checklist_container, View.GONE)
        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.daily_notes_background)
    }

    /**
     * Calculate the optimal inSampleSize value for loading a bitmap efficiently
     */
    private fun calculateInSampleSize(options: BitmapFactory.Options, reqWidth: Int, reqHeight: Int): Int {
        // Raw height and width of image
        val height = options.outHeight
        val width = options.outWidth
        var inSampleSize = 1
        
        if (height > reqHeight || width > reqWidth) {
            val halfHeight: Int = height / 2
            val halfWidth: Int = width / 2
            
            // Calculate the largest inSampleSize value that is a power of 2 and keeps both
            // height and width larger than the requested height and width.
            while ((halfHeight / inSampleSize) >= reqHeight && (halfWidth / inSampleSize) >= reqWidth) {
                inSampleSize *= 2
            }
        }
        
        return inSampleSize
    }
} 