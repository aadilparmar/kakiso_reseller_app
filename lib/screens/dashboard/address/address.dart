// lib/screens/dashboard/address/address.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/check_out_header/check_out_header.dart';
import 'package:kakiso_reseller_app/screens/dashboard/checkout/checkout.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

// 🔹 STEP HEADER

class CustomerAddressPage extends StatefulWidget {
  /// Optional – pass from BusinessDetailsPage if you have it:
  /// Get.to(() => CustomerAddressPage(userData: widget.userData));
  final UserData? userData;

  const CustomerAddressPage({super.key, this.userData});

  @override
  State<CustomerAddressPage> createState() => _CustomerAddressPageState();
}

class _CustomerAddressPageState extends State<CustomerAddressPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _customerNameCtrl = TextEditingController();
  final TextEditingController _customerPhoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _pincodeCtrl = TextEditingController();

  bool _isSaving = false;

  // ---- STORAGE SETUP ----
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _storageKey = 'customer_addresses';

  // business details storage key (same as in BusinessDetailsPage)
  static const String _businessStorageKey = 'business_details';

  // ---- IN-MEMORY LIST OF SAVED ADDRESSES ----
  List<CustomerAddress> _savedAddresses = [];
  int? _selectedIndex; // which saved address is chosen

  // ---- BUSINESS ADDRESS (for FinalCheckoutPage) ----
  String? _businessAddressLabel;
  String? _businessAddressText;

  UserData? get _userData => widget.userData;

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
    _loadBusinessDetails(); // 🔹 load business address for final checkout
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  // ----------------- MODEL -----------------
  CustomerAddress _buildAddressFromForm() {
    return CustomerAddress(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _customerNameCtrl.text.trim(),
      phone: _customerPhoneCtrl.text.trim(),
      addressLine: _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      pincode: _pincodeCtrl.text.trim(),
    );
  }

  // ----------------- STORAGE : CUSTOMER ADDRESSES -----------------
  Future<void> _loadSavedAddresses() async {
    try {
      final String? jsonStr = await _storage.read(key: _storageKey);
      if (jsonStr == null) return;

      final List<dynamic> list = jsonDecode(jsonStr);
      final addresses = list
          .map((e) => CustomerAddress.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _savedAddresses = addresses;
        if (_savedAddresses.isNotEmpty) {
          _selectedIndex = 0;
        }
      });
    } catch (e) {
      debugPrint('Failed to load customer addresses: $e');
    }
  }

  Future<void> _saveAddressesToStorage() async {
    final jsonList = _savedAddresses.map((e) => e.toJson()).toList();
    await _storage.write(key: _storageKey, value: jsonEncode(jsonList));
  }

  // ----------------- STORAGE : BUSINESS DETAILS -----------------
  Future<void> _loadBusinessDetails() async {
    try {
      final String? jsonStr = await _storage.read(key: _businessStorageKey);
      if (jsonStr == null) return;

      final Map<String, dynamic> data = jsonDecode(jsonStr);

      final String businessName =
          (data['businessName'] as String?)?.trim() ?? '';
      final String ownerName = (data['ownerName'] as String?)?.trim() ?? '';
      final String street = (data['address'] as String?)?.trim() ?? '';
      final String city = (data['city'] as String?)?.trim() ?? '';
      final String pincode = (data['pincode'] as String?)?.trim() ?? '';
      final String phone = (data['phone'] as String?)?.trim() ?? '';

      final String label = businessName.isNotEmpty
          ? businessName
          : 'Your Business';

      final String addressText = [
        street,
        if (city.isNotEmpty || pincode.isNotEmpty) '$city - $pincode',
        if (phone.isNotEmpty) 'Phone: $phone',
        if (ownerName.isNotEmpty) 'Owner: $ownerName',
      ].where((e) => e.trim().isNotEmpty).join('\n');

      setState(() {
        _businessAddressLabel = label;
        _businessAddressText = addressText.isNotEmpty
            ? addressText
            : 'Business address not provided';
      });
    } catch (e) {
      debugPrint('Failed to load business details for checkout: $e');
    }
  }

  // ----------------- ACTIONS -----------------
  Future<void> _onSaveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final newAddress = _buildAddressFromForm();
      _savedAddresses.insert(0, newAddress); // latest on top
      _selectedIndex = 0;

      await _saveAddressesToStorage();

      // clear form
      _customerNameCtrl.clear();
      _customerPhoneCtrl.clear();
      _addressCtrl.clear();
      _cityCtrl.clear();
      _pincodeCtrl.clear();

      if (!mounted) return;
      Get.snackbar(
        "Address saved",
        "Customer delivery address has been added.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        "Error",
        "Failed to save address: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onDeleteAddress(int index) async {
    final removeItem = _savedAddresses[index];

    final bool? confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text(
          "Remove address",
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        content: Text(
          "Remove delivery address for \"${removeItem.name}\"?",
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text("Remove", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _savedAddresses.removeAt(index);

      if (_savedAddresses.isEmpty) {
        _selectedIndex = null;
      } else if (_selectedIndex != null) {
        if (_selectedIndex! >= _savedAddresses.length) {
          _selectedIndex = _savedAddresses.length - 1;
        }
      }
    });

    await _saveAddressesToStorage();
  }

  void _onContinue() {
    if (_selectedIndex == null || _savedAddresses.isEmpty) {
      Get.snackbar(
        "Select address",
        "Please select a delivery address to continue.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final selected = _savedAddresses[_selectedIndex!];

    // Optional toast
    Get.snackbar(
      "Address selected",
      "Delivering to ${selected.name}, ${selected.city}.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );

    // -------- Build Customer Address Text --------
    final String customerLabel = selected.name;
    final String customerText =
        "${selected.addressLine}, ${selected.city} - ${selected.pincode}\n"
        "Phone: ${selected.phone}";

    // -------- Business Address (from secure storage) --------
    final String businessLabel = _businessAddressLabel ?? "Your Business";
    final String businessText =
        _businessAddressText ?? "Business address not provided";

    // -------- Navigate to Final Checkout Page --------
    Get.to(
      () => FinalCheckoutPage(
        userData: _userData,
        businessAddressLabel: businessLabel,
        businessAddressText: businessText,
        customerAddressLabel: customerLabel,
        customerAddressText: customerText,
      ),
    );
  }

  // ----------------- UI -----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Customer Delivery Address',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // 🔹 STEP HEADER – Address step
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: CheckoutStepHeader(currentStep: 3),
            ),

            _buildInfoBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAddNewAddressCard(),
                    const SizedBox(height: 20),
                    _buildSavedAddressesSection(),
                  ],
                ),
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: accentColor.withOpacity(0.15), blurRadius: 8),
              ],
            ),
            child: const Icon(Iconsax.location, color: accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Add your customer’s delivery address. You can save multiple addresses and reuse them.',
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'Poppins',
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------- ADD NEW ADDRESS CARD ----------
  Widget _buildAddNewAddressCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Add New Address",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _customerNameCtrl,
              label: 'Customer Name',
              icon: Iconsax.user,
              validator: (v) =>
                  v!.trim().isEmpty ? 'Customer name required' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _customerPhoneCtrl,
              label: 'Customer Phone Number',
              keyboardType: TextInputType.phone,
              icon: Iconsax.call,
              validator: (v) {
                if (v!.trim().isEmpty) return 'Phone number required';
                if (v.trim().length < 10) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addressCtrl,
              label: 'House / Street / Area',
              icon: Iconsax.location,
              maxLines: 2,
              validator: (v) => v!.trim().isEmpty ? 'Address required' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _cityCtrl,
                    label: 'City',
                    icon: Iconsax.location5,
                    validator: (v) =>
                        v!.trim().isEmpty ? 'City required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _pincodeCtrl,
                    label: 'Pincode',
                    keyboardType: TextInputType.number,
                    icon: Iconsax.location_tick,
                    validator: (v) {
                      if (v!.trim().isEmpty) return 'Pincode required';
                      if (v.trim().length < 6) return 'Invalid';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _onSaveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Iconsax.add, size: 18, color: Colors.white),
                label: Text(
                  _isSaving ? "Saving..." : "Save Address",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------- SAVED ADDRESSES ----------
  Widget _buildSavedAddressesSection() {
    if (_savedAddresses.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Saved Addresses",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Iconsax.location_slash, color: Colors.grey.shade500),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "No saved addresses yet. Add one above to reuse it quickly.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Saved Addresses",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _savedAddresses.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final address = _savedAddresses[index];
            final bool isSelected = _selectedIndex == index;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withOpacity(0.06)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? accentColor : Colors.grey.shade300,
                    width: isSelected ? 1.3 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Radio Indicator
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      child: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 20,
                        color: isSelected ? accentColor : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Address Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  address.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                address.phone,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${address.addressLine}, ",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Text(
                            "${address.city} • ${address.pincode}",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Delete Icon
                    IconButton(
                      onPressed: () => _onDeleteAddress(index),
                      icon: const Icon(
                        Iconsax.trash,
                        size: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --------- TEXT FIELD HELPER ----------
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
    );
  }

  // --------- BOTTOM CONTINUE BAR ----------
  Widget _buildBottomBar() {
    final bool hasSelection =
        _selectedIndex != null && _savedAddresses.isNotEmpty;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: hasSelection
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Deliver to",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _savedAddresses[_selectedIndex!].name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    )
                  : const Text(
                      "Select a delivery address",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    ),
            ),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: hasSelection ? _onContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Continue",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Iconsax.arrow_right_3, size: 18, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============= SIMPLE MODEL CLASS =============
class CustomerAddress {
  final String id;
  final String name;
  final String phone;
  final String addressLine;
  final String city;
  final String pincode;

  CustomerAddress({
    required this.id,
    required this.name,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.pincode,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "phone": phone,
    "addressLine": addressLine,
    "city": city,
    "pincode": pincode,
  };

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json["id"] ?? "",
      name: json["name"] ?? "",
      phone: json["phone"] ?? "",
      addressLine: json["addressLine"] ?? "",
      city: json["city"] ?? "",
      pincode: json["pincode"] ?? "",
    );
  }
}
