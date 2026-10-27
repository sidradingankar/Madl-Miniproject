package com.madl.emergency_assistance

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.telephony.SmsManager
import android.view.KeyEvent
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    // Channel names — must match the Dart side
    private val METHOD_CHANNEL = "com.madl.emergency_assistance/native"
    private val EVENT_CHANNEL  = "com.madl.emergency_assistance/volume_events"

    // Volume-down press tracking
    private val volumeDownTimestamps = mutableListOf<Long>()
    private val REQUIRED_PRESSES = 3
    private val PRESS_WINDOW_MS = 2000L   // 2 seconds

    // EventChannel sink — sends events to Flutter
    private var volumeEventSink: EventChannel.EventSink? = null

    // ─── Flutter Engine Setup ──────────────────────────────────

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // MethodChannel: Flutter → Native (send SMS, make call)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "sendSms" -> {
                        val phone = call.argument<String>("phone")
                        val message = call.argument<String>("message")
                        if (phone != null && message != null) {
                            val success = sendDirectSms(phone, message)
                            result.success(success)
                        } else {
                            result.error("INVALID_ARGS", "Phone and message required", null)
                        }
                    }
                    "makeCall" -> {
                        val phone = call.argument<String>("phone")
                        if (phone != null) {
                            val success = makeDirectCall(phone)
                            result.success(success)
                        } else {
                            result.error("INVALID_ARGS", "Phone number required", null)
                        }
                    }
                    "requestSmsPermission" -> {
                        requestSmsPermission()
                        result.success(true)
                    }
                    "requestCallPermission" -> {
                        requestCallPermission()
                        result.success(true)
                    }
                    "checkPermissions" -> {
                        val hasSms = hasSmsPermission()
                        val hasCall = hasCallPermission()
                        result.success(mapOf("sms" to hasSms, "call" to hasCall))
                    }
                    else -> result.notImplemented()
                }
            }

        // EventChannel: Native → Flutter (volume button events)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    volumeEventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    volumeEventSink = null
                }
            })
    }

    // ─── Volume Button Interception ────────────────────────────

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            val now = System.currentTimeMillis()

            // Remove stale presses outside the time window
            volumeDownTimestamps.removeAll { now - it > PRESS_WINDOW_MS }
            volumeDownTimestamps.add(now)

            if (volumeDownTimestamps.size >= REQUIRED_PRESSES) {
                volumeDownTimestamps.clear()
                // Notify Flutter that SOS was triggered via volume buttons
                volumeEventSink?.success("SOS_TRIGGERED")
            }

            return true  // consume the event — volume won't change
        }
        return super.onKeyDown(keyCode, event)
    }

    // ─── Direct SMS Sending ────────────────────────────────────

    private fun hasSmsPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this, android.Manifest.permission.SEND_SMS
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestSmsPermission() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(android.Manifest.permission.SEND_SMS),
            100
        )
    }

    private fun sendDirectSms(phone: String, message: String): Boolean {
        return try {
            if (!hasSmsPermission()) {
                requestSmsPermission()
                return false
            }
            val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                getSystemService(SmsManager::class.java)
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }

            // Split message if it's too long (SMS limit is 160 chars)
            val parts = smsManager.divideMessage(message)
            smsManager.sendMultipartTextMessage(phone, null, parts, null, null)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    // ─── Direct Phone Call ─────────────────────────────────────

    private fun hasCallPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this, android.Manifest.permission.CALL_PHONE
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestCallPermission() {
        ActivityCompat.requestPermissions(
            this,
            arrayOf(android.Manifest.permission.CALL_PHONE),
            101
        )
    }

    private fun makeDirectCall(phone: String): Boolean {
        return try {
            if (!hasCallPermission()) {
                requestCallPermission()
                return false
            }
            val callIntent = Intent(Intent.ACTION_CALL).apply {
                data = Uri.parse("tel:$phone")
            }
            startActivity(callIntent)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}
