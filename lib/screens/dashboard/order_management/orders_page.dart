// lib/screens/dashboard/orders/orders_page.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/controllers/order_controller.dart';
import 'package:kakiso_reseller_app/models/order.dart';
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/order_management/order_details_page.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class OrdersPage extends StatefulWidget {
  /// Pass the logged-in user so we can filter & sync his/her orders
  final UserData? userData;

  const OrdersPage({super.key, this.userData});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final OrderController orderController;

  @override
  void initState() {
    super.initState();

    orderController = Get.isRegistered<OrderController>()
        ? Get.find<OrderController>()
        : Get.put(OrderController(), permanent: true);

    final String wooId = widget.userData?.wooCustomerId ?? '';
    final String appUserId = widget.userData?.userId ?? '';
    final String userEmail = widget.userData?.email ?? '';

    final String syncUserId = wooId.trim().isNotEmpty
        ? wooId.trim()
        : appUserId.trim();

    if (syncUserId.isNotEmpty || userEmail.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        orderController.syncOrdersFromWoo(
          userId: syncUserId,
          userEmail: userEmail,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentWooId = widget.userData?.wooCustomerId ?? '';
    final String currentAppId = widget.userData?.userId ?? '';
    final String currentEmail = widget.userData?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'My Orders',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Iconsax.refresh, size: 20),
            onPressed: () {
              final String syncUserId = currentWooId.trim().isNotEmpty
                  ? currentWooId.trim()
                  : currentAppId.trim();
              final String email = currentEmail.trim();

              if (syncUserId.isNotEmpty || email.isNotEmpty) {
                orderController.syncOrdersFromWoo(
                  userId: syncUserId,
                  userEmail: email,
                );
              }
            },
          ),
        ],
      ),
      body: Obx(() {
        final List<Order> all = orderController.orders;

        // Extra safety: filter by Woo customer id OR old app userId OR by email
        final String uidWoo = currentWooId.trim();
        final String uidApp = currentAppId.trim();
        final String email = currentEmail.trim().toLowerCase();

        final List<Order> orders = all.where((o) {
          bool matchId = false;
          bool matchEmail = false;

          final String orderUserId = o.userId.trim();
          final String orderEmail = o.userEmail.trim().toLowerCase();

          if (uidWoo.isNotEmpty && orderUserId.isNotEmpty) {
            matchId = (orderUserId == uidWoo);
          }

          // Fallback: match old app userId stored in local orders
          if (!matchId && uidApp.isNotEmpty && orderUserId.isNotEmpty) {
            matchId = (orderUserId == uidApp);
          }

          if (email.isNotEmpty && orderEmail.isNotEmpty) {
            matchEmail = (orderEmail == email);
          }

          // If all identifiers are empty (should not happen), show all
          if (uidWoo.isEmpty && uidApp.isEmpty && email.isEmpty) {
            return true;
          }

          return matchId || matchEmail;
        }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (orders.isEmpty) {
          return _buildEmptyState();
        }

        final double totalRevenue = orders.fold(
          0.0,
          (sum, o) => sum + o.amount,
        );

        return Column(
          children: [
            const SizedBox(height: 8),
            _buildSummaryHeader(
              totalOrders: orders.length,
              totalRevenue: totalRevenue,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _OrderCard(order: order);
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSummaryHeader({
    required int totalOrders,
    required double totalRevenue,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accentColor.withOpacity(0.9),
              accentColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Iconsax.receipt_2,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalOrders orders • ₹${totalRevenue.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Iconsax.receipt_1,
                size: 40,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'No orders yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Once you place orders for your customers,\n they will show up here with full status.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;

  const _OrderCard({required this.order});

  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.packed:
        return 'Packed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for delivery';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return Colors.orange;
      case OrderStatus.packed:
        return Colors.deepPurple;
      case OrderStatus.shipped:
        return Colors.blue;
      case OrderStatus.outForDelivery:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
    }
  }

  IconData _statusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return Iconsax.verify;
      case OrderStatus.packed:
        return Iconsax.box;
      case OrderStatus.shipped:
        return Iconsax.truck_fast;
      case OrderStatus.outForDelivery:
        return Iconsax.location;
      case OrderStatus.delivered:
        return Iconsax.tick_circle;
    }
  }

  String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();

    final hour24 = d.hour;
    final minute = d.minute.toString().padLeft(2, '0');
    final isPm = hour24 >= 12;
    final hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final hh = hour12.toString().padLeft(2, '0');
    final ampm = isPm ? 'PM' : 'AM';

    return '$dd/$mm/$yyyy • $hh:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _statusColor(order.status);

    return InkWell(
      onTap: () {
        Get.to(() => OrderDetailsPage(orderId: order.id));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Left icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Iconsax.receipt_item,
                color: accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Middle info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order id + amount
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Order #${order.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '₹${order.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (order.userName.isNotEmpty)
                    Text(
                      order.userName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(order.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // Right status chips
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _statusIcon(order.status),
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _statusLabel(order.status),
                      style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: order.isPaid
                        ? Colors.green.withOpacity(0.08)
                        : Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    order.isPaid ? 'PAID' : 'PAID',
                    style: TextStyle(
                      fontSize: 10,
                      color: order.isPaid ? Colors.green : Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
