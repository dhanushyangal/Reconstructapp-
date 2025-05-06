package com.reconstrect.visionboard

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import android.util.Log
import org.json.JSONArray
import java.util.*
import android.graphics.Color
import android.view.View

class AnnualPlannerWidget : AppWidgetProvider() {
    companion object {
        private const val MAX_MONTHS = 12
        
        private val monthsList = arrayOf(
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        )
        
        private val postitColors = arrayOf(
            0xFFFF7F6A.toInt(), // January - Coral
            0xFFFFB347.toInt(), // February - Orange
            0xFFFFB5B5.toInt(), // March - Pink
            0xFF4169E1.toInt(), // April - Royal Blue
            0xFF87CEEB.toInt(), // May - Sky Blue
            0xFFFFF0F5.toInt(), // June - Light Pink
            0xFFFFFF00.toInt(), // July - Yellow
            0xFFFF69B4.toInt(), // August - Hot Pink
            0xFF00CED1.toInt(), // September - Turquoise
            0xFFFF69B4.toInt(), // October - Pink Purple
            0xFF4169E1.toInt(), // November - Royal Blue
            0xFFFF6B6B.toInt() // Light Rose
        )
        
        private val premiumColors = arrayOf(
            0xFF202020.toInt(),
            0xFF202020.toInt(),
            0xFF202020.toInt(),
            0xFF202020.toInt(),
            0xFF202020.toInt(),
            0xFF202020.toInt(),
            0xFF202020.toInt(),
            0xFF202020.toInt(),
            0xFF202020.toInt(),
            0xFF202020.toInt(),
            0xFF202020.toInt(),
            0xFF202020.toInt()
        )
        
        private val watercolorColors = arrayOf(
            R.drawable.watercolor_1,  // January
            R.drawable.watercolor_2,  // February
            R.drawable.watercolor_3,  // March
            R.drawable.watercolor_4,  // April
            R.drawable.watercolor_5,  // May
            R.drawable.watercolor_6,  // June
            R.drawable.watercolor_7,  // July
            R.drawable.watercolor_8,  // August
            R.drawable.watercolor_9,  // September
            R.drawable.watercolor_10, // October
            R.drawable.watercolor_11, // November
            R.drawable.watercolor_12  // December
        )
        
        private val floralBackgrounds = arrayOf(
            R.drawable.floral_1,  // January
            R.drawable.floral_2,  // February
            R.drawable.floral_3,  // March
            R.drawable.floral_4,  // April
            R.drawable.floral_5,  // May
            R.drawable.floral_6,  // June
            R.drawable.floral_7,  // July
            R.drawable.floral_8,  // August
            R.drawable.floral_1,  // September
            R.drawable.floral_2, // October
            R.drawable.floral_3, // November
            R.drawable.floral_4  // December
        )
        
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.annual_planner_widget)
            views.removeAllViews(R.id.months_container)
            
