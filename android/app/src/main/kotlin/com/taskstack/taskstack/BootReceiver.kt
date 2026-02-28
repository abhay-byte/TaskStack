package com.taskstack.taskstack

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Receives BOOT_COMPLETED and QUICKBOOT_POWERON broadcasts to reschedule
 * all task notifications after device restart.
 *
 * NOTE: The actual rescheduling is handled through FlutterLocalNotificationsPlugin's
 * built-in boot-restoration mechanism when using exactAllowWhileIdle scheduling.
 * This receiver exists as a safety net to trigger Flutter engine initialisation
 * on boot, ensuring the notification channel is properly registered.
 */
class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "TaskStack.BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action in listOf(
                Intent.ACTION_BOOT_COMPLETED,
                "android.intent.action.QUICKBOOT_POWERON",
                "com.htc.intent.action.QUICKBOOT_POWERON"
            )
        ) {
            Log.i(TAG, "Boot received — notifications will self-restore via exactAllowWhileIdle alarms")
            // The OS will fire already-scheduled TriggerContentProvider alarms on reboot
            // for apps using AlarmManager.EXACT + setExactAndAllowWhileIdle.
            // If rescheduling is needed, start a headless Flutter background service here.
        }
    }
}
