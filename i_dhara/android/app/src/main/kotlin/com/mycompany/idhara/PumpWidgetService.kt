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
            val runTime = pumpObj.optInt("runTimeMinutes", 0)

            views.setTextViewText(R.id.pump_item_name, name)

            if (fault != 0) {
                views.setTextViewText(R.id.pump_item_status, "FAULT")
                views.setTextColor(R.id.pump_item_status, android.graphics.Color.RED)
            } else {
                val statusText = if (isRunning) "ON" else "OFF"
                views.setTextViewText(R.id.pump_item_status, statusText)
                views.setTextColor(
                    R.id.pump_item_status,
                    if (isRunning) android.graphics.Color.WHITE else android.graphics.Color.LTGRAY
                )
            }

            views.setTextViewText(R.id.pump_item_signal, "$signalQuality%")
            
            // Set arbitrary progress based on UI or realistic progress
            val progressValue = if (isRunning) (runTime % 100).coerceAtLeast(10) else 0
            views.setProgressBar(R.id.pump_item_progress, 100, if(isRunning) 100 else 0, false)

            // Dynamic colors array based on mockup
            val layoutDrawables = intArrayOf(
                R.drawable.progress_bar_blue,
                R.drawable.progress_bar_green,
                R.drawable.progress_bar_orange,
                R.drawable.progress_bar_pink,
                R.drawable.progress_bar_purple
            )

            // In older APIs, changing progressDrawable dynamically via RemoteViews is tricky.
            // If using setInt, it might not render the clip correctly.
            // But we will attempt to set it, if it fails, it defaults to blue
            // Note: Setting custom drawables inside RemoteViews for progress bars can be limited by RemoteViews security
            // A safer bet in Android Widgets is showing different ProgressBar view IDs altogether, but for 20 pumps we will use blue default if this fails
            
            // NOTE for API 22: You cannot easily change progressDrawable dynamically in RemoteViews. 
            // So we will keep it simple.

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
