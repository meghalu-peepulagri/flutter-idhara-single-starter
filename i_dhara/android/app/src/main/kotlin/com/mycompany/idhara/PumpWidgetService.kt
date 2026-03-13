package com.mycompany.idhara

import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import android.net.Uri
import org.json.JSONArray
import org.json.JSONObject

class PumpWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return PumpRemoteViewsFactory(this.applicationContext)
    }
}

class PumpRemoteViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
    private var pumpDataArray: JSONArray = JSONArray()
    private lateinit var prefs: SharedPreferences

    override fun onCreate() {
        prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
        loadData()
    }

    private fun loadData() {
        // App group sync from flutter using home_widget package saves in "HomeWidgetPreferences" usually or similar default
        // In home_widget v0.1.6 default prefs are used.
        val widgetString = prefs.getString("pump_data", "[]") ?: "[]"
        try {
            pumpDataArray = JSONArray(widgetString)
        } catch (e: Exception) {
            pumpDataArray = JSONArray()
        }
    }

    override fun onDataSetChanged() {
        // This is called when the widget is updated
        loadData()
    }

    override fun onDestroy() {
        // Cleanup if needed
    }

    override fun getCount(): Int {
        return pumpDataArray.length()
    }

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_pump_item)

        try {
            val pumpObj = pumpDataArray.getJSONObject(position)
            val name = pumpObj.optString("name", "Pump ${position + 1}")
            val isRunning = pumpObj.optBoolean("isRunning", false)
            val signalQuality = pumpObj.optInt("signalQuality", 0)
            val fault = pumpObj.optInt("fault", 0)
            val runTimeDuration = pumpObj.optString("runTimeMinutes", "")
            val runTimeProgress = pumpObj.optInt("runTimeProgress", 0)

            views.setTextViewText(R.id.pump_item_name, name)

            // Always show ON/OFF status
            val statusText = if (isRunning) "ON" else "OFF"
            views.setTextViewText(R.id.pump_item_status, statusText)
            views.setTextColor(
                R.id.pump_item_status,
                if (isRunning) android.graphics.Color.WHITE else android.graphics.Color.LTGRAY
            )

            // Show FAULT next to it if fault exists
            if (fault != 0) {
                views.setTextViewText(R.id.pump_item_fault, " FAULT")
                views.setViewVisibility(R.id.pump_item_fault, android.view.View.VISIBLE)
            } else {
                views.setTextViewText(R.id.pump_item_fault, "")
                views.setViewVisibility(R.id.pump_item_fault, android.view.View.GONE)
            }

            // Map Signal Quality to custom ranges
            val signalBars = when (signalQuality) {
                in 20..Int.MAX_VALUE -> R.drawable.ic_signal_4
                in 15..19            -> R.drawable.ic_signal_3
                in 10..14            -> R.drawable.ic_signal_2
                in 2..9              -> R.drawable.ic_signal_1
                else                 -> R.drawable.ic_signal_0
            }
            views.setImageViewResource(R.id.pump_item_signal_icon, signalBars)

            // Display Runtime instead of Signal
            views.setTextViewText(R.id.pump_item_runtime, runTimeDuration)
            
            // The user requested a specific order: 1st Orange, 2nd Blue, 3rd Yellow, 4th Green, etc.
            val progressIds = intArrayOf(
                R.id.pump_item_progress_orange,
                R.id.pump_item_progress_blue,
                R.id.pump_item_progress_yellow,
                R.id.pump_item_progress_green,
                R.id.pump_item_progress_red,
                R.id.pump_item_progress_pink,
                R.id.pump_item_progress_cyan,
                R.id.pump_item_progress_purple,
                R.id.pump_item_progress_teal,
                R.id.pump_item_progress_indigo
            )

            // Hide them all
            for (id in progressIds) {
                views.setViewVisibility(id, android.view.View.GONE)
            }

            // Show and set the appropriate one
            val colorIndex = position % progressIds.size
            val activeProgressId = progressIds[colorIndex]
            views.setViewVisibility(activeProgressId, android.view.View.VISIBLE)
            
            // Progress based on runtime duration out of 24h
            views.setProgressBar(activeProgressId, 100, runTimeProgress, false)

            // Setup FillInIntent to make the item clickable
            val fillInIntent = Intent().apply {
                // Pass some generic data to trigger the template, or pass specific pump data if desired
                putExtra("clicked_pump_mac", pumpObj.optString("macAddress", ""))
                data = Uri.parse("idhara://idhara.com/dashboard")
            }
            views.setOnClickFillInIntent(R.id.pump_item_container, fillInIntent)

        } catch (e: Exception) {
            e.printStackTrace()
        }

        return views
    }

    override fun getLoadingView(): RemoteViews? {
        return null
    }

    override fun getViewTypeCount(): Int {
        return 1
    }

    override fun getItemId(position: Int): Long {
        return position.toLong()
    }

    override fun hasStableIds(): Boolean {
        return true
    }
}
