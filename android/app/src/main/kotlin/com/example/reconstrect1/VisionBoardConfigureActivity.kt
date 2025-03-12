package com.example.reconstrect1

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.os.Bundle
import android.widget.ListView
import android.widget.ArrayAdapter
import android.content.Context
import android.content.SharedPreferences
import es.antonborri.home_widget.HomeWidgetPlugin
import android.view.View
import android.widget.EditText
import android.widget.Button

class VisionBoardConfigureActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private var categoryIndex = 0
    private var category: String? = null

    private val visionCategories = arrayOf(
        "BMI", "Career", "DIY", "Family", "Food",
         "Forgive", "Health", "Help", "Hobbies",
          "Income", "Inspiration", "Invest", "Knowledge",
           "Love", "Luxury", "Music", "Reading", "Self Care",
            "Social", "Tech", "Travel"

    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Set the result to CANCELED. This will cause the widget host to cancel
        // out of the widget placement if they press the back button.
        setResult(RESULT_CANCELED)

        // Get intent extras
        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID

        categoryIndex = intent?.extras?.getInt("category_index", 0) ?: 0
        category = intent?.extras?.getString("category")
        val isEditMode = intent?.extras?.getBoolean("edit_mode", false) ?: false

        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        if (isEditMode && category != null) {
            setContentView(R.layout.vision_board_configure)
            setupTextEditMode(category!!)
        } else {
            setContentView(R.layout.vision_board_category_select)
            setupCategorySelectMode()
        }
    }

    private fun setupTextEditMode(category: String) {
        val editText = findViewById<EditText>(R.id.vision_edit_text)
        val saveButton = findViewById<Button>(R.id.save_button)
        
        // Load existing text if any
        val prefs = HomeWidgetPlugin.getData(this)
        val existingText = prefs.getString("vision_$category", "")
        editText.setText(existingText)
        
        saveButton.setOnClickListener {
            val editor = HomeWidgetPlugin.getData(this).edit()
            editor.putString("vision_$category", editText.text.toString())
            editor.apply()

            // Update the widget
            val appWidgetManager = AppWidgetManager.getInstance(this)
            VisionBoardWidget.updateAppWidget(this, appWidgetManager, appWidgetId)

            val resultValue = Intent().apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            setResult(RESULT_OK, resultValue)
            finish()
        }
    }

    private fun setupCategorySelectMode() {
        val listView = findViewById<ListView>(R.id.category_list)
        listView.adapter = ArrayAdapter(
            this,
            R.layout.category_list_item,
            visionCategories
        )
        
        listView.setOnItemClickListener { _, _, position, _ ->
            val selectedCategory = visionCategories[position]
            
            // Save the selected category with its index
            val editor = HomeWidgetPlugin.getData(this).edit()
            editor.putString("category_${appWidgetId}_$categoryIndex", selectedCategory)
            editor.apply()

            // Update the widget
            val appWidgetManager = AppWidgetManager.getInstance(this)
            VisionBoardWidget.updateAppWidget(this, appWidgetManager, appWidgetId)

            val resultValue = Intent().apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            setResult(RESULT_OK, resultValue)
            finish()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (isFinishing) {
            val resultValue = Intent().apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            setResult(RESULT_OK, resultValue)
        }
    }
} 