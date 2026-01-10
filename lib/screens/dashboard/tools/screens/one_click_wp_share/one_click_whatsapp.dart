// lib/screens/dashboard/tools/one_click_whatsapp.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:showcaseview/showcaseview.dart';

// INTERNAL IMPORTS
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/controllers/catalouge_controller.dart';

// ─── THEME CONSTANTS ─────────────────────────────────────────────────────────
const Color kWhatsAppTeal = Color(0xFF075E54);
const Color kWhatsAppGreen = Color(0xFF25D366);
const Color kChatBubble = Color(0xFFDCF8C6);
const Color kSurface = Colors.white;
const Color kBgColor = Color(0xFFE5DDD5);
const Color kDarkText = Color(0xFF111827);
const Color kAccentBlue = Color(0xFF2563EB);

enum MarginType { fixed, percentage }

class OneClickWhatsAppPage extends StatelessWidget {
  const OneClickWhatsAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ShowCaseWidget(
      builder: (context) => const _OneClickWhatsAppContent(),
      autoPlay: false,
      blurValue: 1,
      enableAutoScroll: true,
      scrollDuration: const Duration(milliseconds: 400),
    );
  }
}

class _OneClickWhatsAppContent extends StatefulWidget {
  const _OneClickWhatsAppContent();

  @override
  State<_OneClickWhatsAppContent> createState() =>
      _OneClickWhatsAppContentState();
}

class _OneClickWhatsAppContentState extends State<_OneClickWhatsAppContent> {
  // --- STATE ---
  final List<ProductModel> selectedProducts = [];
  final TextEditingController businessNameController = TextEditingController();
  final TextEditingController marginInputController = TextEditingController();
  final FlutterNativeContactPicker _contactPicker =
      FlutterNativeContactPicker();
  final _localStorage = GetStorage();

  final ScrollController _scrollController = ScrollController();

  // SHOWCASE KEYS
  final GlobalKey _productKey = GlobalKey();
  final GlobalKey _pricingKey = GlobalKey();
  final GlobalKey _marketingKey = GlobalKey();
  final GlobalKey _previewKey = GlobalKey();
  final GlobalKey _shareKey = GlobalKey();
  final GlobalKey _infoKey = GlobalKey();

  String _generatedCaption = "";
  bool _isDownloading = false;

  // --- PROFIT & PRICING ENGINE (Updated to Percentage Default) ---
  MarginType _marginType = MarginType.percentage;
  double _marginValue = 15.0; // Default 15% margin
  bool _useMagicPricing = true;
  bool _showDiscount = true;

  // --- CONTENT CONTROLS ---
  bool _includeTitle = true;
  bool _includePrice = true;
  bool _includeSizes = true;
  bool _includeDescription = false;

  // --- MARKETING BOOSTERS ---
  bool _isHinglish = false;
  final bool _addTrustBadge = true;
  bool _showBranding = true;
  final String _validityPeriod = 'None';
  String _selectedTone = 'Urgency';

