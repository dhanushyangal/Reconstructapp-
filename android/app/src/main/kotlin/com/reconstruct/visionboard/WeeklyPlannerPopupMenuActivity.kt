package com.reconstrect.visionboard

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.appwidget.AppWidgetManager
import es.antonborri.home_widget.HomeWidgetPlugin

class WeeklyPlannerPopupMenuActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.popup_menu)

        val appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
        val dayIndex = intent.getIntExtra("day_index", 0)
        val day = intent.getStringExtra("day") ?: return

        // Get the current theme
        val currentTheme = HomeWidgetPlugin.getData(this)
            .getString("weekly_planner_theme_$appWidgetId", "Japanese theme Weekly Planner")

        // Set up edit text button
        findViewById<Button>(R.id.edit_text_button).apply {
            text = "Edit Day Tasks"
            setOnClickListener {
                // Launch main app with weekly planner page and theme
                val mainIntent = Intent(this@WeeklyPlannerPopupMenuActivity, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("route", "/weekly_planner")
                    putExtra("day", day)
                    putExtra("theme", currentTheme)
                }
                startActivity(mainIntent)
                finish()
            }
        }

        // Set up change day button
        findViewById<Button>(R.id.change_category_button).apply {
            text = "Change Day"
            setOnClickListener {
                val configIntent = Intent(this@WeeklyPlannerPopupMenuActivity, WeeklyPlannerConfigureActivity::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    putExtra("day_index", dayIndex)
                }
                startActivity(configIntent)
                finish()
            }
        }
    }
} 