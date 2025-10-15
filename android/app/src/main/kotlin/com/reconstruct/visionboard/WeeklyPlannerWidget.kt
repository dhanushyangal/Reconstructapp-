package com.reconstrect.visionboard

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import android.util.Log
import android.app.PendingIntent
import org.json.JSONArray
import java.util.*
import android.view.View
import android.widget.ImageView
import android.graphics.Color

class WeeklyPlannerWidget : AppWidgetProvider() {
    companion object {
        private const val MAX_DAYS = 5
        
        private val days = arrayOf(
            "Monday", "Tuesday", "Wednesday", "Thursday", 
            "Friday", "Saturday", "Sunday"
        )

        private val japaneseBackgrounds = arrayOf(
            R.drawable.japanese_1,
            R.drawable.japanese_1,
            R.drawable.japanese_1,
            R.drawable.japanese_1,
            R.drawable.japanese_1,
            R.drawable.japanese_1,
            R.drawable.japanese_1
        )

        private val patternsBackgrounds = arrayOf(
            R.drawable.pattern_1,
            R.drawable.pattern_2,
            R.drawable.pattern_3,
            R.drawable.pattern_4,
            R.drawable.pattern_5,
            R.drawable.pattern_6,
            R.drawable.pattern_7
        )

        private val watercolorBackgrounds = arrayOf(
            R.drawable.watercolor_1,
            R.drawable.watercolor_2,
            R.drawable.watercolor_3,
            R.drawable.watercolor_4,
            R.drawable.watercolor_5,
            R.drawable.watercolor_6,
            R.drawable.watercolor_7
        )

        private val floralBackgrounds = arrayOf(
            R.drawable.floral_1,
            R.drawable.floral_2,
            R.drawable.floral_3,
            R.drawable.floral_4,
            R.drawable.floral_5,
            R.drawable.floral_6,
            R.drawable.floral_7
        )

        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.weekly_planner_widget)
            views.removeAllViews(R.id.days_container)
            
