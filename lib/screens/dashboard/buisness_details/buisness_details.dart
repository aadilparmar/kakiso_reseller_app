// lib/business_details.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart'; // Requires image_picker package
import 'package:path_provider/path_provider.dart'; // Requires path_provider package
import 'package:path/path.dart' as path; // Requires path package

import 'package:kakiso_reseller_app/models/user.dart';
import 'package:kakiso_reseller_app/screens/dashboard/address/address.dart';
import 'package:kakiso_reseller_app/screens/dashboard/check_out_header/check_out_header.dart';
import 'package:kakiso_reseller_app/screens/dashboard/checkout/checkout.dart';
import 'package:kakiso_reseller_app/services/api_services.dart';
import 'package:kakiso_reseller_app/utils/constants.dart';

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

  // Image Picker
  File? _logoFile;
  final ImagePicker _picker = ImagePicker();

  // Text Controllers
  final TextEditingController _businessNameCtrl = TextEditingController();
  final TextEditingController _ownerNameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _whatsappCtrl = TextEditingController();
  final TextEditingController _addressLine1Ctrl = TextEditingController();
  final TextEditingController _addressLine2Ctrl = TextEditingController();
  final TextEditingController _pincodeCtrl = TextEditingController();
  final TextEditingController _gstinCtrl = TextEditingController();

  // Autocomplete Controllers
  final TextEditingController _stateCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController(
    text: 'India',
  );

  bool _isWhatsAppSame = true;
  bool _isSaving = false;
  bool _hasSavedDetails = false;
  bool _isRemoteLoading = false;
  bool _shipToBusinessAddress = false;

  String? _selectedState;
  String? _selectedCity;

  Key _stateFieldKey = UniqueKey();
  Key _cityFieldKey = UniqueKey();

  // 🔹 DATA: State & City Mapping
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
      'Dwarka',
      'Rohini',
      'Saket',
      'Vasant Kunj',
      'Janakpuri',
      'Laxmi Nagar',
      'Karol Bagh',
      'Connaught Place',
    ],
    'Goa': [
      'Mapusa',
      'Margao',
      'Mormugao',
      'Panaji',
      'Ponda',
      'Vasco da Gama',
      'Bicholim',
      'Curchorem',
    ],
    'Gujarat': [
      'Ahmedabad',
      'Amreli',
      'Anand',
      'Anjar',
      'Bardoli',
      'Bharuch',
      'Bhavnagar',
      'Bhuj',
      'Botad',
      'Dahod',
      'Deesa',
      'Gandhidham',
      'Gandhinagar',
      'Godhra',
      'Gondal',
      'Himmatnagar',
      'Jamnagar',
      'Jetpur',
      'Junagadh',
      'Kalol',
      'Mahesana',
      'Modasa',
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
      'Bahadurgarh',
      'Bhiwani',
      'Charkhi Dadri',
      'Faridabad',
      'Fatehabad',
      'Gurugram',
      'Hansi',
      'Hisar',
      'Jind',
      'Kaithal',
      'Karnal',
      'Kurukshetra',
      'Narnaul',
      'Narwana',
      'Palwal',
      'Panchkula',
      'Panipat',
      'Rewari',
      'Rohtak',
      'Sirsa',
      'Sonipat',
      'Thanesar',
      'Tohana',
      'Yamunanagar',
    ],
    'Himachal Pradesh': [
      'Baddi',
      'Bilaspur',
      'Chamba',
      'Dharamshala',
      'Hamirpur',
      'Kullu',
      'Mandi',
      'Nahan',
      'Paonta Sahib',
      'Shimla',
      'Solan',
      'Sundarnagar',
      'Una',
    ],
    'Jammu and Kashmir': [
      'Anantnag',
      'Baramulla',
      'Jammu',
      'Kathua',
      'Pulwama',
      'Sopore',
      'Srinagar',
      'Udhampur',
    ],
    'Jharkhand': [
      'Adityapur',
      'Bokaro',
      'Chaibasa',
      'Deoghar',
      'Dhanbad',
      'Dumka',
      'Giridih',
      'Hazaribagh',
      'Jamshedpur',
      'Jhumri Tilaiya',
      'Mango',
      'Medininagar',
      'Phusro',
      'Ramgarh',
      'Ranchi',
      'Sahibganj',
    ],
    'Karnataka': [
      'Bagalkot',
      'Belagavi',
      'Ballari',
      'Bengaluru',
      'Bidar',
      'Chikkamagaluru',
      'Chitradurga',
      'Davangere',
      'Dharwad',
      'Gadag',
      'Gangavathi',
      'Hassan',
      'Hospet',
      'Hubballi',
      'Kalaburagi',
      'Kolar',
      'Mandya',
      'Mangaluru',
      'Mysuru',
      'Raichur',
      'Ranebennur',
      'Robertson Pet',
      'Shivamogga',
      'Tumakuru',
      'Udupi',
      'Vijayapura',
    ],
    'Kerala': [
      'Alappuzha',
      'Changanassery',
      'Cherthala',
      'Guruvayur',
      'Kannur',
      'Kasaragod',
      'Kayamkulam',
      'Kochi',
      'Kollam',
      'Kottayam',
      'Kozhikode',
      'Kunnamkulam',
      'Malappuram',
      'Manjeri',
      'Nedumangad',
      'Neyyattinkara',
      'Palakkad',
      'Payyanur',
      'Ponnani',
      'Taliparamba',
      'Thalassery',
      'Thiruvananthapuram',
      'Thrippunithura',
      'Thrissur',
      'Tirur',
      'Vadakara',
    ],
    'Ladakh': ['Leh', 'Kargil'],
    'Lakshadweep': ['Kavaratti', 'Minicoy', 'Andrott'],
    'Madhya Pradesh': [
      'Ashoknagar',
      'Balaghat',
      'Betul',
      'Bhind',
      'Bhopal',
      'Burhanpur',
      'Chhatarpur',
      'Chhindwara',
      'Damoh',
      'Datia',
      'Dewas',
      'Dhar',
      'Guna',
      'Gwalior',
      'Hoshangabad',
      'Indore',
      'Itarsi',
      'Jabalpur',
      'Khandwa',
      'Khargone',
      'Mandsaur',
      'Morena',
      'Murwara',
      'Nagda',
      'Neemuch',
      'Pithampur',
      'Ratlam',
      'Rewa',
      'Sagar',
      'Satna',
      'Sehore',
      'Seoni',
      'Shahdol',
      'Shivpuri',
      'Singrauli',
      'Ujjain',
      'Vidisha',
    ],
    'Maharashtra': [
      'Ahmednagar',
      'Akola',
      'Amravati',
      'Aurangabad',
      'Badlapur',
      'Barshi',
      'Bhiwandi',
      'Bhusawal',
      'Chandrapur',
      'Dhule',
      'Gondia',
      'Ichalkaranji',
      'Jalgaon',
      'Jalna',
      'Kalyan-Dombivli',
      'Kolhapur',
      'Latur',
      'Malegaon',
      'Mira-Bhayandar',
      'Mumbai',
      'Nagpur',
      'Nanded',
      'Nashik',
      'Navi Mumbai',
      'Osmanabad',
      'Panvel',
      'Parbhani',
      'Pune',
      'Sangli',
      'Satara',
      'Solapur',
      'Thane',
      'Ulhasnagar',
      'Vasai-Virar',
      'Wardha',
      'Yavatmal',
    ],
    'Manipur': ['Imphal', 'Thoubal', 'Kakching', 'Ukhrul'],
    'Meghalaya': ['Shillong', 'Tura', 'Jowai', 'Nongstoin'],
    'Mizoram': ['Aizawl', 'Lunglei', 'Saiha', 'Champhai'],
    'Nagaland': [
      'Dimapur',
      'Kohima',
      'Mokokchung',
      'Tuensang',
      'Wokha',
      'Zunheboto',
    ],
    'Odisha': [
      'Balangir',
      'Balasore',
      'Baripada',
      'Bhadrak',
      'Berhampur',
      'Bhubaneswar',
      'Brajrajnagar',
      'Cuttack',
      'Jharsuguda',
      'Jeypore',
      'Puri',
      'Rourkela',
      'Sambalpur',
    ],
    'Puducherry': ['Karaikal', 'Mahe', 'Puducherry', 'Yanam', 'Ozhukarai'],
    'Punjab': [
      'Abohar',
      'Amritsar',
      'Barnala',
      'Batala',
      'Bathinda',
      'Firozpur',
      'Hoshiarpur',
      'Jalandhar',
      'Kapurthala',
      'Khanna',
      'Ludhiana',
      'Malerkotla',
      'Moga',
      'Mohali',
      'Muktsar',
      'Pathankot',
      'Patiala',
      'Phagwara',
      'Rajpura',
    ],
    'Rajasthan': [
      'Ajmer',
      'Alwar',
      'Barmer',
      'Beawar',
      'Bharatpur',
      'Bhilwara',
      'Bhiwadi',
      'Bikaner',
      'Bundi',
      'Chittorgarh',
      'Churu',
      'Dausa',
      'Dholpur',
      'Ganganagar',
      'Hanumangarh',
      'Hindaun',
      'Jaipur',
      'Jaisalmer',
      'Jhunjhunu',
      'Jodhpur',
      'Kishangarh',
      'Kota',
      'Nagaur',
      'Pali',
      'Sawai Madhopur',
      'Sikar',
      'Sirohi',
      'Tonk',
      'Udaipur',
    ],
    'Sikkim': ['Gangtok', 'Namchi', 'Gyalshing', 'Mangan'],
    'Tamil Nadu': [
      'Ambur',
      'Avadi',
      'Chennai',
      'Coimbatore',
      'Cuddalore',
      'Dindigul',
      'Erode',
      'Hosur',
      'Kanchipuram',
      'Karaikudi',
      'Karur',
      'Kumbakonam',
      'Madurai',
      'Nagercoil',
      'Neyveli',
      'Pallavaram',
      'Pudukkottai',
      'Rajapalayam',
      'Salem',
      'Tambaram',
      'Thanjavur',
      'Thoothukudi',
      'Tiruchirappalli',
      'Tirunelveli',
      'Tiruppur',
      'Tiruvannamalai',
      'Vellore',
    ],
    'Telangana': [
      'Adilabad',
      'Hyderabad',
      'Jagtial',
      'Karimnagar',
      'Khammam',
      'Mahbubnagar',
      'Mancherial',
      'Miryalaguda',
      'Nalgonda',
      'Nizamabad',
      'Ramagundam',
      'Secunderabad',
      'Siddipet',
      'Suryapet',
      'Warangal',
    ],
    'Tripura': ['Agartala', 'Dharmanagar', 'Kailasahar', 'Udaipur', 'Ambassa'],
    'Uttar Pradesh': [
      'Agra',
      'Aligarh',
      'Allahabad',
      'Amroha',
      'Ayodhya',
      'Azamgarh',
      'Bahraich',
      'Ballia',
      'Banda',
      'Bareilly',
      'Basti',
      'Budaun',
      'Bulandshahr',
      'Chandausi',
      'Deoria',
      'Etah',
      'Etawah',
      'Faizabad',
      'Farrukhabad',
      'Fatehpur',
      'Firozabad',
      'Ghaziabad',
      'Ghazipur',
      'Gonda',
      'Gorakhpur',
      'Hapur',
      'Hardoi',
      'Hathras',
      'Jaunpur',
      'Jhansi',
      'Kanpur',
      'Kasganj',
      'Khoshambi',
      'Lakhimpur',
      'Lalitpur',
      'Lucknow',
      'Mainpuri',
      'Mathura',
      'Maunath Bhanjan',
      'Meerut',
      'Mirzapur',
      'Modinagar',
      'Moradabad',
      'Muzaffarnagar',
      'Noida',
      'Orai',
      'Pilibhit',
      'Prayagraj',
      'Rae Bareli',
      'Rampur',
      'Saharanpur',
      'Sambhal',
      'Shahjahanpur',
      'Shamli',
      'Sitapur',
      'Sultanpur',
      'Unnao',
      'Varanasi',
    ],
    'Uttarakhand': [
      'Dehradun',
      'Haldwani',
      'Haridwar',
      'Kashipur',
      'Roorkee',
      'Rudrapur',
      'Rishikesh',
      'Nainital',
    ],
    'West Bengal': [
      'Alipurduar',
      'Asansol',
      'Baharampur',
      'Bally',
      'Balurghat',
      'Bankura',
      'Baranagar',
      'Barasat',
      'Bardhaman',
      'Basirhat',
      'Bhatpara',
      'Bidhannagar',
      'Bongaon',
      'Chandannagar',
      'Darjeeling',
      'Durgapur',
      'Haldia',
      'Howrah',
      'Jalpaiguri',
      'Kamarhati',
      'Kharagpur',
      'Kolkata',
      'Krishnanagar',
      'Madhyamgram',
      'Maheshtala',
      'Malda',
      'Medinipur',
      'Naihati',
      'North Dumdum',
      'Panihati',
      'Purulia',
      'Raiganj',
      'Rajarhat',
      'Rajpur Sonarpur',
      'Ranaghat',
      'Serampore',
      'Siliguri',
      'South Dumdum',
      'Titagarh',
      'Uluberia',
    ],
  };

  List<String> get _indianStates => _stateCityMap.keys.toList()..sort();

  List<String> get _availableCities {
    if (_selectedState != null && _stateCityMap.containsKey(_selectedState)) {
      final cities = List<String>.from(_stateCityMap[_selectedState]!);
      cities.sort();
      return cities;
    }
    return [];
  }

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
  }

  // 🔹 LOGO LOGIC
  Future<void> _pickLogo() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName =
          'business_logo_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
      final String localPath = path.join(appDir.path, fileName);

      final File savedImage = await File(image.path).copy(localPath);

      setState(() {
        _logoFile = savedImage;
      });
    } catch (e) {
      debugPrint('Error picking logo: $e');
      Get.snackbar(
        'Error',
        'Could not pick image',
        backgroundColor: Colors.red.shade100,
      );
    }
  }

  Future<void> _loadSavedDetails() async {
    try {
      final String? jsonStr = await _storage.read(key: _storageKey);
      if (jsonStr == null) return;
      final Map<String, dynamic> data = jsonDecode(jsonStr);
      if (!mounted) return;

      final String savedState = (data['state'] as String?)?.trim() ?? '';
      final String savedCity = (data['city'] as String?)?.trim() ?? '';

      // Load Logo
      final String? logoPath = data['logo_path'];
      if (logoPath != null && logoPath.isNotEmpty) {
        final File file = File(logoPath);
        if (await file.exists()) {
          setState(() => _logoFile = file);
        }
      }

      setState(() {
        _businessNameCtrl.text = data['businessName'] ?? _businessNameCtrl.text;
        _ownerNameCtrl.text = data['ownerName'] ?? _ownerNameCtrl.text;
        _phoneCtrl.text = data['phone'] ?? '';
        _whatsappCtrl.text = data['whatsapp'] ?? '';
        _emailCtrl.text = data['email'] ?? _emailCtrl.text;
        _addressLine1Ctrl.text =
            (data['addressLine1'] as String?)?.trim() ?? '';
        _addressLine2Ctrl.text =
            (data['addressLine2'] as String?)?.trim() ?? '';

        if (savedState.isNotEmpty && _stateCityMap.containsKey(savedState)) {
          _selectedState = savedState;
        } else {
          _selectedState = null;
        }
        _stateCtrl.text = _selectedState ?? savedState;
        _stateFieldKey = UniqueKey();

        if (_selectedState != null &&
            _stateCityMap[_selectedState]!.contains(savedCity)) {
          _selectedCity = savedCity;
        } else {
          _selectedCity = null;
        }
        _cityCtrl.text = _selectedCity ?? savedCity;
        _cityFieldKey = UniqueKey();

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
      final String remoteCity = (remoteData['city'] as String?)?.trim() ?? '';

      setState(() {
        _businessNameCtrl.text =
            remoteData['businessName'] ?? _businessNameCtrl.text;
        _ownerNameCtrl.text = remoteData['ownerName'] ?? _ownerNameCtrl.text;
        _phoneCtrl.text = remoteData['phone'] ?? _phoneCtrl.text;
        _whatsappCtrl.text = remoteData['whatsapp'] ?? _whatsappCtrl.text;
        _emailCtrl.text = remoteData['email'] ?? _emailCtrl.text;
        _addressLine1Ctrl.text =
            (remoteData['addressLine1'] as String?)?.trim() ?? '';
        _addressLine2Ctrl.text =
            (remoteData['addressLine2'] as String?)?.trim() ?? '';

        if (remoteState.isNotEmpty && _stateCityMap.containsKey(remoteState)) {
          _selectedState = remoteState;
        } else {
          _selectedState ??= null;
        }
        _stateCtrl.text = _selectedState ?? remoteState;
        _stateFieldKey = UniqueKey();

        if (_selectedState != null &&
            _stateCityMap[_selectedState]!.contains(remoteCity)) {
          _selectedCity = remoteCity;
        } else {
          _selectedCity = null;
        }
        _cityCtrl.text = _selectedCity ?? remoteCity;
        _cityFieldKey = UniqueKey();

        _pincodeCtrl.text = remoteData['pincode'] ?? _pincodeCtrl.text;
        _gstinCtrl.text = remoteData['gstin'] ?? _gstinCtrl.text;

        _isWhatsAppSame =
            _whatsappCtrl.text.isEmpty || _whatsappCtrl.text == _phoneCtrl.text;
        _hasSavedDetails = true;
      });

      // Merge remote data with local logo path (don't overwrite local logo with null from remote)
      final String? currentJson = await _storage.read(key: _storageKey);
      Map<String, dynamic> currentMap = {};
      if (currentJson != null) currentMap = jsonDecode(currentJson);

      remoteData['logo_path'] =
          currentMap['logo_path']; // Preserve local logo path

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

    final String line1 = _addressLine1Ctrl.text.trim();
    final String line2 = _addressLine2Ctrl.text.trim();
    String combinedAddress = line1;
    if (line2.isNotEmpty) {
      combinedAddress = combinedAddress.isEmpty
          ? line2
          : '$combinedAddress, $line2';
    }

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
      "city": _selectedCity,
      "state": _selectedState,
      "country": 'India',
      "pincode": _pincodeCtrl.text.trim(),
      "gstin": _gstinCtrl.text.trim(),
      "logo_path": _logoFile?.path, // Saved locally
    };

    try {
      await _storage.write(key: _storageKey, value: jsonEncode(payload));
      if (_currentUser?.userId != null) {
        await ApiService.updateBusinessDetails(
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
        (_selectedCity != null && _selectedCity!.trim().isNotEmpty) &&
        (_selectedState != null && _selectedState!.trim().isNotEmpty) &&
        _pincodeCtrl.text.trim().isNotEmpty;

    if (!isDetailsComplete) {
      _showMissingDetailsDialog();
      return;
    }

    final line1 = _addressLine1Ctrl.text.trim();
    final line2 = _addressLine2Ctrl.text.trim();
    final city = _selectedCity!.trim();
    final state = _selectedState!.trim();
    final pin = _pincodeCtrl.text.trim();

    String fullFormattedAddress = [
      line1,
      line2,
      city,
      state,
      'India',
    ].where((s) => s.isNotEmpty).join(', ');
    if (pin.isNotEmpty) fullFormattedAddress += ' - $pin';

    if (_shipToBusinessAddress) {
      Get.to(
        () => FinalCheckoutPage(
          userData: _currentUser,
          businessAddressLabel: _businessNameCtrl.text.trim(),
          businessAddressText: fullFormattedAddress,
          customerAddressLabel: "${_ownerNameCtrl.text.trim()} (Self)",
          customerAddressText: fullFormattedAddress,
          isSelfShip: true,
        ),
      );
    } else {
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
                'To proceed with your order, you must first add your business details (City, State, Pincode).',
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

  Widget _buildSearchableDropdown({
    Key? key,
    required String label,
    required String? currentValue,
    required List<String> options,
    required Function(String) onSelected,
    required String? Function(String?) validator,
    required IconData icon,
    bool enabled = true,
  }) {
    return RawAutocomplete<String>(
      key: key,
      initialValue: TextEditingValue(text: currentValue ?? ''),
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text == '') {
          return const Iterable<String>.empty();
        }
        return options.where((String option) {
          return option.toLowerCase().contains(
            textEditingValue.text.toLowerCase(),
          );
        });
      },
      onSelected: onSelected,
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
            if (currentValue != null &&
                textEditingController.text.isEmpty &&
                focusNode.hasFocus == false) {
              textEditingController.text = currentValue;
            }
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              enabled: enabled,
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon, size: 18),
                suffixIcon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
                hintText: 'Search $label',
                filled: !enabled,
                fillColor: !enabled ? Colors.grey.withValues(alpha: 0.1) : null,
              ),
              validator: validator,
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: MediaQuery.of(context).size.width - 64,
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    title: Text(
                      option,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                      ),
                    ),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
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
                            // 📸 1. LOGO SECTION (OPTIONAL)
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
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                        image: _logoFile != null
                                            ? DecorationImage(
                                                image: FileImage(_logoFile!),
                                                fit: BoxFit.cover,
                                              )
                                            : null,
                                      ),
                                      child: _logoFile == null
                                          ? const Icon(
                                              Iconsax.camera,
                                              color: Colors.grey,
                                              size: 30,
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "Tap to upload logo",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    "This logo will be displayed on your invoices and generated PDFs.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

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
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(10),
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: (v) => v!.trim().length < 10
                                        ? 'Invalid phone'
                                        : null,
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
                                        onChanged: (val) => setState(() {
                                          _isWhatsAppSame = val ?? true;
                                          if (_isWhatsAppSame) {
                                            _whatsappCtrl.text =
                                                _phoneCtrl.text;
                                          }
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
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(10),
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
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
                                  _buildSearchableDropdown(
                                    key: _stateFieldKey,
                                    label: 'State',
                                    icon: Iconsax.map,
                                    currentValue: _selectedState,
                                    options: _indianStates,
                                    onSelected: (String selection) {
                                      setState(() {
                                        _selectedState = selection;
                                        _stateCtrl.text = selection;
                                        _selectedCity = null;
                                        _cityCtrl.clear();
                                        _cityFieldKey = UniqueKey();
                                      });
                                    },
                                    validator: (value) {
                                      if (value == null || value.isEmpty)
                                        return 'Required';
                                      if (!_indianStates.contains(value))
                                        return 'Select valid state';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  _buildSearchableDropdown(
                                    key: _cityFieldKey,
                                    label: 'City',
                                    icon: Iconsax.location5,
                                    currentValue: _selectedCity,
                                    enabled: _selectedState != null,
                                    options: _availableCities,
                                    onSelected: (String selection) {
                                      setState(() {
                                        _selectedCity = selection;
                                        _cityCtrl.text = selection;
                                      });
                                    },
                                    validator: (value) {
                                      if (_selectedState == null) return null;
                                      if (value == null || value.isEmpty)
                                        return 'Required';
                                      if (!_availableCities.contains(value))
                                        return 'Select valid city';
                                      return null;
                                    },
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
                                          inputFormatters: [
                                            LengthLimitingTextInputFormatter(6),
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty)
                                              return 'Required';
                                            final regex = RegExp(
                                              r'^[1-9][0-9]{5}$',
                                            );
                                            if (!regex.hasMatch(v.trim()))
                                              return 'Invalid Pincode';
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
                            // 📄 GST SECTION (OPTIONAL - REMOVED VISIBLE 'OPTIONAL' LABEL)
                            _buildSectionCard(
                              title: 'GST & Compliance',
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller: _gstinCtrl,
                                    label: 'GSTIN',
                                    hint: 'Eg. 22AAAAA0000A1Z5',
                                    icon: Iconsax.document_text,
                                    textCapitalization:
                                        TextCapitalization.characters,
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
    final state = _selectedState ?? _stateCtrl.text.trim();
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
              if (title != 'GST & Compliance' && title != 'Business Logo')
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
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
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
