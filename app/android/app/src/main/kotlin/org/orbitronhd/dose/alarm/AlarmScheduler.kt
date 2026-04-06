package org.orbitronhd.dose.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

class AlarmScheduler(private val context: Context) {
    private val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    private val storage = AlarmStorage(context)

    fun schedule(alarmData: AlarmData) {
        // Save to storage first
        storage.saveAlarm(alarmData)

        val triggerAtMs = alarmData.triggerAtMs
        val alarmIntent = getPendingIntent(alarmData.id)

        // Show intent launched when alarm icon is clicked
        val showIntent = Intent(context, org.orbitronhd.dose.MainActivity::class.java)
        showIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        val showPendingIntent = PendingIntent.getActivity(
            context,
            alarmData.id,
            showIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val alarmClockInfo = AlarmManager.AlarmClockInfo(triggerAtMs, showPendingIntent)
        try {
            alarmManager.setAlarmClock(alarmClockInfo, alarmIntent)
        } catch (e: SecurityException) {
            // Android 14+ requires USE_EXACT_ALARM or SCHEDULE_EXACT_ALARM permission
            e.printStackTrace()
        }
    }

    fun cancel(id: Int) {
        // Remove from storage
        storage.removeAlarm(id)

        // Cancel the Intent in AlarmManager
        val alarmIntent = getPendingIntent(id)
        alarmManager.cancel(alarmIntent)
        alarmIntent.cancel()
    }

    fun rescheduleAll() {
        val alarms = storage.getAllAlarms()
        val now = System.currentTimeMillis()
        
        for (alarm in alarms) {
            if (alarm.triggerAtMs > now) {
                // Reschedule if future
                val alarmIntent = getPendingIntent(alarm.id)
                val showIntent = Intent(context, org.orbitronhd.dose.MainActivity::class.java)
                showIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                val showPendingIntent = PendingIntent.getActivity(
                    context,
                    alarm.id,
                    showIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                val alarmClockInfo = AlarmManager.AlarmClockInfo(alarm.triggerAtMs, showPendingIntent)
                try {
                    alarmManager.setAlarmClock(alarmClockInfo, alarmIntent)
                } catch (e: SecurityException) {
                    e.printStackTrace()
                }
            } else {
                // Missed while device was off, ignore or remove
                storage.removeAlarm(alarm.id)
            }
        }
    }

    private fun getPendingIntent(id: Int): PendingIntent {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = AlarmReceiver.ACTION_ALARM_FIRED
            putExtra(AlarmReceiver.EXTRA_ALARM_ID, id)
        }
        return PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }
}
