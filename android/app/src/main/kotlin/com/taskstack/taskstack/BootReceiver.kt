package com.taskstack.taskstack

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Receives BOOT_COMPLETED and QUICKBOOT_POWERON broadcasts after device restart.
 *
 * NOTE: awesome_notifications (the plugin in use) re-registers its AlarmManager
 * exact alarms automatically on reboot when the app is brought to the foreground.
 * This receiver is retained as a logging hook and future extension point for
 * headless rescheduling if AC5 (background/killed-process restore) requires it.
 * No Flutter engine start is performed here until that need is confirmed on device.
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
