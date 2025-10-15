package com.reconstrect.visionboard

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.appwidget.AppWidgetManager
import es.antonborri.home_widget.HomeWidgetPlugin
import android.widget.Button

class AnnualPlannerThemeActivity : Activity() {
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

        setContentView(R.layout.annual_planner_theme_selection)
        setupThemeButtons()
    }

    private fun setupThemeButtons() {
        findViewById<Button>(R.id.postit_theme).setOnClickListener {
            selectTheme("PostIt Annual Planner")
        }
        findViewById<Button>(R.id.premium_theme).setOnClickListener {
            selectTheme("Premium Annual Planner")
        }
        findViewById<Button>(R.id.watercolor_theme).setOnClickListener {
            selectTheme("Watercolor Annual Planner")
        }
        findViewById<Button>(R.id.floral_theme).setOnClickListener {
            selectTheme("Floral Annual Planner")
        }
    }

    private fun selectTheme(theme: String) {
        // Save selected theme
        val prefs = HomeWidgetPlugin.getData(this)
        prefs.edit().putString("annual_planner_theme_$appWidgetId", theme).apply()

        // Send broadcast to update widget - this will auto-add months with tasks
        val updateIntent = Intent(this, AnnualPlannerWidget::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
        }
        sendBroadcast(updateIntent)

        // Finish immediately - widget will auto-populate with months that have tasks
        val resultValue = Intent().apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        }
        setResult(RESULT_OK, resultValue)
        finish()
    }
}