package com.reconstrect.visionboard

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import android.content.ComponentName
import org.json.JSONArray
import org.json.JSONObject

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
                    val title = noteJson.optString("title", "")
                    val content = noteJson.optString("content", "")
                    
                    // Show the note data in the widget
                    views.setTextViewText(R.id.note_title, title)
                    
                    // If there's no title, show more content
                    if (title.isEmpty()) {
                        views.setTextViewText(R.id.note_content, displayText ?: content)
                    } else {
                        views.setTextViewText(R.id.note_content, content)
                    }
                } else {
                    // No notes available
                    views.setTextViewText(R.id.note_title, "")
                    views.setTextViewText(R.id.note_content, "Tap to add notes...")
                }
            } catch (e: Exception) {
                // Error parsing data
                views.setTextViewText(R.id.note_title, "")
                views.setTextViewText(R.id.note_content, "Tap to view your notes")
            }
        } else {
            // No data available
            views.setTextViewText(R.id.note_title, "")
            views.setTextViewText(R.id.note_content, "Tap to add notes...")
        }

        // Create the intent for opening the app
        val openAppIntent = Intent().apply {
            action = Intent.ACTION_VIEW
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            data = Uri.parse("reconstrect://dailynotes")
            component = ComponentName(context.packageName, context.packageName + ".MainActivity")
        }
        
        val openPendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.getActivity(context, 0, openAppIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)
        } else {
            PendingIntent.getActivity(context, 0, openAppIntent, PendingIntent.FLAG_UPDATE_CURRENT)
        }
        
        // Create the intent for adding a new note
        val addNoteIntent = Intent().apply {
            action = Intent.ACTION_VIEW
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            data = Uri.parse("reconstrect://dailynotes/new")
            component = ComponentName(context.packageName, context.packageName + ".MainActivity")
        }
        
        val addNotePendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.getActivity(context, 1, addNoteIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE)
        } else {
            PendingIntent.getActivity(context, 1, addNoteIntent, PendingIntent.FLAG_UPDATE_CURRENT)
        }

        // Set the click listeners
        views.setOnClickPendingIntent(R.id.widget_container, openPendingIntent)
        views.setOnClickPendingIntent(R.id.open_app_button, openPendingIntent)
        views.setOnClickPendingIntent(R.id.add_note_button, addNotePendingIntent)

        // Update the widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
} 