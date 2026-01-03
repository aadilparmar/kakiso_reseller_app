import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_auto_translate/flutter_auto_translate.dart';

class FAQPage extends StatefulWidget {
  const FAQPage({super.key});

  @override
  State<FAQPage> createState() => _FAQPageState();
}

class _FAQPageState extends State<FAQPage> {
  // Category Selection
  String _selectedCategory = "All";
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // ─── DATA SOURCE (From provided CSV) ───
  final List<Map<String, String>> _allFaqs = [
    // --- GENERAL ---
    {
      "category": "General",
      "q": "What is KaKiSo?",
      "a":
          "KaKiSo is India’s first B2B2C marketplace that connects verified suppliers with resellers, letting the reseller browse, save, and order products at reseller prices in one place.",
    },
    {
      "category": "General",
      "q": "What does KaKiSo do?",
      "a":
          "KaKiSo connects trusted suppliers with resellers on one easy platform. Resellers can discover products at wholesale prices and sell without worrying about inventory or shipping, while suppliers can expand their reach and grow their business through a nationwide reseller network.",
    },
    {
      "category": "General",
      "q": "What is Dropshipping?",
      "a":
          "Dropshipping is a simple way to sell products online without keeping any stock. A Reseller lists products in their store, marketplace or social media and when a customer places an order, the reseller purchases the product from a Supplier who ships it directly to the Customer.\n\nExample:\n1. A reseller finds a backpack on KaKiSo listed by a supplier for ₹800.\n2. The reseller lists the same backpack in their online store or social media page for ₹1,200.\n3. When a customer places an order and pays ₹1,200, the reseller places the order on KaKiSo and pays the supplier ₹800.\n4. The supplier then packs and ships the backpack directly to the customer.\n5. The reseller earns a profit of ₹400 — without storing any products or handling delivery.",
    },
    {
      "category": "General",
      "q": "Who can use KaKiSo's service?",
      "a":
          "KaKiSo can be used by Suppliers who want to sell their Products and Resellers who want to sell those products to Customers without holding Inventory. It’s ideal for businesses and individuals who want to expand their reach and grow through Dropshipping.",
    },
    {
      "category": "General",
      "q": "Why KaKiSo?",
      "a":
          "With many marketplaces available, KaKiSo stands out by truly addressing the gaps in the market. Most platforms don’t offer complete support to both Suppliers and Resellers — from Selling Tools and Flexible order Quantities to Profit Protection and Strong Return Policies.\n\nKaKiSo offers:\n1. No minimum order quantity (No MOQ)\n2. Assured profit opportunities\n3. Transparent and reseller-friendly pricing\n4. White labelling support\n5. Hidden Cost Prices to protect your Margins\n6. Reliable return and support policies\n\nKaKiSo is built to help you scale your business with powerful features like easy-to-use platform, no upfront investment, strict supplier verification, and 360° support.",
    },
    {
      "category": "General",
      "q": "Do you support dropshipping in India?",
      "a":
          "Yes, KaKiSo offers complete dropshipping support across India, helping resellers fulfill orders seamlessly nationwide.",
    },

    // --- FEES & PAYMENTS ---
    {
      "category": "Fees",
      "q":
          "Are there any monthly charges, subscription fees, or minimum order requirements?",
      "a":
          "KaKiSo does not charge any monthly subscription. Fees apply only on a per-order basis. There are no minimum order requirements to start reselling with KaKiSo.",
    },
    {
      "category": "Fees",
      "q": "How much is the fee per order?",
      "a":
          "KaKiSo charges a small fee per order:\n• Platform fee: ₹5 per product\n• Convenience fee: ₹12 per order",
    },
    {
      "category": "Fees",
      "q": "Are the prices quoted on the website inclusive of shipping fees?",
      "a":
          "Shipping cost will be additional and will vary based on the supplier and the customer’s pincode.",
    },
    {
      "category": "Fees",
      "q": "Do you charge GST?",
      "a":
          "All product prices on the KaKiSo app are GST-inclusive. KaKiSo ensures quality products at the best possible prices.",
    },
    {
      "category": "Fees",
      "q": "Do you provide any bulk pricing or reseller discounts?",
      "a":
          "KaKiSo is a platform designed specifically for resellers, and the prices listed are already discounted by the supplier to support reseller profitability.",
    },

    // --- RESELLER GUIDE ---
    {
      "category": "Reseller",
      "q": "Who is a Reseller?",
      "a":
          "A Dropshipping Reseller is someone who sells products online without keeping stock. They list Supplier products on their store, and when a customer orders, the Supplier ships it directly to the Customer.",
    },
    {
      "category": "Reseller",
      "q": "What are the benefits of becoming a reseller?",
      "a":
          "Becoming a Reseller is beneficial because it requires Low Investment, No Inventory Storage, and Minimal Risk.",
    },
    {
      "category": "Reseller",
      "q": "What are the benefits of becoming a reseller on our website?",
      "a":
          "Resellers enjoy Special Discounts, Marketing Materials, and Basic Training to help them sell better. They also receive support from a Dedicated Account Manager along with other incentives that make their business easier and more Profitable.",
    },
    {
      "category": "Reseller",
      "q": "How to Register as a Reseller?",
      "a":
          "Step-by-Step Guide:\n1. Open the app or https://kakiso.com/shop/\n2. Click the “Become a Reseller” button.\n3. Fill in your Name, Email ID, and Mobile Number, check the checkbox, then click Login.\n4. Check your email — you’ll receive your password there.\n5. Sign in using your Email ID and the password sent to you.\n6. Complete the required Business Details in your account profile.\n7. Wait for verification — your account will be activated after we review your details.\n\nTip: Check your spam folder if you don't receive the password email.",
    },
    {
      "category": "Reseller",
      "q": "How do I earn with KaKiSo?",
      "a":
          "Earning with KaKiSo is simple and takes just 3 easy steps:\n\nStep 1: Pick\nBrowse and select products from our wide range of high-quality items available on the KaKiSo app.\n\nStep 2: Share\nAdd your preferred margin to the product price and share your chosen products with your network (WhatsApp/Facebook).\n\nStep 3: Earn\nOnce the customer places an order and pays your price, you place the order on KaKiSo and the supplier ships the product with an invoice containing your price and details.",
    },
    {
      "category": "Reseller",
      "q": "Can I sell on other marketplaces like Amazon, Meesho, Flipkart?",
      "a":
          "Yes, you can sell KaKiSo products on other marketplaces such as Amazon, Meesho, Flipkart, and similar platforms.",
    },
    {
      "category": "Reseller",
      "q":
          "Can I sell KaKiSo products on META (WhatsApp, Instagram, Facebook) and my own website?",
      "a":
          "Yes, you can sell KaKiSo products on META platforms such as WhatsApp, Instagram, and Facebook, as well as on your own website.",
    },
    {
      "category": "Reseller",
      "q": "Do I need to buy the products before I sell them?",
      "a":
          "No. Reselling with KaKiSo requires no upfront investment. You place an order only after receiving payment from your customer, buy the product at a discounted reseller price, and earn your margin with minimal risk.",
    },
    {
      "category": "Reseller",
      "q": "How do I get my first order?",
      "a":
          "1. Start with friends and family: Share your catalogue with people you know.\n2. Use social media actively: Post products on WhatsApp Status, Instagram Stories, and Facebook.\n3. Leverage Facebook Marketplace: List popular and trending products.\n4. Choose trending products: Start with best-selling items.\n5. Set attractive pricing: Keep margins reasonable initially.\n6. Share clear product details: Include good images and prices.\n7. Be responsive: Reply quickly to inquiries.\n8. Ask for referrals.",
    },
    {
      "category": "Reseller",
      "q": "Can I set different Margins for different Products?",
      "a":
          "Initially, you can set a uniform margin across all products. However, during checkout, you have the flexibility to adjust the final selling price based on the amount quoted to your customer.",
    },

    // --- PRODUCTS & INVENTORY ---
    {
      "category": "Products",
      "q": "What products do you offer?",
      "a":
          "We offer a wide range of products across multiple categories, including Clothing, Fashion & Accessories, Home Essentials, and Lifestyle products. Our catalog is regularly updated with new and trending items.",
    },
    {
      "category": "Products",
      "q": "How do I get the Product Catalogue?",
      "a":
          "You can create your own customised catalogue directly from the KaKiSo app. Tap the top-right corner of the app and select My Catalogue. Choose products, add them to your catalogue, and share it with your customers.",
    },
    {
      "category": "Products",
      "q": "How do I get product images and details?",
      "a":
          "You can get product images and details directly from the KaKiSo app. Add products to My Catalogue to easily save and share them with your customers.",
    },
    {
      "category": "Products",
      "q": "How can I add my logo to product images?",
      "a":
          "Yes, you can download product images directly from the app and edit them to add your own logo or branding.",
    },
    {
      "category": "Products",
      "q": "How can I get inventory for each SKU?",
      "a":
          "Inventory details for each SKU are available directly on the KaKiSo app. You can check product availability while browsing the catalog to help you manage orders effectively.",
    },
    {
      "category": "Products",
      "q": "What about the quality of the products?",
      "a":
          "KaKiSo works closely with trusted suppliers to ensure that all products meet quality standards before being listed on the platform. We continuously monitor supplier performance to provide reliable, good-quality products.",
    },

    // --- SHIPPING & RETURNS ---
    {
      "category": "Shipping",
      "q":
          "What is your average delivery time for different regions across India?",
      "a":
          "Our average delivery time across most regions in India is 2–4 business days. Delivery timelines may vary slightly depending on the supplier, customer location, and serviceability of the pincode.",
    },
    {
      "category": "Shipping",
      "q": "Do you offer COD (Cash on Delivery)?",
      "a": "As of now, we do not offer Cash on Delivery (COD).",
    },
    {
      "category": "Shipping",
      "q": "What kind of packaging do you provide?",
      "a":
          "All orders are dispatched in white-label packaging to maintain your Brand Identity. No supplier information is shared, and any branding or details included on the package will represent you.",
    },
    {
      "category": "Shipping",
      "q":
          "Can you share your replacement/refund policy for damaged or defective products?",
      "a":
          "To help us assist you efficiently in cases of damaged products, we kindly request resellers to share an unboxing video for verification. Once reviewed, we will promptly proceed with the appropriate replacement or refund.",
    },
    {
      "category": "Shipping",
      "q": "What courier partners do you use, and do you offer tracking?",
      "a":
          "We work with multiple courier partners, and shipments are assigned based on service availability for the customer’s specific pincode.",
    },
    {
      "category": "Shipping",
      "q": "Will KaKiSo share its name, link or price when I share catalogs?",
      "a":
          "No. When you share catalogs with your customers, KaKiSo’s name, website link, and product prices are not shown. This allows you to present the products under your own branding and pricing.",
    },
    {
      "category": "Shipping",
      "q": "Does KaKiSo communicate with my customers?",
      "a":
          "No. KaKiSo has absolutely no direct contact or communication with your customers. All customer interactions are handled entirely by you.",
    },

    // --- ACCOUNT & TECH ---
    {
      "category": "Account",
      "q": "Do I need a GST Registration to become a Reseller?",
      "a":
          "No, a GST registration is not mandatory to become a reseller with KaKiSo. However, basic GST rules apply if your turnover exceeds the government threshold (INR 40L/20L).",
    },
    {
      "category": "Account",
      "q": "Why should I provide my bank details?",
      "a":
          "We request you to update your Bank Details on the app so we can transfer your Margin Payments and Bonuses directly to your Bank Account. Please ensure the details are accurate to avoid any delays.",
    },
    {
      "category": "Account",
      "q": "Do you provide inventory syncing or API integration?",
      "a":
          "Inventory API syncing is not available at the moment, but it is under development and will be introduced soon to improve automation and efficiency.",
    },
    {
      "category": "Account",
      "q": "How do I contact the KaKiSo Support Team?",
      "a":
          "You can contact the KaKiSo Support Team from Monday to Saturday, 10:00 AM to 7:00 PM.\nCall/WhatsApp: +91-9907800700\nEmail: support@kakiso.com",
    },
  ];

