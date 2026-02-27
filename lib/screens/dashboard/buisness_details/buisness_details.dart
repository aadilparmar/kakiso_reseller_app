// lib/screens/dashboard/buisness_details/buisness_details.dart
// v2: Old UI preserved + web-synced fields (Store, PAN, Bank, Signature)
// Uses /kakiso/v1/business REST API (same user_meta as web dashboard)

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/address/address.dart';
import 'package:kakiso_reseller_app/screens/dashboard/check_out_header/check_out_header.dart';
import 'package:kakiso_reseller_app/screens/dashboard/checkout/checkout.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

// ═══════════════════════════════════════════════════════════════════
// SIGNATURE PAD (built-in, no package needed)
// ═══════════════════════════════════════════════════════════════════

class SignaturePad extends StatefulWidget {
  final double height;
  final String? existingSignatureBase64;
  const SignaturePad({
    super.key,
    this.height = 150,
    this.existingSignatureBase64,
  });
  @override
  State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _cur = [];
  bool _hasDrawn = false, _showCanvas = false;
  bool get hasSignature =>
      _hasDrawn || (widget.existingSignatureBase64?.isNotEmpty ?? false);

  void clear() => setState(() {
    _strokes.clear();
    _cur = [];
    _hasDrawn = false;
  });

  Future<String?> toBase64() async {
    if (!_hasDrawn) return widget.existingSignatureBase64;
    try {
      final rec = ui.PictureRecorder();
      final canvas = Canvas(rec);
      final paint = Paint()
        ..color = const Color(0xFF0f172a)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      for (final s in _strokes) {
        if (s.length < 2) continue;
        final p = Path()..moveTo(s.first.dx, s.first.dy);
        for (int i = 1; i < s.length; i++) p.lineTo(s[i].dx, s[i].dy);
        canvas.drawPath(p, paint);
      }
      final img = await rec.endRecording().toImage(380, widget.height.toInt());
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      if (bd == null) return null;
      return 'data:image/png;base64,${base64Encode(bd.buffer.asUint8List())}';
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasEx = widget.existingSignatureBase64?.isNotEmpty ?? false;
    if (hasEx && !_showCanvas) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.green.shade300, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Image.memory(
                base64Decode(
                  widget.existingSignatureBase64!.replaceFirst(
                    'data:image/png;base64,',
                    '',
                  ),
                ),
                height: widget.height - 20,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text(
                  'Signature saved',
                  style: TextStyle(color: Colors.green),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 4),
              const Text(
                'Signature saved',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() {
                  _showCanvas = true;
                  _hasDrawn = false;
                  _strokes.clear();
                }),
                child: const Text(
                  'UPDATE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: _hasDrawn ? Colors.blue.shade300 : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: GestureDetector(
            onPanStart: (d) => setState(() {
              _cur = [d.localPosition];
              _hasDrawn = true;
            }),
            onPanUpdate: (d) => setState(() => _cur.add(d.localPosition)),
            onPanEnd: (_) => setState(() {
              _strokes.add(List.from(_cur));
              _cur = [];
            }),
            child: CustomPaint(
              painter: _SigPainter(_strokes, _cur),
              child: _strokes.isEmpty && !_hasDrawn
                  ? const Center(
                      child: Text(
                        'SIGN HERE',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (hasEx)
              TextButton(
                onPressed: () => setState(() {
                  _showCanvas = false;
                  _hasDrawn = false;
                  _strokes.clear();
                }),
                child: const Text(
                  'CANCEL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            const Spacer(),
            if (_hasDrawn)
              TextButton.icon(
                onPressed: clear,
                icon: const Icon(Icons.refresh, size: 16, color: Colors.red),
                label: const Text(
                  'CLEAR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SigPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> cur;
  _SigPainter(this.strokes, this.cur);
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0xFF0f172a)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final st in strokes) _d(c, st, p);
    _d(c, cur, p);
  }

  void _d(Canvas c, List<Offset> s, Paint p) {
    if (s.length < 2) return;
    final pp = Path()..moveTo(s.first.dx, s.first.dy);
    for (int i = 1; i < s.length; i++) pp.lineTo(s[i].dx, s[i].dy);
    c.drawPath(pp, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter o) => true;
}

// ═══════════════════════════════════════════════════════════════════
// BUSINESS DETAILS PAGE
// ═══════════════════════════════════════════════════════════════════

class BusinessDetailsPage extends StatefulWidget {
  final UserData? userData;
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
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _storageKey = 'business_details';
  UserData? _currentUser;
  File? _logoFile;
  final ImagePicker _picker = ImagePicker();

  // Controllers (old + new)
  final _storeNameCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _addressLine1Ctrl = TextEditingController();
  final _addressLine2Ctrl = TextEditingController();
  final _addressLine3Ctrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _acNumberCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _upiCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'India');

  bool _isWhatsAppSame = true,
      _isSaving = false,
      _hasSavedDetails = false,
      _isRemoteLoading = false,
      _shipToBusinessAddress = false;
  String? _selectedState, _selectedCity, _resellerId, _existingSignature;
  Key _stateFieldKey = UniqueKey(), _cityFieldKey = UniqueKey();
  final GlobalKey<SignaturePadState> _sigKey = GlobalKey<SignaturePadState>();

  // State-City map (keep your existing one — this is a subset)
  final Map<String, List<String>> _stateCityMap = {
    'Gujarat': [
      'Ahmedabad',
      'Surat',
      'Vadodara',
      'Rajkot',
      'Bhavnagar',
      'Jamnagar',
      'Junagadh',
      'Gandhinagar',
      'Anand',
      'Nadiad',
      'Morbi',
      'Mehsana',
      'Bharuch',
      'Navsari',
      'Valsad',
      'Vapi',
      'Gandhidham',
      'Bhuj',
      'Surendranagar',
      'Porbandar',
      'Palanpur',
      'Godhra',
    ],
    'Maharashtra': [
      'Mumbai',
      'Pune',
      'Nagpur',
      'Thane',
      'Nashik',
      'Aurangabad',
      'Solapur',
      'Kolhapur',
      'Amravati',
      'Navi Mumbai',
      'Sangli',
      'Jalgaon',
      'Akola',
      'Latur',
      'Dhule',
      'Ahmednagar',
      'Chandrapur',
      'Parbhani',
      'Ichalkaranji',
      'Jalna',
    ],
    'Rajasthan': [
      'Jaipur',
      'Jodhpur',
      'Kota',
      'Bikaner',
      'Ajmer',
      'Udaipur',
      'Bhilwara',
      'Alwar',
      'Bharatpur',
      'Sikar',
      'Pali',
      'Sri Ganganagar',
      'Hanumangarh',
    ],
    'Uttar Pradesh': [
      'Lucknow',
      'Kanpur',
      'Agra',
      'Varanasi',
      'Allahabad',
      'Meerut',
      'Bareilly',
      'Aligarh',
      'Moradabad',
      'Saharanpur',
      'Gorakhpur',
      'Noida',
      'Ghaziabad',
      'Firozabad',
      'Jhansi',
      'Muzaffarnagar',
      'Mathura',
    ],
    'Delhi': ['New Delhi', 'Delhi'],
    'Karnataka': [
      'Bengaluru',
      'Mysuru',
      'Hubli',
      'Mangaluru',
      'Belgaum',
      'Gulbarga',
      'Davanagere',
      'Bellary',
      'Shimoga',
      'Tumkur',
      'Raichur',
      'Bidar',
    ],
    'Tamil Nadu': [
      'Chennai',
      'Coimbatore',
      'Madurai',
      'Tiruchirappalli',
      'Salem',
      'Tirunelveli',
      'Tiruppur',
      'Erode',
      'Vellore',
      'Thoothukudi',
      'Dindigul',
      'Thanjavur',
    ],
    'Telangana': [
      'Hyderabad',
      'Warangal',
      'Nizamabad',
      'Karimnagar',
      'Khammam',
      'Ramagundam',
      'Mahbubnagar',
    ],
    'Andhra Pradesh': [
      'Visakhapatnam',
      'Vijayawada',
      'Guntur',
      'Nellore',
      'Kurnool',
      'Kakinada',
      'Rajahmundry',
      'Tirupati',
      'Kadapa',
      'Anantapur',
      'Eluru',
    ],
    'Kerala': [
      'Thiruvananthapuram',
      'Kochi',
      'Kozhikode',
      'Thrissur',
      'Kollam',
      'Palakkad',
      'Alappuzha',
      'Kannur',
      'Malappuram',
      'Kottayam',
    ],
    'Madhya Pradesh': [
      'Bhopal',
      'Indore',
      'Jabalpur',
      'Gwalior',
      'Ujjain',
      'Sagar',
      'Dewas',
      'Satna',
      'Ratlam',
      'Rewa',
      'Katni',
      'Singrauli',
    ],
    'West Bengal': [
      'Kolkata',
      'Howrah',
      'Durgapur',
      'Asansol',
      'Siliguri',
      'Bardhaman',
      'Malda',
      'Baharampur',
      'Habra',
      'Kharagpur',
    ],
    'Bihar': [
      'Patna',
      'Gaya',
      'Bhagalpur',
      'Muzaffarpur',
      'Purnia',
      'Darbhanga',
      'Arrah',
      'Begusarai',
      'Katihar',
      'Munger',
    ],
    'Punjab': [
      'Ludhiana',
      'Amritsar',
      'Jalandhar',
      'Patiala',
      'Bathinda',
      'Mohali',
      'Pathankot',
      'Hoshiarpur',
      'Moga',
    ],
    'Haryana': [
      'Faridabad',
      'Gurgaon',
      'Panipat',
      'Ambala',
      'Yamunanagar',
      'Rohtak',
      'Hisar',
      'Karnal',
      'Sonipat',
      'Panchkula',
    ],
    'Odisha': [
      'Bhubaneswar',
      'Cuttack',
      'Rourkela',
      'Berhampur',
      'Sambalpur',
      'Puri',
      'Balasore',
      'Baripada',
    ],
    'Chhattisgarh': [
      'Raipur',
      'Bhilai',
      'Bilaspur',
      'Korba',
      'Durg',
      'Rajnandgaon',
      'Raigarh',
    ],
    'Jharkhand': [
      'Ranchi',
      'Jamshedpur',
      'Dhanbad',
      'Bokaro',
      'Deoghar',
      'Hazaribag',
      'Giridih',
    ],
    'Assam': [
      'Guwahati',
      'Silchar',
      'Dibrugarh',
      'Jorhat',
      'Nagaon',
      'Tinsukia',
      'Tezpur',
    ],
    'Uttarakhand': [
      'Dehradun',
      'Haridwar',
      'Roorkee',
      'Haldwani',
      'Rudrapur',
      'Kashipur',
      'Rishikesh',
    ],
    'Himachal Pradesh': [
      'Shimla',
      'Dharamshala',
      'Solan',
      'Mandi',
      'Palampur',
      'Baddi',
      'Nahan',
      'Kullu',
    ],
    'Goa': ['Panaji', 'Margao', 'Vasco da Gama', 'Mapusa', 'Ponda'],
    'Jammu and Kashmir': [
      'Srinagar',
      'Jammu',
      'Anantnag',
      'Baramulla',
      'Sopore',
    ],
    'Tripura': ['Agartala', 'Udaipur', 'Dharmanagar'],
    'Meghalaya': ['Shillong', 'Tura', 'Jowai'],
    'Manipur': ['Imphal', 'Thoubal', 'Bishnupur'],
    'Mizoram': ['Aizawl', 'Lunglei', 'Champhai'],
    'Arunachal Pradesh': ['Itanagar', 'Naharlagun', 'Tawang'],
    'Nagaland': ['Kohima', 'Dimapur', 'Mokokchung'],
    'Sikkim': ['Gangtok', 'Namchi', 'Gyalshing'],
  };
  List<String> get _states => _stateCityMap.keys.toList()..sort();
  List<String> _getCitiesForState(String? s) =>
      (s != null && _stateCityMap.containsKey(s))
      ? (List<String>.from(_stateCityMap[s]!)..sort())
      : [];

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
    if (widget.userData != null) _currentUser = widget.userData;
  }

  @override
  void dispose() {
    for (final c in [
      _storeNameCtrl,
      _businessNameCtrl,
      _ownerNameCtrl,
      _phoneCtrl,
      _emailCtrl,
      _whatsappCtrl,
      _addressLine1Ctrl,
      _addressLine2Ctrl,
      _addressLine3Ctrl,
      _pincodeCtrl,
      _gstinCtrl,
      _panCtrl,
      _bankNameCtrl,
      _acNumberCtrl,
      _ifscCtrl,
      _upiCtrl,
      _stateCtrl,
      _cityCtrl,
      _countryCtrl,
    ])
      c.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final fn =
          'business_logo_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
      final saved = await File(image.path).copy(path.join(dir.path, fn));
      setState(() => _logoFile = saved);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not pick image',
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  Future<void> _loadSavedDetails() async {
    try {
      final jsonStr = await _storage.read(key: _storageKey);
      if (jsonStr == null) return;
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      if (!mounted) return;
      final savedState = (data['state'] as String?)?.trim() ?? '';
      final savedCity = (data['city'] as String?)?.trim() ?? '';
      final logoPath = data['logo_path'] as String?;
      if (logoPath != null && logoPath.isNotEmpty) {
        final f = File(logoPath);
        if (await f.exists()) setState(() => _logoFile = f);
      }
      setState(() {
        _storeNameCtrl.text = data['storeName'] ?? _storeNameCtrl.text;
        _businessNameCtrl.text = data['businessName'] ?? _businessNameCtrl.text;
        _ownerNameCtrl.text = data['ownerName'] ?? _ownerNameCtrl.text;
        _phoneCtrl.text = data['phone'] ?? '';
        _whatsappCtrl.text = data['whatsapp'] ?? '';
        _emailCtrl.text = data['email'] ?? _emailCtrl.text;
        _addressLine1Ctrl.text =
            (data['addressLine1'] as String?)?.trim() ?? '';
        _addressLine2Ctrl.text =
            (data['addressLine2'] as String?)?.trim() ?? '';
        _addressLine3Ctrl.text =
            (data['addressLine3'] as String?)?.trim() ?? '';
        _gstinCtrl.text = data['gstin'] ?? '';
        _panCtrl.text = data['pan'] ?? '';
        _bankNameCtrl.text = data['bankName'] ?? '';
        _acNumberCtrl.text = data['acNumber'] ?? '';
        _ifscCtrl.text = data['ifsc'] ?? '';
        _upiCtrl.text = data['upi'] ?? '';
        if (savedState.isNotEmpty && _stateCityMap.containsKey(savedState))
          _selectedState = savedState;
        else
          _selectedState = null;
        _stateCtrl.text = _selectedState ?? savedState;
        _stateFieldKey = UniqueKey();
        if (_selectedState != null &&
            _stateCityMap[_selectedState]!.contains(savedCity))
          _selectedCity = savedCity;
        else
          _selectedCity = null;
        _cityCtrl.text = _selectedCity ?? savedCity;
        _cityFieldKey = UniqueKey();
        _pincodeCtrl.text = data['pincode'] ?? '';
        _isWhatsAppSame =
            _whatsappCtrl.text.isEmpty || _whatsappCtrl.text == _phoneCtrl.text;
        _hasSavedDetails = true;
      });
    } catch (e) {
      debugPrint('Load saved error: $e');
    }
  }

  Future<void> _loadRemoteDetails() async {
    final userId = _currentUser?.userId;
    if (userId == null || userId.trim().isEmpty) return;
    setState(() => _isRemoteLoading = true);
    try {
      final data = await ApiService().fetchFullBusinessDetails(userId: userId);
      if (data == null || !mounted) return;
      final rs = (data['billing_state'] as String?)?.trim() ?? '';
      final rc = (data['billing_city'] as String?)?.trim() ?? '';
      setState(() {
        _resellerId = data['reseller_id'] ?? '';
        _existingSignature = data['digital_signature'] ?? '';
        _storeNameCtrl.text = data['store_name'] ?? _storeNameCtrl.text;
        _businessNameCtrl.text =
            data['business_name'] ?? _businessNameCtrl.text;
        _gstinCtrl.text = data['gstin'] ?? _gstinCtrl.text;
        _panCtrl.text = data['pan'] ?? _panCtrl.text;
        _bankNameCtrl.text = data['bank_name'] ?? _bankNameCtrl.text;
        _acNumberCtrl.text = data['ac_number'] ?? _acNumberCtrl.text;
        _ifscCtrl.text = data['ifsc'] ?? _ifscCtrl.text;
        _upiCtrl.text = data['upi'] ?? _upiCtrl.text;
        final fn = data['billing_first_name'] ?? data['first_name'] ?? '';
        final ln = data['billing_last_name'] ?? data['last_name'] ?? '';
        if (fn.toString().isNotEmpty) _ownerNameCtrl.text = '$fn $ln'.trim();
        if ((data['billing_phone'] ?? '').toString().isNotEmpty)
          _phoneCtrl.text = data['billing_phone'];
        _emailCtrl.text = data['email'] ?? _emailCtrl.text;
        if ((data['whatsapp'] ?? '').toString().isNotEmpty)
          _whatsappCtrl.text = data['whatsapp'];
        _addressLine1Ctrl.text =
            data['billing_address_1'] ?? _addressLine1Ctrl.text;
        _addressLine2Ctrl.text =
            data['billing_address_2'] ?? _addressLine2Ctrl.text;
        _addressLine3Ctrl.text =
            data['billing_address_3'] ?? _addressLine3Ctrl.text;
        _pincodeCtrl.text = data['billing_postcode'] ?? _pincodeCtrl.text;
        if (rs.isNotEmpty && _stateCityMap.containsKey(rs)) _selectedState = rs;
        _stateCtrl.text = _selectedState ?? rs;
        _stateFieldKey = UniqueKey();
        if (_selectedState != null &&
            _stateCityMap[_selectedState]!.contains(rc))
          _selectedCity = rc;
        _cityCtrl.text = _selectedCity ?? rc;
        _cityFieldKey = UniqueKey();
        _isWhatsAppSame =
            _whatsappCtrl.text.isEmpty || _whatsappCtrl.text == _phoneCtrl.text;
        _hasSavedDetails =
            _storeNameCtrl.text.isNotEmpty ||
            _businessNameCtrl.text.isNotEmpty ||
            _addressLine1Ctrl.text.isNotEmpty;
      });
      final cur = await _storage.read(key: _storageKey);
      Map<String, dynamic> cm = {};
      if (cur != null) cm = jsonDecode(cur);
      final lp = _buildLocalPayload();
      lp['logo_path'] = cm['logo_path'];
      await _storage.write(key: _storageKey, value: jsonEncode(lp));
    } catch (e) {
      debugPrint('Remote load error: $e');
    } finally {
      if (mounted) setState(() => _isRemoteLoading = false);
    }
  }

  Map<String, dynamic> _buildLocalPayload() => {
    'storeName': _storeNameCtrl.text.trim(),
    'businessName': _businessNameCtrl.text.trim(),
    'ownerName': _ownerNameCtrl.text.trim(),
    'phone': _phoneCtrl.text.trim(),
    'whatsapp': _isWhatsAppSame
        ? _phoneCtrl.text.trim()
        : _whatsappCtrl.text.trim(),
    'email': _emailCtrl.text.trim(),
    'addressLine1': _addressLine1Ctrl.text.trim(),
    'addressLine2': _addressLine2Ctrl.text.trim(),
    'addressLine3': _addressLine3Ctrl.text.trim(),
    'city': _selectedCity ?? _cityCtrl.text.trim(),
    'state': _selectedState ?? _stateCtrl.text.trim(),
    'country': 'India',
    'pincode': _pincodeCtrl.text.trim(),
    'gstin': _gstinCtrl.text.trim(),
    'pan': _panCtrl.text.trim(),
    'bankName': _bankNameCtrl.text.trim(),
    'acNumber': _acNumberCtrl.text.trim(),
    'ifsc': _ifscCtrl.text.trim(),
    'upi': _upiCtrl.text.trim(),
    'logo_path': _logoFile?.path,
  };

  // ═══ SAVE (uses new REST API) ═══
  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedState == null || _selectedState!.trim().isEmpty) {
      Get.snackbar(
        'State Required',
        'Please select your state.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    if (_selectedCity == null || _selectedCity!.trim().isEmpty) {
      Get.snackbar(
        'City Required',
        'Please select your city.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    _stateCtrl.text = _selectedState!;
    _cityCtrl.text = _selectedCity!;
    setState(() => _isSaving = true);
    String? sigBase64 = _existingSignature;
    if (_sigKey.currentState != null) {
      final ns = await _sigKey.currentState!.toBase64();
      if (ns != null) sigBase64 = ns;
    }
    final fn = _ownerNameCtrl.text.trim().split(' ');
    final fName = fn.isNotEmpty ? fn[0] : '';
    final lName = fn.length > 1 ? fn.sublist(1).join(' ') : '';
    final serverPayload = <String, dynamic>{
      'store_name': _storeNameCtrl.text.trim(),
      'business_name': _businessNameCtrl.text.trim(),
      'gstin': _gstinCtrl.text.trim().toUpperCase(),
      'pan': _panCtrl.text.trim().toUpperCase(),
      'bank_name': _bankNameCtrl.text.trim(),
      'ac_number': _acNumberCtrl.text.trim(),
      'ifsc': _ifscCtrl.text.trim().toUpperCase(),
      'upi': _upiCtrl.text.trim(),
      'billing_first_name': fName,
      'billing_last_name': lName,
      'billing_phone': _phoneCtrl.text.trim(),
      'billing_address_1': _addressLine1Ctrl.text.trim(),
      'billing_address_2': _addressLine2Ctrl.text.trim(),
      'billing_address_3': _addressLine3Ctrl.text.trim(),
      'billing_city': _selectedCity,
      'billing_state': _selectedState,
      'billing_postcode': _pincodeCtrl.text.trim(),
      'whatsapp': _isWhatsAppSame
          ? _phoneCtrl.text.trim()
          : _whatsappCtrl.text.trim(),
      'first_name': fName,
      'last_name': lName,
    };
    if (sigBase64 != null && sigBase64.isNotEmpty)
      serverPayload['digital_signature'] = sigBase64;
    try {
      await _storage.write(
        key: _storageKey,
        value: jsonEncode(_buildLocalPayload()),
      );
      if (_currentUser?.userId != null)
        await ApiService().saveFullBusinessDetails(
          userId: _currentUser!.userId,
          data: serverPayload,
        );
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
      debugPrint('Save error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ═══ CHECKOUT FLOW CHECKS (same as old) ═══
  void _onContinueFromCheckout() {
    bool ok =
        _storeNameCtrl.text.trim().isNotEmpty &&
        _ownerNameCtrl.text.trim().isNotEmpty &&
        _phoneCtrl.text.trim().isNotEmpty &&
        _addressLine1Ctrl.text.trim().isNotEmpty &&
        (_selectedCity != null && _selectedCity!.trim().isNotEmpty) &&
        (_selectedState != null && _selectedState!.trim().isNotEmpty) &&
        _pincodeCtrl.text.trim().isNotEmpty;
    if (!ok) {
      _showMissingDetailsDialog();
      return;
    }
    final l1 = _addressLine1Ctrl.text.trim();
    final l2 = _addressLine2Ctrl.text.trim();
    final l3 = _addressLine3Ctrl.text.trim();
    final city = _selectedCity!.trim();
    final state = _selectedState!.trim();
    final pin = _pincodeCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    String addr = [
      l1,
      l2,
      l3,
      city,
      state,
      'India',
    ].where((s) => s.isNotEmpty).join(', ');
    if (pin.isNotEmpty) addr += ' - $pin';
    final label =
        '${_storeNameCtrl.text.trim().isNotEmpty ? _storeNameCtrl.text.trim() : _businessNameCtrl.text.trim()} \u2022 $phone';
    if (_shipToBusinessAddress) {
      Get.to(() => CustomerAddressPage(userData: _currentUser));
    } else {
      Get.to(() => CustomerAddressPage(userData: _currentUser));
    }
  }

  void _showMissingDetailsDialog() {
    final m = <String>[];
    if (_storeNameCtrl.text.trim().isEmpty) m.add('Store Name');
    if (_ownerNameCtrl.text.trim().isEmpty) m.add('Owner Name');
    if (_phoneCtrl.text.trim().isEmpty) m.add('Phone');
    if (_addressLine1Ctrl.text.trim().isEmpty) m.add('Address Line 1');
    if (_selectedState == null || _selectedState!.trim().isEmpty)
      m.add('State');
    if (_selectedCity == null || _selectedCity!.trim().isEmpty) m.add('City');
    if (_pincodeCtrl.text.trim().isEmpty) m.add('Pincode');
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Iconsax.info_circle, color: Colors.red.shade400, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Missing Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please fill in the following:',
              style: TextStyle(fontSize: 13, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 8),
            ...m.map(
              (x) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 6, color: Colors.red.shade300),
                    const SizedBox(width: 8),
                    Text(
                      x,
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('OK')),
        ],
      ),
    );
  }

  // ═══ BUILD (same layout as old) ═══
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
        actions: [
          if (_resellerId != null && _resellerId!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0f172a),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _resellerId!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
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
                      'Syncing your saved business details\u2026',
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
                    ? Form(key: _formKey, child: _buildFormBody())
                    : _buildReadOnlyBody(),
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  // ═══ FORM BODY (fromDrawer = true) ═══
  Widget _buildFormBody() {
    return Column(
      children: [
        _buildSectionCard(
          title: 'Business Logo',
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickLogo,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300),
                    image: _logoFile != null
                        ? DecorationImage(
                            image: FileImage(_logoFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _logoFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Iconsax.camera,
                              size: 28,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Upload Logo',
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'Poppins',
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Store & Identity',
          child: Column(
            children: [
              _buildTextField(
                controller: _storeNameCtrl,
                label: 'Store Display Name',
                hint: 'e.g. Kiran Electronics',
                icon: Iconsax.shop,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Store name is required'
                    : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _businessNameCtrl,
                label: 'Legal Business Name',
                hint: 'Registered company name',
                icon: Iconsax.building,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Owner & Contact',
          child: Column(
            children: [
              _buildTextField(
                controller: _ownerNameCtrl,
                label: 'Owner Name',
                hint: 'Your full name',
                icon: Iconsax.user,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _phoneCtrl,
                label: 'Phone',
                hint: '10-digit mobile',
                icon: Iconsax.call,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.trim().length < 10) return 'Enter 10 digits';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _emailCtrl,
                label: 'Email',
                hint: 'your@email.com',
                icon: Iconsax.sms,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _isWhatsAppSame,
                    onChanged: (v) =>
                        setState(() => _isWhatsAppSame = v ?? true),
                    activeColor: accentColor,
                    visualDensity: VisualDensity.compact,
                  ),
                  const Text(
                    'WhatsApp same as phone',
                    style: TextStyle(fontSize: 12, fontFamily: 'Poppins'),
                  ),
                ],
              ),
              if (!_isWhatsAppSame) ...[
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _whatsappCtrl,
                  label: 'WhatsApp Number',
                  hint: '10-digit number',
                  icon: Iconsax.message,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Billing Address',
          child: Column(
            children: [
              _buildTextField(
                controller: _addressLine1Ctrl,
                label: 'Address Line 1',
                hint: 'Shop/Office, Building',
                icon: Iconsax.location,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _addressLine2Ctrl,
                label: 'Address Line 2',
                hint: 'Street, Area',
                icon: Iconsax.location,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _addressLine3Ctrl,
                label: 'Address Line 3',
                hint: 'Landmark (optional)',
                icon: Iconsax.location,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildAutocompleteField(
                      key: _stateFieldKey,
                      controller: _stateCtrl,
                      label: 'State',
                      hint: 'Select',
                      icon: Iconsax.map_1,
                      options: _states,
                      initialValue: _selectedState,
                      onSelected: (v) {
                        setState(() {
                          _selectedState = v;
                          _stateCtrl.text = v;
                          _selectedCity = null;
                          _cityCtrl.text = '';
                          _cityFieldKey = UniqueKey();
                        });
                      },
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildAutocompleteField(
                      key: _cityFieldKey,
                      controller: _cityCtrl,
                      label: 'City',
                      hint: 'Select',
                      icon: Iconsax.buildings_2,
                      options: _getCitiesForState(_selectedState),
                      initialValue: _selectedCity,
                      onSelected: (v) {
                        setState(() {
                          _selectedCity = v;
                          _cityCtrl.text = v;
                        });
                      },
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _pincodeCtrl,
                label: 'Pincode',
                hint: '360001',
                icon: Iconsax.location_tick,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(6),
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(v.trim()))
                    return 'Invalid';
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'GST & Compliance',
          child: Column(
            children: [
              _buildTextField(
                controller: _gstinCtrl,
                label: 'GSTIN',
                hint: '22AAAAA0000A1Z5',
                icon: Iconsax.document_text,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _panCtrl,
                label: 'PAN Number',
                hint: 'ABCDE1234F',
                icon: Iconsax.card,
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Bank Account',
          child: Column(
            children: [
              Text(
                'Optional \u2014 needed for payouts',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _bankNameCtrl,
                label: 'Bank Name',
                hint: 'e.g. State Bank of India',
                icon: Iconsax.bank,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _acNumberCtrl,
                label: 'Account Number',
                hint: 'Your bank A/C',
                icon: Iconsax.card,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _ifscCtrl,
                      label: 'IFSC',
                      hint: 'SBIN0001234',
                      icon: Iconsax.code,
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _upiCtrl,
                      label: 'UPI ID',
                      hint: 'name@upi',
                      icon: Iconsax.money_send,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionCard(
          title: 'Digital Signature',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Required for invoices. Draw your signature below.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              SignaturePad(
                key: _sigKey,
                height: 130,
                existingSignatureBase64: _existingSignature,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══ REUSABLE WIDGETS (same style as old) ═══
  Widget _buildSectionCard({required String title, required Widget child}) {
    final isOpt =
        title == 'GST & Compliance' ||
        title == 'Business Logo' ||
        title == 'Bank Account' ||
        title == 'Digital Signature';
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
              if (!isOpt)
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
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        isDense: true,
      ),
    );
  }

  Widget _buildAutocompleteField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required List<String> options,
    required String? initialValue,
    required void Function(String) onSelected,
    String? Function(String?)? validator,
  }) {
    return Autocomplete<String>(
      key: key,
      initialValue: TextEditingValue(text: initialValue ?? ''),
      optionsBuilder: (v) => v.text.isEmpty
          ? options
          : options.where(
              (o) => o.toLowerCase().contains(v.text.toLowerCase()),
            ),
      onSelected: onSelected,
      fieldViewBuilder: (ctx, ctrl, fn, os) {
        if (ctrl.text.isEmpty && initialValue != null) ctrl.text = initialValue;
        return TextFormField(
          controller: ctrl,
          focusNode: fn,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            suffixIcon: const Icon(Icons.arrow_drop_down),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            isDense: true,
            filled: true,
            fillColor: Colors.grey.withValues(alpha: 0.1),
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

  Widget _buildSavedSummaryCard() {
    final l1 = _addressLine1Ctrl.text.trim();
    final l2 = _addressLine2Ctrl.text.trim();
    final city = _cityCtrl.text.trim();
    final state = _selectedState ?? _stateCtrl.text.trim();
    final pin = _pincodeCtrl.text.trim();
    String addr = [
      l1,
      l2,
      city,
      state,
      'India',
    ].where((s) => s.isNotEmpty).join(', ');
    if (pin.isNotEmpty) addr += ' - $pin';
    final name = _storeNameCtrl.text.trim().isNotEmpty
        ? _storeNameCtrl.text.trim()
        : (_businessNameCtrl.text.isEmpty
              ? 'My Business'
              : _businessNameCtrl.text.trim());
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
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '\u2713 Saved',
                        style: TextStyle(
                          fontSize: 9,
                          fontFamily: 'Poppins',
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (addr.isNotEmpty)
                  Text(
                    addr,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  children: [
                    if (_phoneCtrl.text.trim().isNotEmpty)
                      Text(
                        '\ud83d\udcde ${_phoneCtrl.text.trim()}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    if (_emailCtrl.text.trim().isNotEmpty)
                      Text(
                        '\u2709\ufe0f ${_emailCtrl.text.trim()}',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipToBusinessOption() => Container(
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
      onChanged: (v) => setState(() => _shipToBusinessAddress = v ?? false),
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

  Widget _buildReadOnlyBody() {
    if (_hasSavedDetails)
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

  Widget _buildBottomButton() => SafeArea(
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
