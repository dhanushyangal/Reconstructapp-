package com.reconstrect.visionboard

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.appwidget.AppWidgetManager
import es.antonborri.home_widget.HomeWidgetPlugin

class AnnualPlannerPopupMenuActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.popup_menu)

        val appWidgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, AppWidgetManager.INVALID_APPWIDGET_ID)
        val monthIndex = intent.getIntExtra("month_index", 0)
        val month = intent.getStringExtra("month") ?: return

        // Get the current theme
        val currentTheme = HomeWidgetPlugin.getData(this)
            .getString("annual_planner_theme_$appWidgetId", "PostIt Annual Planner")

        // Set up edit text button
        findViewById<Button>(R.id.edit_text_button).apply {
            text = "Edit Month Tasks"
            setOnClickListener {
                // Launch main app with annual planner page and theme
                val mainIntent = Intent(this@AnnualPlannerPopupMenuActivity, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                    putExtra("route", "/annual_planner")
                    putExtra("month", month)
                    putExtra("theme", currentTheme)
                }
                startActivity(mainIntent)
                finish()
            }
        }

        // Set up change month button
        findViewById<Button>(R.id.change_category_button).apply {
            text = "Change Month"
            setOnClickListener {
                val configIntent = Intent(this@AnnualPlannerPopupMenuActivity, AnnualPlannerConfigureActivity::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    putExtra("month_index", monthIndex)
                }
                startActivity(configIntent)
                finish()
            }
        }
    }
} 