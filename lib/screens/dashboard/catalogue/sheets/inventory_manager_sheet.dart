import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';

class InventoryManagerSheet extends StatelessWidget {
  final CatalogueModel catalogue;

  const InventoryManagerSheet({Key? key, required this.catalogue})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // -------------------------------------------------------------------------
    // 1. DATA PREPARATION
    // -------------------------------------------------------------------------
    final int totalItems = catalogue.products.length;

    // Logic: Managed stock > 0 OR Status is 'instock'
    final int inStockItems = catalogue.products.where((p) {
      if (p.manageStock) {
        return p.stockQuantity > 0 && p.stockStatus == 'instock';
      }
      return p.stockStatus == 'instock';
    }).length;

    final int lowStockItems = catalogue.products.where((p) {
      if (p.manageStock) {
        return p.stockQuantity > 0 &&
            p.stockQuantity < 5 &&
            p.stockStatus == 'instock';
      }
      return false;
    }).length;

    final int outOfStockItems = totalItems - inStockItems;

    // -------------------------------------------------------------------------
    // 2. UI STRUCTURE
    // -------------------------------------------------------------------------
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFA), // Crisp clean background
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildDragHandle(),

          _buildHeader(catalogue.name, totalItems),

          _buildStockHealthBar(
            totalItems,
            inStockItems,
            lowStockItems,
            outOfStockItems,
          ),

          Expanded(
            child: catalogue.products.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      10,
                      20,
                      // Safe Area Bottom Padding + Extra space
                      MediaQuery.of(context).viewPadding.bottom + 20,
                    ),
                    itemCount: catalogue.products.length,
                    itemBuilder: (context, index) {
                      return _buildProStockCard(catalogue.products[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HEADER & CONTROLS
  // ---------------------------------------------------------------------------

  Widget _buildDragHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AutoTranslate(
                child: Text(
                  "Inventory",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w600, // Max weight used
                    color: Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "$total Items in $title",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          // We can add a filter icon here in future if needed
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VISUALIZATIONS
  // ---------------------------------------------------------------------------

  Widget _buildStockHealthBar(int total, int good, int low, int out) {
    if (total == 0) return const SizedBox.shrink();

    // Calculate percentages for flex
    // Note: 'good' here implies total inStock, so we subtract low to get "Healthy"
    int healthy = good - low;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AutoTranslate(
            child: Text(
              "Stock Health",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Segmented Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Row(
                children: [
                  if (healthy > 0)
                    Expanded(
                      flex: healthy,
                      child: Container(color: const Color(0xFF10B981)),
                    ),
                  if (low > 0)
                    Expanded(
                      flex: low,
                      child: Container(color: const Color(0xFFF59E0B)),
                    ),
                  if (out > 0)
                    Expanded(
                      flex: out,
                      child: Container(color: const Color(0xFFEF4444)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Row(
            children: [
              _buildLegendDot(const Color(0xFF10B981), "Good"),
              const SizedBox(width: 12),
              _buildLegendDot(const Color(0xFFF59E0B), "Low (<5)"),
              const SizedBox(width: 12),
              _buildLegendDot(const Color(0xFFEF4444), "Empty"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        AutoTranslate(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontFamily: 'Poppins',
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PRODUCT LIST ITEM
  // ---------------------------------------------------------------------------

  Widget _buildProStockCard(ProductModel product) {
    // Determine Logic
    bool isInStock = false;
    String statusLabel = "In Stock";
    Color statusColor = const Color(0xFF10B981); // Green

    if (product.manageStock) {
      isInStock = product.stockQuantity > 0 && product.stockStatus == 'instock';
      if (isInStock && product.stockQuantity < 5) {
        statusLabel = "Low Stock";
        statusColor = const Color(0xFFF59E0B); // Orange
      } else if (!isInStock) {
        statusLabel = "Out of Stock";
        statusColor = const Color(0xFFEF4444); // Red
      }
    } else {
      // Not managed
      isInStock = product.stockStatus == 'instock';
      if (!isInStock) {
        statusLabel = "Out of Stock";
        statusColor = const Color(0xFFEF4444);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // 1. Color Coded Left Strip
              Container(width: 4, color: statusColor),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // 2. Product Image
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF3F4F6)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: product.image.isNotEmpty
                              ? Image.network(product.image, fit: BoxFit.cover)
                              : const Icon(
                                  Iconsax.image,
                                  size: 20,
                                  color: Color(0xFFD1D5DB),
                                ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // 3. Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.userSku != null &&
                                      product.userSku!.isNotEmpty
                                  ? product.userSku!
                                  : "No SKU",
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 11,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 4. Quantity & Status
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (product.manageStock && isInStock)
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: "${product.stockQuantity} ",
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600, // Prominent
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const TextSpan(
                                    text: "Qty",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            // If stock is not managed (unlimited) or empty
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Icon(
                                isInStock ? Iconsax.box : Iconsax.slash,
                                size: 18,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),

                          const SizedBox(height: 4),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: AutoTranslate(
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.box_remove,
              size: 32,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 16),
          const AutoTranslate(
            child: Text(
              "No products found",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
