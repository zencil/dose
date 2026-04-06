package org.orbitronhd.dose.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import androidx.core.content.ContextCompat

class AlarmReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_ALARM_FIRED = "org.orbitronhd.dose.alarm.ACTION_ALARM_FIRED"
        const val ACTION_SNOOZE = "org.orbitronhd.dose.ACTION_SNOOZE"
        const val ACTION_DONE = "org.orbitronhd.dose.ACTION_DONE"
        const val EXTRA_ALARM_ID = "EXTRA_ALARM_ID"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return

        if (action == ACTION_ALARM_FIRED) {
            val alarmId = intent.getIntExtra(EXTRA_ALARM_ID, -1)
            if (alarmId == -1) return

            val storage = AlarmStorage(context)
            val alarmData = storage.getAlarm(alarmId) ?: return

            // Acquire a partial wake lock to keep CPU running until service starts
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "Dose:AlarmReceiverLock"
            )
            wakeLock.acquire(3000)

            // Start Foreground Service
            val serviceIntent = Intent(context, AlarmForegroundService::class.java).apply {
                putExtra(AlarmForegroundService.EXTRA_ALARM_ID, alarmId)
                putExtra(AlarmForegroundService.EXTRA_TITLE, alarmData.title)
                putExtra(AlarmForegroundService.EXTRA_BODY, alarmData.body)
                putExtra(AlarmForegroundService.EXTRA_LOOP, alarmData.loopAudio)
                putExtra(AlarmForegroundService.EXTRA_VIBRATE, alarmData.vibrate)
            }
            
            ContextCompat.startForegroundService(context, serviceIntent)
            
            // Remove from storage now that it fired
            storage.removeAlarm(alarmId)
        } else if (action == ACTION_SNOOZE || action == ACTION_DONE) {
            val alarmId = intent.getIntExtra(AlarmForegroundService.EXTRA_ALARM_ID, -1)
            if (alarmId != -1) {
                // Stop the service silently
                val stopIntent = Intent(context, AlarmForegroundService::class.java).apply {
                    this.action = AlarmForegroundService.ACTION_STOP
                }
                context.startService(stopIntent)
                
                // Notify Flutter to run background tasks
                val actionType = if (action == ACTION_SNOOZE) "snooze" else "done"
                DoseAlarmPlugin.notifyAlarmAction(alarmId, actionType)
            }
        }
    }
}
