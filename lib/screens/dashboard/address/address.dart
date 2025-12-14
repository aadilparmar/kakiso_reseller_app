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

// 🔹 STEP: Customer Address (Step 3)

class CustomerAddressPage extends StatefulWidget {
  /// Optional – pass from BusinessDetailsPage if you have it:
  /// Get.to(() => CustomerAddressPage(userData: widget.userData));
  final UserData? userData;

  /// If true -> opened from drawer (settings mode, no step header + no continue)
  final bool fromDrawer;

  const CustomerAddressPage({
    super.key,
    this.userData,
    this.fromDrawer = false,
  });

  @override
  State<CustomerAddressPage> createState() => _CustomerAddressPageState();
}

class _CustomerAddressPageState extends State<CustomerAddressPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _customerNameCtrl = TextEditingController();
  final TextEditingController _customerPhoneCtrl = TextEditingController();

  // Address split into three lines
  final TextEditingController _addressLine1Ctrl = TextEditingController();
  final TextEditingController _addressLine2Ctrl = TextEditingController();
  final TextEditingController _addressLine3Ctrl = TextEditingController();

  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController(
    text: 'India',
  );
  final TextEditingController _pincodeCtrl = TextEditingController();

  // State dropdown selection
  String? selectedState;

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

  // List of Indian states and UTs for dropdown
  final List<String> indianStates = [
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chhattisgarh",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Madhya Pradesh",
    "Maharashtra",
    "Manipur",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Odisha",
    "Punjab",
    "Rajasthan",
    "Sikkim",
    "Tamil Nadu",
    "Telangana",
    "Tripura",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal",
    "Delhi",
    "Jammu & Kashmir",
    "Ladakh",
    "Puducherry",
    "Chandigarh",
    "Andaman & Nicobar Islands",
    "Lakshadweep",
  ];

  @override
  void initState() {
    super.initState();
    _countryCtrl.text = 'India';
    _loadSavedAddresses();
    _loadBusinessDetails(); // 🔹 load business address for final checkout
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _addressLine1Ctrl.dispose();
    _addressLine2Ctrl.dispose();
    _addressLine3Ctrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  // ----------------- MODEL -----------------
  CustomerAddress _buildAddressFromForm() {
    // Combine three address lines into a single stored address string
    final fullAddress = [
      _addressLine1Ctrl.text.trim(),
      _addressLine2Ctrl.text.trim(),
      _addressLine3Ctrl.text.trim(),
    ].where((e) => e.isNotEmpty).join(", ");

    return CustomerAddress(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _customerNameCtrl.text.trim(),
      phone: _customerPhoneCtrl.text.trim(),
      addressLine: fullAddress,
      city: _cityCtrl.text.trim(),
      state: selectedState ?? '',
      country: 'India', // locked to India
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
      final String state = (data['state'] as String?)?.trim() ?? '';
      final String country = (data['country'] as String?)?.trim() ?? '';
      final String pincode = (data['pincode'] as String?)?.trim() ?? '';
      final String phone = (data['phone'] as String?)?.trim() ?? '';

      final String label = businessName.isNotEmpty
          ? businessName
          : 'Your Business';

      // Build nicer multi-line address
      final List<String> line1Parts = [];
      if (street.isNotEmpty) line1Parts.add(street);
      if (city.isNotEmpty) line1Parts.add(city);
      if (state.isNotEmpty) line1Parts.add(state);
      if (country.isNotEmpty) line1Parts.add(country);

      String line1 = line1Parts.join(', ');
      if (pincode.isNotEmpty) {
        line1 = line1.isEmpty ? pincode : '$line1 - $pincode';
      }

      final List<String> finalLines = [];
      if (line1.trim().isNotEmpty) finalLines.add(line1);
      if (phone.isNotEmpty) finalLines.add('Phone: $phone');
      if (ownerName.isNotEmpty) finalLines.add('Owner: $ownerName');

      final String addressText = finalLines.join('\n');

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
      _savedAddresses.insert(
        0,
        newAddress,
      ); // latest on top, treated as default
      _selectedIndex = 0;

      await _saveAddressesToStorage();

      // clear form
      _customerNameCtrl.clear();
      _customerPhoneCtrl.clear();
      _addressLine1Ctrl.clear();
      _addressLine2Ctrl.clear();
      _addressLine3Ctrl.clear();
      _cityCtrl.clear();
      _pincodeCtrl.clear();
      selectedState = null;
      _countryCtrl.text = 'India';

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

  void _onContinueCheckout() {
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

    // -------- Build Customer Address Text (nice formatting) --------
    final List<String> lineParts = [];
    if (selected.addressLine.trim().isNotEmpty) {
      lineParts.add(selected.addressLine.trim());
    }
    if (selected.city.trim().isNotEmpty) {
      lineParts.add(selected.city.trim());
    }
    if (selected.state.trim().isNotEmpty) {
      lineParts.add(selected.state.trim());
    }
    if (selected.country.trim().isNotEmpty) {
      lineParts.add(selected.country.trim());
    }

    String line1 = lineParts.join(', ');
    if (selected.pincode.trim().isNotEmpty) {
      line1 = '$line1 - ${selected.pincode.trim()}';
    }

    final String customerLabel = selected.name;
    final String customerText = [
      line1,
      'Phone: ${selected.phone}',
    ].where((e) => e.trim().isNotEmpty).join('\n');

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

  Future<void> _onUpdateFromDrawer() async {
    // When opened from drawer, just ensure addresses are saved and show snackbar
    if (_savedAddresses.isEmpty) {
      Get.snackbar(
        "No address found",
        "Add at least one customer address, then tap Update & Save.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    await _saveAddressesToStorage();

    Get.snackbar(
      "Addresses updated",
      "Your customer address list has been updated.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  // ----------------- UI -----------------
  @override
  Widget build(BuildContext context) {
    final bool fromDrawer = widget.fromDrawer;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
        title: Text(
          fromDrawer ? 'Customer Addresses' : 'Customer Delivery Address',
          style: const TextStyle(
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

            // 🔹 STEP HEADER – Address step (only in checkout flow)
            if (!fromDrawer)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: CheckoutStepHeader(currentStep: 2),
              ),

            if (!fromDrawer) _buildInfoBanner(),

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
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.15),
                  blurRadius: 8,
                ),
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
            color: Colors.black.withValues(alpha: 0.03),
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
              hint: 'Eg. Aadil Parmar',
              validator: (v) =>
                  v!.trim().isEmpty ? 'Customer name required' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _customerPhoneCtrl,
              label: 'Customer Phone Number',
              keyboardType: TextInputType.phone,
              icon: Iconsax.call,
              hint: '10-digit mobile number',
              validator: (v) {
                if (v!.trim().isEmpty) return 'Phone number required';
                if (v.trim().length < 10) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Address Lines
            _buildTextField(
              controller: _addressLine1Ctrl,
              label: 'Address Line 1',
              icon: Iconsax.location,
              hint: 'House No. / Building / Street',
              validator: (v) => v!.trim().isEmpty ? 'Address required' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addressLine2Ctrl,
              label: 'Address Line 2 (Optional)',
              icon: Iconsax.location,
              hint: 'Area / Landmark',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addressLine3Ctrl,
              label: 'Address Line 3 (Optional)',
              icon: Iconsax.location,
              hint: 'Locality / Additional Info',
            ),
            const SizedBox(height: 12),

            // City + State
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _cityCtrl,
                    label: 'City',
                    icon: Iconsax.location5,
                    hint: 'Eg. Rajkot',
                    validator: (v) =>
                        v!.trim().isEmpty ? 'City required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedState,
                    isExpanded:
                        true, // 👈 important: prevent horizontal overflow
                    items: indianStates
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                              s,
                              style: const TextStyle(fontFamily: 'Poppins'),
                              overflow: TextOverflow
                                  .ellipsis, // 👈 long names = ellipsis
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      setState(() => selectedState = val);
                    },
                    decoration: InputDecoration(
                      labelText: "State",
                      prefixIcon: const Icon(Iconsax.map, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'State required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Country + Pincode
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _countryCtrl,
                    enabled: false, // locked to India
                    decoration: InputDecoration(
                      labelText: 'Country',
                      prefixIcon: const Icon(Iconsax.global, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    controller: _pincodeCtrl,
                    label: 'Pincode',
                    keyboardType: TextInputType.number,
                    icon: Iconsax.location_tick,
                    hint: 'Eg. 360001',
                    validator: (v) {
                      if (v!.trim().isEmpty) return 'Pincode required';
                      if (v.trim().length < 6) return 'Invalid pincode';
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
            final bool isDefault = index == 0;

            // Combine address lines nicely
            final partsLine1 = <String>[];
            if (address.addressLine.trim().isNotEmpty) {
              partsLine1.add(address.addressLine.trim());
            }
            final partsLine2 = <String>[];
            if (address.city.trim().isNotEmpty) {
              partsLine2.add(address.city.trim());
            }
            if (address.state.trim().isNotEmpty) {
              partsLine2.add(address.state.trim());
            }
            final partsLine3 = <String>[];
            if (address.country.trim().isNotEmpty) {
              partsLine3.add(address.country.trim());
            }
            if (address.pincode.trim().isNotEmpty) {
              partsLine3.add(address.pincode.trim());
            }

            final line1 = partsLine1.join(', ');
            final line2 = partsLine2.join(', ');
            final line3 = partsLine3.join(' • ');

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
                      ? accentColor.withValues(alpha: 0.06)
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
                              if (isDefault) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'Default',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (line1.isNotEmpty)
                            Text(
                              line1,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade800,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          if (line2.isNotEmpty)
                            Text(
                              line2,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade800,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          if (line3.isNotEmpty)
                            Text(
                              line3,
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
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
    );
  }

  // --------- BOTTOM CONTINUE / UPDATE BAR ----------
  Widget _buildBottomBar() {
    final bool fromDrawer = widget.fromDrawer;
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
              child: fromDrawer
                  ? Text(
                      "Saved addresses: ${_savedAddresses.length}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    )
                  : hasSelection
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
                onPressed: fromDrawer
                    ? _onUpdateFromDrawer
                    : (hasSelection ? _onContinueCheckout : null),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      fromDrawer ? "Update & Save" : "Continue",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      fromDrawer ? Iconsax.tick_circle : Iconsax.arrow_right_3,
                      size: 18,
                      color: Colors.white,
                    ),
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
  final String state;
  final String country;
  final String pincode;

  CustomerAddress({
    required this.id,
    required this.name,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
  });

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "phone": phone,
    "addressLine": addressLine,
    "city": city,
    "state": state,
    "country": country,
    "pincode": pincode,
  };

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json["id"] ?? "",
      name: json["name"] ?? "",
      phone: json["phone"] ?? "",
      addressLine: json["addressLine"] ?? "",
      city: json["city"] ?? "",
      state: json["state"] ?? "",
      country: json["country"] ?? "",
      pincode: json["pincode"] ?? "",
    );
  }
}
