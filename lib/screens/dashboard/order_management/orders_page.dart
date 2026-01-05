import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import 'package:kakiso_reseller_app/controllers/order_controller.dart';
import 'package:kakiso_reseller_app/models/order.dart';
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/order_management/order_details_page.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

enum OrderSortOption { newest, oldest, amountHigh, amountLow }

class OrdersPage extends StatefulWidget {
  final UserData? userData;

  const OrdersPage({super.key, this.userData});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final OrderController orderController;

  // Search & Filter State
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  OrderStatus? _selectedStatusFilter;
  OrderSortOption _selectedSortOption = OrderSortOption.newest;

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    FocusScope.of(context).unfocus();
  }

  // --- HELPER METHODS FOR STATUS ---
  String _statusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.packed:
        return 'Packed';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
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
  // ---------------------------------

  // --- INSIGHTS FUNCTIONALITY ---
  void _showInsights(
    BuildContext context,
    List<Order> orders,
    double totalRevenue,
  ) {
    if (orders.isEmpty) return;

    final double averageValue = totalRevenue / orders.length;

    final Map<OrderStatus, int> statusCounts = {};
    for (var o in orders) {
      statusCounts[o.status] = (statusCounts[o.status] ?? 0) + 1;
    }

    final int deliveredCount = statusCounts[OrderStatus.delivered] ?? 0;
    final int activeCount = orders.length - deliveredCount;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        // SAFE AREA ADDED HERE
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const Text(
                  "Analytics & Insights",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildInsightCard(
                        label: "Avg. Order Value",
                        value: "₹${averageValue.toStringAsFixed(0)}",
                        icon: Iconsax.chart_2,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInsightCard(
                        label: "Active Orders",
                        value: "$activeCount",
                        icon: Iconsax.box_time,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text(
                  "Order Status Breakdown",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),

                ...OrderStatus.values.map((status) {
                  final int count = statusCounts[status] ?? 0;
                  if (count == 0) return const SizedBox.shrink();

                  final double percentage = count / orders.length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _statusIcon(status),
                                  size: 16,
                                  color: _statusColor(status),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _statusLabel(status),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              "$count (${(percentage * 100).toStringAsFixed(0)}%)",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _statusColor(status),
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInsightCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
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
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Iconsax.refresh, size: 20, color: Colors.black),
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

        final String uidWoo = currentWooId.trim();
        final String uidApp = currentAppId.trim();
        final String email = currentEmail.trim().toLowerCase();

        List<Order> filteredList = all.where((o) {
          bool matchId = false;
          bool matchEmail = false;

          final String orderUserId = o.userId.trim();
          final String orderEmail = o.userEmail.trim().toLowerCase();

          if (uidWoo.isNotEmpty && orderUserId.isNotEmpty) {
            matchId = (orderUserId == uidWoo);
          }
          if (!matchId && uidApp.isNotEmpty && orderUserId.isNotEmpty) {
            matchId = (orderUserId == uidApp);
          }
          if (email.isNotEmpty && orderEmail.isNotEmpty) {
            matchEmail = (orderEmail == email);
          }
          if (uidWoo.isEmpty && uidApp.isEmpty && email.isEmpty) {
            return true;
          }
          return matchId || matchEmail;
        }).toList();

        if (_selectedStatusFilter != null) {
          filteredList = filteredList
              .where((o) => o.status == _selectedStatusFilter)
              .toList();
        }

        if (_searchQuery.isNotEmpty) {
          final q = _searchQuery.toLowerCase();
          filteredList = filteredList.where((o) {
            final idMatch = o.id.toString().contains(q);
            final nameMatch = o.userName.toLowerCase().contains(q);
            final emailMatch = o.userEmail.toLowerCase().contains(q);
            return idMatch || nameMatch || emailMatch;
          }).toList();
        }

        filteredList.sort((a, b) {
          switch (_selectedSortOption) {
            case OrderSortOption.newest:
              return b.createdAt.compareTo(a.createdAt);
            case OrderSortOption.oldest:
              return a.createdAt.compareTo(b.createdAt);
            case OrderSortOption.amountHigh:
              return b.amount.compareTo(a.amount);
            case OrderSortOption.amountLow:
              return a.amount.compareTo(b.amount);
          }
        });

        final double totalRevenue = filteredList.fold(
          0.0,
          (sum, o) => sum + o.amount,
        );

        // SAFE AREA ADDED HERE
        return SafeArea(
          child: Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (val) {
                                setState(() {
                                  _searchQuery = val.trim();
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Search ID, Name or Email...',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500,
                                ),
                                prefixIcon: const Icon(
                                  Iconsax.search_normal,
                                  size: 18,
                                  color: Colors.grey,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        onPressed: _clearSearch,
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: PopupMenuButton<OrderSortOption>(
                            icon: const Icon(
                              Iconsax.sort,
                              color: Colors.black87,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (OrderSortOption result) {
                              setState(() {
                                _selectedSortOption = result;
                              });
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<OrderSortOption>>[
                                  const PopupMenuItem<OrderSortOption>(
                                    value: OrderSortOption.newest,
                                    child: Text('Newest First'),
                                  ),
                                  const PopupMenuItem<OrderSortOption>(
                                    value: OrderSortOption.oldest,
                                    child: Text('Oldest First'),
                                  ),
                                  const PopupMenuItem<OrderSortOption>(
                                    value: OrderSortOption.amountHigh,
                                    child: Text('Amount: High to Low'),
                                  ),
                                  const PopupMenuItem<OrderSortOption>(
                                    value: OrderSortOption.amountLow,
                                    child: Text('Amount: Low to High'),
                                  ),
                                ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'All',
                            isSelected: _selectedStatusFilter == null,
                            onTap: () =>
                                setState(() => _selectedStatusFilter = null),
                          ),
                          ...OrderStatus.values.map((status) {
                            return _buildFilterChip(
                              label: _statusLabel(status),
                              isSelected: _selectedStatusFilter == status,
                              onTap: () => setState(
                                () => _selectedStatusFilter = status,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              if (filteredList.isNotEmpty)
                _buildSummaryHeader(
                  context,
                  orders: filteredList,
                  totalRevenue: totalRevenue,
                ),

              const SizedBox(height: 8),

              Expanded(
                child: filteredList.isEmpty
                    ? _buildEmptyState(isSearchResult: _searchQuery.isNotEmpty)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final order = filteredList[index];
                          return _OrderCard(order: order);
                        },
                      ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? accentColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? accentColor : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(
    BuildContext context, {
    required List<Order> orders,
    required double totalRevenue,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showInsights(context, orders, totalRevenue),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accentColor.withValues(alpha: 0.9),
                  accentColor.withValues(alpha: 0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.25),
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
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Iconsax.chart,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Order Summary',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "Tap for insights",
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${orders.length} orders • ₹${totalRevenue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({bool isSearchResult = false}) {
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
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                isSearchResult ? Iconsax.search_status : Iconsax.receipt_1,
                size: 40,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isSearchResult ? 'No orders found' : 'No orders yet',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              isSearchResult
                  ? 'Try adjusting your search or filters.'
                  : 'Once you place orders for your customers,\n they will show up here with full status.',
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

  // Helper methods (duplicates of those in main class for local usage)
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
    // 1. Ensure we treat the input as UTC first, then add 5:30 offset
    // This forces IST regardless of the device's local timezone.
    final DateTime utcTime = dt.isUtc ? dt : dt.toUtc();
    final DateTime indiaTime = utcTime.add(
      const Duration(hours: 5, minutes: 30),
    );

    final dd = indiaTime.day.toString().padLeft(2, '0');
    final mm = indiaTime.month.toString().padLeft(2, '0');
    final yyyy = indiaTime.year.toString();

    final hour24 = indiaTime.hour;
    final minute = indiaTime.minute.toString().padLeft(2, '0');
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
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Iconsax.receipt_item,
                color: accentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'PAID',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.green,
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
