// lib/screens/dashboard/buisness_details/buisness_details.dart
// v3: Lock + Edit Request flow matching web dashboard
// First save = direct. After that = locked → admin approval to edit.
// Bank, Signature, WhatsApp = always editable.

import 'dart:convert';
import 'dart:io';
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
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

// ═══════════════════════════════════════════════════════════════════
// SIGNATURE PAD
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

  // Controllers
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

  // Edit request controllers (for locked fields)
  final _editStoreNameCtrl = TextEditingController();
  final _editBizNameCtrl = TextEditingController();
  final _editGstinCtrl = TextEditingController();
  final _editPanCtrl = TextEditingController();
  final _editOwnerCtrl = TextEditingController();
  final _editPhoneCtrl = TextEditingController();
  final _editAddr1Ctrl = TextEditingController();
  final _editAddr2Ctrl = TextEditingController();
  final _editAddr3Ctrl = TextEditingController();
  final _editCityCtrl = TextEditingController();
  final _editStateCtrl = TextEditingController();
  final _editPinCtrl = TextEditingController();

  bool _isWhatsAppSame = true, _isSaving = false, _hasSavedDetails = false;
  bool _isRemoteLoading = false, _shipToBusinessAddress = false;
  String? _selectedState, _selectedCity, _resellerId, _existingSignature;
  Key _stateFieldKey = UniqueKey(), _cityFieldKey = UniqueKey();
  final GlobalKey<SignaturePadState> _sigKey = GlobalKey<SignaturePadState>();

  // ── LOCK & PENDING STATE ──
  bool _bizLocked = false;
  bool _billingLocked = false;
  bool _hasPendingBizEdit = false;
  bool _hasPendingBillingEdit = false;
  bool _isSubmittingEdit = false;

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
      _editStoreNameCtrl,
      _editBizNameCtrl,
      _editGstinCtrl,
      _editPanCtrl,
      _editOwnerCtrl,
      _editPhoneCtrl,
      _editAddr1Ctrl,
      _editAddr2Ctrl,
      _editAddr3Ctrl,
      _editCityCtrl,
      _editStateCtrl,
      _editPinCtrl,
    ])
      c.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    try {
      final i = await _picker.pickImage(source: ImageSource.gallery);
      if (i == null) return;
      final d = await getApplicationDocumentsDirectory();
      final saved = await File(i.path).copy(
        path.join(
          d.path,
          'biz_logo_${DateTime.now().millisecondsSinceEpoch}${path.extension(i.path)}',
        ),
      );
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
      final js = await _storage.read(key: _storageKey);
      if (js == null) return;
      final d = jsonDecode(js) as Map<String, dynamic>;
      if (!mounted) return;
      final ss = (d['state'] as String?)?.trim() ?? '';
      final sc = (d['city'] as String?)?.trim() ?? '';
      final lp = d['logo_path'] as String?;
      if (lp != null && lp.isNotEmpty) {
        final f = File(lp);
        if (await f.exists()) setState(() => _logoFile = f);
      }
      setState(() {
        _storeNameCtrl.text = d['storeName'] ?? '';
        _businessNameCtrl.text = d['businessName'] ?? '';
        _ownerNameCtrl.text = d['ownerName'] ?? _ownerNameCtrl.text;
        _phoneCtrl.text = d['phone'] ?? '';
        _whatsappCtrl.text = d['whatsapp'] ?? '';
        _emailCtrl.text = d['email'] ?? _emailCtrl.text;
        _addressLine1Ctrl.text = (d['addressLine1'] as String?)?.trim() ?? '';
        _addressLine2Ctrl.text = (d['addressLine2'] as String?)?.trim() ?? '';
        _addressLine3Ctrl.text = (d['addressLine3'] as String?)?.trim() ?? '';
        _gstinCtrl.text = d['gstin'] ?? '';
        _panCtrl.text = d['pan'] ?? '';
        _bankNameCtrl.text = d['bankName'] ?? '';
        _acNumberCtrl.text = d['acNumber'] ?? '';
        _ifscCtrl.text = d['ifsc'] ?? '';
        _upiCtrl.text = d['upi'] ?? '';
        if (ss.isNotEmpty && _stateCityMap.containsKey(ss)) _selectedState = ss;
        _stateCtrl.text = _selectedState ?? ss;
        _stateFieldKey = UniqueKey();
        if (_selectedState != null &&
            _stateCityMap[_selectedState]!.contains(sc))
          _selectedCity = sc;
        _cityCtrl.text = _selectedCity ?? sc;
        _cityFieldKey = UniqueKey();
        _pincodeCtrl.text = d['pincode'] ?? '';
        _isWhatsAppSame =
            _whatsappCtrl.text.isEmpty || _whatsappCtrl.text == _phoneCtrl.text;
        _hasSavedDetails = true;
      });
    } catch (e) {
      debugPrint('Load local error: $e');
    }
  }

  Future<void> _loadRemoteDetails() async {
    final uid = _currentUser?.userId;
    if (uid == null || uid.trim().isEmpty) return;
    setState(() => _isRemoteLoading = true);
    try {
      final d = await ApiService().fetchFullBusinessDetails(userId: uid);
      if (d == null || !mounted) return;
      final rs = (d['billing_state'] as String?)?.trim() ?? '';
      final rc = (d['billing_city'] as String?)?.trim() ?? '';
      setState(() {
        _resellerId = d['reseller_id'] ?? '';
        _existingSignature = d['digital_signature'] ?? '';
        // Lock & pending status
        _bizLocked = d['business_locked'] == true;
        _billingLocked = d['billing_locked'] == true;
        _hasPendingBizEdit = d['has_pending_biz_edit'] == true;
        _hasPendingBillingEdit = d['has_pending_billing_edit'] == true;
        // Fields
        _storeNameCtrl.text = d['store_name'] ?? _storeNameCtrl.text;
        _businessNameCtrl.text = d['business_name'] ?? _businessNameCtrl.text;
        _gstinCtrl.text = d['gstin'] ?? _gstinCtrl.text;
        _panCtrl.text = d['pan'] ?? _panCtrl.text;
        _bankNameCtrl.text = d['bank_name'] ?? _bankNameCtrl.text;
        _acNumberCtrl.text = d['ac_number'] ?? _acNumberCtrl.text;
        _ifscCtrl.text = d['ifsc'] ?? _ifscCtrl.text;
        _upiCtrl.text = d['upi'] ?? _upiCtrl.text;
        final fn = d['billing_first_name'] ?? d['first_name'] ?? '';
        final ln = d['billing_last_name'] ?? d['last_name'] ?? '';
        if (fn.toString().isNotEmpty) _ownerNameCtrl.text = '$fn $ln'.trim();
        if ((d['billing_phone'] ?? '').toString().isNotEmpty)
          _phoneCtrl.text = d['billing_phone'];
        _emailCtrl.text = d['email'] ?? _emailCtrl.text;
        if ((d['whatsapp'] ?? '').toString().isNotEmpty)
          _whatsappCtrl.text = d['whatsapp'];
        _addressLine1Ctrl.text =
            d['billing_address_1'] ?? _addressLine1Ctrl.text;
        _addressLine2Ctrl.text =
            d['billing_address_2'] ?? _addressLine2Ctrl.text;
        _addressLine3Ctrl.text =
            d['billing_address_3'] ?? _addressLine3Ctrl.text;
        _pincodeCtrl.text = d['billing_postcode'] ?? _pincodeCtrl.text;
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

  // ═══ SAVE (first-time or unlocked fields + bank/sig) ═══
  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_bizLocked) {
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
    }
    setState(() => _isSaving = true);
    String? sig = _existingSignature;
    if (_sigKey.currentState != null) {
      final ns = await _sigKey.currentState!.toBase64();
      if (ns != null) sig = ns;
    }
    final fn = _ownerNameCtrl.text.trim().split(' ');
    final fName = fn.isNotEmpty ? fn[0] : '';
    final lName = fn.length > 1 ? fn.sublist(1).join(' ') : '';
    final p = <String, dynamic>{
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
      'billing_city': _selectedCity ?? _cityCtrl.text.trim(),
      'billing_state': _selectedState ?? _stateCtrl.text.trim(),
      'billing_postcode': _pincodeCtrl.text.trim(),
      'whatsapp': _isWhatsAppSame
          ? _phoneCtrl.text.trim()
          : _whatsappCtrl.text.trim(),
      'first_name': fName,
      'last_name': lName,
    };
    if (sig != null && sig.isNotEmpty) p['digital_signature'] = sig;
    try {
      await _storage.write(
        key: _storageKey,
        value: jsonEncode(_buildLocalPayload()),
      );
      if (_currentUser?.userId != null) {
        final result = await ApiService().saveFullBusinessDetails(
          userId: _currentUser!.userId,
          data: p,
        );
        if (!mounted) return;
        if (result['success'] == true) {
          setState(() {
            _hasSavedDetails = true;
            _bizLocked = result['business_locked'] == true;
            _billingLocked = result['billing_locked'] == true;
          });
          Get.snackbar(
            'Success',
            result['message'] ?? 'Saved!',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          if (!widget.fromDrawer)
            Get.to(() => CustomerAddressPage(userData: _currentUser));
        } else {
          Get.snackbar(
            'Error',
            result['message'] ?? 'Save failed',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      }
    } catch (e) {
      debugPrint('Save error: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ═══ SUBMIT EDIT REQUEST (for locked fields) ═══
  Future<void> _submitBizEditRequest() async {
    if (_editStoreNameCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Required',
        'Store name cannot be empty',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    setState(() => _isSubmittingEdit = true);
    try {
      final result = await ApiService().requestBusinessEdit(
        userId: _currentUser!.userId,
        editType: 'business',
        data: {
          'store_name': _editStoreNameCtrl.text.trim(),
          'business_name': _editBizNameCtrl.text.trim(),
          'gstin': _editGstinCtrl.text.trim().toUpperCase(),
          'pan': _editPanCtrl.text.trim().toUpperCase(),
        },
      );
      if (!mounted) return;
      Get.back(); // close bottom sheet
      if (result['success'] == true) {
        setState(() => _hasPendingBizEdit = true);
        Get.snackbar(
          'Submitted',
          result['message'] ?? 'Edit request sent!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Failed',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Biz edit request error: $e');
    } finally {
      if (mounted) setState(() => _isSubmittingEdit = false);
    }
  }

  Future<void> _submitBillingEditRequest() async {
    if (_editAddr1Ctrl.text.trim().isEmpty ||
        _editPhoneCtrl.text.trim().isEmpty) {
      Get.snackbar(
        'Required',
        'Phone and Address are required',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    setState(() => _isSubmittingEdit = true);
    final fn = _editOwnerCtrl.text.trim().split(' ');
    try {
      final result = await ApiService().requestBusinessEdit(
        userId: _currentUser!.userId,
        editType: 'billing',
        data: {
          'billing_first_name': fn.isNotEmpty ? fn[0] : '',
          'billing_last_name': fn.length > 1 ? fn.sublist(1).join(' ') : '',
          'billing_phone': _editPhoneCtrl.text.trim(),
          'billing_address_1': _editAddr1Ctrl.text.trim(),
          'billing_address_2': _editAddr2Ctrl.text.trim(),
          'billing_address_3': _editAddr3Ctrl.text.trim(),
          'billing_city': _editCityCtrl.text.trim(),
          'billing_state': _editStateCtrl.text.trim(),
          'billing_postcode': _editPinCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      Get.back();
      if (result['success'] == true) {
        setState(() => _hasPendingBillingEdit = true);
        Get.snackbar(
          'Submitted',
          result['message'] ?? 'Edit request sent!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Failed',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('Billing edit request error: $e');
    } finally {
      if (mounted) setState(() => _isSubmittingEdit = false);
    }
  }

  void _showBizEditSheet() {
    _editStoreNameCtrl.text = _storeNameCtrl.text;
    _editBizNameCtrl.text = _businessNameCtrl.text;
    _editGstinCtrl.text = _gstinCtrl.text;
    _editPanCtrl.text = _panCtrl.text;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Request Business Edit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Changes will take effect once admin approves.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.amber.shade700,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),
              _editField(_editStoreNameCtrl, 'Store Name', Iconsax.shop),
              const SizedBox(height: 12),
              _editField(
                _editBizNameCtrl,
                'Legal Business Name',
                Iconsax.building,
              ),
              const SizedBox(height: 12),
              _editField(
                _editGstinCtrl,
                'GSTIN',
                Iconsax.document_text,
                cap: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              _editField(
                _editPanCtrl,
                'PAN',
                Iconsax.card,
                cap: TextCapitalization.characters,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmittingEdit ? null : _submitBizEditRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0f172a),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmittingEdit
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'SUBMIT FOR APPROVAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showBillingEditSheet() {
    _editOwnerCtrl.text = _ownerNameCtrl.text;
    _editPhoneCtrl.text = _phoneCtrl.text;
    _editAddr1Ctrl.text = _addressLine1Ctrl.text;
    _editAddr2Ctrl.text = _addressLine2Ctrl.text;
    _editAddr3Ctrl.text = _addressLine3Ctrl.text;
    _editCityCtrl.text = _cityCtrl.text;
    _editStateCtrl.text = _stateCtrl.text;
    _editPinCtrl.text = _pincodeCtrl.text;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Request Billing Edit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Changes will take effect once admin approves.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.amber.shade700,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 16),
              _editField(_editOwnerCtrl, 'Name', Iconsax.user),
              const SizedBox(height: 12),
              _editField(
                _editPhoneCtrl,
                'Phone',
                Iconsax.call,
                keyboard: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _editField(_editAddr1Ctrl, 'Address Line 1', Iconsax.location),
              const SizedBox(height: 12),
              _editField(_editAddr2Ctrl, 'Address Line 2', Iconsax.location),
              const SizedBox(height: 12),
              _editField(_editAddr3Ctrl, 'Address Line 3', Iconsax.location),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _editField(
                      _editCityCtrl,
                      'City',
                      Iconsax.buildings_2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _editField(_editStateCtrl, 'State', Iconsax.map_1),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _editField(
                _editPinCtrl,
                'Pincode',
                Iconsax.location_tick,
                keyboard: TextInputType.number,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmittingEdit
                      ? null
                      : _submitBillingEditRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0f172a),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmittingEdit
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'SUBMIT FOR APPROVAL',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _editField(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? keyboard,
    TextCapitalization cap = TextCapitalization.words,
  }) => TextField(
    controller: c,
    keyboardType: keyboard,
    textCapitalization: cap,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 18),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      isDense: true,
    ),
  );

  // ═══ CHECKOUT CHECKS (same as old) ═══
  void _onContinueFromCheckout() {
    bool ok =
        (_storeNameCtrl.text.trim().isNotEmpty ||
            _businessNameCtrl.text.trim().isNotEmpty) &&
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
    Get.to(() => CustomerAddressPage(userData: _currentUser));
  }

  void _showMissingDetailsDialog() {
    final m = <String>[];
    if (_storeNameCtrl.text.trim().isEmpty &&
        _businessNameCtrl.text.trim().isEmpty)
      m.add('Store/Business Name');
    if (_ownerNameCtrl.text.trim().isEmpty) m.add('Owner Name');
    if (_phoneCtrl.text.trim().isEmpty) m.add('Phone');
    if (_addressLine1Ctrl.text.trim().isEmpty) m.add('Address');
    if (_selectedState == null) m.add('State');
    if (_selectedCity == null) m.add('City');
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
              'Please fill in:',
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

  // ═══ LOCKED FIELD DISPLAY ═══
  Widget _lockedField(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'Poppins',
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : '-',
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Icon(Iconsax.lock_1, size: 14, color: Colors.grey.shade400),
      ],
    ),
  );

  Widget _pendingBanner() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.amber.shade50,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.amber.shade200),
    ),
    child: Row(
      children: [
        Icon(Iconsax.clock, size: 16, color: Colors.amber.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Edit request pending admin approval.',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'Poppins',
              color: Colors.amber.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _requestEditButton(
    String label,
    VoidCallback onTap, {
    bool disabled = false,
  }) => SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: disabled ? null : onTap,
      icon: Icon(disabled ? Iconsax.clock : Iconsax.edit_2, size: 16),
      label: Text(
        disabled ? 'EDIT REQUEST PENDING' : label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
          letterSpacing: 0.5,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: disabled ? Colors.grey : const Color(0xFF0f172a),
        side: BorderSide(
          color: disabled ? Colors.grey.shade300 : const Color(0xFF0f172a),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    ),
  );

  // ═══ BUILD ═══
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
                      'Syncing\u2026',
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

  // ═══ FORM BODY (fromDrawer) ═══
  Widget _buildFormBody() {
    return Column(
      children: [
        // Logo (always editable)
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

        // ── STORE & IDENTITY (lockable) ──
        _buildSectionCard(
          title: 'Store & Identity',
          locked: _bizLocked,
          child: _bizLocked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_hasPendingBizEdit) _pendingBanner(),
                    _lockedField('Store Name', _storeNameCtrl.text),
                    _lockedField('Legal Name', _businessNameCtrl.text),
                    _lockedField('GSTIN', _gstinCtrl.text),
                    _lockedField('PAN', _panCtrl.text),
                    const SizedBox(height: 8),
                    _requestEditButton(
                      'REQUEST EDIT',
                      _showBizEditSheet,
                      disabled: _hasPendingBizEdit,
                    ),
                  ],
                )
              : Column(
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
                    const SizedBox(height: 12),
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

        // ── OWNER & CONTACT (billing lockable for name/phone) ──
        _buildSectionCard(
          title: 'Owner & Contact',
          locked: _billingLocked,
          child: _billingLocked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_hasPendingBillingEdit) _pendingBanner(),
                    _lockedField('Owner', _ownerNameCtrl.text),
                    _lockedField('Phone', _phoneCtrl.text),
                    _lockedField('Email', _emailCtrl.text),
                  ],
                )
              : Column(
                  children: [
                    _buildTextField(
                      controller: _ownerNameCtrl,
                      label: 'Owner Name',
                      hint: 'Your name',
                      icon: Iconsax.user,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _phoneCtrl,
                      label: 'Phone',
                      hint: '10-digit',
                      icon: Iconsax.call,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length < 10) return '10 digits';
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
                        label: 'WhatsApp',
                        hint: '10-digit',
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

        // ── BILLING ADDRESS (lockable) ──
        _buildSectionCard(
          title: 'Billing Address',
          locked: _billingLocked,
          child: _billingLocked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_hasPendingBillingEdit) _pendingBanner(),
                    _lockedField(
                      'Address',
                      [
                        _addressLine1Ctrl.text,
                        _addressLine2Ctrl.text,
                        _addressLine3Ctrl.text,
                      ].where((s) => s.trim().isNotEmpty).join(', '),
                    ),
                    _lockedField('City', _cityCtrl.text),
                    _lockedField('State', _stateCtrl.text),
                    _lockedField('Pincode', _pincodeCtrl.text),
                    const SizedBox(height: 8),
                    _requestEditButton(
                      'REQUEST BILLING EDIT',
                      _showBillingEditSheet,
                      disabled: _hasPendingBillingEdit,
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildTextField(
                      controller: _addressLine1Ctrl,
                      label: 'Address Line 1',
                      hint: 'Shop/Office',
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
                      hint: 'Landmark',
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
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
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
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
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

        // ── BANK (always editable) ──
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
                hint: 'e.g. SBI',
                icon: Iconsax.bank,
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _acNumberCtrl,
                label: 'Account Number',
                hint: 'A/C No',
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

        // ── SIGNATURE (always editable) ──
        _buildSectionCard(
          title: 'Digital Signature',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Required for invoices.',
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

  // ═══ REUSABLE WIDGETS ═══
  Widget _buildSectionCard({
    required String title,
    required Widget child,
    bool locked = false,
  }) {
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
              if (locked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.lock_1,
                        size: 10,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Locked',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else if (!isOpt)
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
  }) => TextFormField(
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
  }) => Autocomplete<String>(
    key: key,
    initialValue: TextEditingValue(text: initialValue ?? ''),
    optionsBuilder: (v) => v.text.isEmpty
        ? options
        : options.where((o) => o.toLowerCase().contains(v.text.toLowerCase())),
    onSelected: onSelected,
    fieldViewBuilder: (ctx, c, fn, os) {
      if (c.text.isEmpty && initialValue != null) c.text = initialValue;
      return TextFormField(
        controller: c,
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
            'Review your shop details. These will be shown to customers.',
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
    final addr =
        [
          _addressLine1Ctrl.text.trim(),
          _addressLine2Ctrl.text.trim(),
          _cityCtrl.text.trim(),
          _selectedState ?? _stateCtrl.text.trim(),
          'India',
        ].where((s) => s.isNotEmpty).join(', ') +
        (_pincodeCtrl.text.trim().isNotEmpty
            ? ' - ${_pincodeCtrl.text.trim()}'
            : '');
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
        "Deliver to you instead of customer.",
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
    if (_hasSavedDetails) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SizedBox(height: 8),
          Text(
            'To update, go to menu \u2192 "Business Details".',
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'Poppins',
              color: Colors.grey,
            ),
          ),
        ],
      );
    }
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
            'Add your business details from the Profile page.',
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
