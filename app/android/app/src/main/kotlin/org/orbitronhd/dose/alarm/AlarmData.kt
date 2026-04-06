package org.orbitronhd.dose.alarm

import org.json.JSONObject

data class AlarmData(
    val id: Int,
    val triggerAtMs: Long,
    val title: String,
    val body: String,
    val loopAudio: Boolean,
    val vibrate: Boolean
) {
    fun toJson(): JSONObject {
        val json = JSONObject()
        json.put("id", id)
        json.put("triggerAtMs", triggerAtMs)
        json.put("title", title)
        json.put("body", body)
        json.put("loopAudio", loopAudio)
        json.put("vibrate", vibrate)
        return json
    }

    companion object {
        fun fromJson(jsonStr: String): AlarmData {
            val json = JSONObject(jsonStr)
            return AlarmData(
                id = json.getInt("id"),
                triggerAtMs = json.getLong("triggerAtMs"),
                title = json.getString("title"),
                body = json.getString("body"),
                loopAudio = json.getBoolean("loopAudio"),
                vibrate = json.getBoolean("vibrate")
            )
        }
        
        fun fromJson(json: JSONObject): AlarmData {
            return AlarmData(
                id = json.getInt("id"),
                triggerAtMs = json.getLong("triggerAtMs"),
                title = json.getString("title"),
                body = json.getString("body"),
                loopAudio = json.getBoolean("loopAudio"),
                vibrate = json.getBoolean("vibrate")
            )
        }
    }
}
