package com.reconstrect.visionboard

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
import android.text.Html

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
            0xFF262626.toInt(),
            0xFF262626.toInt(),
            0xFF262626.toInt(),
            0xFF262626.toInt(),
            0xFF262626.toInt()
        )
        
        private val postitColors = arrayOf(
            0xFFF59138.toInt(),
            0xFFF3768F.toInt(),
            0xFFECC460.toInt(),
            0xFFA5DB76.toInt(),
            0xFF438ECC.toInt()
        )
        
        private val boxColors = arrayOf(
            0xFF90CAF9.toInt(),
            0xFF64B5F6.toInt(),
            0xFF42A5F5.toInt(),
            0xFF2196F3.toInt(),
            0xFF1E88E5.toInt()
        )
        
       
        
        private val winterWarmthColors = arrayOf(
             0xFFd4c9b4.toInt(), // Light Beige
             0xFF25330F.toInt(), // Dark Green
             0xFFb78c56.toInt(), // Gray
             0xFF462A19.toInt(), // Icy Blue
             0xFF233E48.toInt()  // Frost Gray
        )
        
        private val coffeeHuesColors = arrayOf(
            0xFF2D1E17.toInt(), // Custom Color 1
            0xFF342519.toInt(), // Custom Color 2
            0xFF684F36.toInt(), // Custom Color 3
            0xFFB39977.toInt(), // Custom Color 4
            0xFFEDE6D9.toInt() // Rustic Brown
        )

        private val rubyRedsColors = arrayOf(
            0xFF590d22.toInt(),
            0xFF800020.toInt(),
            0xFFc9184a.toInt(),
            0xFFdc153d.toInt(),
            0xFFe34235.toInt()
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
                        views.setInt(R.id.widget_container, "setBackgroundColor", 0xFF000000.toInt())
                        
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
                    }
                    "Box Vision Board" -> {
                        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.box_vision_background)
                        views.setInt(R.id.categories_container, "setBackgroundResource", R.drawable.box_vision_background)
                    }
                    "Ruby Reds Vision Board" -> {
                        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.ruby_reds_background)
                        views.setInt(R.id.categories_container, "setBackgroundResource", R.drawable.ruby_reds_background)
                    }
                    "Winter Warmth Vision Board" -> {
                        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.winter_warmth_background)
                        views.setInt(R.id.categories_container, "setBackgroundResource", R.drawable.winter_warmth_background)
                    }
                    "Coffee Hues Vision Board" -> {
                        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.watercolor_background)
                        views.setInt(R.id.categories_container, "setBackgroundResource", R.drawable.watercolor_background)
                    }
                    else -> {
                        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.vision_board_background)
                        views.setInt(R.id.categories_container, "setBackgroundResource", R.drawable.vision_board_background)
                    }
                }
                
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
                        "Ruby Reds Vision Board" -> rubyRedsColors[i % rubyRedsColors.size]
                        "Winter Warmth Vision Board" -> winterWarmthColors[i % winterWarmthColors.size]
                        "Coffee Hues Vision Board" -> coffeeHuesColors[i % coffeeHuesColors.size]
                        "Box Vision Board" -> 0x33FFFFFF // Transparent background for Box Vision Board
                        else -> boxColors[i % boxColors.size]
                    }
                    
                    // Set the background color for the category container
                    itemView.setInt(R.id.category_container, "setBackgroundColor", backgroundColor)
                    
                    // Keep the floating background drawable
                    if (currentTheme == "Box Vision Board") {
                        itemView.setInt(R.id.category_container, "setBackgroundResource", R.drawable.floating_category_background)
                    }
                    
                    // Set text color based on background brightness
                    val textColor = when (currentTheme) {
                        "Premium Vision Board" -> 0xFFFFFFFF.toInt() // White text
                        "Ruby Reds Vision Board" -> 0xFFFFFFFF.toInt() // White text
                        "Winter Warmth Vision Board" -> 0xFFFFFFFF.toInt() // White text
                        "Coffee Hues Vision Board" -> 0xFFFFFFFF.toInt() // White text
                        "PostIt Vision Board" -> 0xFFFFFFFF.toInt() // White text
                        "Box Vision Board" -> 0xFF000000.toInt() // Black text
                        else -> 0xFF000000.toInt() // Black text for other themes
                    }
                    itemView.setTextColor(R.id.category_name, textColor)
                    itemView.setTextColor(R.id.todo_text, textColor)
                    
                    // Load todos based on theme
                    val savedTodos = when (currentTheme) {
                        "Premium Vision Board" -> HomeWidgetPlugin.getData(context)
                            .getString("premium_todos_$category", "")
                        "PostIt Vision Board" -> HomeWidgetPlugin.getData(context)
                            .getString("postit_todos_$category", "")
                        "Ruby Reds Vision Board" -> HomeWidgetPlugin.getData(context)
                            .getString("ruby_reds_todos_$category", "")
                        "Winter Warmth Vision Board" -> HomeWidgetPlugin.getData(context)
                            .getString("winter_warmth_todos_$category", "")
                        "Coffee Hues Vision Board" -> HomeWidgetPlugin.getData(context)
                            .getString("coffee_hues_todos_$category", "")
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
                            val text = "• ${item.getString("text")}"
                            val isDone = item.getBoolean("isDone")
                            
                            if (isDone) {
                                // For completed items, use special character to create strikethrough effect
                                val strikedText = text.map { char -> "$char\u0336" }.joinToString("")
                                todoItems.add(strikedText)
                            } else {
                                todoItems.add(text)
                            }
                        }

                        todoItems.joinToString("\n")
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

                appWidgetManager.updateAppWidget(appWidgetId, views)
                Log.d("VisionBoardWidget", "Widget $appWidgetId updated with ${categories.size} categories")
            } catch (e: Exception) {
                Log.e("VisionBoardWidget", "Error updating widget", e)
            }
        }

        private fun isValidCategory(context: Context, appWidgetId: Int, categoryIndex: Int): Boolean {
            val prefs = HomeWidgetPlugin.getData(context)
            val existingCategories = mutableListOf<String>()
            
            // Get all existing categories
            var index = 0
            while (true) {
                val category = prefs.getString("category_${appWidgetId}_$index", null) ?: break
                if (index != categoryIndex) { // Skip the current category being changed
                    existingCategories.add(category)
                }
                index++
            }
            
            // Get the category being checked
            val categoryToCheck = prefs.getString("category_${appWidgetId}_$categoryIndex", null)
            
            return categoryToCheck != null && categoryToCheck !in existingCategories
        }
    }
} 