package com.example.reconstrect1

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.appwidget.AppWidgetManager
import es.antonborri.home_widget.HomeWidgetPlugin

class ThemeSelectionActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Set the result to CANCELED. This will cause the widget host to cancel
        // out of the widget placement if they press the back button.
        setResult(RESULT_CANCELED)

        // Get the widget ID from the intent
        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setContentView(R.layout.theme_selection_menu)

        setupThemeButtons()
    }

    private fun setupThemeButtons() {
        findViewById<android.widget.Button>(R.id.box_theme_button).setOnClickListener {
            selectThemeAndContinue("Box Vision Board")
        }

        findViewById<android.widget.Button>(R.id.post_it_theme_button).setOnClickListener {
            selectThemeAndContinue("PostIt Vision Board")
        }

        findViewById<android.widget.Button>(R.id.premium_theme_button).setOnClickListener {
            selectThemeAndContinue("Premium Vision Board")
        }

        findViewById<android.widget.Button>(R.id.animal_theme_button).setOnClickListener {
            selectThemeAndContinue("Animal Vision Board")
        }

        findViewById<android.widget.Button>(R.id.sport_theme_button).setOnClickListener {
            selectThemeAndContinue("Sport Vision Board")
        }

        findViewById<android.widget.Button>(R.id.watercolor_theme_button).setOnClickListener {
            selectThemeAndContinue("Watercolor Vision Board")
        }
    }

    private fun selectThemeAndContinue(theme: String) {
        // Save selected theme with widget-specific key
        val prefs = HomeWidgetPlugin.getData(this)
        prefs.edit().putString("widget_theme_$appWidgetId", theme).apply()

        // Launch category selection
        val configIntent = Intent(this, VisionBoardConfigureActivity::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            putExtra("category_index", 0)
        }
        startActivity(configIntent)

        // Set the result for widget creation
        val resultValue = Intent().apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        setResult(RESULT_OK, resultValue)
        finish()
    }
} 