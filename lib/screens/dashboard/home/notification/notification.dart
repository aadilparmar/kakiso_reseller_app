import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

// --- IMPORTS ---
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/controllers/home_products_controller.dart';
import 'package:kakiso_reseller_app/screens/dashboard/product/product_details_page.dart';
import 'package:kakiso_reseller_app/services/notification_services.dart';

// --- 1. MODEL ---
enum NotificationType { order, offer, info, alert, product }

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final NotificationType type;
  bool isRead;
  final String? productImage;
  final ProductModel? linkedProduct;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.productImage,
    this.linkedProduct,
  });
}

// --- 2. CONTROLLER ---
class NotificationController extends GetxController {
  var notifications = <NotificationModel>[].obs;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _startProductNotificationTimer();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  // 🔹 Firebase Handler
  void addFromFirebase({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) {
    NotificationType type = NotificationType.info;
    String lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('order')) {
      type = NotificationType.order;
    } else if (lowerTitle.contains('offer') || title.contains('%')) {
      type = NotificationType.offer;
    } else if (lowerTitle.contains('alert') || lowerTitle.contains('deal')) {
      type = NotificationType.alert;
    } else if (lowerTitle.contains('arrival') || lowerTitle.contains('stock')) {
      type = NotificationType.product;
    }

    String? imageUrl = data?['image'];

    final newNotification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: DateTime.now(),
      type: type,
      isRead: false,
      productImage: imageUrl,
    );

    notifications.insert(0, newNotification);
  }

  // --- SMART GENERATOR LOGIC ---
  void _startProductNotificationTimer() {
    // Run immediately after 5 seconds
    Future.delayed(const Duration(seconds: 5), _generateSmartNotification);

    // Schedule for every 5 minutess
    _timer = Timer.periodic(const Duration(minutes: 20), (timer) {
      _generateSmartNotification();
    });
  }

  void _generateSmartNotification() {
    try {
      final homeController = Get.isRegistered<HomeProductsController>()
          ? Get.find<HomeProductsController>()
          : Get.put(HomeProductsController());

      final products = homeController.allProducts;

      String title = '';
      String body = '';
      NotificationType type = NotificationType.info;
      String? image;
      ProductModel? linkedProduct;

      if (products.isEmpty) {
        title = "🚀 Welcome to Kakiso!";
        body = "Your business journey starts here. Check out new arrivals.";
        type = NotificationType.info;
      } else {
        final random = Random();
        final product = products[random.nextInt(products.length)];
        linkedProduct = product;
        image = product.image;

        double price = double.tryParse(product.price) ?? 0;
        int discount = product.discountPercentage ?? 0;

        if (discount > 15) {
          type = NotificationType.offer;
          title = "🎉 Mega Offer on ${product.name}";
          body = "Flat $discount% OFF! Grab it for just ₹${product.price}.";
        } else if (price < 800 && price > 0) {
          type = NotificationType.alert;
          title = "🔥 Steal Deal Under ₹800";
          body = "Budget buy: ${product.name} is selling fast.";
        } else {
          type = NotificationType.product;
          title = "✨ Trending Now: ${product.name}";
          body = "Refresh your catalog with this new arrival.";
        }
      }

      // Add to List
      final newNotification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        timestamp: DateTime.now(),
        type: type,
        isRead: false,
        productImage: image,
        linkedProduct: linkedProduct,
      );

      notifications.insert(0, newNotification);

      // Trigger System Notification
      NotificationService().showNotification(title: title, body: body);

      // Trigger In-App Snackbar
      Get.snackbar(
        title,
        body,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.white.withOpacity(0.9),
        colorText: Colors.black,
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 4),
        icon: image != null
            ? Image.network(image, width: 40, height: 40, fit: BoxFit.cover)
            : const Icon(Iconsax.notification, color: accentColor),
        onTap: (_) {
          if (linkedProduct != null)
            Get.to(() => ProductDetailsPage(product: linkedProduct!));
        },
      );
    } catch (e) {
      debugPrint("Notification Error: $e");
    }
  }

  void markAsRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      var item = notifications[index];
      item.isRead = true;
      notifications[index] = item;
      notifications.refresh();
      if (item.linkedProduct != null) {
        Get.to(() => ProductDetailsPage(product: item.linkedProduct!));
      }
    }
  }

  void markAllAsRead() {
    for (var i = 0; i < notifications.length; i++) {
      var item = notifications[i];
      item.isRead = true;
      notifications[i] = item;
    }
    notifications.refresh();
  }

  void removeNotification(String id) {
    notifications.removeWhere((n) => n.id == id);
  }
}

// --- 3. UI SCREEN ---
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationController());

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          "Notifications",
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => controller.markAllAsRead(),
            child: const Text(
              "Mark all read",
              style: TextStyle(
                color: accentColor,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.notification_bing,
                  size: 60,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                const Text(
                  "No notifications yet",
                  style: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: controller.notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final notification = controller.notifications[index];
            return _buildNotificationItem(notification, controller);
          },
        );
      }),
    );
  }

  Widget _buildNotificationItem(
    NotificationModel item,
    NotificationController controller,
  ) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => controller.removeNotification(item.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Iconsax.trash, color: Colors.red),
      ),
      child: GestureDetector(
        onTap: () => controller.markAsRead(item.id),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: item.isRead ? Colors.white : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? Colors.grey.shade200
                  : accentColor.withOpacity(0.3),
              width: item.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.productImage != null && item.productImage!.isNotEmpty)
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                    image: DecorationImage(
                      image: NetworkImage(item.productImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getIconBgColor(item.type),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIcon(item.type),
                    color: _getIconColor(item.type),
                    size: 26,
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(item.timestamp),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getIconBgColor(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Colors.blue.shade50;
      case NotificationType.offer:
        return const Color(0xFFFFF4E5);
      case NotificationType.alert:
        return const Color(0xFFFFEBEE);
      case NotificationType.product:
        return const Color(0xFFF3E5F5);
      case NotificationType.info:
        return Colors.grey.shade100;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Colors.blue;
      case NotificationType.offer:
        return Colors.orange.shade700;
      case NotificationType.alert:
        return Colors.red.shade600;
      case NotificationType.product:
        return Colors.purple.shade600;
      case NotificationType.info:
        return Colors.grey.shade600;
    }
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.order:
        return Iconsax.box;
      case NotificationType.offer:
        return Iconsax.discount_shape;
      case NotificationType.alert:
        return Iconsax.flash_1;
      case NotificationType.product:
        return Iconsax.bag_2;
      case NotificationType.info:
        return Iconsax.info_circle;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inSeconds < 60) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }
}
