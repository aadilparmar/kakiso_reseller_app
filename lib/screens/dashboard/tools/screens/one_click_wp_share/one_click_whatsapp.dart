// lib/screens/dashboard/tools/one_click_whatsapp.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

// INTERNAL IMPORTS
// Ensure these match your actual project structure
import 'package:kakiso_reseller_app/models/product.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';

const Color kAccent = Color(0xFF0BA39A);
const Color kBgColor = Color(0xFFF9FAFB);

class OneClickWhatsAppPage extends StatefulWidget {
  const OneClickWhatsAppPage({super.key});

  @override
  State<OneClickWhatsAppPage> createState() => _OneClickWhatsAppPageState();
}

class _OneClickWhatsAppPageState extends State<OneClickWhatsAppPage>
    with WidgetsBindingObserver {
  // --- CONTROLLERS ---
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  // --- STATE ---
  ProductModel? selectedProduct;
  final List<String> recipients = [];
  bool isSending = false;
  int sendingIndex = 0; // To track progress

  final FlutterNativeContactPicker nativePicker = FlutterNativeContactPicker();

  // This completer helps us wait until the user returns to the app
  Completer<void>? _resumeCompleter;

  // --- TEMPLATES ---
  static const List<String> _defaultTemplates = [
    'Hi! I found this amazing product 👇\n\n{product_block}\n\nLet me know if you want to order! 😊',
    'Hey! Check this out:\n\n{product_block}\n\nAvailable in all sizes. Reply to book yours.',
    '🔥 Limited Time Deal 🔥\n\n{product_block}\n\nGrab it before it goes out of stock!',
  ];
  final List<String> _userTemplates = [];
  List<String> get _allTemplates =>
      List.unmodifiable([..._defaultTemplates, ..._userTemplates]);
  static const String _prefsKey = 'wa_user_templates';

  // --- COUNTRY CODES ---
  final List<Map<String, String>> countryCodes = [
    {'label': 'IN', 'code': '+91'},
    {'label': 'US', 'code': '+1'},
    {'label': 'UK', 'code': '+44'},
    {'label': 'CA', 'code': '+1'},
    {'label': 'AU', 'code': '+61'},
  ];
  String selectedCountry = '+91';

  @override
  void initState() {
    super.initState();
    // Register this class to listen to app lifecycle changes (Background/Foreground)
    WidgetsBinding.instance.addObserver(this);
    _loadTemplates();
  }

  @override
  void dispose() {
    // Remove observer to prevent memory leaks
    WidgetsBinding.instance.removeObserver(this);
    phoneController.dispose();
    messageController.dispose();
    super.dispose();
  }

  // --- LIFECYCLE LISTENER ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the app resumes (user comes back from WhatsApp), complete the future
    if (state == AppLifecycleState.resumed) {
      if (_resumeCompleter != null && !_resumeCompleter!.isCompleted) {
        _resumeCompleter!.complete();
      }
    }
  }

  // --- LOGIC: TEMPLATES ---
  Future<void> _loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList(_prefsKey);
    if (stored != null) {
      setState(() {
        _userTemplates.clear();
        _userTemplates.addAll(stored);
      });
    }
  }

  Future<void> _saveTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _userTemplates);
  }

  Future<void> _saveMessageAsTemplate() async {
    final t = messageController.text.trim();
    if (t.isEmpty) {
      _showSnack('Cannot save empty message');
      return;
    }
    setState(() => _userTemplates.insert(0, t));
    await _saveTemplates();
    _showSnack('Template saved!');
  }

  void _applyTemplate(int index) {
    if (index < 0 || index >= _allTemplates.length || selectedProduct == null) {
      _showSnack('Select a product first to apply template');
      return;
    }
    final p = selectedProduct!;
    final productBlock = _buildProductBlock(p);
    String template = _allTemplates[index];
    template = template.replaceAll('{product_block}', productBlock);

    setState(() {
      messageController.text = template;
      messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: messageController.text.length),
      );
    });
  }

  // --- LOGIC: PRODUCT BLOCK ---
  String _buildProductBlock(ProductModel p) {
    final buffer = StringBuffer();
    buffer.writeln('🛍️ *${p.name}*');
    buffer.writeln('💰 Price: *₹${p.price}*');

    if (p.discountPercentage != null && p.discountPercentage! > 0) {
      buffer.writeln(
        '✨ MRP: ~₹${p.regularPrice}~ (${p.discountPercentage}% OFF)',
      );
    }
    if (p.brandName != null && p.brandName!.trim().isNotEmpty) {
      buffer.writeln('🏷 Brand: ${p.brandName}');
    }
    if (p.attributes.isNotEmpty) {
      final summary = p.attributes
          .take(2)
          .map(
            (a) => a.options.isNotEmpty ? '${a.name}: ${a.options.first}' : '',
          )
          .where((s) => s.isNotEmpty)
          .join(' | ');
      if (summary.isNotEmpty) buffer.writeln('📌 $summary');
    }
    return buffer.toString().trim();
  }

  // --- LOGIC: RECIPIENTS ---
  String _sanitizeNumber(String raw) {
    String clean = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (clean.isEmpty) return '';
    if (!clean.startsWith('+')) {
      clean = '$selectedCountry$clean';
    }
    return clean;
  }

  void _addQuickPhone() {
    final raw = phoneController.text.trim();
    if (raw.isEmpty) return;
    final sanitized = _sanitizeNumber(raw);
    if (sanitized.length < 10) {
      _showSnack('Invalid phone number');
      return;
    }
    if (!recipients.contains(sanitized)) {
      setState(() {
        recipients.add(sanitized);
        phoneController.clear();
      });
    } else {
      _showSnack('Number already added');
      phoneController.clear();
    }
  }

  Future<void> _pickContactAndAdd() async {
    try {
      final contact = await nativePicker.selectPhoneNumber();
      if (contact != null) {
        final raw = contact.selectedPhoneNumber ?? contact.phoneNumbers?.first;
        if (raw != null) {
          final sanitized = _sanitizeNumber(raw);
          setState(() {
            if (!recipients.contains(sanitized)) recipients.add(sanitized);
          });
        }
      }
    } catch (e) {
      debugPrint("Contact picker error: $e");
    }
  }

  // --- LOGIC: SENDING (FIXED) ---
  Future<bool> _launchSingleWhatsApp(String number, String msg) async {
    // Remove all non-digits for the URL, but keep the + if needed or strip it depending on requirement.
    // Usually WA api works best with straight digits including country code, no + or spaces
    final cleanNum = number.replaceAll(RegExp(r'[^\d]'), '');
    final encodedMsg = Uri.encodeComponent(msg);

    final appUrl = Uri.parse(
      'whatsapp://send?phone=$cleanNum&text=$encodedMsg',
    );
    final webUrl = Uri.parse('https://wa.me/$cleanNum?text=$encodedMsg');

    try {
      // 1. Try launching the App Intent
      if (await canLaunchUrl(appUrl)) {
        return await launchUrl(appUrl, mode: LaunchMode.externalApplication);
      }
      // 2. Fallback to Web/Universal link
      else {
        return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Launch Error: $e");
      return false;
    }
  }

  Future<void> _sendToAll() async {
    if (selectedProduct == null) {
      _showSnack('Please select a product first');
      return;
    }
    if (recipients.isEmpty) {
      _showSnack('Add at least one recipient');
      return;
    }
    final msg = messageController.text.trim();
    if (msg.isEmpty) {
      _showSnack('Message cannot be empty');
      return;
    }

    setState(() {
      isSending = true;
      sendingIndex = 0;
    });

    _showSnack(
      'Starting bulk send. Please press BACK after sending each message.',
    );

    int successCount = 0;

    for (int i = 0; i < recipients.length; i++) {
      setState(() => sendingIndex = i + 1); // Update UI

      final number = recipients[i];

      // Initialize the completer
      _resumeCompleter = Completer<void>();

      // Launch WhatsApp
      bool launched = await _launchSingleWhatsApp(number, msg);

      if (launched) {
        successCount++;

        // If there are more recipients left, we MUST wait for the user to return
        if (i < recipients.length - 1) {
          // Wait here until 'didChangeAppLifecycleState' fires 'resumed'
          await _resumeCompleter!.future;

          // Small buffer delay to ensure UI is ready before firing next intent
          await Future.delayed(const Duration(milliseconds: 700));
        }
      } else {
        _showSnack('Could not open WhatsApp for $number');
      }
    }

    setState(() {
      isSending = false;
      sendingIndex = 0;
    });
    _showSnack('Completed! Sent to $successCount recipients.');
  }

  Future<void> _shareImageWithCaption() async {
    if (selectedProduct == null) {
      _showSnack('Select a product first');
      return;
    }

    final caption = messageController.text.isNotEmpty
        ? messageController.text
        : _buildProductBlock(selectedProduct!);

    try {
      if (selectedProduct!.image.isNotEmpty) {
        final XFile file = await ApiService.downloadImageAsFile(
          selectedProduct!.image,
        );
        await Share.shareXFiles([file], text: caption);
      } else {
        await Share.share(caption);
      }
    } catch (e) {
      _showSnack('Could not share: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- PRODUCT PICKER ---
  Future<void> _openProductPicker() async {
    final ProductModel? picked = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ProductPickerSheet(),
    );

    if (picked != null) {
      setState(() {
        selectedProduct = picked;
      });
      if (messageController.text.trim().isEmpty) {
        final block = _buildProductBlock(picked);
        messageController.text =
            "Hey! Check out this product:\n\n$block\n\nReply if interested!";
      }
    }
  }

  // ===========================================================================
  // UI BUILD
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        title: const Text(
          'One Click WhatsApp Share',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- STEP 1: PRODUCT ---
                  _SectionHeader(number: '1', title: 'Select Product'),
                  const SizedBox(height: 12),
                  _buildProductSelector(),

                  const SizedBox(height: 24),

                  // --- STEP 2: RECIPIENTS ---
                  _SectionHeader(number: '2', title: 'Add Recipients'),
                  const SizedBox(height: 12),
                  _buildRecipientInput(),
                  if (recipients.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildRecipientChips(),
                  ],

                  const SizedBox(height: 24),

                  // --- STEP 3: MESSAGE ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _SectionHeader(
                        number: '3',
                        title: 'Compose Message',
                      ),
                      if (_allTemplates.isNotEmpty)
                        TextButton(
                          onPressed: _saveMessageAsTemplate,
                          child: const Text(
                            'Save as Template',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            itemCount: _allTemplates.length,
                            itemBuilder: (ctx, i) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ActionChip(
                                  label: Text(
                                    'Template ${i + 1}',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                    ),
                                  ),
                                  backgroundColor: Colors.grey.shade100,
                                  onPressed: () => _applyTemplate(i),
                                ),
                              );
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        TextField(
                          controller: messageController,
                          maxLines: 6,
                          minLines: 3,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Type your message here...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- PREVIEW ---
                  const Text(
                    'PREVIEW',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildWhatsAppPreview(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // --- BOTTOM BAR ---
          _buildBottomBar(),
        ],
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildProductSelector() {
    final bool hasProduct = selectedProduct != null;

    return InkWell(
      onTap: _openProductPicker,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasProduct ? kAccent : Colors.grey.shade200,
            width: hasProduct ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                image: (hasProduct && selectedProduct!.image.isNotEmpty)
                    ? DecorationImage(
                        image: NetworkImage(selectedProduct!.image),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !hasProduct
                  ? Icon(Iconsax.bag_2, color: Colors.grey.shade400)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasProduct ? selectedProduct!.name : 'No Product Selected',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: hasProduct ? Colors.black87 : Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasProduct
                        ? '₹${selectedProduct!.price}'
                        : 'Tap to select a product from catalog',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: hasProduct ? kAccent : Colors.grey.shade400,
                      fontWeight: hasProduct
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCountry,
              style: const TextStyle(
                fontFamily: 'Poppins',
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
              items: countryCodes
                  .map(
                    (c) => DropdownMenuItem(
                      value: c['code'],
                      child: Text(c['code']!),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedCountry = v!),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          Expanded(
            child: TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 15),
              decoration: const InputDecoration(
                hintText: 'Phone number',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _addQuickPhone(),
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.add_circle, color: kAccent),
            onPressed: _addQuickPhone,
            tooltip: 'Add',
          ),
          IconButton(
            icon: const Icon(Iconsax.profile_add, color: Colors.black54),
            onPressed: _pickContactAndAdd,
            tooltip: 'Import Contact',
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: recipients.map((phone) {
        return Chip(
          label: Text(
            phone,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
          ),
          backgroundColor: kAccent.withValues(alpha: 0.1),
          deleteIcon: const Icon(Icons.close, size: 14),
          onDeleted: () => setState(() => recipients.remove(phone)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          side: BorderSide.none,
        );
      }).toList(),
    );
  }

  Widget _buildWhatsAppPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDCF8C6),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.zero,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedProduct != null && selectedProduct!.image.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  selectedProduct!.image,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          Text(
            messageController.text.isEmpty
                ? 'Your message will appear here...'
                : messageController.text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.bottomRight,
            child: Text(
              '10:30 AM',
              style: TextStyle(fontSize: 10, color: Colors.black45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                onPressed: _shareImageWithCaption,
                icon: const Icon(Iconsax.gallery, size: 20),
                label: const Text('Share Img'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: isSending ? null : _sendToAll,
                icon: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Iconsax.send_2, color: Colors.white),
                label: Text(
                  isSending
                      ? 'Sending $sendingIndex/${recipients.length}...'
                      : 'Send Message',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

class _SectionHeader extends StatelessWidget {
  final String number;
  final String title;

  const _SectionHeader({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _ProductPickerSheet extends StatefulWidget {
  const _ProductPickerSheet();

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch({String query = ''}) async {
    setState(() => _isLoading = true);
    try {
      final items = query.isEmpty
          ? await ApiService.fetchProducts(page: 1, perPage: 20)
          : await ApiService.searchProducts(query);

      if (mounted)
        setState(() {
          _products = items;
          _isLoading = false;
        });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search product...',
                prefixIcon: const Icon(Iconsax.search_normal),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) => _fetch(query: v),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kAccent))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _products.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final p = _products[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 50,
                            height: 50,
                            color: Colors.grey.shade100,
                            child: p.image.isNotEmpty
                                ? Image.network(
                                    p.image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.image),
                                  )
                                : const Icon(Icons.image),
                          ),
                        ),
                        title: Text(
                          p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '₹${p.price}',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: kAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Radio<String>(
                          value: p.id.toString(),
                          groupValue: null,
                          onChanged: (_) => Navigator.pop(context, p),
                          activeColor: kAccent,
                        ),
                        onTap: () => Navigator.pop(context, p),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
