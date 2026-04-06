package org.orbitronhd.dose.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || 
            intent.action == "android.intent.action.MY_PACKAGE_REPLACED" ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            
            AlarmScheduler(context).rescheduleAll()
        }
    }
}