            try {
                val currentTheme = getCurrentTheme(context, appWidgetId)
                Log.d("WeeklyWidget", "Current theme: $currentTheme")
                
                // Get all configured days
                val allConfiguredDays = mutableListOf<Pair<Int, String>>()
                for (i in 0 until MAX_DAYS) {
                    val day = HomeWidgetPlugin.getData(context).getString("day_${appWidgetId}_$i", null)
                    if (day != null) {
                        allConfiguredDays.add(Pair(i, day))
                        Log.d("WeeklyWidget", "Found configured day: $day at index $i")
                    }
                }
                
                Log.d("WeeklyWidget", "Total configured days: ${allConfiguredDays.size}")
                
                // Auto-add days with tasks if less than 4
                if (allConfiguredDays.size < 4) {
                    val prefs = HomeWidgetPlugin.getData(context)
                    val existingDays = allConfiguredDays.map { it.second }.toSet()
                    val daysWithTasks = days.filter { day ->
                        day !in existingDays && hasDayTasks(context, appWidgetId, day)
                    }
                    
                    val editor = prefs.edit()
                    var added = 0
                    for (day in daysWithTasks) {
                        if (allConfiguredDays.size + added < 4) {
                            val newIndex = allConfiguredDays.size + added
                            editor.putString("day_${appWidgetId}_$newIndex", day)
                            allConfiguredDays.add(Pair(newIndex, day))
                            added++
                            Log.d("WeeklyWidget", "Auto-added day: $day")
                        } else {
                            break
                        }
                    }
                    if (added > 0) {
                        editor.apply()
                    }
                }
                
                // Filter to only show days with tasks
                val selectedDays = allConfiguredDays.filter { (_, day) ->
                    val hasTasks = hasDayTasks(context, appWidgetId, day)
                    Log.d("WeeklyWidget", "Day $day has tasks: $hasTasks")
                    hasTasks
                }
                
                Log.d("WeeklyWidget", "Days with tasks: ${selectedDays.size}")

                // Handle empty state - show message if no days have tasks
                if (selectedDays.isEmpty()) {
                    Log.d("WeeklyWidget", "No days with tasks found for widget $appWidgetId")
                    
                    // Show empty state message on widget
                    val emptyView = RemoteViews(context.packageName, R.layout.weekly_planner_day_item)
                    emptyView.setTextViewText(R.id.day_name, "No Goals")
                    emptyView.setTextViewText(R.id.todos_text, "Add goals in:\n$currentTheme\n\nTap + to add days")
                    emptyView.setInt(R.id.day_container, "setBackgroundColor", 0xFFFFE4B5.toInt())
                    emptyView.setTextColor(R.id.day_name, 0xFF000000.toInt())
                    emptyView.setTextColor(R.id.todos_text, 0xFF666666.toInt())
                    views.addView(R.id.days_container, emptyView)
                }

                // Add days with tasks
                for (i in selectedDays.indices) {
                    val dayView = RemoteViews(context.packageName, R.layout.weekly_planner_day_item)
                    val dayEntry = selectedDays[i]
                    val day = dayEntry.second
                    
                    // Apply theme-specific styling (match Flutter theme names)
                    when {
                        currentTheme.contains("Japanese") -> {
                            dayView.setImageViewResource(R.id.day_background, japaneseBackgrounds[i])
                        }
                        currentTheme.contains("Patterns") -> {
                            dayView.setImageViewResource(R.id.day_background, patternsBackgrounds[i])
                        }
                        currentTheme.contains("Watercolor") -> {
                            dayView.setImageViewResource(R.id.day_background, watercolorBackgrounds[i])
                        }
                        currentTheme.contains("Floral") -> {
                            dayView.setImageViewResource(R.id.day_background, floralBackgrounds[i])
                        }
                        else -> {
                            // Default to floral theme
                            dayView.setImageViewResource(R.id.day_background, floralBackgrounds[i])
                        }
                    }
                    
                    // Get todos for this day
                    val todos = getTodosForDay(context, currentTheme, day)
                    
                    // Set day name and todos
                    dayView.setTextViewText(R.id.day_name, day)
                    dayView.setTextViewText(R.id.todos_text, todos)
                    
                    Log.d("WeeklyWidget", "Day: $day, Theme: $currentTheme, Todos: ${todos.substring(0, minOf(50, todos.length))}")
                    
                    // Set text colors based on theme
                    dayView.setTextColor(R.id.day_name, Color.BLACK)
                    dayView.setTextColor(R.id.todos_text, Color.BLACK)
                    
                    views.addView(R.id.days_container, dayView)

                    // Add click handler for the day
                    val popupIntent = Intent(context, WeeklyPlannerWidget::class.java).apply {
                        action = "SHOW_POPUP_MENU"
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                        putExtra("day_index", i)
                        putExtra("day", day)
                    }
                    
                    val pendingIntentFlags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    } else {
                        PendingIntent.FLAG_UPDATE_CURRENT
                    }

                    val popupPendingIntent = PendingIntent.getBroadcast(
                        context,
                        appWidgetId * 100 + i,  // Unique request code for each day
                        popupIntent,
                        pendingIntentFlags
                    )
                    
                    // Set the click listener on the entire day container
                    dayView.setOnClickPendingIntent(R.id.day_container, popupPendingIntent)
                }
                
                // Clear and add + button if there's room for more days
                views.removeAllViews(R.id.add_day_container)
                Log.d("WeeklyWidget", "Checking if should add + button. Configured days: ${allConfiguredDays.size}, MAX_DAYS: $MAX_DAYS")
                
