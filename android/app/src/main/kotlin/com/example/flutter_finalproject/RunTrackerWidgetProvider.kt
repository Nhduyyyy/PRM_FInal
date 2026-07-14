package com.example.flutter_finalproject

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/// Renders this week's distance + current streak on the Android home
/// screen, refreshed from Dart via HomeWidgetService after each saved run.
class RunTrackerWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences
  ) {
    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.home_widget_layout).apply {
            val pendingIntent = HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)
            setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            val weekKm = widgetData.getString("week_km", null) ?: "0.0"
            setTextViewText(R.id.widget_week_km, "$weekKm km")

            val streak = widgetData.getString("streak", null) ?: "0"
            setTextViewText(R.id.widget_streak, "🔥 $streak ngày streak")
          }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
