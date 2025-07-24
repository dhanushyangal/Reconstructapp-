package com.reconstrect.visionboard

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import es.antonborri.home_widget.HomeWidgetPlugin

class WeeklyPlannerThemeActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setContentView(R.layout.weekly_planner_theme_selection)
        setupThemeButtons()
    }

    private fun setupThemeButtons() {
        findViewById<Button>(R.id.watercolor_theme).setOnClickListener {
            selectTheme("Watercolor theme Weekly Planner")
        }

        findViewById<Button>(R.id.patterns_theme).setOnClickListener {
            selectTheme("Patterns theme Weekly Planner")
        }

        findViewById<Button>(R.id.floral_theme).setOnClickListener {
            selectTheme("Floral theme Weekly Planner")
        }

        findViewById<Button>(R.id.japanese_theme).setOnClickListener {
            selectTheme("Japanese theme Weekly Planner")
        }
    }

    private fun selectTheme(theme: String) {
        // Save selected theme
        val prefs = HomeWidgetPlugin.getData(this)
        prefs.edit().putString("weekly_planner_theme_$appWidgetId", theme).apply()

        // Launch day selection
        val configIntent = Intent(this, WeeklyPlannerConfigureActivity::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            putExtra("day_index", 0)  // Start with first day
        }
        startActivity(configIntent)

        // Set result and finish
        val resultValue = Intent().apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        setResult(RESULT_OK, resultValue)
        finish()
    }
} 