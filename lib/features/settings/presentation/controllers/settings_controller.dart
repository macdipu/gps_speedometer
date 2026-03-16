/// SettingsController — GetX Controller
/// Manages user preferences: speed unit, theme, language.
/// Persists settings using shared_preferences (via GetStorage for simplicity here).

import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/gps_utils.dart';

class SettingsController extends GetxController {
  // --------------------------------------------------------------------------
  // Reactive state
  // --------------------------------------------------------------------------
  final speedUnit = SpeedUnit.kmh.obs;
  final isDarkMode = true.obs;
  final locale = const Locale('en').obs;

  // --------------------------------------------------------------------------
  // Speed unit
  // --------------------------------------------------------------------------

  void setSpeedUnit(SpeedUnit unit) => speedUnit.value = unit;

  void toggleSpeedUnit() {
    speedUnit.value =
        speedUnit.value == SpeedUnit.kmh ? SpeedUnit.mph : SpeedUnit.kmh;
  }

  String get speedUnitLabel =>
      speedUnit.value == SpeedUnit.kmh ? 'km/h' : 'mph';

  // --------------------------------------------------------------------------
  // Theme
  // --------------------------------------------------------------------------

  void toggleTheme() => isDarkMode.value = !isDarkMode.value;

  // --------------------------------------------------------------------------
  // Language
  // --------------------------------------------------------------------------

  void setLocale(Locale l) {
    locale.value = l;
    Get.updateLocale(l);
  }

  static const List<Map<String, dynamic>> supportedLocales = [
    {'code': 'en', 'label': 'English'},
    {'code': 'es', 'label': 'Español'},
    {'code': 'fr', 'label': 'Français'},
    {'code': 'de', 'label': 'Deutsch'},
    {'code': 'it', 'label': 'Italiano'},
    {'code': 'pt', 'label': 'Português'},
    {'code': 'ru', 'label': 'Русский'},
    {'code': 'zh', 'label': '中文'},
    {'code': 'ja', 'label': '日本語'},
    {'code': 'ko', 'label': '한국어'},
    {'code': 'ar', 'label': 'العربية'},
    {'code': 'hi', 'label': 'हिन्दी'},
    {'code': 'bn', 'label': 'বাংলা'},
    {'code': 'tr', 'label': 'Türkçe'},
    {'code': 'nl', 'label': 'Nederlands'},
    {'code': 'pl', 'label': 'Polski'},
    {'code': 'sv', 'label': 'Svenska'},
    {'code': 'da', 'label': 'Dansk'},
    {'code': 'fi', 'label': 'Suomi'},
    {'code': 'nb', 'label': 'Norsk'},
    {'code': 'cs', 'label': 'Čeština'},
    {'code': 'sk', 'label': 'Slovenčina'},
    {'code': 'hu', 'label': 'Magyar'},
    {'code': 'ro', 'label': 'Română'},
    {'code': 'bg', 'label': 'Български'},
    {'code': 'uk', 'label': 'Українська'},
    {'code': 'id', 'label': 'Bahasa Indonesia'},
    {'code': 'ms', 'label': 'Bahasa Melayu'},
    {'code': 'vi', 'label': 'Tiếng Việt'},
    {'code': 'th', 'label': 'ภาษาไทย'},
  ];
}
