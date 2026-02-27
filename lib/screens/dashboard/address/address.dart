// lib/screens/dashboard/address/address.dart
// v2: Full DB sync via /kakiso/v1/addresses REST API
// Addresses stored in reseller_customer_addresses user_meta (same as web)
// Local cache in FlutterSecureStorage for offline/speed

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/check_out_header/check_out_header.dart';
import 'package:kakiso_reseller_app/screens/dashboard/checkout/checkout.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

class CustomerAddressPage extends StatefulWidget {
  final UserData? userData;
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
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _addressLine1Ctrl = TextEditingController();
  final _addressLine2Ctrl = TextEditingController();
  final _addressLine3Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'India');
  final _pincodeCtrl = TextEditingController();
  Key _stateFieldKey = UniqueKey();
  Key _cityFieldKey = UniqueKey();
  String? _selectedState, _selectedCity;
  bool _isSaving = false, _isLoading = false;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _storageKey = 'customer_addresses';
  static const String _businessStorageKey = 'business_details';

  List<CustomerAddress> _savedAddresses = [];
  int? _selectedIndex;
  String? _businessAddressLabel, _businessAddressText;
  UserData? get _userData => widget.userData;

  final Map<String, List<String>> _stateCityMap = {
    'Andaman and Nicobar Islands': [
      'Port Blair',
      'Diglipur',
      'Mayabunder',
      'Rangat',
      'Bamboo Flat',
      'Garacharma',
    ],
    'Andhra Pradesh': [
      'Adoni',
      'Amaravati',
      'Anantapur',
      'Bhimavaram',
      'Chittoor',
      'Dharmavaram',
      'Eluru',
      'Gudivada',
      'Guntur',
      'Hindupur',
      'Kadapa',
      'Kakinada',
      'Kurnool',
      'Machilipatnam',
      'Madanapalle',
      'Nandyal',
      'Narasaraopet',
      'Nellore',
      'Ongole',
      'Proddatur',
      'Rajahmundry',
      'Srikakulam',
      'Tadepalligudem',
      'Tenali',
      'Tirupati',
      'Vijayawada',
      'Visakhapatnam',
      'Vizianagaram',
    ],
    'Arunachal Pradesh': [
      'Itanagar',
      'Naharlagun',
      'Pasighat',
      'Tawang',
      'Ziro',
      'Bomdila',
      'Aalo',
      'Tezu',
      'Roing',
    ],
    'Assam': [
      'Barpeta',
      'Bongaigaon',
      'Dhubri',
      'Dibrugarh',
      'Diphu',
      'Guwahati',
      'Jorhat',
      'Karimganj',
      'Kokrajhar',
      'Lanka',
      'Lumding',
      'Nagaon',
      'Nalbari',
      'North Lakhimpur',
      'Sibsagar',
      'Silchar',
      'Tezpur',
      'Tinsukia',
    ],
    'Bihar': [
      'Arrah',
      'Aurangabad',
      'Begusarai',
      'Bettiah',
      'Bhagalpur',
      'Bihar Sharif',
      'Buxar',
      'Chhapra',
      'Darbhanga',
      'Dehri',
      'Gaya',
      'Hajipur',
      'Jamalpur',
      'Katihar',
      'Kishanganj',
      'Madhubani',
      'Motihari',
      'Munger',
      'Muzaffarpur',
      'Patna',
      'Purnia',
      'Saharsa',
      'Samastipur',
      'Sasaram',
      'Siwan',
      'Sitamarhi',
    ],
    'Chandigarh': ['Chandigarh'],
    'Chhattisgarh': [
      'Ambikapur',
      'Bhilai',
      'Bilaspur',
      'Chirmiri',
      'Dhamtari',
      'Durg',
      'Jagdalpur',
      'Korba',
      'Raigarh',
      'Raipur',
      'Rajnandgaon',
    ],
    'Dadra and Nagar Haveli and Daman and Diu': [
      'Daman',
      'Diu',
      'Silvassa',
      'Dadra',
    ],
    'Delhi': [
      'Delhi',
      'New Delhi',
      'North Delhi',
      'South Delhi',
      'East Delhi',
      'West Delhi',
    ],
    'Goa': ['Panaji', 'Margao', 'Vasco da Gama', 'Mapusa', 'Ponda'],
    'Gujarat': [
      'Ahmedabad',
      'Amreli',
      'Anand',
      'Bharuch',
      'Bhavnagar',
      'Bhuj',
      'Dahod',
      'Gandhinagar',
      'Gandhidham',
      'Godhra',
      'Jamnagar',
      'Junagadh',
      'Mehsana',
      'Morbi',
      'Nadiad',
      'Navsari',
      'Palanpur',
      'Patan',
      'Porbandar',
      'Rajkot',
      'Surat',
      'Surendranagar',
      'Vadodara',
      'Valsad',
      'Vapi',
      'Veraval',
    ],
    'Haryana': [
      'Ambala',
      'Bhiwani',
      'Faridabad',
      'Gurugram',
      'Hisar',
      'Karnal',
      'Panipat',
      'Panchkula',
      'Rohtak',
      'Sirsa',
      'Sonipat',
      'Yamunanagar',
    ],
    'Himachal Pradesh': [
      'Baddi',
      'Bilaspur',
      'Dharamshala',
      'Hamirpur',
      'Kullu',
      'Mandi',
      'Nahan',
      'Palampur',
      'Shimla',
      'Solan',
      'Una',
    ],
    'Jammu and Kashmir': [
      'Anantnag',
      'Baramulla',
      'Jammu',
      'Kathua',
      'Sopore',
      'Srinagar',
      'Udhampur',
    ],
    'Jharkhand': [
      'Bokaro',
      'Deoghar',
      'Dhanbad',
      'Dumka',
      'Giridih',
      'Hazaribag',
      'Jamshedpur',
      'Ranchi',
    ],
    'Karnataka': [
      'Bagalkot',
      'Ballari',
      'Belgaum',
      'Bengaluru',
      'Bidar',
      'Davanagere',
      'Dharwad',
      'Gulbarga',
      'Hassan',
      'Hubli',
      'Kolar',
      'Mandya',
      'Mangaluru',
      'Mysuru',
      'Raichur',
      'Shimoga',
      'Tumkur',
      'Udupi',
    ],
    'Kerala': [
      'Alappuzha',
      'Kannur',
      'Kasaragod',
      'Kochi',
      'Kollam',
      'Kottayam',
      'Kozhikode',
      'Malappuram',
      'Palakkad',
      'Pathanamthitta',
      'Thiruvananthapuram',
      'Thrissur',
    ],
    'Ladakh': ['Kargil', 'Leh'],
    'Lakshadweep': ['Kavaratti'],
    'Madhya Pradesh': [
      'Bhopal',
      'Burhanpur',
      'Chhindwara',
      'Dewas',
      'Gwalior',
      'Indore',
      'Jabalpur',
      'Katni',
      'Khandwa',
      'Morena',
      'Ratlam',
      'Rewa',
      'Sagar',
      'Satna',
      'Sehore',
      'Singrauli',
      'Ujjain',
      'Vidisha',
    ],
    'Maharashtra': [
      'Ahmednagar',
      'Akola',
      'Amravati',
      'Aurangabad',
      'Chandrapur',
      'Dhule',
      'Ichalkaranji',
      'Jalgaon',
      'Jalna',
      'Kolhapur',
      'Latur',
      'Malegaon',
      'Mumbai',
      'Nagpur',
      'Nanded',
      'Nashik',
      'Navi Mumbai',
      'Parbhani',
      'Pune',
      'Sangli',
      'Satara',
      'Solapur',
      'Thane',
    ],
    'Manipur': ['Bishnupur', 'Imphal', 'Thoubal'],
    'Meghalaya': ['Jowai', 'Shillong', 'Tura'],
    'Mizoram': ['Aizawl', 'Champhai', 'Lunglei'],
    'Nagaland': ['Dimapur', 'Kohima', 'Mokokchung'],
    'Odisha': [
      'Balasore',
      'Baripada',
      'Berhampur',
      'Bhubaneswar',
      'Cuttack',
      'Jharsuguda',
      'Puri',
      'Rourkela',
      'Sambalpur',
    ],
    'Puducherry': ['Karaikal', 'Mahe', 'Puducherry', 'Yanam'],
    'Punjab': [
      'Amritsar',
      'Bathinda',
      'Hoshiarpur',
      'Jalandhar',
      'Ludhiana',
      'Moga',
      'Mohali',
      'Pathankot',
      'Patiala',
    ],
    'Rajasthan': [
      'Ajmer',
      'Alwar',
      'Bharatpur',
      'Bhilwara',
      'Bikaner',
      'Hanumangarh',
      'Jaipur',
      'Jodhpur',
      'Kota',
      'Pali',
      'Sikar',
      'Sri Ganganagar',
      'Udaipur',
    ],
    'Sikkim': ['Gangtok', 'Gyalshing', 'Namchi'],
    'Tamil Nadu': [
      'Chennai',
      'Coimbatore',
      'Cuddalore',
      'Dindigul',
      'Erode',
      'Hosur',
      'Karur',
      'Madurai',
      'Nagapattinam',
      'Namakkal',
      'Nagercoil',
      'Salem',
      'Thanjavur',
      'Thoothukudi',
      'Tiruchirappalli',
      'Tirunelveli',
      'Tiruppur',
      'Vellore',
    ],
    'Telangana': [
      'Hyderabad',
      'Karimnagar',
      'Khammam',
      'Mahbubnagar',
      'Nalgonda',
      'Nizamabad',
      'Ramagundam',
      'Siddipet',
      'Warangal',
    ],
    'Tripura': ['Agartala', 'Dharmanagar', 'Udaipur'],
    'Uttar Pradesh': [
      'Agra',
      'Aligarh',
      'Allahabad',
      'Amroha',
      'Ayodhya',
      'Bareilly',
      'Bulandshahr',
      'Etawah',
      'Firozabad',
      'Ghaziabad',
      'Gorakhpur',
      'Jhansi',
      'Kanpur',
      'Lakhimpur Kheri',
      'Lucknow',
      'Mathura',
      'Meerut',
      'Moradabad',
      'Muzaffarnagar',
      'Noida',
      'Saharanpur',
      'Shahjahanpur',
      'Varanasi',
    ],
    'Uttarakhand': [
      'Dehradun',
      'Haldwani',
      'Haridwar',
      'Kashipur',
      'Rishikesh',
      'Roorkee',
      'Rudrapur',
    ],
    'West Bengal': [
      'Asansol',
      'Baharampur',
      'Bardhaman',
      'Darjeeling',
      'Durgapur',
      'Habra',
      'Howrah',
      'Kharagpur',
      'Kolkata',
      'Malda',
      'Midnapore',
      'Siliguri',
    ],
  };
  List<String> get _states => _stateCityMap.keys.toList()..sort();
  List<String> _getCitiesForState(String? s) =>
      (s != null && _stateCityMap.containsKey(s))
      ? (List<String>.from(_stateCityMap[s]!)..sort())
      : [];

  @override
  void initState() {
    super.initState();
    _countryCtrl.text = 'India';
    _loadSavedAddresses();
    _loadBusinessDetails();
    _loadRemoteAddresses();
  }

  @override
  void dispose() {
    for (final c in [
      _customerNameCtrl,
      _customerPhoneCtrl,
      _addressLine1Ctrl,
      _addressLine2Ctrl,
      _addressLine3Ctrl,
      _cityCtrl,
      _stateCtrl,
      _countryCtrl,
      _pincodeCtrl,
    ])
      c.dispose();
    super.dispose();
  }

  // ═══ MODEL ═══
  CustomerAddress _buildAddressFromForm() => CustomerAddress(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    name: _customerNameCtrl.text.trim(),
    phone: _customerPhoneCtrl.text.trim(),
    address1: _addressLine1Ctrl.text.trim(),
    address2: _addressLine2Ctrl.text.trim(),
    address3: _addressLine3Ctrl.text.trim(),
    city: _selectedCity ?? '',
    state: _selectedState ?? '',
    country: 'India',
    pincode: _pincodeCtrl.text.trim(),
  );

  // ═══ LOCAL STORAGE ═══
  Future<void> _loadSavedAddresses() async {
    try {
      final js = await _storage.read(key: _storageKey);
      if (js == null) return;
      final list = (jsonDecode(js) as List)
          .map((e) => CustomerAddress.fromJson(e))
          .toList();
      setState(() {
        _savedAddresses = list;
        if (_savedAddresses.isNotEmpty) _selectedIndex = 0;
      });
    } catch (e) {
      debugPrint('Load local addresses error: $e');
    }
  }

  Future<void> _saveAddressesToStorage() async {
    await _storage.write(
      key: _storageKey,
      value: jsonEncode(_savedAddresses.map((e) => e.toJson()).toList()),
    );
  }

  // ═══ REMOTE SYNC ═══
  Future<void> _loadRemoteAddresses() async {
    final uid = _userData?.userId;
    if (uid == null || uid.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final remoteList = await ApiService().fetchCustomerAddresses(userId: uid);
      if (!mounted || remoteList.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final addresses = remoteList
          .map((e) => CustomerAddress.fromServerJson(e))
          .toList();
      setState(() {
        _savedAddresses = addresses;
        if (_savedAddresses.isNotEmpty && _selectedIndex == null)
          _selectedIndex = 0;
      });
      await _saveAddressesToStorage(); // cache locally
    } catch (e) {
      debugPrint('Remote address load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ═══ BUSINESS DETAILS (for checkout) ═══
  Future<void> _loadBusinessDetails() async {
    try {
      final js = await _storage.read(key: _businessStorageKey);
      if (js == null) return;
      final d = jsonDecode(js) as Map<String, dynamic>;
      final biz = (d['storeName'] ?? d['businessName'] ?? '').toString().trim();
      final street = (d['addressLine1'] ?? d['address'] ?? '')
          .toString()
          .trim();
      final city = (d['city'] ?? '').toString().trim();
      final state = (d['state'] ?? '').toString().trim();
      final pin = (d['pincode'] ?? '').toString().trim();
      final phone = (d['phone'] ?? '').toString().trim();
      final owner = (d['ownerName'] ?? '').toString().trim();
      String addr = [
        street,
        city,
        state,
        'India',
      ].where((s) => s.isNotEmpty).join(', ');
      if (pin.isNotEmpty) addr += ' - $pin';
      final lines = <String>[];
      if (addr.isNotEmpty) lines.add(addr);
      if (phone.isNotEmpty) lines.add('Phone: $phone');
      if (owner.isNotEmpty) lines.add('Owner: $owner');
      setState(() {
        _businessAddressLabel = biz.isNotEmpty ? biz : 'Your Business';
        _businessAddressText = lines.isNotEmpty
            ? lines.join('\n')
            : 'Business address not provided';
      });
    } catch (e) {
      debugPrint('Load business error: $e');
    }
  }

  // ═══ SAVE ADDRESS (local + server) ═══
  Future<void> _onSaveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedState == null || _selectedState!.isEmpty) {
      Get.snackbar(
        'State Required',
        'Please select a state.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    if (_selectedCity == null || _selectedCity!.isEmpty) {
      Get.snackbar(
        'City Required',
        'Please select a city.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final newAddr = _buildAddressFromForm();
      // Optimistic UI
      _savedAddresses.insert(0, newAddr);
      _selectedIndex = 0;
      await _saveAddressesToStorage();
      // Server sync
      final uid = _userData?.userId;
      if (uid != null && uid.trim().isNotEmpty) {
        final result = await ApiService().addCustomerAddress(
          userId: uid,
          address: newAddr.toServerJson(),
        );
        if (result['success'] == true && result['address'] != null) {
          // Update with server-generated ID if different
          final serverId = result['address']['id'] ?? newAddr.id;
          if (serverId != newAddr.id && _savedAddresses.isNotEmpty) {
            _savedAddresses[0] = _savedAddresses[0].copyWith(id: serverId);
            await _saveAddressesToStorage();
          }
        }
      }
      // Clear form
      _customerNameCtrl.clear();
      _customerPhoneCtrl.clear();
      _addressLine1Ctrl.clear();
      _addressLine2Ctrl.clear();
      _addressLine3Ctrl.clear();
      _selectedState = null;
      _stateCtrl.clear();
      _stateFieldKey = UniqueKey();
      _selectedCity = null;
      _cityCtrl.clear();
      _cityFieldKey = UniqueKey();
      _pincodeCtrl.clear();
      _countryCtrl.text = 'India';
      if (!mounted) return;
      setState(() {});
      Get.snackbar(
        "Address saved",
        "Customer delivery address has been added.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ═══ DELETE ADDRESS (local + server) ═══
  void _onDeleteAddress(int index) async {
    final item = _savedAddresses[index];
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text(
          "Remove address",
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        content: Text(
          'Remove delivery address for "${item.name}"?',
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
      if (_savedAddresses.isEmpty)
        _selectedIndex = null;
      else if (_selectedIndex != null &&
          _selectedIndex! >= _savedAddresses.length)
        _selectedIndex = _savedAddresses.length - 1;
    });
    await _saveAddressesToStorage();
    // Server delete
    final uid = _userData?.userId;
    if (uid != null && uid.trim().isNotEmpty) {
      await ApiService().deleteCustomerAddress(userId: uid, addressId: item.id);
    }
  }

  // ═══ CHECKOUT CONTINUE ═══
  void _onContinueCheckout() {
    if (_selectedIndex == null || _savedAddresses.isEmpty) {
      Get.snackbar(
        "Select address",
        "Please select a delivery address.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    final s = _savedAddresses[_selectedIndex!];
    Get.snackbar(
      "Address selected",
      "Delivering to ${s.name}, ${s.city}.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
    final addr =
        [
          s.fullAddress,
          s.city,
          s.state,
          s.country,
        ].where((e) => e.trim().isNotEmpty).join(', ') +
        (s.pincode.isNotEmpty ? ' - ${s.pincode}' : '');
    final custText = [
      addr,
      'Phone: ${s.phone}',
    ].where((e) => e.isNotEmpty).join('\n');
    Get.to(
      () => FinalCheckoutPage(
        userData: _userData,
        businessAddressLabel: _businessAddressLabel ?? 'Your Business',
        businessAddressText: _businessAddressText ?? '',
        customerAddressLabel: s.name,
        customerAddressText: custText,
      ),
    );
  }

  Future<void> _onUpdateFromDrawer() async {
    if (_savedAddresses.isEmpty) {
      Get.snackbar(
        "No address",
        "Add at least one address.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }
    await _saveAddressesToStorage();
    Get.snackbar(
      "Updated",
      "Customer address list updated.",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  // ═══ BUILD ═══
  @override
  Widget build(BuildContext context) {
    final fromDrawer = widget.fromDrawer;
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
            if (!fromDrawer)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: CheckoutStepHeader(currentStep: 2),
              ),
            if (!fromDrawer) _buildInfoBanner(),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
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
                      'Syncing addresses\u2026',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Poppins',
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
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

  Widget _buildInfoBanner() => Container(
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
            "Add your customer\u2019s delivery address. You can save multiple addresses and reuse them.",
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

  Widget _buildAddNewAddressCard() => Container(
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
            validator: (v) => v!.trim().isEmpty ? 'Name required' : null,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _customerPhoneCtrl,
            label: 'Phone',
            keyboardType: TextInputType.phone,
            icon: Iconsax.call,
            hint: '10-digit',
            inputFormatters: [
              LengthLimitingTextInputFormatter(10),
              FilteringTextInputFormatter.digitsOnly,
            ],
            validator: (v) {
              if (v!.trim().isEmpty) return 'Required';
              if (v.trim().length < 10) return 'Invalid';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressLine1Ctrl,
            label: 'Address Line 1',
            icon: Iconsax.location,
            hint: 'House No. / Building / Street',
            validator: (v) => v!.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressLine2Ctrl,
            label: 'Address Line 2',
            icon: Iconsax.location,
            hint: 'Area / Locality (optional)',
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _addressLine3Ctrl,
            label: 'Address Line 3',
            icon: Iconsax.location,
            hint: 'Landmark (optional)',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSearchableDropdown(
                  key: _stateFieldKey,
                  label: 'State',
                  currentValue: _selectedState,
                  options: _states,
                  onSelected: (v) {
                    setState(() {
                      _selectedState = v;
                      _stateCtrl.text = v;
                      _selectedCity = null;
                      _cityCtrl.clear();
                      _cityFieldKey = UniqueKey();
                    });
                  },
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                  icon: Iconsax.map_1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSearchableDropdown(
                  key: _cityFieldKey,
                  label: 'City',
                  currentValue: _selectedCity,
                  options: _getCitiesForState(_selectedState),
                  onSelected: (v) {
                    setState(() {
                      _selectedCity = v;
                      _cityCtrl.text = v;
                    });
                  },
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                  icon: Iconsax.buildings_2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _pincodeCtrl,
                  label: 'Pincode',
                  icon: Iconsax.location_tick,
                  hint: '6-digit',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (v) {
                    if (v!.trim().isEmpty) return 'Required';
                    if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(v.trim()))
                      return 'Invalid';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _countryCtrl,
                  label: 'Country',
                  icon: Iconsax.global,
                  hint: 'India',
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
                    "No saved addresses yet. Add one above.",
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
        Text(
          "Saved Addresses (${_savedAddresses.length})",
          style: const TextStyle(
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
          itemBuilder: (_, i) {
            final a = _savedAddresses[i];
            final sel = _selectedIndex == i;
            final def = i == 0;
            final l1 = a.fullAddress;
            final l2 = [a.city, a.state].where((s) => s.isNotEmpty).join(', ');
            final l3 = [
              a.country,
              a.pincode,
            ].where((s) => s.isNotEmpty).join(' \u2022 ');
            return GestureDetector(
              onTap: () => setState(() => _selectedIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: sel
                      ? accentColor.withValues(alpha: 0.06)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: sel ? accentColor : Colors.grey.shade300,
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Radio<int>(
                      value: i,
                      groupValue: _selectedIndex,
                      onChanged: (v) => setState(() => _selectedIndex = v),
                      activeColor: accentColor,
                      visualDensity: VisualDensity.compact,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  a.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ),
                              if (def)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Default',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: accentColor,
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\ud83d\udcde ${a.phone}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          if (l1.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              l1,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                          if (l2.isNotEmpty)
                            Text(
                              l2,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade700,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          if (l3.isNotEmpty)
                            Text(
                              l3,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                                fontFamily: 'Poppins',
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Iconsax.trash,
                        size: 18,
                        color: Colors.red.shade300,
                      ),
                      onPressed: () => _onDeleteAddress(i),
                      visualDensity: VisualDensity.compact,
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

  Widget _buildBottomBar() {
    final fromDrawer = widget.fromDrawer;
    final hasSel = _selectedIndex != null && _savedAddresses.isNotEmpty;
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
                      "Saved: ${_savedAddresses.length}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontFamily: 'Poppins',
                      ),
                    )
                  : hasSel
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
                    : (hasSel ? _onContinueCheckout : null),
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

  // ═══ FIELD HELPERS ═══
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) => TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    maxLines: maxLines,
    validator: validator,
    inputFormatters: inputFormatters,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: true,
    ),
  );

  Widget _buildSearchableDropdown({
    Key? key,
    required String label,
    required String? currentValue,
    required List<String> options,
    required Function(String) onSelected,
    required String? Function(String?) validator,
    required IconData icon,
    bool enabled = true,
  }) => RawAutocomplete<String>(
    key: key,
    initialValue: TextEditingValue(text: currentValue ?? ''),
    optionsBuilder: (v) => v.text.isEmpty
        ? const Iterable.empty()
        : options.where((o) => o.toLowerCase().contains(v.text.toLowerCase())),
    onSelected: onSelected,
    fieldViewBuilder: (ctx, ctrl, fn, os) {
      if (currentValue != null && ctrl.text.isEmpty && !fn.hasFocus)
        ctrl.text = currentValue;
      return TextFormField(
        controller: ctrl,
        focusNode: fn,
        enabled: enabled,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 18),
          suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          isDense: true,
          hintText: 'Search $label',
          filled: !enabled,
          fillColor: !enabled ? Colors.grey.shade100 : null,
        ),
      );
    },
    optionsViewBuilder: (ctx, onSel, opts) => Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: MediaQuery.of(ctx).size.width - 64,
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: opts.length,
            itemBuilder: (_, i) {
              final o = opts.elementAt(i);
              return ListTile(
                title: Text(
                  o,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                ),
                onTap: () => onSel(o),
              );
            },
          ),
        ),
      ),
    ),
  );
}

// ═══ MODEL (matches web: address_1, address_2, address_3) ═══
class CustomerAddress {
  final String id,
      name,
      phone,
      address1,
      address2,
      address3,
      city,
      state,
      country,
      pincode;
  CustomerAddress({
    required this.id,
    required this.name,
    required this.phone,
    this.address1 = '',
    this.address2 = '',
    this.address3 = '',
    required this.city,
    required this.state,
    this.country = 'India',
    required this.pincode,
  });

  String get fullAddress => [
    address1,
    address2,
    address3,
  ].where((s) => s.trim().isNotEmpty).join(', ');

  CustomerAddress copyWith({String? id}) => CustomerAddress(
    id: id ?? this.id,
    name: name,
    phone: phone,
    address1: address1,
    address2: address2,
    address3: address3,
    city: city,
    state: state,
    country: country,
    pincode: pincode,
  );

  // Local storage format
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'address1': address1,
    'address2': address2,
    'address3': address3,
    'city': city,
    'state': state,
    'country': country,
    'pincode': pincode,
  };
  factory CustomerAddress.fromJson(Map<String, dynamic> j) => CustomerAddress(
    id: j['id'] ?? '',
    name: j['name'] ?? '',
    phone: j['phone'] ?? '',
    address1: j['address1'] ?? j['addressLine'] ?? '',
    address2: j['address2'] ?? '',
    address3: j['address3'] ?? '',
    city: j['city'] ?? '',
    state: j['state'] ?? '',
    country: j['country'] ?? 'India',
    pincode: j['pincode'] ?? '',
  );

  // Server format (matches web: address_1, address_2, address_3)
  Map<String, dynamic> toServerJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'address_1': address1,
    'address_2': address2,
    'address_3': address3,
    'city': city,
    'state': state,
    'pincode': pincode,
  };
  factory CustomerAddress.fromServerJson(Map<String, dynamic> j) =>
      CustomerAddress(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        phone: j['phone'] ?? '',
        address1: j['address_1'] ?? '',
        address2: j['address_2'] ?? '',
        address3: j['address_3'] ?? '',
        city: j['city'] ?? '',
        state: j['state'] ?? '',
        country: 'India',
        pincode: j['pincode'] ?? '',
      );
}
