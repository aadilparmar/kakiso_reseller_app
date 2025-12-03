import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/address/address.dart';
import 'package:kakiso_reseller_app/screens/dashboard/check_out_header/check_out_header.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

// 🔹 Checkout step: Business details (Step 2)

class BusinessDetailsPage extends StatefulWidget {
  final UserData? userData; // optional, to prefill if available

  /// If true → opened from drawer (settings mode)
  /// If false / null → opened from checkout flow
  final bool fromDrawer;

  const BusinessDetailsPage({
    super.key,
    this.userData,
    this.fromDrawer = false,
  });

  @override
  State<BusinessDetailsPage> createState() => _BusinessDetailsPageState();
}

class _BusinessDetailsPageState extends State<BusinessDetailsPage> {
  final _formKey = GlobalKey<FormState>();

  // local storage
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _storageKey = 'business_details';

  final TextEditingController _businessNameCtrl = TextEditingController();
  final TextEditingController _ownerNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _whatsappCtrl = TextEditingController();

  // Address controllers
  final TextEditingController _addressCtrl = TextEditingController(); // Street
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _stateCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController(
    text: 'India',
  );
  final TextEditingController _pincodeCtrl = TextEditingController();

  final TextEditingController _gstinCtrl = TextEditingController();

  bool _isWhatsAppSame = true;
  bool _isSaving = false;
  bool _hasSavedDetails = false; // 🔹 to know if user already saved once
  bool _isRemoteLoading = false; // 🔹 when fetching from server

  @override
  void initState() {
    super.initState();

    // Prefill from UserData (name + email)
    if (widget.userData != null) {
      _ownerNameCtrl.text = widget.userData!.name;
      _emailCtrl.text = widget.userData!.email;
    }

    // Load any previously saved business details (device-local)
    _loadSavedDetails();

    // Then load from server so details follow the user across devices
    _loadRemoteDetails();
  }

  // 🔹 load from secure storage (fast, device-only)
  Future<void> _loadSavedDetails() async {
    try {
      final String? jsonStr = await _storage.read(key: _storageKey);
      if (jsonStr == null) return;

      final Map<String, dynamic> data = jsonDecode(jsonStr);

      if (!mounted) return;

      setState(() {
        _businessNameCtrl.text = data['businessName'] ?? _businessNameCtrl.text;
        _ownerNameCtrl.text = data['ownerName'] ?? _ownerNameCtrl.text;
        _phoneCtrl.text = data['phone'] ?? '';
        _whatsappCtrl.text = data['whatsapp'] ?? '';
        _emailCtrl.text = data['email'] ?? _emailCtrl.text;

        _addressCtrl.text = data['address'] ?? '';
        _cityCtrl.text = data['city'] ?? '';
        _stateCtrl.text = data['state'] ?? '';
        _countryCtrl.text = data['country'] ?? _countryCtrl.text;
        _pincodeCtrl.text = data['pincode'] ?? '';

        _gstinCtrl.text = data['gstin'] ?? '';

        _isWhatsAppSame =
            _whatsappCtrl.text.isEmpty || _whatsappCtrl.text == _phoneCtrl.text;

        _hasSavedDetails = true; // 🔹 show summary UI
      });
    } catch (e) {
      debugPrint('Failed to load saved business details: $e');
    }
  }

