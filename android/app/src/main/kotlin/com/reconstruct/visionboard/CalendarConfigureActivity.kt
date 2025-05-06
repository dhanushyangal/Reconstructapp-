package com.reconstrect.visionboard

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.content.Context
import android.util.Log
import android.os.Handler
import android.os.Looper

class CalendarConfigureActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)
        setContentView(R.layout.calendar_configure)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        setupThemeButtons()
    }

    private fun setupThemeButtons() {
        findViewById<Button>(R.id.animal_theme).setOnClickListener { 
            selectTheme("Animal theme 2025 Calendar") 
        }
        findViewById<Button>(R.id.summer_theme).setOnClickListener { 
            selectTheme("Summer theme 2025 Calendar") 
        }
        findViewById<Button>(R.id.spaniel_theme).setOnClickListener { 
            selectTheme("Spaniel theme 2025 Calendar") 
        }
        findViewById<Button>(R.id.happy_couple_theme).setOnClickListener { 
            selectTheme("Happy Couple theme 2025 Calendar") 
        }
    }

    private fun selectTheme(theme: String) {
        val context = this
        val appWidgetManager = AppWidgetManager.getInstance(context)

        // Save the selected theme with widget-specific key
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val themeKey = CalendarThemeWidget.getThemeKey(appWidgetId)
        
        Log.d("CalendarConfigureActivity", "Saving theme: $theme for widget: $appWidgetId")
        prefs.edit()
            .putString(themeKey, theme)
            .putString("calendar_theme", theme)
            .apply()

        // Update widget with the new theme
        CalendarThemeWidget().updateAppWidget(context, appWidgetManager, appWidgetId)

        // Send broadcast to update all instances of the widget with specific action
        val updateIntent = Intent(context, CalendarThemeWidget::class.java).apply {
            action = "CALENDAR_THEME_UPDATED"
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
            putExtra("widget_type", "calendar")
        }
        context.sendBroadcast(updateIntent)

        // Create result intent and finish activity
        val resultValue = Intent()
        resultValue.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        setResult(RESULT_OK, resultValue)
        finish()
    }

    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"
    }
} 