import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Firebase Cloud Messaging Service
/// Handles push notifications
class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Initialize FCM
  Future<void> initialize({
    required Function(RemoteMessage) onMessage,
    required Function(RemoteMessage) onMessageOpenedApp,
    required Function(String?) onTokenRefresh,
  }) async {
    try {
      // Request permission
      final settings = await requestPermission();
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('FCM: User granted permission');
        
        // Get FCM token
        _fcmToken = await _fcm.getToken();
        debugPrint('FCM Token: $_fcmToken');
        onTokenRefresh(_fcmToken);
        
        // Listen to token refresh
        _fcm.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          debugPrint('FCM Token refreshed: $newToken');
          onTokenRefresh(newToken);
        });
        
        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(onMessage);
        
        // Handle notification tap when app is in background
        FirebaseMessaging.onMessageOpenedApp.listen(onMessageOpenedApp);
        
        // Handle notification tap when app was terminated
        final initialMessage = await _fcm.getInitialMessage();
        if (initialMessage != null) {
          onMessageOpenedApp(initialMessage);
        }
        
        // Setup background message handler
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
      } else {
        debugPrint('FCM: User declined or has not accepted permission');
      }
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  /// Request notification permission
  Future<NotificationSettings> requestPermission() async {
    return await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true,
      provisional: false,
      sound: true,
    );
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _fcm.deleteToken();
      _fcmToken = null;
      debugPrint('FCM token deleted');
    } catch (e) {
      debugPrint('Error deleting token: $e');
    }
  }

  /// Get initial message (for when app was opened from terminated state)
  Future<RemoteMessage?> getInitialMessage() async {
    return await _fcm.getInitialMessage();
  }

  /// Set foreground notification presentation options (iOS)
  Future<void> setForegroundNotificationPresentationOptions({
    bool alert = true,
    bool badge = true,
    bool sound = true,
  }) async {
    if (Platform.isIOS) {
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: alert,
        badge: badge,
        sound: sound,
      );
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _fcm.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification?.title}');
  
  // Handle the message (save to local DB, show notification, etc.)
  // This runs in a separate isolate
}
