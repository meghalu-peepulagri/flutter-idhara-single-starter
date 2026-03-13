package com.mycompany.idhara

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.app.AlarmManager
import android.os.SystemClock
import android.widget.RemoteViews
import android.app.PendingIntent
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetBackgroundIntent

class PumpWidgetProvider : HomeWidgetProvider() {

    private val REFRESH_INTERVAL_MS: Long = 15000 // 15 seconds

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_pump)
            
            // Set up the intent that starts the RemoteViewsService, which will
            // provide the views for this collection.
            val intent = Intent(context, PumpWidgetService::class.java).apply {
                // Add the app widget ID to the intent extras.
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }

            // Set the RemoteAdapter to use the service
            views.setRemoteAdapter(R.id.pump_list, intent)

            // Set up click intent template
            val clickIntent = Intent(context, MainActivity::class.java).apply {
                action = Intent.ACTION_VIEW
            }
            val clickPendingIntent = PendingIntent.getActivity(
                context, 
                0, 
                clickIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )
            views.setPendingIntentTemplate(R.id.pump_list, clickPendingIntent)

            // Schedule the auto-refresh alarm
            scheduleAutoRefresh(context)

            // Instruct the widget manager to update the widget
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.pump_list)
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelAutoRefresh(context)
    }

    private fun scheduleAutoRefresh(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("idhara://refresh"))
        
        // Use setRepeating for periodic updates. 
        // Note: Android restricts frequent alarms (min 1 minute) on newer versions for battery saving.
        // For strictly 15-second intervals, inexact repeating is used, but it may be batched by the OS.
        alarmManager.setRepeating(
            AlarmManager.ELAPSED_REALTIME_WAKEUP,
            SystemClock.elapsedRealtime() + REFRESH_INTERVAL_MS,
            REFRESH_INTERVAL_MS,
            backgroundIntent
        )
    }

    private fun cancelAutoRefresh(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val backgroundIntent = HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("idhara://refresh"))
        alarmManager.cancel(backgroundIntent)
    }
}
