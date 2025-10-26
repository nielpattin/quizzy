package com.quizzy.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

class MainActivity: FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "in_app_notifications"
            val channelName = "In-App Notifications"
            val channelDescription = "Real-time in-app notifications"
            val importance = NotificationManager.IMPORTANCE_HIGH
            
            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = channelDescription
                enableVibration(true)
                enableLights(true)
            }
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
}