  @override
  Widget build(BuildContext context) {
    // 1. FILTER LOGIC
    List<Map<String, String>> filteredList = _allFaqs.where((item) {
      bool categoryMatch =
          _selectedCategory == "All" || item['category'] == _selectedCategory;
      bool searchMatch =
          _searchQuery.isEmpty ||
          item['q']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['a']!.toLowerCase().contains(_searchQuery.toLowerCase());
      return categoryMatch && searchMatch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const AutoTranslate(
          child: Text(
            "Help Center",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: Column(
        children: [
          // ─── 1. SEARCH BAR ───
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(fontFamily: 'Poppins'),
              decoration: InputDecoration(
                hintText: "Search questions...",
                prefixIcon: const Icon(Iconsax.search_normal, size: 20),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
            ),
          ),

          // ─── 2. CATEGORY CHIPS ───
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildChip("All"),
                  _buildChip("General"),
                  _buildChip("Reseller"),
                  _buildChip("Fees"),
                  _buildChip("Shipping"),
                  _buildChip("Products"),
                  _buildChip("Account"),
                ],
              ),
            ),
          ),

          // ─── 3. FAQ LIST ───
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Iconsax.search_status,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        const AutoTranslate(
                          child: Text(
                            "No results found",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return _buildFAQItem(item['q']!, item['a']!);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ─── WIDGET HELPERS ───

  Widget _buildChip(String label) {
    bool isSelected = _selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: AutoTranslate(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? Colors.white : Colors.black87,
              fontSize: 13,
            ),
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = label;
          });
        },
        selectedColor: const Color(0xFF2563EB),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
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
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: const Color(0xFF2563EB),
          collapsedIconColor: Colors.grey,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: AutoTranslate(
            child: Text(
              question,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF212121),
              ),
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide.none),
              ),
              child: AutoTranslate(
                child: Text(
                  answer,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Color(0xFF616161),
                    height: 1.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