  // 🔹 load from WooCommerce/Kakiso backend (cross-device source of truth)
  Future<void> _loadRemoteDetails() async {
    final userId = widget.userData?.userId;
    if (userId == null || userId.trim().isEmpty) {
      return;
    }

    setState(() => _isRemoteLoading = true);

    try {
      final remoteData = await ApiService.fetchBusinessDetails(userId: userId);

      if (remoteData == null || !mounted) return;

      setState(() {
        _businessNameCtrl.text =
            remoteData['businessName'] ?? _businessNameCtrl.text;
        _ownerNameCtrl.text = remoteData['ownerName'] ?? _ownerNameCtrl.text;
        _phoneCtrl.text = remoteData['phone'] ?? _phoneCtrl.text;
        _whatsappCtrl.text = remoteData['whatsapp'] ?? _whatsappCtrl.text;
        _emailCtrl.text = remoteData['email'] ?? _emailCtrl.text;

        _addressCtrl.text = remoteData['address'] ?? _addressCtrl.text;
        _cityCtrl.text = remoteData['city'] ?? _cityCtrl.text;
        _stateCtrl.text = remoteData['state'] ?? _stateCtrl.text;
        _countryCtrl.text = remoteData['country'] ?? _countryCtrl.text;
        _pincodeCtrl.text = remoteData['pincode'] ?? _pincodeCtrl.text;

        _gstinCtrl.text = remoteData['gstin'] ?? _gstinCtrl.text;

        _isWhatsAppSame =
            _whatsappCtrl.text.isEmpty || _whatsappCtrl.text == _phoneCtrl.text;

        _hasSavedDetails = true;
      });

      // Also sync to local storage so next open is instant
      await _storage.write(key: _storageKey, value: jsonEncode(remoteData));
    } catch (e) {
      debugPrint('Failed to fetch remote business details: $e');
    } finally {
      if (mounted) setState(() => _isRemoteLoading = false);
    }
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _whatsappCtrl.dispose();

    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _countryCtrl.dispose();
    _pincodeCtrl.dispose();

    _gstinCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    // Build the payload that we save locally AND send to backend
    final Map<String, dynamic> payload = {
      "businessName": _businessNameCtrl.text.trim(),
      "ownerName": _ownerNameCtrl.text.trim(),
      "phone": _phoneCtrl.text.trim(),
      "whatsapp": _isWhatsAppSame
          ? _phoneCtrl.text.trim()
          : _whatsappCtrl.text.trim(),
      "email": _emailCtrl.text.trim(),
      "address": _addressCtrl.text.trim(),
      "city": _cityCtrl.text.trim(),
      "state": _stateCtrl.text.trim(),
      "country": _countryCtrl.text.trim(),
      "pincode": _pincodeCtrl.text.trim(),
      "gstin": _gstinCtrl.text.trim(),
    };

    try {
      // 1️⃣ Save locally (for app reuse)
      await _storage.write(key: _storageKey, value: jsonEncode(payload));

      // 2️⃣ Push to WooCommerce "customer" (billing/shipping)
      await ApiService.updateBusinessDetails(
        userId: widget.userData?.userId,
        data: payload,
      );

      // 3️⃣ Push to WordPress "Business Details (Reseller)" user meta box
      await ApiService.updateResellerBusinessMeta(
        userId: widget.userData?.userId,
        data: payload,
      );

      if (!mounted) return;

      setState(() {
        _hasSavedDetails = true;
      });

      if (widget.fromDrawer) {
        // SETTINGS MODE
        Get.snackbar(
          'Details updated',
          'Your business details have been updated.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        // CHECKOUT FLOW
        Get.snackbar(
          'Business details saved',
          'Your information will be used on invoices & catalogues.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.to(() => CustomerAddressPage(userData: widget.userData));
      }
    } catch (e) {
      if (!mounted) return;
      // Get.snackbar(
      //   'Error',
      //   'Failed to save business details: $e',
      //   snackPosition: SnackPosition.BOTTOM,
      //   backgroundColor: Colors.red,
      //   colorText: Colors.white,
      // );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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
        title: const Text(
          'Your Business Details',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),

            // 🔹 STEP 2 header only in checkout flow (NOT from drawer)
            if (!fromDrawer)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: CheckoutStepHeader(currentStep: 2),
              ),

            if (_isRemoteLoading)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4,
                ),
                child: Row(
                  children: const [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Syncing your saved business details…',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Poppins',
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

            // Info banner only in checkout mode
            if (!fromDrawer) _buildInfoBanner(),

            if (_hasSavedDetails)
              _buildSavedSummaryCard(), // 🔹 summary if saved

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildSectionCard(
                        title: 'Business Profile',
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _businessNameCtrl,
                              label: 'Business / Shop Name',
                              hint: 'Eg. Aadil Fashion Hub',
                              icon: Iconsax.shop,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your business name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _ownerNameCtrl,
                              label: 'Your Name',
                              hint: 'Owner / Proprietor name',
                              icon: Iconsax.user,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildSectionCard(
                        title: 'Contact Details',
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _phoneCtrl,
                              label: 'Primary Phone Number',
                              hint: '10-digit mobile number',
                              icon: Iconsax.call,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter phone number';
                                }
                                if (value.trim().length < 10) {
                                  return 'Enter a valid phone number';
                                }
                                return null;
                              },
                              onChanged: (val) {
                                if (_isWhatsAppSame) {
                                  _whatsappCtrl.text = val;
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Checkbox(
                                  value: _isWhatsAppSame,
                                  activeColor: accentColor,
                                  onChanged: (val) {
                                    setState(() {
                                      _isWhatsAppSame = val ?? true;
                                      if (_isWhatsAppSame) {
                                        _whatsappCtrl.text = _phoneCtrl.text;
                                      }
                                    });
                                  },
                                ),
                                const Expanded(
                                  child: Text(
                                    'WhatsApp number is same as phone',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (!_isWhatsAppSame) ...[
                              const SizedBox(height: 4),
                              _buildTextField(
                                controller: _whatsappCtrl,
                                label: 'WhatsApp Number',
                                hint: 'WhatsApp contact',
                                icon: Iconsax.sms,
                                keyboardType: TextInputType.phone,
                                validator: (v) {
                                  if (!_isWhatsAppSame) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Please enter WhatsApp number';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 12),
                            _buildTextField(
                              controller: _emailCtrl,
                              label: 'Email',
                              hint: 'For invoices & communication',
                              icon: Iconsax.direct_right,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 🔹 Address section (nicer layout)
                      _buildSectionCard(
                        title: 'Address',
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _addressCtrl,
                              label: 'Street Address',
                              hint: 'Building, street, area',
                              icon: Iconsax.location,
                              maxLines: 2,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your street address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            // City + State
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _cityCtrl,
                                    label: 'City',
                                    hint: 'Eg. Rajkot',
                                    icon: Iconsax.location5,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'City required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _stateCtrl,
                                    label: 'State',
                                    hint: 'Eg. Gujarat',
                                    icon: Iconsax.map,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'State required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Country + Pincode
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _countryCtrl,
                                    label: 'Country',
                                    hint: 'Eg. India',
                                    icon: Iconsax.global,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Country required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _pincodeCtrl,
                                    label: 'Pincode',
                                    hint: 'Eg. 360001',
                                    icon: Iconsax.location_tick,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Pincode required';
                                      }
                                      if (value.trim().length < 6) {
                                        return 'Invalid';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildSectionCard(
                        title: 'GST & Compliance (Optional)',
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: _gstinCtrl,
                              label: 'GSTIN (optional)',
                              hint: 'Eg. 22AAAAA0000A1Z5',
                              icon: Iconsax.document_text,
                              textCapitalization: TextCapitalization.characters,
                            ),
                            const SizedBox(height: 6),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'If you don’t have GST, you can leave this empty.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontFamily: 'Poppins',
                                ),
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
            _buildBottomButton(),
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
            child: const Icon(Iconsax.shop, color: accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Add your shop details. These will be shown to your customers on catalogues & orders.',
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

  // 🔹 Summary when details already saved
  Widget _buildSavedSummaryCard() {
    // Build a clean one-line address for summary
    final street = _addressCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final state = _stateCtrl.text.trim();
    final country = _countryCtrl.text.trim();
    final pin = _pincodeCtrl.text.trim();

    final List<String> parts = [];
    if (street.isNotEmpty) parts.add(street);
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (country.isNotEmpty) parts.add(country);

    String addressLine = parts.isEmpty
        ? 'No address added yet'
        : parts.join(', ');
    if (pin.isNotEmpty) {
      addressLine = '$addressLine - $pin';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Iconsax.shop, color: accentColor, size: 20),
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
                        _businessNameCtrl.text.isEmpty
                            ? 'Your business'
                            : _businessNameCtrl.text,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Saved',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (_ownerNameCtrl.text.trim().isNotEmpty)
                  Text(
                    "Owner: ${_ownerNameCtrl.text.trim()}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade800,
                      fontFamily: 'Poppins',
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  addressLine,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (_phoneCtrl.text.trim().isNotEmpty)
                      Text(
                        "📞 ${_phoneCtrl.text.trim()}",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    if (_emailCtrl.text.trim().isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          "✉️ ${_emailCtrl.text.trim()}",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (_gstinCtrl.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    "GSTIN: ${_gstinCtrl.text.trim()}",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              if (title == 'Business Profile' ||
                  title == 'Contact Details' ||
                  title == 'Address')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Required',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.red,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    void Function(String)? onChanged,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
    );
  }

  Widget _buildBottomButton() {
    final bool fromDrawer = widget.fromDrawer;

    // ✅ Decide button label based on context
    String buttonText;
    if (fromDrawer) {
      buttonText = _hasSavedDetails ? 'Update & Save' : 'Save';
    } else {
      buttonText = _hasSavedDetails ? 'Update & Continue' : 'Save & Continue';
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        buttonText,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Iconsax.arrow_right_3,
                        size: 18,
                        color: Colors.white,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