            try {
                // Get current theme and active months
                val prefs = HomeWidgetPlugin.getData(context)
                val currentTheme = prefs.getString("annual_planner_theme_$appWidgetId", "PostIt Annual Planner") ?: "PostIt Annual Planner"
                
                // Count active months
                val selectedMonths = mutableListOf<Pair<Int, String>>()
                for (i in 0 until MAX_MONTHS) {
                    val month = prefs.getString("month_${appWidgetId}_$i", null)
                    if (month != null) {
                        selectedMonths.add(Pair(i, month))
                    }
                }
                
                val activeMonthCount = selectedMonths.size

                // Add existing months
                for (i in 0 until MAX_MONTHS) {
                    val monthItem = RemoteViews(context.packageName, R.layout.annual_planner_month_item)
                    
                    // Find if there's a month for this position
                    val monthEntry = selectedMonths.find { it.first == i }
                    
                    if (monthEntry != null) {
                        val month = monthEntry.second
                        
                        // Get todos for this month
                        var todoText = getTodoTextForMonth(context, currentTheme, month)
                        
                        // Set month name and todos
                        monthItem.setTextViewText(R.id.month_name, month)
                        monthItem.setTextViewText(R.id.todo_text, todoText)
                        
                        
                        // Set background image based on theme
                        val monthIndex = monthsList.indexOf(month)
                        when (currentTheme) {
                            "PostIt Annual Planner" -> {
                                views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.postit_background)
                                views.setInt(R.id.categories_container, "setBackgroundResource", 0) // Remove background
                                monthItem.setInt(R.id.month_container, "setBackgroundColor", postitColors[monthIndex])
                                monthItem.setTextColor(R.id.month_name, Color.parseColor("#1976D2")) // Using hex color for blue
                                monthItem.setTextColor(R.id.todo_text, Color.BLACK)
                            }
                            "Premium Annual Planner" -> {
                                views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.vision_board_background)
                                views.setInt(R.id.categories_container, "setBackgroundResource", 0)
                                monthItem.setInt(R.id.month_container, "setBackgroundColor", premiumColors[monthIndex])
                                monthItem.setTextColor(R.id.month_name, 0xFFFFFFFF.toInt()) // White text
                                monthItem.setTextColor(R.id.todo_text, 0xFFFFFFFF.toInt())  // White text
                            }
                            "Watercolor Annual Planner" -> {
                                views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.vision_board_background)
                                views.setInt(R.id.categories_container, "setBackgroundResource", 0)
                                monthItem.setImageViewResource(R.id.month_background, watercolorColors[monthIndex])
                                monthItem.setInt(R.id.month_container, "setBackgroundColor", 0x00000000) // Transparent
                                monthItem.setTextColor(R.id.month_name, Color.BLACK)
                                monthItem.setTextColor(R.id.todo_text, Color.BLACK)
                            }
                            "Floral Annual Planner" -> {
                                views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.vision_board_background)
                                views.setInt(R.id.categories_container, "setBackgroundResource", 0)
                                monthItem.setImageViewResource(R.id.month_background, floralBackgrounds[monthIndex])
                                monthItem.setInt(R.id.month_container, "setBackgroundColor", 0x00000000) // Transparent
                                monthItem.setTextColor(R.id.month_name, 0xFFFFFFFF.toInt()) // White text for month name
                                monthItem.setTextColor(R.id.todo_text, 0xFFFFFFFF.toInt())  // White text for todo text
                            }
                        }
                        
                        // Add click handler for the month item
                        val editIntent = Intent(context, AnnualPlannerWidget::class.java).apply {
                            action = "EDIT_MONTH"
                            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                            putExtra("month_index", i)
                            putExtra("month", month)
                        }
                        
                        val pendingIntentFlags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                        } else {
                            PendingIntent.FLAG_UPDATE_CURRENT
                        }
                        
                        val editPendingIntent = PendingIntent.getBroadcast(
                            context,
                            appWidgetId * 100 + i, // Unique request code
                            editIntent,
                            pendingIntentFlags
                        )
                        monthItem.setOnClickPendingIntent(R.id.month_container, editPendingIntent)
                        
                        views.addView(R.id.months_container, monthItem)
                        
                        // Add + button if this is the last filled slot and there's room for more
                        if (i == selectedMonths.size - 1 && selectedMonths.size < MAX_MONTHS) {
                            val addButtonView = RemoteViews(context.packageName, R.layout.annual_planner_add_month)
                            
                            // Create intent for adding new month
                            val addIntent = Intent(context, AnnualPlannerConfigureActivity::class.java).apply {
                                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                                putExtra("month_index", selectedMonths.size)
                            }
                            
                            val addPendingIntent = PendingIntent.getActivity(
                                context,
                                appWidgetId * 1000 + selectedMonths.size, // Unique request code
                                addIntent,
                                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                            )
                            
                            addButtonView.setOnClickPendingIntent(R.id.add_month_button, addPendingIntent)
                            views.addView(R.id.months_container, addButtonView)
                        }
                    } else {
                        // Empty slot
                        monthItem.setViewVisibility(R.id.month_name, View.INVISIBLE)
                        monthItem.setViewVisibility(R.id.todo_text, View.INVISIBLE)
                        monthItem.setViewVisibility(R.id.month_background, View.INVISIBLE)
                        views.addView(R.id.months_container, monthItem)
                    }
                }

                appWidgetManager.updateAppWidget(appWidgetId, views)
                Log.d("AnnualPlannerWidget", "Widget updated with $activeMonthCount months")
            } catch (e: Exception) {
                Log.e("AnnualPlannerWidget", "Error updating widget", e)
                // Show a basic error state
                val errorView = RemoteViews(context.packageName, R.layout.annual_planner_month_item)
                errorView.setTextViewText(R.id.month_name, "Error loading widget")
                views.addView(R.id.months_container, errorView)
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }
        
        private fun getTodoTextForMonth(context: Context, theme: String, month: String): String {
            val prefs = HomeWidgetPlugin.getData(context)
            
            // Only use direct JSON parsing - skip pre-formatted text
            val jsonKey = when (theme) {
                "PostIt Annual Planner" -> "PostItTheme_todos_$month"
                "Premium Annual Planner" -> "PremiumTheme_todos_$month"
                "Watercolor Annual Planner" -> "WatercolorTheme_todos_$month"
                "Floral Annual Planner" -> "FloralTheme_todos_$month"
                else -> "PostItTheme_todos_$month"
            }
            
            // Get JSON data directly and log for debugging
            val encodedTodos = prefs.getString(jsonKey, null)
            Log.d("AnnualPlannerWidget", "Loading todos for $month with key $jsonKey: ${encodedTodos?.length ?: 0} chars")
            
            return getTodoTextFromEncoded(encodedTodos)
        }

        private fun getTodoTextFromEncoded(encodedTodos: String?): String {
            return try {
                val jsonArray = JSONArray(encodedTodos ?: "[]")
                val todoItems = mutableListOf<String>()
                
                for (j in 0 until jsonArray.length()) {
                    val todoObj = jsonArray.getJSONObject(j)
                    val text = "• ${todoObj.getString("text")}"
                    
                    // Check both field names for completion status
                    val isDone = if (todoObj.has("isDone")) {
                        todoObj.getBoolean("isDone")
                    } else if (todoObj.has("completed")) {
                        todoObj.getBoolean("completed")
                    } else {
                        false
                    }
                    
                    if (isDone) {
                        // Use a more visible strikethrough character combination
                        val strikethroughText = StringBuilder()
                        for (char in text) {
                            strikethroughText.append(char).append('\u0336')
                        }
                        todoItems.add(strikethroughText.toString())
                    } else {
                        // Use consistent bullet point for incomplete tasks
                        todoItems.add("$text")
                    }
                }
                
                todoItems.joinToString("\n")
            } catch (e: Exception) {
                Log.e("AnnualPlannerWidget", "Error parsing todos", e)
                ""
            }
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(
            android.content.ComponentName(context, AnnualPlannerWidget::class.java)
        )
        
        for (appWidgetId in appWidgetIds) {
            // Initialize default theme and month
            val calendar = Calendar.getInstance()
            val currentMonth = monthsList[calendar.get(Calendar.MONTH)]
            
            val prefs = HomeWidgetPlugin.getData(context)
            val editor = prefs.edit()
            editor.putString("annual_planner_theme_$appWidgetId", "PostIt Annual Planner")
            editor.putString("month_${appWidgetId}_0", currentMonth)
            editor.apply()
            
            // Update the widget
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            "EDIT_MONTH" -> {
                val appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
                val monthIndex = intent.getIntExtra("month_index", 0)
                val month = intent.getStringExtra("month") ?: return
                
                // Launch the annual planner popup menu activity
                val popupIntent = Intent(context, AnnualPlannerPopupMenuActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    putExtra("month_index", monthIndex)
                    putExtra("month", month)
                }
                context.startActivity(popupIntent)
            }
            AppWidgetManager.ACTION_APPWIDGET_UPDATE -> {
                    val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    android.content.ComponentName(context, AnnualPlannerWidget::class.java)
                )
                    for (appWidgetId in appWidgetIds) {
                        updateAppWidget(context, appWidgetManager, appWidgetId)
                    }
                }
        }
    }
} 