import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// 🔴 CRITICAL: Ensure this path matches exactly where your notification.dart file is.
// If your file is in 'lib/screens/dashboard/notifications/notification.dart', change this line!
import 'package:kakiso_reseller_app/screens/dashboard/home/notification/notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  final AndroidNotificationChannel _androidChannel =
      const AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
        playSound: true,
      );

  Future<void> initialize() async {
    try {
      // 1. Setup Local Notification Settings
      // 🔴 CHANGE: Use 'notification_icon' (matches the file you added to drawable)
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('notification_icon');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          Get.to(() => const NotificationScreen());
        },
      );

      // 2. Create Channel
      final platform = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      await platform?.createNotificationChannel(_androidChannel);

      // 3. Request Permissions
      if (Platform.isAndroid) {
        await platform?.requestNotificationsPermission();
      }

      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // 4. Foreground Listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          showNotification(
            title: notification.title ?? 'New Notification',
            body: notification.body ?? '',
          );
        }
        _addToInAppController(message);
      });

      // 5. Background Tap Listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        Get.to(() => const NotificationScreen());
        _addToInAppController(message);
      });
    } catch (e) {
      debugPrint("🔴 Error initializing Notifications: $e");
    }
  }

  // 🔹 Trigger System Notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: 'notification_icon', // 🔴 MUST MATCH FILENAME IN DRAWABLE
          importance: Importance.max,
          priority: Priority.high,
          color: const Color(0xFF6C63FF),
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  void _addToInAppController(RemoteMessage message) {
    if (Get.isRegistered<NotificationController>()) {
      final controller = Get.find<NotificationController>();
      controller.addFromFirebase(
        title: message.notification?.title ?? "New Update",
        body: message.notification?.body ?? "",
        data: message.data,
      );
    }
  }
}
