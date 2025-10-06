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
        private const val MAX_DAYS = 7
        
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
                
                // Get all configured days
                val allConfiguredDays = mutableListOf<Pair<Int, String>>()
                for (i in 0 until MAX_DAYS) {
                    val day = HomeWidgetPlugin.getData(context).getString("day_${appWidgetId}_$i", null)
                    if (day != null) {
                        allConfiguredDays.add(Pair(i, day))
                    }
                }
                
                // Filter to only show days with tasks
                val selectedDays = allConfiguredDays.filter { (_, day) ->
                    hasDayTasks(context, appWidgetId, day)
                }

                // Add days with tasks
                for (i in selectedDays.indices) {
                    val dayView = RemoteViews(context.packageName, R.layout.weekly_planner_day_item)
                    val dayEntry = selectedDays[i]
                    val day = dayEntry.second
                    
                    // Apply theme-specific styling
                    when (currentTheme) {
                        "Japanese theme Weekly Planner" -> {
                            dayView.setImageViewResource(R.id.day_background, japaneseBackgrounds[i])
                        }
                        "Patterns theme Weekly Planner" -> {
                            dayView.setImageViewResource(R.id.day_background, patternsBackgrounds[i])
                        }
                        "Watercolor theme Weekly Planner" -> {
                            dayView.setImageViewResource(R.id.day_background, watercolorBackgrounds[i])
                        }
                        "Floral theme Weekly Planner" -> {
                            dayView.setImageViewResource(R.id.day_background, floralBackgrounds[i])
                        }
                    }
                    
                    // Get todos for this day
                    val todos = getTodosForDay(context, currentTheme, day)
                    
                    // Set day name and todos
                    dayView.setTextViewText(R.id.day_name, day)
                    dayView.setTextViewText(R.id.todos_text, todos)
                    
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
                
                // Add + button if there's room for more days
                if (allConfiguredDays.size < MAX_DAYS) {
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
                    views.addView(R.id.days_container, addButtonView)
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
            return HomeWidgetPlugin.getData(context)
                .getString("weekly_planner_theme_$appWidgetId", "Japanese theme Weekly Planner") ?: "Japanese theme Weekly Planner"
        }

        private fun getTodosForDay(context: Context, theme: String, day: String): String {
            val prefs = HomeWidgetPlugin.getData(context)
            val key = when (theme) {
                "Japanese theme Weekly Planner" -> "JapaneseTheme_todos_$day"
                "Patterns theme Weekly Planner" -> "PatternsTheme_todos_$day"
                "Watercolor theme Weekly Planner" -> "WatercolorTheme_todos_$day"
                "Floral theme Weekly Planner" -> "FloralTheme_todos_$day"
                else -> "JapaneseTheme_todos_$day"
            }

            return try {
                val todosJson = prefs.getString(key, "[]") ?: "[]"
                val jsonArray = JSONArray(todosJson)
                val todoItems = mutableListOf<String>()
                
                for (i in 0 until jsonArray.length()) {
                    val todoObj = jsonArray.getJSONObject(i)
                    val text = "• ${todoObj.getString("text")}"
                    val isDone = todoObj.getBoolean("isDone")
                    
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
            val prefs = HomeWidgetPlugin.getData(context)
            val currentTheme = getCurrentTheme(context, appWidgetId)
            
            val key = when (currentTheme) {
                "Japanese theme Weekly Planner" -> "JapaneseTheme_todos_$day"
                "Patterns theme Weekly Planner" -> "PatternsTheme_todos_$day"
                "Watercolor theme Weekly Planner" -> "WatercolorTheme_todos_$day"
                "Floral theme Weekly Planner" -> "FloralTheme_todos_$day"
                else -> "JapaneseTheme_todos_$day"
            }
            
            val todosJson = prefs.getString(key, null)
            if (todosJson?.isEmpty() != false) return false
            
            return try {
                val jsonArray = JSONArray(todosJson)
                jsonArray.length() > 0
            } catch (e: Exception) {
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