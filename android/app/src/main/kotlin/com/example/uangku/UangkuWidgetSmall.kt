package com.example.uangku

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * Widget Uangku — Small (2×2)
 * Membaca data dari SharedPreferences yang ditulis Flutter via home_widget.
 */
class UangkuWidgetSmall : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // home_widget menyimpan data di SharedPreferences bernama "HomeWidgetPreferences"
            val prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)

            val balance     = prefs.getString("balance",     "Rp –") ?: "Rp –"
            val lastUpdated = prefs.getString("last_updated", "–")   ?: "–"

            val views = RemoteViews(context.packageName, R.layout.uangku_widget_small)

            views.setTextViewText(R.id.widget_balance,      balance)
            views.setTextViewText(R.id.widget_last_updated, lastUpdated)

            // Tap widget → buka MainActivity
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                1,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            // Untuk small widget, gunakan id root LinearLayout langsung
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
