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

    companion object {
        private const val MAX_CHECKLIST_ITEMS = 3
        
        // Update the widget when the app updates the data
        fun updateWidget(context: Context) {
            val intent = Intent(context, DailyNotesWidget::class.java)
            intent.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            
            // Get all widget IDs
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context.packageName, DailyNotesWidget::class.java.name)
            )
            
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, appWidgetIds)
            context.sendBroadcast(intent)
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

        // Load the saved notes data
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val notesData = prefs.getString("flutter.daily_notes_data", null)
        val displayText = prefs.getString("flutter.daily_notes_display_text", "Tap to add notes...")

        if (notesData != null) {
            try {
                // Parse the notes data
                val jsonArray = JSONArray(notesData)
                
                if (jsonArray.length() > 0) {
                    // Get the first note (which should be either pinned or the most recent)
                    val noteJson = jsonArray.getJSONObject(0)
                    updateWidgetFromNote(context, views, noteJson, displayText)
                } else {
                    // No notes available
                    setEmptyState(views)
                }
            } catch (e: Exception) {
                // Error parsing data
                setEmptyState(views)
            }
        } else {
            // No data available
            setEmptyState(views)
        }

        // Create the intent for opening the app
        val openAppIntent = Intent()
        openAppIntent.action = Intent.ACTION_VIEW
        openAppIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        openAppIntent.data = Uri.parse("reconstrect://dailynotes")
        openAppIntent.component = ComponentName(context.packageName, context.packageName + ".MainActivity")
        
        val openPendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.getActivity(context, 0, openAppIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)
        } else {
            PendingIntent.getActivity(context, 0, openAppIntent, PendingIntent.FLAG_UPDATE_CURRENT)
        }
        
        // Create the intent for adding a new note
        val addNoteIntent = Intent()
        addNoteIntent.action = Intent.ACTION_VIEW
        addNoteIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        addNoteIntent.data = Uri.parse("reconstrect://dailynotes/new")
        addNoteIntent.component = ComponentName(context.packageName, context.packageName + ".MainActivity")
        
        val addNotePendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.getActivity(context, 1, addNoteIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)
        } else {
            PendingIntent.getActivity(context, 1, addNoteIntent, PendingIntent.FLAG_UPDATE_CURRENT)
        }

        // Set the click listeners
        views.setOnClickPendingIntent(R.id.widget_container, openPendingIntent)
        views.setOnClickPendingIntent(R.id.add_note_button, addNotePendingIntent)

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
        
        // Set background color based on note color
        try {
            // Set background color
            views.setInt(R.id.widget_container, "setBackgroundColor", colorValue)
        } catch (e: Exception) {
            // Fallback to default background if there's an issue
            views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.note_background)
        }
        
        // Handle title
        if (title.isNotEmpty()) {
            views.setTextViewText(R.id.note_title, title)
            views.setViewVisibility(R.id.note_title, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.note_title, View.GONE)
        }
        
        // Handle image if available
        if (imagePath.isNotEmpty()) {
            try {
                val imageFile = File(imagePath)
                if (imageFile.exists()) {
                    // Load and resize the image
                    val options = BitmapFactory.Options().apply {
                        inSampleSize = 2 // Reduce image size for better performance
                    }
                    val bitmap = BitmapFactory.decodeFile(imagePath, options)
                    if (bitmap != null) {
                        // Scale the bitmap to fit the widget's image view
                        val scaledBitmap = Bitmap.createScaledBitmap(
                            bitmap,
                            bitmap.width,
                            160, // Match the height in the layout
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
            // We have checklist items
            val checklistItems = noteJson.getJSONArray("checklistItems")
            val checklistText = StringBuilder()
            
            // Build a formatted string of checklist items
            val itemsToShow = Math.min(checklistItems.length(), MAX_CHECKLIST_ITEMS)
            for (i in 0 until itemsToShow) {
                val item = checklistItems.getJSONObject(i)
                val isChecked = item.optBoolean("isChecked", false)
                val itemText = item.optString("text", "")
                
                if (itemText.isNotEmpty()) {
                    checklistText.append(if (isChecked) "☑ " else "☐ ")
                    checklistText.append(itemText)
                    checklistText.append("\n")
                }
            }
            
            // If there are more items, add indication
            if (checklistItems.length() > MAX_CHECKLIST_ITEMS) {
                checklistText.append("+ ${checklistItems.length() - MAX_CHECKLIST_ITEMS} more items")
            }
            
            views.setTextViewText(R.id.note_content, checklistText.toString().trim())
            views.setViewVisibility(R.id.note_content, View.VISIBLE)
        } else if (content.isNotEmpty()) {
            // We have regular content
            views.setTextViewText(R.id.note_content, content)
            views.setViewVisibility(R.id.note_content, View.VISIBLE)
        } else if (displayText != null && displayText.isNotEmpty()) {
            // Use display text if available
            views.setTextViewText(R.id.note_content, displayText)
            views.setViewVisibility(R.id.note_content, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.note_content, View.GONE)
        }
    }
    
    /**
     * Set the widget to show an empty state
     */
    private fun setEmptyState(views: RemoteViews) {
        views.setViewVisibility(R.id.note_image, View.GONE)
        views.setViewVisibility(R.id.note_title, View.GONE)
        views.setTextViewText(R.id.note_content, "Tap to add notes...")
        views.setViewVisibility(R.id.note_content, View.VISIBLE)
        views.setViewVisibility(R.id.checklist_container, View.GONE)
    }
} 