package org.orbitronhd.dose.alarm

import android.content.Context
import android.content.SharedPreferences
import org.json.JSONArray
import org.json.JSONObject

class AlarmStorage(context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    companion object {
        private const val PREFS_NAME = "org.orbitronhd.dose.alarm.prefs"
        private const val KEY_ALARMS = "alarms"
    }

    fun saveAlarm(alarmData: AlarmData) {
        val alarms = getAllAlarms().toMutableList()
        // Remove existing if it has the same ID
        alarms.removeAll { it.id == alarmData.id }
        alarms.add(alarmData)
        saveList(alarms)
    }

    fun removeAlarm(id: Int) {
        val alarms = getAllAlarms().toMutableList()
        val changed = alarms.removeAll { it.id == id }
        if (changed) {
            saveList(alarms)
        }
    }
    
    fun getAlarm(id: Int): AlarmData? {
        return getAllAlarms().find { it.id == id }
    }

    fun getAllAlarms(): List<AlarmData> {
        val jsonStr = prefs.getString(KEY_ALARMS, null) ?: return emptyList()
        val result = mutableListOf<AlarmData>()
        try {
            val jsonArray = JSONArray(jsonStr)
            for (i in 0 until jsonArray.length()) {
                val jsonObj = jsonArray.getJSONObject(i)
                result.add(AlarmData.fromJson(jsonObj))
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        return result
    }

    private fun saveList(alarms: List<AlarmData>) {
        val jsonArray = JSONArray()
        for (alarm in alarms) {
            jsonArray.put(alarm.toJson())
        }
        prefs.edit().putString(KEY_ALARMS, jsonArray.toString()).apply()
    }
    
    fun clear() {
        prefs.edit().clear().apply()
    }
}
