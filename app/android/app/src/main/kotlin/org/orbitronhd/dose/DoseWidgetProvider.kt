package org.orbitronhd.dose

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class DoseWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray, widgetData: SharedPreferences) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Get data from SharedPreferences (set by Flutter)
                val missedText = widgetData.getString("widget_missed_text", "No missed medicines")
                val upcomingText = widgetData.getString("widget_upcoming_text", "Nothing scheduled")

                // Set the text
                setTextViewText(R.id.widget_missed_text, missedText)
                setTextViewText(R.id.widget_upcoming_text, upcomingText)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
