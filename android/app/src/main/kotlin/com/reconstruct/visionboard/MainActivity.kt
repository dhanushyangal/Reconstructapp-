package com.reconstrect.visionboard

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Bundle
import android.content.Context
import android.app.PendingIntent
import android.util.Log
import android.os.Build
import android.net.Uri
import android.view.WindowManager
import androidx.core.view.WindowCompat

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.reconstrect.visionboard/widget"
        private const val TAG = "MainActivity"
    }

    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel?.setMethodCallHandler { call, result ->
            Log.d(TAG, "Received method call: ${call.method}")
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Set up edge-to-edge display
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            WindowCompat.setDecorFitsSystemWindows(window, false)
        }
        
        Log.d(TAG, "onCreate called")
        processIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "onNewIntent called")
        setIntent(intent)
        processIntent(intent)
    }

    private fun processIntent(intent: Intent) {
        Log.d(TAG, "Processing intent: ${intent.action}, data: ${intent.data}")

        if (methodChannel == null) {
            Log.e(TAG, "MethodChannel is null")
            return
        }

        // Handle deep links for notes
        if (intent.action == Intent.ACTION_VIEW && intent.data != null) {
            val uri = intent.data
            
            if (uri?.scheme == "reconstrect" && uri.host == "dailynotes") {
                Log.d(TAG, "Daily Notes deep link: ${uri.path}")
                
                if (uri.path == "/new") {
                    // Open daily notes with new note
                    methodChannel?.invokeMethod(
                        "openDailyNotes",
                        mapOf("create_new" to true)
                    )
                } else {
                    // Open daily notes page
                    methodChannel?.invokeMethod(
                        "openDailyNotes",
                        mapOf("create_new" to false)
                    )
                }
                return
            }
        }

        // Legacy widget handling
        val action = intent.getStringExtra("action") ?: ""
        val theme = intent.getStringExtra("theme") ?: ""
        val category = intent.getStringExtra("category") ?: ""
        val widgetType = intent.getStringExtra("widget_type") ?: ""

        Log.d(TAG, "Action: $action, Theme: $theme, Category: $category, WidgetType: $widgetType")

        when (action) {
            "edit_calendar" -> {
                val monthIndex = intent.getIntExtra("month_index", 0)
                val calendarTheme = intent.getStringExtra("calendar_theme")
                
                methodChannel?.invokeMethod(
                    "openEventsView",
                    mapOf(
                        "month_index" to monthIndex,
                        "calendar_theme" to calendarTheme,
                        "show_events" to true,
                        "widget_type" to widgetType
                    )
                )
            }
            "open_events" -> {
                val monthIndex = intent.getIntExtra("month_index", -1)
                val eventId = intent.getStringExtra("event_id") ?: ""
                val showEvents = intent.getBooleanExtra("show_events", false)
                val calendarTheme = intent.getStringExtra("calendar_theme")

                methodChannel?.invokeMethod(
                    "openEventsView",
                    mapOf(
                        "month_index" to monthIndex,
                        "event_id" to eventId,
                        "show_events" to showEvents,
                        "calendar_theme" to calendarTheme,
                        "widget_type" to widgetType
                    )
                )
            }
            else -> {
                methodChannel?.invokeMethod(
                    "openVisionBoardWithTheme",
                    mapOf(
                        "theme" to theme,
                        "category" to category,
                        "widget_type" to widgetType
                    )
                )
            }
        }
    }

    private fun createEventsViewIntent(context: Context, monthIndex: Int): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("action", "open_events")
            putExtra("month_index", monthIndex)
            putExtra("show_events", true)
            putExtra("event_id", "some_event_id")
        }

        return PendingIntent.getActivity(
            context,
            monthIndex,
            intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )
    }
}
