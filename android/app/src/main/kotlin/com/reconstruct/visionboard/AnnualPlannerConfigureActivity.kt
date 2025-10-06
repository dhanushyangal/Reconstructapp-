package com.reconstrect.visionboard

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.widget.ListView
import android.widget.ArrayAdapter
import es.antonborri.home_widget.HomeWidgetPlugin
import android.widget.Toast
import android.util.Log
import java.util.*

class AnnualPlannerConfigureActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private var monthIndex = 0

    private val months = arrayOf(
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        monthIndex = intent?.extras?.getInt("month_index", 0) ?: 0

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setContentView(R.layout.annual_planner_month_select)
        setupMonthSelection()
    }

    private fun setupMonthSelection() {
        try {
            val listView = findViewById<ListView>(R.id.month_list)
            
            // Get existing months for this widget
            val existingMonths = mutableListOf<String>()
            var index = 0
            while (true) {
                val month = HomeWidgetPlugin.getData(this)
                    .getString("month_${appWidgetId}_$index", null) ?: break
                existingMonths.add(month)
                index++
            }
            
            // If no months exist, add current month
            if (existingMonths.isEmpty()) {
                val calendar = Calendar.getInstance()
                val currentMonth = months[calendar.get(Calendar.MONTH)]
                val editor = HomeWidgetPlugin.getData(this).edit()
                editor.putString("month_${appWidgetId}_0", currentMonth)
                editor.apply()
                existingMonths.add(currentMonth)
            }
            
            // Filter months to only show those that have tasks
            val monthsWithTasks = months.filter { month ->
                AnnualPlannerWidget.hasMonthTasks(this, appWidgetId, month)
            }
            
            // Filter out months that are already in use
            val availableMonthsWithTasks = monthsWithTasks.filter { it !in existingMonths }
            
            if (availableMonthsWithTasks.isEmpty()) {
                val message = if (existingMonths.isNotEmpty()) {
                    "No months with tasks available to change to"
                } else {
                    "No months with tasks available to add. Please add tasks to months first."
                }
                Toast.makeText(this, message, Toast.LENGTH_LONG).show()
                finish()
                return
            }
            
            listView.adapter = ArrayAdapter(this, android.R.layout.simple_list_item_1, availableMonthsWithTasks)
            setupListViewClickListener(listView, availableMonthsWithTasks)
            
        } catch (e: Exception) {
            Log.e("AnnualPlannerConfig", "Error in setupMonthSelection", e)
            Toast.makeText(this, "Error setting up month selection", Toast.LENGTH_SHORT).show()
            finish()
        }
    }

    private fun setupListViewClickListener(listView: ListView, availableMonths: List<String>) {
        listView.setOnItemClickListener { _, _, position, _ ->
            val selectedMonth = availableMonths[position]
            
            // Save the selected month
            val editor = HomeWidgetPlugin.getData(this).edit()
            editor.putString("month_${appWidgetId}_$monthIndex", selectedMonth)
            editor.apply()

            // Show confirmation message since we know this month has tasks
            Toast.makeText(this, "Month '$selectedMonth' selected (has tasks)", Toast.LENGTH_SHORT).show()

            // Update the widget
            val updateIntent = Intent(this, AnnualPlannerWidget::class.java).apply {
                action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
            }
            sendBroadcast(updateIntent)

            val resultValue = Intent().apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            setResult(RESULT_OK, resultValue)
            finish()
        }
    }
} 