package com.example.reconstrect1

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.appwidget.AppWidgetManager
import es.antonborri.home_widget.HomeWidgetPlugin

class PopupMenuActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.popup_menu)

        val appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
        val categoryIndex = intent.getIntExtra("category_index", 0)
        val category = intent.getStringExtra("category") ?: return

        // Get the current theme
        val currentTheme = HomeWidgetPlugin.getData(this)
            .getString("widget_theme_$appWidgetId", "Box Vision Board")

        // Set up edit text button
        findViewById<Button>(R.id.edit_text_button).setOnClickListener {
            // Launch main app with vision board page and theme
            val mainIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra("route", "/vision_board")
                putExtra("category", category)
                putExtra("theme", currentTheme)
            }
            startActivity(mainIntent)
            finish()
        }

        // Set up change category button
        findViewById<Button>(R.id.change_category_button).setOnClickListener {
            val configIntent = Intent(this, VisionBoardConfigureActivity::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                putExtra("category_index", categoryIndex)
            }
            startActivity(configIntent)
            finish()
        }
    }
} 