// lib/main.dart
// Welcome to the One of the Best and First master piece Created By : Aadil Parmar
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:kakiso_reseller_app/app.dart';
import 'package:kakiso_reseller_app/controllers/shared_products_controller.dart';
import 'package:kakiso_reseller_app/services/notification_services.dart';

// 1. IMPORT THE PACKAGE
import 'package:flutter_auto_translate/flutter_auto_translate.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  // 🔹 2. FIX: INITIALIZE TRANSLATION SERVICE AS AN INSTANCE
  // Create the instance
  final translationService = TranslationService();
  // INITIALIZE THE CONTROLLER HERE
  Get.put(SharedProductsController());
  // Register it with GetX so we can find it in other files
  Get.put(translationService);
  // Call init() on the instance (not statically)
  await translationService.init();
  await NotificationService().initialize();
  runApp(const App());
}