                if (allConfiguredDays.size < MAX_DAYS) {
                    Log.d("WeeklyWidget", "Adding + button")
                    val addButtonView = RemoteViews(context.packageName, R.layout.weekly_planner_add_day)
                    
                    val addIntent = Intent(context, WeeklyPlannerConfigureActivity::class.java).apply {
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                        putExtra("day_index", allConfiguredDays.size)
                    }
                    
                    val addPendingIntent = PendingIntent.getActivity(
                        context,
                        appWidgetId * 1000 + allConfiguredDays.size,
                        addIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    
                    addButtonView.setOnClickPendingIntent(R.id.add_day_button, addPendingIntent)
                    views.addView(R.id.add_day_container, addButtonView)
                    Log.d("WeeklyWidget", "+ button added successfully")
                } else {
                    Log.d("WeeklyWidget", "Not adding + button - max days reached")
                }
                
                // If no days are configured yet, show the + button prominently
                if (allConfiguredDays.isEmpty()) {
                    Log.d("WeeklyWidget", "No configured days found, showing add button")
                }

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                Log.e("WeeklyWidget", "Error updating widget", e)
                // Show a basic error state
                val errorView = RemoteViews(context.packageName, R.layout.weekly_planner_day_item)
                errorView.setTextViewText(R.id.day_name, "Error loading widget")
                views.addView(R.id.days_container, errorView)
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }

        private fun getCurrentTheme(context: Context, appWidgetId: Int): String {
            // Auto-detect current theme from last used theme in app
            val prefs = HomeWidgetPlugin.getData(context)
            return prefs.getString("flutter.weekly_planner_current_theme", null)
                ?: prefs.getString("weekly_planner_current_theme", "Floral Weekly Planner")
                ?: "Floral Weekly Planner"
        }

        private fun getTodosForDay(context: Context, theme: String, day: String): String {
            // Use universal storage key (same across all themes)
            val prefs = HomeWidgetPlugin.getData(context)
            // Check both flutter. prefixed and non-prefixed keys
            val todosJson = prefs.getString("flutter.weekly_planner_$day", null)
                ?: prefs.getString("weekly_planner_$day", "[]")
                ?: "[]"

            return try {
                val jsonArray = JSONArray(todosJson)
                val todoItems = mutableListOf<String>()
                
                for (i in 0 until jsonArray.length()) {
                    val todoObj = jsonArray.getJSONObject(i)
                    val text = "• ${todoObj.getString("text")}"
                    // Check both "completed" and "isDone" fields for compatibility
                    val isDone = todoObj.optBoolean("completed", false) || todoObj.optBoolean("isDone", false)
                    
                    if (isDone) {
                        // Use a more visible strikethrough character combination
                        val strikethroughText = StringBuilder()
                        for (char in text) {
                            strikethroughText.append(char).append('\u0336')
                        }
                        todoItems.add(strikethroughText.toString())
                    } else {
                        todoItems.add("$text")
                    }
                }
                
                todoItems.joinToString("\n")
            } catch (e: Exception) {
                ""
            }
        }

        /**
         * Check if a day has any tasks for the given theme
         */
        fun hasDayTasks(context: Context, appWidgetId: Int, day: String): Boolean {
            // Use universal storage key (check both flutter. prefix and without)
            val prefs = HomeWidgetPlugin.getData(context)
            val todosJson = prefs.getString("flutter.weekly_planner_$day", null)
                ?: prefs.getString("weekly_planner_$day", null)
            
            if (todosJson?.isEmpty() != false) {
                Log.d("WeeklyWidget", "No data found for day: $day")
                return false
            }
            
            return try {
                val jsonArray = JSONArray(todosJson)
                val hasTasks = jsonArray.length() > 0
                Log.d("WeeklyWidget", "Day $day has ${jsonArray.length()} tasks")
                hasTasks
            } catch (e: Exception) {
                Log.e("WeeklyWidget", "Error parsing tasks for $day: ${e.message}")
                todosJson?.trim()?.isNotEmpty() == true
            }
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            "SHOW_POPUP_MENU" -> {
                val appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
                val dayIndex = intent.getIntExtra("day_index", 0)
                val day = intent.getStringExtra("day") ?: return

                // Create and show the popup dialog activity
                val dialogIntent = Intent(context, WeeklyPlannerPopupMenuActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    putExtra("day_index", dayIndex)
                    putExtra("day", day)
                }
                context.startActivity(dialogIntent)
            }
            AppWidgetManager.ACTION_APPWIDGET_UPDATE -> {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    android.content.ComponentName(context, WeeklyPlannerWidget::class.java)
                )
                for (appWidgetId in appWidgetIds) {
                    updateAppWidget(context, appWidgetManager, appWidgetId)
                }
            }
        }
    }
}