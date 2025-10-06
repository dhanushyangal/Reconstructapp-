package com.reconstrect.visionboard

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.widget.ListView
import android.widget.ArrayAdapter
import es.antonborri.home_widget.HomeWidgetPlugin
import android.widget.Toast

class WeeklyPlannerConfigureActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private var dayIndex = 0

    private val days = arrayOf(
        "Monday", "Tuesday", "Wednesday", "Thursday", 
        "Friday", "Saturday", "Sunday"
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        dayIndex = intent?.extras?.getInt("day_index", 0) ?: 0

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setContentView(R.layout.weekly_planner_configure)

        // Get existing days
        val existingDays = mutableListOf<String>()
        for (i in 0 until dayIndex) {
            val day = HomeWidgetPlugin.getData(this)
                .getString("day_${appWidgetId}_$i", null)
            if (day != null) {
                existingDays.add(day)
            }
        }

        // Filter days to only show those that have tasks
        val daysWithTasks = days.filter { day ->
            WeeklyPlannerWidget.hasDayTasks(this, appWidgetId, day)
        }
        
        // Filter out days that are already in use
        val availableDaysWithTasks = daysWithTasks.filter { it !in existingDays }

        if (availableDaysWithTasks.isEmpty()) {
            val message = if (existingDays.isNotEmpty()) {
                "No days with tasks available to change to"
            } else {
                "No days with tasks available to add. Please add tasks to days first."
            }
            Toast.makeText(this, message, Toast.LENGTH_LONG).show()
            finish()
            return
        }

        // Setup ListView
        val listView = findViewById<ListView>(R.id.day_list)
        val adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, availableDaysWithTasks)
        listView.adapter = adapter

        setupListViewClickListener(listView, availableDaysWithTasks)
    }

    private fun setupListViewClickListener(listView: ListView, availableDays: List<String>) {
        listView.setOnItemClickListener { _, _, position, _ ->
            val selectedDay = availableDays[position]
            
            // Save the selected day
            val editor = HomeWidgetPlugin.getData(this).edit()
            editor.putString("day_${appWidgetId}_$dayIndex", selectedDay)
            editor.apply()

            // Show confirmation message since we know this day has tasks
            Toast.makeText(this, "Day '$selectedDay' selected (has tasks)", Toast.LENGTH_SHORT).show()

            // Update the widget
            val updateIntent = Intent(this, WeeklyPlannerWidget::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
            }
            sendBroadcast(updateIntent)

            // Return result and finish immediately after first day selection
            val resultValue = Intent().apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            setResult(RESULT_OK, resultValue)
            finish()
        }
    }
} 