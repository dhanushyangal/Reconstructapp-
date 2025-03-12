package com.example.reconstrect1

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import android.util.Log
import android.app.PendingIntent
import android.view.View
import org.json.JSONArray
import org.json.JSONObject

class VisionBoardWidget : AppWidgetProvider() {
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
                val categoryIndex = intent.getIntExtra("category_index", 0)
                val category = intent.getStringExtra("category") ?: return

                // Create and show the popup dialog activity with FLAG_ACTIVITY_NEW_TASK and FLAG_ACTIVITY_CLEAR_TOP
                val dialogIntent = Intent(context, PopupMenuActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    putExtra("category_index", categoryIndex)
                    putExtra("category", category)
                }
                context.startActivity(dialogIntent)
            }
            "OPEN_VISION_BOARD" -> {
                val category = intent.getStringExtra("category") ?: return

                // Launch the main app with category information
                val mainIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("route", "/vision_board")
                    putExtra("category", category)
                }
                context.startActivity(mainIntent)
            }
            AppWidgetManager.ACTION_APPWIDGET_UPDATE -> {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(
                    android.content.ComponentName(context, VisionBoardWidget::class.java)
                )
                for (appWidgetId in appWidgetIds) {
                    updateAppWidget(context, appWidgetManager, appWidgetId)
                }
            }
        }
    }

    companion object {
        private const val MAX_CATEGORIES = 5
        
        // Color arrays for each theme's categories
        private val premiumColors = arrayOf(
            0xFF2C2C2C.toInt(),
            0xFF363636.toInt(),
            0xFF404040.toInt(),
            0xFF4A4A4A.toInt(),
            0xFF545454.toInt()
        )
        
        private val postitColors = arrayOf(
            0xFFFFB74D.toInt(),
            0xFFFFCC80.toInt(),
            0xFFFFE0B2.toInt(),
            0xFFFFECB3.toInt(),
            0xFFFFF3E0.toInt()
        )
        
        private val boxColors = arrayOf(
            0xFF90CAF9.toInt(),
            0xFF64B5F6.toInt(),
            0xFF42A5F5.toInt(),
            0xFF2196F3.toInt(),
            0xFF1E88E5.toInt()
        )
        
        private val animalColors = arrayOf(
            0xFF8D6E63.toInt(),
            0xFF795548.toInt(),
            0xFF6D4C41.toInt(),
            0xFF5D4037.toInt(),
            0xFF4E342E.toInt()
        )
        
        private val sportColors = arrayOf(
            0xFF66BB6A.toInt(),
            0xFF4CAF50.toInt(),
            0xFF43A047.toInt(),
            0xFF388E3C.toInt(),
            0xFF2E7D32.toInt()
        )
        
        private val watercolorColors = arrayOf(
            0xFFE1BEE7.toInt(),
            0xFFCE93D8.toInt(),
            0xFFBA68C8.toInt(),
            0xFFAB47BC.toInt(),
            0xFF9C27B0.toInt()
        )

        private fun getThemeKey(appWidgetId: Int) = "widget_theme_$appWidgetId"  // New function for per-widget theme key

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            try {
                val prefs = HomeWidgetPlugin.getData(context)
                val views = RemoteViews(context.packageName, R.layout.vision_board_widget)
                
                // Get current theme using widget-specific key
                val currentTheme = prefs.getString(getThemeKey(appWidgetId), "Box Vision Board")
                
                // Set widget background based on theme
                when (currentTheme) {
                    "Premium Vision Board" -> {
                        // Set both container backgrounds to black
                        views.setInt(R.id.widget_container, "setBackgroundColor", 0xFF000000.toInt())
                        views.setInt(R.id.widget_title, "setTextColor", 0xFFFFFFFF.toInt())
                        
                        // Set category text color to white
                        for (i in 0 until MAX_CATEGORIES) {
                            val categoryId = context.resources.getIdentifier(
                                "category_$i",
                                "id",
                                context.packageName
                            )
                            if (categoryId != 0) {
                                views.setTextColor(categoryId, 0xFFFFFFFF.toInt())
                            }
                        }
                    }
                    "PostIt Vision Board" -> {
                        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.postit_background)
                        views.setInt(R.id.categories_container, "setBackgroundResource", R.drawable.postit_background)
                        views.setInt(R.id.widget_title, "setTextColor", 0xFF000000.toInt())
                    }
                     "Box Vision Board" -> {
                        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.box_vision_background) // Set the image resource
                        views.setInt(R.id.categories_container, "setBackgroundResource", R.drawable.box_vision_background) // Set the same image for categories
                        views.setInt(R.id.widget_title, "setTextColor", 0xFF1976D2.toInt())
                    }
                    "Animal Vision Board" -> {
                        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.animal_background)
                        views.setInt(R.id.categories_container, "setBackgroundResource", R.drawable.animal_background)
                        views.setInt(R.id.widget_title, "setTextColor", 0xFFFFFFFF.toInt())
                    }
                    "Sport Vision Board" -> {
                        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.sport_background)
                        views.setInt(R.id.categories_container, "setBackgroundResource", R.drawable.sport_background)
                        views.setInt(R.id.widget_title, "setTextColor", 0xFFFFFFFF.toInt())
                    }
                    "Watercolor Vision Board" -> {
                        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.watercolor_background)
                        views.setInt(R.id.categories_container, "setBackgroundResource", R.drawable.watercolor_background)
                        views.setInt(R.id.widget_title, "setTextColor", 0xFF000000.toInt())
                    }
                    else -> {
                        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.vision_board_background)
                        views.setInt(R.id.categories_container, "setBackgroundResource", R.drawable.vision_board_background)
                        views.setInt(R.id.widget_title, "setTextColor", 0xFF1976D2.toInt())
                    }
                }
                
                // Set widget title
                views.setTextViewText(R.id.widget_title, currentTheme)
                
                // Define PendingIntent flags
                val pendingIntentFlags = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.M) {
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                } else {
                    PendingIntent.FLAG_UPDATE_CURRENT
                }

                // Clear the existing views in the LinearLayout
                views.removeAllViews(R.id.categories_container)

                // Get all categories for this widget
                val categories = mutableListOf<String>()
                var index = 0
                while (true) {
                    val category = prefs.getString("category_${appWidgetId}_$index", null) ?: break
                    categories.add(category)
                    index++
                }

                // Add categories to container
                for (i in categories.indices) {
                    val itemView = RemoteViews(context.packageName, R.layout.vision_board_grid_item)
                    val category = categories[i]
                    
                    // Set category background color based on theme and position
                    val backgroundColor = when (currentTheme) {
                        "Premium Vision Board" -> premiumColors[i % premiumColors.size]
                        "PostIt Vision Board" -> postitColors[i % postitColors.size]
                        "Animal Vision Board" -> animalColors[i % animalColors.size]
                        "Sport Vision Board" -> sportColors[i % sportColors.size]
                        "Watercolor Vision Board" -> watercolorColors[i % watercolorColors.size]
                        "Box Vision Board" -> 0x00000000 // Transparent background for Box Vision Board
                        else -> boxColors[i % boxColors.size]
                    }
                    
                    // Set the background color for the category item only if it's not Box Vision Board
                    if (currentTheme != "Box Vision Board") {
                        itemView.setInt(R.id.category_container, "setBackgroundColor", backgroundColor)
                    }
                    
                    // Set text color based on background brightness
                    val textColor = if (currentTheme == "Premium Vision Board") {
                        0xFFFFFFFF.toInt() // White text for dark backgrounds
                    } else {
                        0xFF000000.toInt() // Black text for light backgrounds
                    }
                    itemView.setTextColor(R.id.category_name, textColor)
                    itemView.setTextColor(R.id.todo_text, textColor)
                    
                    // Load todos based on theme
                    val savedTodos = when (currentTheme) {
                        "Premium Vision Board" -> HomeWidgetPlugin.getData(context)
                            .getString("premium_todos_$category", "")
                        "PostIt Vision Board" -> HomeWidgetPlugin.getData(context)
                            .getString("postit_todos_$category", "")
                        "Animal Vision Board" -> HomeWidgetPlugin.getData(context)
                            .getString("animal_todos_$category", "")
                        "Sport Vision Board" -> HomeWidgetPlugin.getData(context)
                            .getString("sport_todos_$category", "")
                        "Watercolor Vision Board" -> HomeWidgetPlugin.getData(context)
                            .getString("watercolor_todos_$category", "")
                        "Box Vision Board" -> {
                            val todos = HomeWidgetPlugin.getData(context)
                                .getString("BoxThem_todos_$category", "")
                            Log.d("VisionBoardWidget", "Retrieved todos for $category: $todos")
                            todos
                        }
                        else -> ""
                    }

                    val displayText = try {
                        val jsonArray = JSONArray(savedTodos)
                        val todoItems = mutableListOf<String>()
                        
                        for (j in 0 until jsonArray.length()) {
                            val item = jsonArray.getJSONObject(j)
                            val isDone = item.getBoolean("isDone")
                            if (!isDone) {
                                todoItems.add("• ${item.getString("text")}")
                            }
                        }

                        if (todoItems.isEmpty()) ""
                        else todoItems.joinToString("\n")
                    } catch (e: Exception) {
                        ""
                    }

                    itemView.setTextViewText(R.id.category_name, category)
                    itemView.setTextViewText(R.id.todo_text, displayText)
                    
                    // Create a broadcast intent for showing the popup menu
                    val popupIntent = Intent(context, VisionBoardWidget::class.java).apply {
                        action = "SHOW_POPUP_MENU"
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                        putExtra("category_index", i)
                        putExtra("category", category)
                    }
                    val popupPendingIntent = PendingIntent.getBroadcast(
                        context,
                        appWidgetId * 100 + i,  // Unique request code for each category
                        popupIntent,
                        pendingIntentFlags
                    )
                    itemView.setOnClickPendingIntent(R.id.category_name, popupPendingIntent)
                    
                    // Add the item to the container
                    views.addView(R.id.categories_container, itemView)
                }

                // Add the "+" button if there's room for more categories
                if (categories.size < MAX_CATEGORIES) {
                    val addItemView = RemoteViews(context.packageName, R.layout.vision_board_add_item)
                    
                    val addIntent = Intent(context, VisionBoardConfigureActivity::class.java).apply {
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                        putExtra("category_index", categories.size)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    val addPendingIntent = PendingIntent.getActivity(
                        context,
                        appWidgetId * 100 + 99,  // Unique request code for add button
                        addIntent,
                        pendingIntentFlags
                    )
                    addItemView.setOnClickPendingIntent(R.id.add_category_button, addPendingIntent)
                    views.addView(R.id.categories_container, addItemView)
                }

                // Add click listener for the title
                val titleIntent = Intent(context, ThemeSelectionActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                val titlePendingIntent = PendingIntent.getActivity(
                    context,
                    appWidgetId * 100 + 98,  // Unique request code for title
                    titleIntent,
                    pendingIntentFlags
                )
                views.setOnClickPendingIntent(R.id.widget_title, titlePendingIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
                Log.d("VisionBoardWidget", "Widget $appWidgetId updated with ${categories.size} categories")
            } catch (e: Exception) {
                Log.e("VisionBoardWidget", "Error updating widget", e)
            }
        }
    }
} 