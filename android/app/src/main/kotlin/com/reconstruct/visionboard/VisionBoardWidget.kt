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
        private const val MAX_CATEGORIES = 5 // 4 auto-added + 1 manual
        
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
                
                // Auto-detect current theme from last used theme in app
                val currentTheme = prefs.getString("flutter.vision_board_current_theme", null)
                    ?: prefs.getString("vision_board_current_theme", "Box Theme Vision Board")
                    ?: "Box Theme Vision Board" // Ensure non-null
                
                Log.d("VisionBoardWidget", "Current theme detected: $currentTheme")
                
                // Set widget background based on theme (using flexible matching)
                when {
                    currentTheme.contains("Premium", ignoreCase = true) || currentTheme.contains("black", ignoreCase = true) -> {
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
                    currentTheme.contains("PostIt", ignoreCase = true) || currentTheme.contains("Post it", ignoreCase = true) || currentTheme.contains("Post-it", ignoreCase = true) -> {
                        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.postit_background)
                        views.setInt(R.id.categories_container, "setBackgroundResource", R.drawable.postit_background)
                    }
                    currentTheme.contains("Box", ignoreCase = true) || currentTheme.contains("Boxy", ignoreCase = true) -> {
                        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.box_vision_background)
                        views.setInt(R.id.categories_container, "setBackgroundResource", R.drawable.box_vision_background)
                    }
                    currentTheme.contains("Ruby", ignoreCase = true) || currentTheme.contains("Reds", ignoreCase = true) -> {
                        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.ruby_reds_background)
                        views.setInt(R.id.categories_container, "setBackgroundResource", R.drawable.ruby_reds_background)
                    }
                    currentTheme.contains("Winter", ignoreCase = true) || currentTheme.contains("Warmth", ignoreCase = true) || currentTheme.contains("Floral", ignoreCase = true) -> {
                        views.setInt(R.id.widget_container, "setBackgroundResource", R.drawable.winter_warmth_background)
                        views.setInt(R.id.categories_container, "setBackgroundResource", R.drawable.winter_warmth_background)
                    }
                    currentTheme.contains("Coffee", ignoreCase = true) || currentTheme.contains("Hues", ignoreCase = true) -> {
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
                val allCategories = mutableListOf<String>()
                var index = 0
                while (true) {
                    val category = prefs.getString("category_${appWidgetId}_$index", null) ?: break
                    allCategories.add(category)
                    index++
                }
                
                // Auto-add categories with tasks if less than 4
                if (allCategories.size < 4) {
                    val visionCategories = arrayOf(
                        "BMI", "Career", "DIY", "Family", "Food",
                        "Forgive", "Health", "Help", "Hobbies",
                        "Income", "Inspiration", "Invest", "Knowledge",
                        "Love", "Luxury", "Music", "Reading", "Self Care",
                        "Social", "Tech", "Travel"
                    )
                    
                    val categoriesWithTasks = visionCategories.filter { category ->
                        category !in allCategories && hasCategoryTasks(context, appWidgetId, category)
                    }
                    
                    val editor = prefs.edit()
                    var added = 0
                    for (category in categoriesWithTasks) {
                        if (allCategories.size + added < 4) {
                            editor.putString("category_${appWidgetId}_${allCategories.size + added}", category)
                            allCategories.add(category)
                            added++
                            Log.d("VisionBoardWidget", "Auto-added category: $category")
                        } else {
                            break
                        }
                    }
                    if (added > 0) {
                        editor.apply()
                    }
                }

                // Filter categories to only show those with tasks
                val categoriesWithTasks = mutableListOf<String>()
                for (category in allCategories) {
                    // Load todos using universal key (check both flutter. prefix and without)
                    val savedTodos = prefs.getString("flutter.vision_board_$category", null)
                        ?: prefs.getString("vision_board_$category", "")
                    
                    // Check if category has any tasks
                    if (savedTodos?.isNotEmpty() == true) {
                        try {
                            val jsonArray = JSONArray(savedTodos)
                            if (jsonArray.length() > 0) {
                                categoriesWithTasks.add(category)
                            }
                        } catch (e: Exception) {
                            // If JSON parsing fails, still add the category if it has content
                            if (savedTodos?.trim()?.isNotEmpty() == true) {
                                categoriesWithTasks.add(category)
                            }
                        }
                    }
                }

                // Handle empty state - show message if no categories have tasks
                if (categoriesWithTasks.isEmpty()) {
                    Log.d("VisionBoardWidget", "No categories with tasks found for widget $appWidgetId")
                    
                    // Show empty state message on widget
                    val emptyView = RemoteViews(context.packageName, R.layout.vision_board_grid_item)
                    emptyView.setTextViewText(R.id.category_name, "No Goals")
                    emptyView.setTextViewText(R.id.todo_text, "Add goals in:\n$currentTheme\n\nTap + to add categories")
                    emptyView.setInt(R.id.category_container, "setBackgroundColor", 0x33FFFFFF)
                    emptyView.setTextColor(R.id.category_name, 0xFF000000.toInt())
                    emptyView.setTextColor(R.id.todo_text, 0xFF666666.toInt())
                    views.addView(R.id.categories_container, emptyView)
                } else {
                    // Add categories to container (only those with tasks)
                    for (i in categoriesWithTasks.indices) {
                    val itemView = RemoteViews(context.packageName, R.layout.vision_board_grid_item)
                    val category = categoriesWithTasks[i]
                    
                    // Set category background color based on theme and position (flexible matching)
                    val backgroundColor = when {
                        currentTheme.contains("Premium", ignoreCase = true) || currentTheme.contains("black", ignoreCase = true) -> premiumColors[i % premiumColors.size]
                        currentTheme.contains("PostIt", ignoreCase = true) || currentTheme.contains("Post it", ignoreCase = true) || currentTheme.contains("Post-it", ignoreCase = true) -> postitColors[i % postitColors.size]
                        currentTheme.contains("Ruby", ignoreCase = true) || currentTheme.contains("Reds", ignoreCase = true) -> rubyRedsColors[i % rubyRedsColors.size]
                        currentTheme.contains("Winter", ignoreCase = true) || currentTheme.contains("Warmth", ignoreCase = true) || currentTheme.contains("Floral", ignoreCase = true) -> winterWarmthColors[i % winterWarmthColors.size]
                        currentTheme.contains("Coffee", ignoreCase = true) || currentTheme.contains("Hues", ignoreCase = true) -> coffeeHuesColors[i % coffeeHuesColors.size]
                        currentTheme.contains("Box", ignoreCase = true) || currentTheme.contains("Boxy", ignoreCase = true) -> 0x33FFFFFF // Transparent background for Box Vision Board
                        else -> boxColors[i % boxColors.size]
                    }
                    
                    // Set the background color for the category container
                    itemView.setInt(R.id.category_container, "setBackgroundColor", backgroundColor)
                    
                    // Keep the floating background drawable for Box theme
                    if (currentTheme.contains("Box", ignoreCase = true) || currentTheme.contains("Boxy", ignoreCase = true)) {
                        itemView.setInt(R.id.category_container, "setBackgroundResource", R.drawable.floating_category_background)
                    }
                    
                    // Set text color based on background brightness (flexible matching)
                    val textColor = when {
                        currentTheme.contains("Premium", ignoreCase = true) || currentTheme.contains("black", ignoreCase = true) -> 0xFFFFFFFF.toInt() // White text
                        currentTheme.contains("Ruby", ignoreCase = true) || currentTheme.contains("Reds", ignoreCase = true) -> 0xFFFFFFFF.toInt() // White text
                        currentTheme.contains("Winter", ignoreCase = true) || currentTheme.contains("Warmth", ignoreCase = true) || currentTheme.contains("Floral", ignoreCase = true) -> 0xFFFFFFFF.toInt() // White text
                        currentTheme.contains("Coffee", ignoreCase = true) || currentTheme.contains("Hues", ignoreCase = true) -> 0xFFFFFFFF.toInt() // White text
                        currentTheme.contains("PostIt", ignoreCase = true) || currentTheme.contains("Post it", ignoreCase = true) || currentTheme.contains("Post-it", ignoreCase = true) -> 0xFF000000.toInt() // Black text
                        currentTheme.contains("Box", ignoreCase = true) || currentTheme.contains("Boxy", ignoreCase = true) -> 0xFF000000.toInt() // Black text
                        else -> 0xFF000000.toInt() // Black text for other themes
                    }
                    itemView.setTextColor(R.id.category_name, textColor)
                    itemView.setTextColor(R.id.todo_text, textColor)
                    
                    // Load todos using universal key (check both flutter. prefix and without)
                    val savedTodos = prefs.getString("flutter.vision_board_$category", null)
                        ?: prefs.getString("vision_board_$category", "")

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
            }

            // Add the "+" button if there's room for more categories
            if (allCategories.size < MAX_CATEGORIES) {
                val addItemView = RemoteViews(context.packageName, R.layout.vision_board_add_item)
                
                val addIntent = Intent(context, VisionBoardConfigureActivity::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    putExtra("category_index", allCategories.size)
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
            Log.d("VisionBoardWidget", "Widget $appWidgetId updated with ${categoriesWithTasks.size} categories with tasks (out of ${allCategories.size} total categories)")
        } catch (e: Exception) {
            Log.e("VisionBoardWidget", "Error updating widget", e)
        }
    }

        /**
         * Check if a category has any tasks for the given theme
         */
        fun hasCategoryTasks(context: Context, appWidgetId: Int, category: String): Boolean {
            // Use universal storage key (check both flutter. prefix and without)
            val prefs = HomeWidgetPlugin.getData(context)
            val savedTodos = prefs.getString("flutter.vision_board_$category", null)
                ?: prefs.getString("vision_board_$category", "")
            
            if (savedTodos?.isEmpty() != false) return false
            
            return try {
                val jsonArray = JSONArray(savedTodos)
                jsonArray.length() > 0
            } catch (e: Exception) {
                savedTodos?.trim()?.isNotEmpty() == true
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