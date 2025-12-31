import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        importance: Importance.high,
        playSound: true,
      );

  Future<void> initialize() async {
    try {
      // 1. Request Permissions
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // 2. Setup Init Settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('ic_launcher');

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

      // 3. Initialize Plugin
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          Get.to(() => const NotificationScreen());
        },
      );

      // 4. Create Channel
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);

      // 5. Listeners for Firebase
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

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        Get.to(() => const NotificationScreen());
        _addToInAppController(message);
      });
    } catch (e) {
      debugPrint("🔴 Error initializing Notifications: $e");
    }
  }

  // 🔹 NEW: Public method to trigger Local Notification manually
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecond, // Unique ID
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          icon: 'ic_launcher',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFF6C63FF),
          styleInformation: BigTextStyleInformation(body), // Allows long text
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
