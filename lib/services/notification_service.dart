import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // Navigate to the specific post
      // This will be handled by the main app
      print('Notification tapped with payload: $payload');
    }
  }

  static Future<void> showUploadProgress({
    required int id,
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
  }) async {
    await initialize();

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'upload_progress',
      'Upload Progress',
      channelDescription: 'Shows upload progress for media files',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      showProgress: true,
      maxProgress: maxProgress,
      progress: progress,
      autoCancel: false,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details);
  }

  static Future<void> showUploadComplete({
    required String tweetId,
    required String title,
    required String body,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'upload_complete',
      'Upload Complete',
      channelDescription: 'Notifies when upload is complete',
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: tweetId, // Pass tweet ID as payload for navigation
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  static Future<void> showIncomingCall({
    required String callId,
    required String callerName,
    required String callType,
  }) async {
    await initialize();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'incoming_calls',
      'Incoming Calls',
      channelDescription: 'Notifications for incoming calls',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,
      autoCancel: false,
      ongoing: true,
      enableLights: true,
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('phone_ringing'),
      actions: [
        AndroidNotificationAction(
          'accept_call',
          'Accept',
          icon: DrawableResourceAndroidBitmap('ic_call_accept'),
        ),
        AndroidNotificationAction(
          'decline_call',
          'Decline',
          icon: DrawableResourceAndroidBitmap('ic_call_decline'),
        ),
      ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'phone_ringing.aiff',
      categoryIdentifier: 'INCOMING_CALL',
      interruptionLevel: InterruptionLevel.critical,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      callId.hashCode,
      'Incoming ${callType == 'video' ? 'Video' : 'Voice'} Call',
      'From $callerName',
      details,
      payload: 'incoming_call:$callId:$callType',
    );
  }

  static Future<void> cancelCallNotification(String callId) async {
    await _notifications.cancel(callId.hashCode);
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}