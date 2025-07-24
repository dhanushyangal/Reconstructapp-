package com.reconstrect.visionboard

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.util.Log
import android.widget.RemoteViews
import java.util.Calendar
import android.content.SharedPreferences
import android.app.PendingIntent
import org.json.JSONObject
import android.text.Html

class CalendarThemeWidget : AppWidgetProvider() {
    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val HOME_WIDGET_DATA_NAME = "home_widget_data"
        private const val CALENDAR_DATA_KEY = "calendar_data"
        
        fun getThemeKey(appWidgetId: Int) = "calendar_theme_$appWidgetId"

        private fun getCurrentTheme(context: Context, appWidgetId: Int): String {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val themeKey = getThemeKey(appWidgetId)
            val defaultTheme = "Animal theme 2025 Calendar"
            val theme = prefs.getString(themeKey, defaultTheme) ?: defaultTheme
            
            // Add debug logging
            Log.d("CalendarWidget", "Getting theme for widget $appWidgetId")
            Log.d("CalendarWidget", "Theme key: $themeKey")
            Log.d("CalendarWidget", "Retrieved theme: $theme")
            
            return theme
        }

        private fun createEventsViewIntent(context: Context, monthIndex: Int, appWidgetId: Int): PendingIntent {
            val currentTheme = getCurrentTheme(context, appWidgetId)
            Log.d("CalendarWidget", "Creating intent for theme: $currentTheme")
            
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("action", "openEventsView")
                putExtra("month_index", monthIndex)
                putExtra("show_events", true)
                putExtra("calendar_theme", currentTheme)
            }
            
            return PendingIntent.getActivity(
                context,
                monthIndex,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        // Define category colors
        private val categoryColors = mapOf(
            "Personal" to Color.parseColor("#ff6f61"),     // Coral
            "Professional" to Color.parseColor("#1b998b"),  // Teal
            "Finance" to Color.parseColor("#fddb3a"),      // Yellow
            "Health" to Color.parseColor("#8360c3")        // Purple
        )
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d("CalendarWidget", "onUpdate called for ${appWidgetIds.size} widgets")
        for (appWidgetId in appWidgetIds) {
            try {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            } catch (e: Exception) {
                Log.e("CalendarWidget", "Error updating widget $appWidgetId: ${e.message}")
                e.printStackTrace()
            }
        }
    }

    fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.calendar_theme_widget)
        val calendar = Calendar.getInstance()
        
        try {
            val currentTheme = getCurrentTheme(context, appWidgetId)
            Log.d("CalendarWidget", "Current theme: $currentTheme")
            
            val calendarDataKey = getCalendarDataKey(currentTheme)
            Log.d("CalendarWidget", "Calendar data key: $calendarDataKey")
            
            val calendarData = getCalendarData(context, appWidgetId)
            Log.d("CalendarWidget", "Raw calendar data: $calendarData")
            
            val selectedDates = parseCalendarData(calendarData)
            Log.d("CalendarWidget", "Parsed selected dates: $selectedDates")
            
            // Set month name and year
            val monthName = getMonthName(calendar.get(Calendar.MONTH))
            views.setTextViewText(R.id.month_name, "$monthName ${calendar.get(Calendar.YEAR)}")
            
            // Load the current month's image
            val imagePrefix = when (currentTheme) {
                "Animal theme 2025 Calendar" -> "animaltheme"
                "Summer theme 2025 Calendar" -> "summertheme"
                "Spaniel theme 2025 Calendar" -> "spanieltheme"
                "Happy Couple theme 2025 Calendar" -> "happycoupletheme"
                else -> "animaltheme"
            }
            loadMonthImage(context, views, imagePrefix, calendar.get(Calendar.MONTH) + 1)

            updateCalendarGrid(context, views, calendar, selectedDates)
            
        } catch (e: Exception) {
            Log.e("CalendarWidget", "Error updating widget: ${e.message}")
            e.printStackTrace()
        }
        
        // Add click listener for the events button
        val monthIndex = calendar.get(Calendar.MONTH)
        val eventsIntent = createEventsViewIntent(context, monthIndex, appWidgetId)
        views.setOnClickPendingIntent(R.id.view_events_button, eventsIntent)
        
        // Add click listener for the edit text
        val editIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("action", "edit_calendar")
            putExtra("theme", getCurrentTheme(context, appWidgetId))
        }
        val editPendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId + 100,
            editIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.month_name, editPendingIntent)
        
        // Add click listener for the add button
        val addIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("action", "edit_calendar")
            putExtra("month_index", calendar.get(Calendar.MONTH))
            putExtra("calendar_theme", getCurrentTheme(context, appWidgetId))
        }
        val addPendingIntent = PendingIntent.getActivity(
            context,
            appWidgetId + 200, // Unique request code for add button
            addIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Update the button size
        views.setViewPadding(R.id.view_events_button, 8, 8, 8, 8) // Reduce padding
        views.setInt(R.id.view_events_button, "setMinimumWidth", 48) // Set minimum width
        views.setInt(R.id.view_events_button, "setMinimumHeight", 48) // Set minimum height
        views.setOnClickPendingIntent(R.id.view_events_button, addPendingIntent)
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        Log.d("CalendarWidget", "Received intent: ${intent.action}")
        
        if (intent.action == AppWidgetManager.ACTION_APPWIDGET_UPDATE ||
            intent.action == "CALENDAR_DATA_UPDATED") {
            
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                android.content.ComponentName(context, CalendarThemeWidget::class.java)
            )
            
            Log.d("CalendarWidget", "Updating ${appWidgetIds.size} widgets")
            
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }

    private fun parseCalendarData(data: String?): Map<String, String> {
        if (data.isNullOrEmpty() || data == "{}") {
            Log.d("CalendarWidget", "No data to parse")
            return emptyMap()
        }

        val events = mutableMapOf<String, String>()
        try {
            Log.d("CalendarWidget", "Parsing data: $data")
            val jsonObject = JSONObject(data)
            val iterator = jsonObject.keys()
            while (iterator.hasNext()) {
                val dateStr = iterator.next()
                val category = jsonObject.getString(dateStr)
                events[dateStr] = category
                Log.d("CalendarWidget", "Parsed event: $dateStr -> $category")
            }
        } catch (e: Exception) {
            Log.e("CalendarWidget", "Error parsing calendar data", e)
        }
        
        Log.d("CalendarWidget", "Parsed ${events.size} events")
        return events
    }

    private fun updateCalendarGrid(
        context: Context,
        views: RemoteViews,
        calendar: Calendar,
        selectedDates: Map<String, String>
    ) {
        val monthDays = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
        calendar.set(Calendar.DAY_OF_MONTH, 1)
        val firstDayOfMonth = calendar.get(Calendar.DAY_OF_WEEK) - 1
        
        // Get today's date components
        val today = Calendar.getInstance()
        val isCurrentMonth = today.get(Calendar.MONTH) == calendar.get(Calendar.MONTH) &&
                            today.get(Calendar.YEAR) == calendar.get(Calendar.YEAR)
        val todayDate = today.get(Calendar.DAY_OF_MONTH)
        
        Log.d("CalendarWidget", "First day of month falls on: $firstDayOfMonth (0=Sunday)")
        Log.d("CalendarWidget", "Updating calendar grid with ${selectedDates.size} events")
        
        // Create calendar grid
        val gridLayout = RemoteViews(context.packageName, R.layout.calendar_grid)
        
        // Add day headers (Sunday to Saturday)
        for (day in arrayOf("S", "M", "T", "W", "T", "F", "S")) {
            val dayHeaderView = RemoteViews(context.packageName, R.layout.calendar_day_item)
            dayHeaderView.setTextViewText(R.id.day_text, day)
            dayHeaderView.setInt(R.id.day_text, "setTextColor", Color.BLACK)
            dayHeaderView.setInt(R.id.day_text, "setBackgroundResource", 0) // Remove background/border
            gridLayout.addView(R.id.calendar_grid, dayHeaderView)
        }
        
        // Add empty cells before the first day of the month
        for (i in 0 until firstDayOfMonth) {
            val emptyView = RemoteViews(context.packageName, R.layout.calendar_day_item)
            emptyView.setTextViewText(R.id.day_text, "")
            emptyView.setInt(R.id.day_text, "setBackgroundResource", 0) // Remove background/border
            gridLayout.addView(R.id.calendar_grid, emptyView)
        }
        
        // Add the days of the month
        for (day in 1..monthDays) {
            val dayView = RemoteViews(context.packageName, R.layout.calendar_day_item)
            
            // Format date string to match Flutter's format
            val dateStr = String.format(
                "%d-%02d-%02d",
                calendar.get(Calendar.YEAR),
                calendar.get(Calendar.MONTH) + 1,
                day
            )
            
            // Check if this date has an event
            val category = selectedDates[dateStr]
            
            // Make today's date bold and blue if we're in the current month
            if (isCurrentMonth && day == todayDate) {
                dayView.setTextViewText(R.id.day_text, Html.fromHtml("<b>${day}</b>"))
                dayView.setFloat(R.id.day_text, "setTextSize", 15f)
                dayView.setInt(R.id.day_text, "setTextColor", Color.parseColor("#23c4f7"))
                dayView.setInt(R.id.day_text, "setBackgroundResource", R.drawable.calendar_day_with_border)
            } else if (category != null) {
                val backgroundColor = categoryColors[category]
                if (backgroundColor != null) {
                    dayView.setTextViewText(R.id.day_text, day.toString())
                    dayView.setInt(R.id.day_text, "setBackgroundColor", backgroundColor)
                    dayView.setInt(R.id.day_text, "setTextColor", Color.WHITE)
                }
            } else {
                dayView.setTextViewText(R.id.day_text, day.toString())
                dayView.setInt(R.id.day_text, "setBackgroundResource", R.drawable.calendar_day_with_border)
                dayView.setInt(R.id.day_text, "setTextColor", Color.BLACK)
            }
            
            gridLayout.addView(R.id.calendar_grid, dayView)
        }
        
        // Fill remaining cells to complete the grid
        val totalCells = 42 // 6 rows × 7 days
        val remainingCells = totalCells - (firstDayOfMonth + monthDays)
        for (i in 0 until remainingCells) {
            val emptyView = RemoteViews(context.packageName, R.layout.calendar_day_item)
            emptyView.setTextViewText(R.id.day_text, "")
            emptyView.setInt(R.id.day_text, "setBackgroundResource", 0) // Remove background/border
            gridLayout.addView(R.id.calendar_grid, emptyView)
        }
        
        views.removeAllViews(R.id.calendar_container)
        views.addView(R.id.calendar_container, gridLayout)
    }

    private fun getFirstDayOffset(calendar: Calendar): Int {
        val temp = calendar.clone() as Calendar
        temp.set(Calendar.DAY_OF_MONTH, 1)
        return temp.get(Calendar.DAY_OF_WEEK) - 1
    }

    private fun getMonthName(month: Int): String = when (month) {
        0 -> "January"
        1 -> "February"
        2 -> "March"
        3 -> "April"
        4 -> "May"
        5 -> "June"
        6 -> "July"
        7 -> "August"
        8 -> "September"
        9 -> "October"
        10 -> "November"
        else -> "December"
    }

    private fun getCalendarDataKey(theme: String): String = when (theme) {
        "Animal theme 2025 Calendar" -> "animal.calendar_theme_2025"
        "Summer theme 2025 Calendar" -> "summer.calendar_theme_2025"
        "Spaniel theme 2025 Calendar" -> "spaniel.calendar_theme_2025"
        "Happy Couple theme 2025 Calendar" -> "happy_couple.calendar_theme_2025"
        else -> "animal.calendar_theme_2025"
    }

    private fun getCalendarData(context: Context, appWidgetId: Int): String? {
        val currentTheme = getCurrentTheme(context, appWidgetId)
        Log.d("CalendarWidget", "Getting calendar data for theme: $currentTheme")
        
        // Get the appropriate key based on the theme
        val dataKey = getCalendarDataKey(currentTheme)
        Log.d("CalendarWidget", "Using data key: $dataKey")
        
        // Try HomeWidget data first
        val homeWidgetPrefs = context.getSharedPreferences(HOME_WIDGET_DATA_NAME, Context.MODE_PRIVATE)
        var data = homeWidgetPrefs.getString(dataKey, null)
        if (!data.isNullOrEmpty() && data != "{}") {
            Log.d("CalendarWidget", "Found data in HomeWidget: $data")
            return data
        }
        
        // Try Flutter preferences
        val flutterPrefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        data = flutterPrefs.getString(dataKey, null)
        if (!data.isNullOrEmpty() && data != "{}") {
            Log.d("CalendarWidget", "Found data in FlutterPrefs: $data")
            return data
        }
        
        // Try alternative keys as fallback
        val alternativeKeys = listOf(
            "${dataKey}_data",
            "flutter.$dataKey",
            dataKey.replace("_theme_2025", "_data")
        )
        
        for (key in alternativeKeys) {
            data = homeWidgetPrefs.getString(key, null) ?: flutterPrefs.getString(key, null)
            if (!data.isNullOrEmpty() && data != "{}") {
                Log.d("CalendarWidget", "Found data with alternative key $key: $data")
                return data
            }
        }
        
        Log.d("CalendarWidget", "No valid data found for theme: $currentTheme")
        return "{}"
    }

    private fun loadMonthImage(context: Context, views: RemoteViews, imagePrefix: String, monthNumber: Int) {
        val imageResourceId = when (imagePrefix) {
            "animaltheme" -> context.resources.getIdentifier(
                "animal_theme$monthNumber",
                "drawable",
                context.packageName
            )
            "summertheme" -> context.resources.getIdentifier(
                "summertheme_$monthNumber",
                "drawable",
                context.packageName
            )
            "spanieltheme" -> context.resources.getIdentifier(
                "spanieltheme_$monthNumber",
                "drawable",
                context.packageName
            )
            "happycoupletheme" -> context.resources.getIdentifier(
                "couple$monthNumber",
                "drawable",
                context.packageName
            )
            else -> 0
        }
        
        if (imageResourceId != 0) {
            views.setImageViewResource(R.id.month_image, imageResourceId)
        } else {
            // Fallback to animal theme if image not found
            val defaultImageId = context.resources.getIdentifier(
                "animaltheme_$monthNumber",
                "drawable",
                context.packageName
            )
            if (defaultImageId != 0) {
                views.setImageViewResource(R.id.month_image, defaultImageId)
            }
        }
    }
} 