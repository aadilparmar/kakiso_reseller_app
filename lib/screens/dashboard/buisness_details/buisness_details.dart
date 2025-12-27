import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/address/address.dart';
import 'package:kakiso_reseller_app/screens/dashboard/check_out_header/check_out_header.dart';
import 'package:kakiso_reseller_app/screens/dashboard/checkout/checkout.dart';
// 🔹 Import Final Checkout Page
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class BusinessDetailsPage extends StatefulWidget {
  final UserData? userData; // optional

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

  UserData? _currentUser;

  final TextEditingController _businessNameCtrl = TextEditingController();
  final TextEditingController _ownerNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _whatsappCtrl = TextEditingController();

  // Address controllers
  final TextEditingController _addressLine1Ctrl = TextEditingController();
  final TextEditingController _addressLine2Ctrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _stateCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController(
    text: 'India',
  );
  final TextEditingController _pincodeCtrl = TextEditingController();
  final TextEditingController _gstinCtrl = TextEditingController();

  bool _isWhatsAppSame = true;
  bool _isSaving = false;
  bool _hasSavedDetails = false;
  bool _isRemoteLoading = false;

  // 🔹 Ship to business address option
  bool _shipToBusinessAddress = false;

  final List<String> _indianStates = const [
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Delhi',
    'Jammu and Kashmir',
    'Ladakh',
    'Lakshadweep',
    'Puducherry',
  ];

  String? _selectedState;

  @override
  void initState() {
    super.initState();
    _resolveCurrentUser();
    if (_currentUser != null) {
      _ownerNameCtrl.text = _currentUser!.name;
      _emailCtrl.text = _currentUser!.email;
    }
    _countryCtrl.text = 'India';
    _loadSavedDetails();
    _loadRemoteDetails();
  }

  void _resolveCurrentUser() {
    if (widget.userData != null) {
      _currentUser = widget.userData;
      return;
    }
    try {
      // if (Get.isRegistered<UserController>()) _currentUser = Get.find<UserController>().user;
    } catch (e) {
      debugPrint("Could not auto-fetch user: $e");
    }
  }

  Future<void> _loadSavedDetails() async {
    try {
      final String? jsonStr = await _storage.read(key: _storageKey);
      if (jsonStr == null) return;
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      if (!mounted) return;

      final String savedState = (data['state'] as String?)?.trim() ?? '';
      final String savedLine1 = (data['addressLine1'] as String?)?.trim() ?? '';
      final String savedLine2 = (data['addressLine2'] as String?)?.trim() ?? '';
      final String savedAddressCombined =
          (data['address'] as String?)?.trim() ?? '';

      setState(() {
        _businessNameCtrl.text = data['businessName'] ?? _businessNameCtrl.text;
        _ownerNameCtrl.text = data['ownerName'] ?? _ownerNameCtrl.text;
        _phoneCtrl.text = data['phone'] ?? '';
        _whatsappCtrl.text = data['whatsapp'] ?? '';
        _emailCtrl.text = data['email'] ?? _emailCtrl.text;

        if (savedLine1.isNotEmpty || savedLine2.isNotEmpty) {
          _addressLine1Ctrl.text = savedLine1;
          _addressLine2Ctrl.text = savedLine2;
        } else if (savedAddressCombined.isNotEmpty) {
          _addressLine1Ctrl.text = savedAddressCombined;
          _addressLine2Ctrl.text = '';
        }

        _cityCtrl.text = data['city'] ?? '';
        if (savedState.isNotEmpty && _indianStates.contains(savedState)) {
          _selectedState = savedState;
        } else {
          _selectedState = null;
        }
        _stateCtrl.text = _selectedState ?? savedState;
        _pincodeCtrl.text = data['pincode'] ?? '';
        _gstinCtrl.text = data['gstin'] ?? '';

        _isWhatsAppSame =
            _whatsappCtrl.text.isEmpty || _whatsappCtrl.text == _phoneCtrl.text;
        _hasSavedDetails = true;
      });
    } catch (e) {
      debugPrint('Failed to load saved business details: $e');
    }
  }

  Future<void> _loadRemoteDetails() async {
    final userId = _currentUser?.userId;
    if (userId == null || userId.trim().isEmpty) return;

    setState(() => _isRemoteLoading = true);

    try {
      final remoteData = await ApiService.fetchBusinessDetails(userId: userId);
      if (remoteData == null || !mounted) return;

      final String remoteState = (remoteData['state'] as String?)?.trim() ?? '';
      final String remoteAddress =
          (remoteData['address'] as String?)?.trim() ?? '';

      setState(() {
        _businessNameCtrl.text =
            remoteData['businessName'] ?? _businessNameCtrl.text;
        _ownerNameCtrl.text = remoteData['ownerName'] ?? _ownerNameCtrl.text;
        _phoneCtrl.text = remoteData['phone'] ?? _phoneCtrl.text;
        _whatsappCtrl.text = remoteData['whatsapp'] ?? _whatsappCtrl.text;
        _emailCtrl.text = remoteData['email'] ?? _emailCtrl.text;

        if (_addressLine1Ctrl.text.trim().isEmpty && remoteAddress.isNotEmpty) {
          _addressLine1Ctrl.text = remoteAddress;
        }
        _cityCtrl.text = remoteData['city'] ?? _cityCtrl.text;

        if (remoteState.isNotEmpty && _indianStates.contains(remoteState)) {
          _selectedState = remoteState;
        } else if (_stateCtrl.text.isNotEmpty &&
            _indianStates.contains(_stateCtrl.text.trim())) {
          _selectedState = _stateCtrl.text.trim();
        } else {
          _selectedState = null;
        }
        _stateCtrl.text = _selectedState ?? remoteState;
        _pincodeCtrl.text = remoteData['pincode'] ?? _pincodeCtrl.text;
        _gstinCtrl.text = remoteData['gstin'] ?? _gstinCtrl.text;

        _isWhatsAppSame =
            _whatsappCtrl.text.isEmpty || _whatsappCtrl.text == _phoneCtrl.text;
        _hasSavedDetails = true;
      });

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
    _addressLine1Ctrl.dispose();
    _addressLine2Ctrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _countryCtrl.dispose();
    _pincodeCtrl.dispose();
    _gstinCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedState == null || _selectedState!.trim().isEmpty) {
      Get.snackbar(
        'State required',
        'Please select your state.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    _stateCtrl.text = _selectedState!;
    setState(() => _isSaving = true);

    final String line1 = _addressLine1Ctrl.text.trim();
    final String line2 = _addressLine2Ctrl.text.trim();
    String combinedAddress = line1;
    if (line2.isNotEmpty)
      combinedAddress = combinedAddress.isEmpty
          ? line2
          : '$combinedAddress, $line2';

    final Map<String, dynamic> payload = {
      "businessName": _businessNameCtrl.text.trim(),
      "ownerName": _ownerNameCtrl.text.trim(),
      "phone": _phoneCtrl.text.trim(),
      "whatsapp": _isWhatsAppSame
          ? _phoneCtrl.text.trim()
          : _whatsappCtrl.text.trim(),
      "email": _emailCtrl.text.trim(),
      "address": combinedAddress,
      "addressLine1": line1,
      "addressLine2": line2,
      "city": _cityCtrl.text.trim(),
      "state": _selectedState ?? _stateCtrl.text.trim(),
      "country": 'India',
      "pincode": _pincodeCtrl.text.trim(),
      "gstin": _gstinCtrl.text.trim(),
    };

    try {
      await _storage.write(key: _storageKey, value: jsonEncode(payload));
      if (_currentUser?.userId != null) {
        await ApiService.updateBusinessDetails(
          userId: _currentUser!.userId,
          data: payload,
        );
        await ApiService.updateResellerBusinessMeta(
          userId: _currentUser!.userId,
          data: payload,
        );
      }
      if (!mounted) return;
      setState(() => _hasSavedDetails = true);

      if (widget.fromDrawer) {
        Get.snackbar(
          'Success',
          'Business details updated.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Saved',
          'Details saved successfully.',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.to(() => CustomerAddressPage(userData: _currentUser));
      }
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onContinueFromCheckout() {
    bool isDetailsComplete =
        _businessNameCtrl.text.trim().isNotEmpty &&
        _ownerNameCtrl.text.trim().isNotEmpty &&
        _phoneCtrl.text.trim().isNotEmpty &&
        _addressLine1Ctrl.text.trim().isNotEmpty &&
        _cityCtrl.text.trim().isNotEmpty &&
        (_selectedState != null && _selectedState!.trim().isNotEmpty) &&
        _pincodeCtrl.text.trim().isNotEmpty;

    if (!isDetailsComplete) {
      _showMissingDetailsDialog();
      return;
    }

    // 🔹 Build the Full Address String once
    final line1 = _addressLine1Ctrl.text.trim();
    final line2 = _addressLine2Ctrl.text.trim();
    final city = _cityCtrl.text.trim();
    final state = (_selectedState ?? _stateCtrl.text).trim();
    final pin = _pincodeCtrl.text.trim();

    String fullFormattedAddress = [
      line1,
      line2,
      city,
      state,
      'India',
    ].where((s) => s.isNotEmpty).join(', ');
    if (pin.isNotEmpty) fullFormattedAddress += ' - $pin';

    // 🔹 LOGIC CHECK: Ship to business?
    if (_shipToBusinessAddress) {
      // DIRECTLY GO TO FINAL CHECKOUT
      // We use the Business Name as the Label and the Business Address for BOTH fields

      Get.to(
        () => FinalCheckoutPage(
          userData: _currentUser,
          // Billing Info
          businessAddressLabel: _businessNameCtrl.text.trim(),
          businessAddressText: fullFormattedAddress,
          // Shipping Info (SAME AS BILLING)
          customerAddressLabel: "${_ownerNameCtrl.text.trim()} (Self)",
          customerAddressText: fullFormattedAddress,
          // Flag to update UI
          isSelfShip: true,
        ),
      );
    } else {
      // Normal Flow: Select Customer Address
      Get.to(() => CustomerAddressPage(userData: _currentUser));
    }
  }

  void _showMissingDetailsDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.warning_2,
                  color: Colors.orange,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Missing Business Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'To proceed with your order, you must first add your business details.\n\nPlease navigate to the Profile Page manually to add them.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

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
          'Your Billing Details',
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
            if (!widget.fromDrawer)
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

            if (!widget.fromDrawer && _hasSavedDetails) _buildInfoBanner(),

            if (_hasSavedDetails) ...[
              _buildSavedSummaryCard(),
              if (!widget.fromDrawer) _buildShipToBusinessOption(),
            ],

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: widget.fromDrawer
                    ? Form(
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
                                    validator: (v) =>
                                        v!.trim().isEmpty ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _ownerNameCtrl,
                                    label: 'Your Name',
                                    hint: 'Owner / Proprietor name',
                                    icon: Iconsax.user,
                                    validator: (v) =>
                                        v!.trim().isEmpty ? 'Required' : null,
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
                                    hint: '10-digit mobile',
                                    icon: Iconsax.call,
                                    keyboardType: TextInputType.phone,
                                    validator: (v) => v!.trim().length < 10
                                        ? 'Invalid phone'
                                        : null,
                                    onChanged: (val) {
                                      if (_isWhatsAppSame)
                                        _whatsappCtrl.text = val;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _isWhatsAppSame,
                                        activeColor: accentColor,
                                        onChanged: (val) => setState(() {
                                          _isWhatsAppSame = val ?? true;
                                          if (_isWhatsAppSame)
                                            _whatsappCtrl.text =
                                                _phoneCtrl.text;
                                        }),
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
                                      validator: (v) =>
                                          !_isWhatsAppSame && v!.trim().isEmpty
                                          ? 'Required'
                                          : null,
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _emailCtrl,
                                    label: 'Email',
                                    hint: 'For invoices',
                                    icon: Iconsax.direct_right,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) => !v!.contains('@')
                                        ? 'Invalid email'
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildSectionCard(
                              title: 'Address',
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller: _addressLine1Ctrl,
                                    label: 'Address Line 1',
                                    hint: 'Building / Flat',
                                    icon: Iconsax.location,
                                    validator: (v) =>
                                        v!.trim().isEmpty ? 'Required' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTextField(
                                    controller: _addressLine2Ctrl,
                                    label: 'Address Line 2 (optional)',
                                    hint: 'Street, Area',
                                    icon: Iconsax.location,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          controller: _cityCtrl,
                                          label: 'City',
                                          hint: 'Eg. Rajkot',
                                          icon: Iconsax.location5,
                                          validator: (v) => v!.trim().isEmpty
                                              ? 'Required'
                                              : null,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: _selectedState,
                                          isExpanded: true,
                                          items: _indianStates
                                              .map(
                                                (s) => DropdownMenuItem(
                                                  value: s,
                                                  child: Text(
                                                    s,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (val) => setState(() {
                                            _selectedState = val;
                                            _stateCtrl.text = val ?? '';
                                          }),
                                          decoration: InputDecoration(
                                            labelText: 'State',
                                            prefixIcon: const Icon(
                                              Iconsax.map,
                                              size: 18,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            isDense: true,
                                          ),
                                          validator: (v) =>
                                              v == null ? 'Required' : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: _countryCtrl,
                                          enabled: false,
                                          decoration: InputDecoration(
                                            labelText: 'Country',
                                            prefixIcon: const Icon(
                                              Iconsax.global,
                                              size: 18,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
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
                                          hint: 'Eg. 360001',
                                          icon: Iconsax.location_tick,
                                          keyboardType: TextInputType.number,
                                          validator: (v) => v!.trim().length < 6
                                              ? 'Invalid'
                                              : null,
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
                                    textCapitalization:
                                        TextCapitalization.characters,
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
                      )
                    : _buildReadOnlyBody(),
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyBody() {
    if (_hasSavedDetails) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SizedBox(height: 8),
          Text(
            'To update your business details, open the menu/drawer and go to "Business Details".',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Poppins',
              color: Colors.grey,
            ),
          ),
        ],
      );
    } else {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.info_circle,
                size: 32,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Business Details Found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'To proceed with your order, you must first add your business details.\n\nPlease navigate to the Profile Page manually to add them.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'Poppins',
                color: Colors.black54,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }
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
            child: const Icon(Iconsax.shop, color: accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Review your shop details. These will be shown to your customers on catalogues & orders.',
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

  Widget _buildSavedSummaryCard() {
    final line1 = _addressLine1Ctrl.text.trim();
    final line2 = _addressLine2Ctrl.text.trim();
    final city = _cityCtrl.text.trim();
    final state = (_selectedState ?? _stateCtrl.text).trim();
    final pin = _pincodeCtrl.text.trim();
    String addressLine = [
      line1,
      line2,
      city,
      state,
      'India',
    ].where((s) => s.isNotEmpty).join(', ');
    if (pin.isNotEmpty) addressLine += ' - $pin';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
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
                        color: Colors.green.withValues(alpha: 0.08),
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
                  maxLines: 3,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipToBusinessOption() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _shipToBusinessAddress ? accentColor : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CheckboxListTile(
        value: _shipToBusinessAddress,
        activeColor: accentColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onChanged: (val) {
          setState(() {
            _shipToBusinessAddress = val ?? false;
          });
        },
        title: const Text(
          "Ship to my business address",
          style: TextStyle(
            fontSize: 13,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: const Text(
          "The order will be delivered to you instead of a customer.",
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'Poppins',
            color: Colors.grey,
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _shipToBusinessAddress
                ? accentColor.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Iconsax.box,
            size: 18,
            color: _shipToBusinessAddress ? accentColor : Colors.grey,
          ),
        ),
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
            color: Colors.black.withValues(alpha: 0.03),
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
              if (title != 'GST & Compliance (Optional)')
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.06),
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
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSaving
                ? null
                : (widget.fromDrawer ? _onSubmit : _onContinueFromCheckout),
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
                        widget.fromDrawer
                            ? (_hasSavedDetails ? 'Update & Save' : 'Save')
                            : 'Continue',
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