  @override
  void initState() {
    super.initState();
    marginInputController.text = _marginValue.toStringAsFixed(0);
    _loadBusinessName();
    _updateCaption();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndStartTour());
  }

  void _checkAndStartTour() {
    bool hasShown = _localStorage.read('has_shown_whatsapp_tour_v4') ?? false;
    if (!hasShown) {
      _startTour();
      _localStorage.write('has_shown_whatsapp_tour_v4', true);
    }
  }

  void _startTour() {
    ShowCaseWidget.of(context).startShowCase([
      _productKey,
      _pricingKey,
      _marketingKey,
      _previewKey,
      _shareKey,
    ]);
  }

  Future<void> _loadBusinessName() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('business_name') ?? '';
    if (name.isNotEmpty) {
      setState(() {
        businessNameController.text = name;
        _showBranding = true;
      });
      _updateCaption();
    }
  }

  Future<void> _saveBusinessName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('business_name', name);
  }

  @override
  void dispose() {
    businessNameController.dispose();
    marginInputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  double _calculateSellingPrice(String basePriceStr) {
    double base = double.tryParse(basePriceStr) ?? 0.0;
    double price = base;

    if (_marginType == MarginType.fixed) {
      price = base + _marginValue;
    } else {
      // Percentage calculation: Base + (Base * Margin%)
      price = base + (base * _marginValue / 100);
    }

    if (_useMagicPricing) {
      double remainder = price % 100;
      if (remainder < 50) {
        price = (price - remainder) + 49;
      } else {
        price = (price - remainder) + 99;
      }
    }
    return price;
  }

  double _calculateTotalPotentialProfit() {
    double totalProfit = 0.0;
    for (var p in selectedProducts) {
      double selling = _calculateSellingPrice(p.price);
      double base = double.tryParse(p.price) ?? 0.0;
      totalProfit += (selling - base);
    }
    return totalProfit;
  }

  String _getDiscountString(double sellingPrice) {
    if (!_showDiscount) return "";
    double fakeMRP = sellingPrice * 1.45;
    fakeMRP = (fakeMRP / 50).ceil() * 50;
    int offPercent = ((fakeMRP - sellingPrice) / fakeMRP * 100).round();
    return "MRP ~₹${fakeMRP.toStringAsFixed(0)}~ ($offPercent% OFF)";
  }

  String _getDynamicDate() {
    switch (_validityPeriod) {
      case '24 Hours':
        return "⏳ Offer Ends in 24 Hours!";
      case 'Sunday':
        return "⏳ Valid till this Sunday Midnight.";
      case 'Month End':
        return "⏳ Month End Clearance Sale.";
      default:
        return "";
    }
  }

  void _updateCaption() {
    if (selectedProducts.isEmpty) {
      setState(() => _generatedCaption = "Add products to generate catalog.");
      return;
    }
    final buffer = StringBuffer();
    final businessName = businessNameController.text.trim();
    final hasName = businessName.isNotEmpty && _showBranding;

    if (_isHinglish) {
      if (hasName) buffer.writeln("👋 *Welcome to $businessName*");
      if (_selectedTone == 'Urgency')
        buffer.writeln("🔥 *Jaldi Karo! Offer Khatam hone wala hai* 🔥");
      else if (_selectedTone == 'Luxury')
        buffer.writeln("✨ *Premium Collection - Sirf Aapke Liye* ✨");
      else
        buffer.writeln("😍 *Dekhiye hamari nayi collection*");
    } else {
      if (hasName) buffer.writeln("👋 *New at $businessName*");
      if (_selectedTone == 'Urgency')
        buffer.writeln("🚨 *FLASH SALE! Limited Time Offer* 🚨");
      else if (_selectedTone == 'Luxury')
        buffer.writeln("✨ *Exclusive Premium Designs* ✨");
      else
        buffer.writeln("😍 *Check out these new arrivals!*");
    }

    if (_validityPeriod != 'None') buffer.writeln(_getDynamicDate());
    buffer.writeln("");

    for (int i = 0; i < selectedProducts.length; i++) {
      final p = selectedProducts[i];
      final sellingPrice = _calculateSellingPrice(p.price);
      buffer.writeln("━━━━━━━━━━━━━━━━");
      buffer.writeln("✅ *Design ${i + 1}*");
      if (_includeTitle) buffer.writeln("📦 ${p.name}");
      if (_includePrice) {
        if (_showDiscount) {
          buffer.writeln("🏷️ ${_getDiscountString(sellingPrice)}");
          buffer.writeln(
            "👉 *Offer Price: ₹${sellingPrice.toStringAsFixed(0)}* 🔥",
          );
        } else {
          buffer.writeln("💰 *Price: ₹${sellingPrice.toStringAsFixed(0)}*");
        }
      }
      if (_includeSizes && p.attributes.isNotEmpty) {
        final sizes = p.attributes.firstWhere(
          (a) => a.name.toLowerCase().contains('size'),
          orElse: () => ProductAttribute(id: 0, name: '', options: []),
        );
        if (sizes.options.isNotEmpty)
          buffer.writeln("📏 Sizes: ${sizes.options.join(', ')}");
      }
      if (_includeDescription && p.description.isNotEmpty) {
        String cleanDesc = p.description.replaceAll(RegExp(r'<[^>]*>'), '');
        if (cleanDesc.length > 100)
          cleanDesc = "${cleanDesc.substring(0, 100)}...";
        buffer.writeln("📝 Details: $cleanDesc");
      }
    }
    buffer.writeln("━━━━━━━━━━━━━━━━");
    if (_addTrustBadge)
      buffer.writeln(
        _isHinglish
            ? "\n⭐ *Best Quality* | ⭐ *Easy Returns*"
            : "\n⭐ *Quality Verified* | ⭐ *Easy Returns*",
      );
    buffer.writeln(
      _isHinglish ? "🚚 *Free Home Delivery*" : "🚚 *Free Shipping*",
    );
    buffer.writeln("");
    buffer.writeln(
      _isHinglish
          ? "👇 *Order karne ke liye photo reply karein!*"
          : "👇 *Reply with photo to place order!*",
    );
    buffer.writeln(
      "\n#Fashion #Sale #Trending #${_isHinglish ? 'DilSeDesi' : 'Style'}",
    );

    setState(() => _generatedCaption = buffer.toString());
  }

  Future<void> _shareCampaign() async {
    if (selectedProducts.isEmpty) {
      _showSnack("Please select products first", isError: true);
      return;
    }
    setState(() => _isDownloading = true);
    try {
      List<XFile> filesToShare = [];
      for (var product in selectedProducts) {
        if (product.image.isNotEmpty) {
          final file = await ApiService().downloadImageAsFile(product.image);
          filesToShare.add(file);
        }
      }
      await Clipboard.setData(ClipboardData(text: _generatedCaption));
      if (filesToShare.isEmpty)
        await Share.share(_generatedCaption);
      else
        await Share.shareXFiles(
          filesToShare,
          text: _generatedCaption,
          subject: 'New Collection',
        );
    } catch (e) {
      _showSnack("Error: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _sendDirectMessage() async {
    if (selectedProducts.isEmpty) {
      _showSnack("Select products first", isError: true);
      return;
    }
    final contact = await _contactPicker.selectPhoneNumber();
    if (contact?.selectedPhoneNumber == null) return;
    String phone = contact!.selectedPhoneNumber!.replaceAll(
      RegExp(r'[^\d]'),
      '',
    );
    final message = Uri.encodeComponent(_generatedCaption);
    final url = Uri.parse("whatsapp://send?phone=$phone&text=$message");
    if (await canLaunchUrl(url))
      await launchUrl(url);
    else
      _showSnack("Could not launch WhatsApp");
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: isError ? Colors.red : kDarkText,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openMultiProductPicker() async {
    final List<ProductModel>? picked = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _MultiProductPickerSheet(),
    );
    if (picked != null && picked.isNotEmpty) {
      setState(() {
        for (var p in picked) {
          if (!selectedProducts.any((existing) => existing.id == p.id)) {
            if (selectedProducts.length < 10) selectedProducts.add(p);
          }
        }
      });
      _updateCaption();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: const Text(
          'Marketing Studio',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: kDarkText,
          ),
        ),
        backgroundColor: kSurface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: kDarkText,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            key: _infoKey,
            icon: const Icon(Iconsax.info_circle, color: kAccentBlue),
            onPressed: _startTour,
          ),
          if (selectedProducts.isNotEmpty)
            IconButton(
              onPressed: () => setState(() {
                selectedProducts.clear();
                _updateCaption();
              }),
              icon: const Icon(Iconsax.trash, color: Colors.red),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildSectionTitle("1. Select Products"),
                  Showcase(
                    key: _productKey,
                    title: "Select Products",
                    description: "Choose products from your catalogues.",
                    child: _buildProductShowcase(),
                  ),
                  _buildSectionTitle("2. Profit & Pricing"),
                  Showcase(
                    key: _pricingKey,
                    title: "Smart Margin",
                    description:
                        "Set your percentage margin for all selected products.",
                    child: _buildPricingEngine(),
                  ),
                  _buildSectionTitle("3. Content & Marketing"),
                  Showcase(
                    key: _marketingKey,
                    title: "Customize Content",
                    description: "Add business name and choose tone.",
                    child: _buildMarketingTools(),
                  ),
                  _buildSectionTitle("4. Live Preview"),
                  Showcase(
                    key: _previewKey,
                    title: "Live Preview",
                    description: "See the final WhatsApp message.",
                    child: _buildRealWhatsAppPreview(),
                  ),
                  const SizedBox(height: 200),
                ],
              ),
            ),
          ),
          Showcase(
            key: _shareKey,
            title: "Broadcast",
            description: "Share to WhatsApp instantly!",
            child: _buildBottomDock(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.grey.shade600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildProductShowcase() {
    if (selectedProducts.isEmpty) {
      return GestureDetector(
        onTap: _openMultiProductPicker,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 140,
          decoration: BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kWhatsAppTeal.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.add, color: kWhatsAppTeal, size: 30),
              ),
              const SizedBox(height: 10),
              const Text(
                "Tap to Add Catalogue Products",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: kWhatsAppTeal,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 180,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: selectedProducts.length + 1,
        itemBuilder: (context, index) {
          if (index == selectedProducts.length) {
            return GestureDetector(
              onTap: _openMultiProductPicker,
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.add_circle, color: Colors.grey, size: 28),
                    SizedBox(height: 8),
                    Text(
                      "Add",
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }
          final p = selectedProducts[index];
          final sellingPrice = _calculateSellingPrice(p.price);
          return Stack(
            children: [
              Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          p.image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "₹${sellingPrice.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: kDarkText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 4,
                right: 16,
                child: GestureDetector(
                  onTap: () => setState(() {
                    selectedProducts.removeAt(index);
                    _updateCaption();
                  }),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.close, size: 16, color: Colors.red),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPricingEngine() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Total Profit",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    "+ ₹${_calculateTotalPotentialProfit().toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: kWhatsAppTeal,
                    ),
                  ),
                ],
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: marginInputController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                    labelText: "Margin %",
                    suffixText: '%',
                  ),
                  onChanged: (val) {
                    setState(() {
                      _marginValue = double.tryParse(val) ?? 0;
                      _updateCaption();
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: _marginValue.clamp(0.0, 100.0),
            min: 0,
            max: 100,
            divisions: 20,
            label: "${_marginValue.round()}%",
            activeColor: kWhatsAppTeal,
            onChanged: (val) {
              setState(() {
                _marginValue = val;
                marginInputController.text = val.toStringAsFixed(0);
                _updateCaption();
              });
            },
          ),
          const Divider(height: 20),
          _buildSwitchTile(
            title: "Magic '99' Pricing",
            subtitle: "Auto-rounds price to end in 99",
            value: _useMagicPricing,
            onChanged: (v) => setState(() {
              _useMagicPricing = v;
              _updateCaption();
            }),
            icon: Iconsax.magic_star,
            iconColor: Colors.purple,
          ),
          _buildSwitchTile(
            title: "Show Fake Discount",
            subtitle: "Adds 'MRP ₹999 (50% OFF)'",
            value: _showDiscount,
            onChanged: (v) => setState(() {
              _showDiscount = v;
              _updateCaption();
            }),
            icon: Iconsax.discount_shape,
            iconColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildMarketingTools() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Content to Share:",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip(
                "Title",
                _includeTitle,
                (v) => setState(() {
                  _includeTitle = v;
                  _updateCaption();
                }),
              ),
              _buildFilterChip(
                "Price",
                _includePrice,
                (v) => setState(() {
                  _includePrice = v;
                  _updateCaption();
                }),
              ),
              _buildFilterChip(
                "Sizes",
                _includeSizes,
                (v) => setState(() {
                  _includeSizes = v;
                  _updateCaption();
                }),
              ),
              _buildFilterChip(
                "Full Desc",
                _includeDescription,
                (v) => setState(() {
                  _includeDescription = v;
                  _updateCaption();
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: businessNameController,
            decoration: InputDecoration(
              hintText: "Your Business Name",
              prefixIcon: const Icon(Iconsax.shop, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (v) {
              _saveBusinessName(v);
              _updateCaption();
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildVibeBtn("Urgency 🚨", "Urgency", Colors.red),
              const SizedBox(width: 8),
              _buildVibeBtn("Luxury ✨", "Luxury", Colors.purple),
              const SizedBox(width: 8),
              _buildVibeBtn("Friendly 😊", "Friendly", Colors.orange),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              "Hinglish Mode 🇮🇳",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: const Text(
              "Use mix of Hindi-English",
              style: TextStyle(fontSize: 11),
            ),
            activeColor: Colors.orange,
            value: _isHinglish,
            onChanged: (v) => setState(() {
              _isHinglish = v;
              _updateCaption();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    bool selected,
    Function(bool) onSelected,
  ) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: Colors.grey.shade100,
      selectedColor: kWhatsAppTeal.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        fontSize: 12,
        color: selected ? kWhatsAppTeal : Colors.black87,
      ),
      checkmarkColor: kWhatsAppTeal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: selected ? kWhatsAppTeal : Colors.transparent),
      ),
    );
  }

  Widget _buildVibeBtn(String label, String val, Color color) {
    bool isSelected = _selectedTone == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _selectedTone = val;
          _updateCaption();
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? color : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRealWhatsAppPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE5DDD5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kChatBubble,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectedProducts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        selectedProducts.first.image,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                  ),
                SelectableText(
                  _generatedCaption,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('hh:mm a').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.done_all, size: 14, color: Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: kWhatsAppTeal,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomDock() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: kSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            InkWell(
              onTap: _sendDirectMessage,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: kBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(Iconsax.direct_send, color: kDarkText),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isDownloading ? null : _shareCampaign,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kWhatsAppGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isDownloading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              "Preparing...",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.share, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Share the Campaign",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
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

// ─── UPDATED PRODUCT PICKER SHEET ──────────────────────────────────────────
class _MultiProductPickerSheet extends StatefulWidget {
  const _MultiProductPickerSheet();
  @override
  State<_MultiProductPickerSheet> createState() =>
      _MultiProductPickerSheetState();
}

class _MultiProductPickerSheetState extends State<_MultiProductPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final CatalogueController catalogueController =
      Get.find<CatalogueController>();

  List<ProductModel> _allCatalogueProducts = [];
  List<ProductModel> _filteredProducts = [];
  final Set<ProductModel> _selected = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFromCatalogues();
  }

  void _loadFromCatalogues() {
    setState(() => _isLoading = true);
    final products = catalogueController.myCatalogues
        .expand((cat) => cat.products)
        .toSet()
        .toList();

    setState(() {
      _allCatalogueProducts = products;
      _filteredProducts = products;
      _isLoading = false;
    });
  }

  void _runSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = _allCatalogueProducts;
      } else {
        _filteredProducts = _allCatalogueProducts
            .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleSelection(ProductModel p) {
    setState(() {
      if (_selected.contains(p)) {
        _selected.remove(p);
      } else {
        if (_selected.length >= 10) return;
        _selected.add(p);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          const SizedBox(height: 10),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: kWhatsAppTeal),
                  )
                : _filteredProducts.isEmpty
                ? _buildEmptyCatalogueState()
                : _buildProductGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Catalogue Products",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              Text(
                "${_selected.length} selected (max 10)",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          if (_selected.isNotEmpty)
            ElevatedButton(
              onPressed: () => Navigator.pop(context, _selected.toList()),
              style: ElevatedButton.styleFrom(
                backgroundColor: kWhatsAppTeal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "Add to Studio",
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search in your catalogues...',
          prefixIcon: const Icon(Iconsax.search_normal),
          filled: true,
          fillColor: kBgColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: _runSearch,
      ),
    );
  }

  Widget _buildProductGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (ctx, i) {
        final p = _filteredProducts[i];
        final isSelected = _selected.contains(p);
        return GestureDetector(
          onTap: () => _toggleSelection(p),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? kWhatsAppTeal : Colors.grey.shade200,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(9),
                    ),
                    child: Image.network(p.image, fit: BoxFit.cover),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    "₹${p.price}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyCatalogueState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Iconsax.box, size: 40, color: Colors.grey),
          SizedBox(height: 10),
          Text("No products found in your catalogues."),
          Text(
            "Add products to a catalogue first.",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
