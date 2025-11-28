import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LanguageController extends GetxController {
  static LanguageController get instance => Get.find();

  final _storage = GetStorage();
  final _langKey = 'selected_language';

  final Rx<Locale> currentLocale = const Locale('en', 'IN').obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedLanguage();
  }

  void _loadSavedLanguage() {
    final saved = _storage.read<String>(_langKey);
    if (saved != null) {
      final parts = saved.split('_'); // "en_IN"
      if (parts.length == 2) {
        final locale = Locale(parts[0], parts[1]);
        currentLocale.value = locale;
        Get.updateLocale(locale);
      }
    }
  }

  void changeLanguage(String langCode, String countryCode) {
    final locale = Locale(langCode, countryCode);
    currentLocale.value = locale;
    Get.updateLocale(locale);
    _storage.write(_langKey, '${langCode}_$countryCode');
  }
}
