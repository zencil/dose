package org.orbitronhd.dose.alarm

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DoseAlarmPlugin(private val context: Context) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    companion object {
        private const val METHOD_CHANNEL = "org.orbitronhd.dose/alarm"
        private const val EVENT_CHANNEL = "org.orbitronhd.dose/alarm_events"
        
        private var eventSink: EventChannel.EventSink? = null
        private val handler = Handler(Looper.getMainLooper())

        fun register(flutterEngine: FlutterEngine, context: Context) {
            val plugin = DoseAlarmPlugin(context)
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
                .setMethodCallHandler(plugin)
                
            EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
                .setStreamHandler(plugin)
        }

        fun notifyAlarmFired(id: Int, title: String) {
            handler.post {
                eventSink?.success(mapOf(
                    "type" to "alarmFired",
                    "id" to id,
                    "title" to title
                ))
            }
        }

        fun notifyAlarmAction(id: Int, action: String) {
            handler.post {
                eventSink?.success(mapOf(
                    "type" to "alarmAction",
                    "id" to id,
                    "action" to action
                ))
            }
        }
    }

    private val scheduler = AlarmScheduler(context)
    private val storage = AlarmStorage(context)

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "scheduleAlarm" -> {
                val id = call.argument<Int>("id") ?: return result.error("INVALID_ARGS", "Missing ID", null)
                val triggerAtMs = call.argument<Long>("triggerAtMs") ?: return result.error("INVALID_ARGS", "Missing triggerAtMs", null)
                val title = call.argument<String>("title") ?: "Alarm"
                val body = call.argument<String>("body") ?: ""
                val loopAudio = call.argument<Boolean>("loopAudio") ?: true
                val vibrate = call.argument<Boolean>("vibrate") ?: true

                val alarmData = AlarmData(id, triggerAtMs, title, body, loopAudio, vibrate)
                scheduler.schedule(alarmData)
                result.success(null)
            }
            "cancelAlarm" -> {
                val id = call.argument<Int>("id") ?: return result.error("INVALID_ARGS", "Missing ID", null)
                scheduler.cancel(id)
                result.success(null)
            }
            "stopRinging" -> {
                val stopIntent = Intent(context, AlarmForegroundService::class.java).apply {
                    action = AlarmForegroundService.ACTION_STOP
                }
                context.startService(stopIntent)
                result.success(null)
            }
            "getScheduledAlarms" -> {
                val alarms = storage.getAllAlarms().map {
                    mapOf(
                        "id" to it.id,
                        "triggerAtMs" to it.triggerAtMs,
                        "title" to it.title,
                        "body" to it.body,
                        "loopAudio" to it.loopAudio,
                        "vibrate" to it.vibrate
                    )
                }
                result.success(alarms)
            }
            "minimizeIfLocked" -> {
                try {
                    val keyguardManager = context.getSystemService(Context.KEYGUARD_SERVICE) as android.app.KeyguardManager
                    if (keyguardManager.isKeyguardLocked) {
                        val intent = Intent(Intent.ACTION_MAIN).apply {
                            addCategory(Intent.CATEGORY_HOME)
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        }
                        context.startActivity(intent)
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
                result.success(null)
            }
            "isRinging" -> {
                val alarmId = call.argument<Int>("id") ?: return result.error("INVALID", null, null)
                val ringing = AlarmForegroundService.isRinging(alarmId)
                result.success(ringing)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }
}
