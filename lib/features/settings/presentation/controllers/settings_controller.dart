/// SettingsController — GetX Controller
/// Manages user preferences: speed unit, theme, language, speed alerts.
/// Persists settings using Shared Preferences.

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/gps_utils.dart';

class SettingsController extends GetxController {
  late final SharedPreferences _prefs;

  // --------------------------------------------------------------------------
  // Reactive state
  // --------------------------------------------------------------------------
  final speedUnit = SpeedUnit.kmh.obs;
  final isDarkMode = true.obs;
  final locale = const Locale('en').obs;

  // Speed Limit Alerts (Phase 7)
  /// Whether the audio speed limit warning is active
  final speedAlertEnabled = false.obs;

  /// Speed limit threshold in km/h (converted to mph in UI if user uses mph)
  final speedLimitKmh = 120.0.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    // Load speed unit
    final unitIndex = _prefs.getInt('speedUnit') ?? 0;
    speedUnit.value = SpeedUnit.values[unitIndex];

    // Load theme
    isDarkMode.value = _prefs.getBool('isDarkMode') ?? true;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);

    // Load locale
    final localeCode = _prefs.getString('locale') ?? 'en';
    locale.value = Locale(localeCode);
    Get.updateLocale(locale.value);

    // Load speed alerts
    speedAlertEnabled.value = _prefs.getBool('speedAlertEnabled') ?? false;
    speedLimitKmh.value = _prefs.getDouble('speedLimitKmh') ?? 120.0;
  }

  // --------------------------------------------------------------------------
  // Speed unit
  // --------------------------------------------------------------------------

  void setSpeedUnit(SpeedUnit unit) {
    speedUnit.value = unit;
    _prefs.setInt('speedUnit', unit.index);
  }

  void toggleSpeedUnit() {
    final newUnit =
        speedUnit.value == SpeedUnit.kmh ? SpeedUnit.mph : SpeedUnit.kmh;
    setSpeedUnit(newUnit);
  }

  String get speedUnitLabel =>
      speedUnit.value == SpeedUnit.kmh ? 'km/h' : 'mph';

  // --------------------------------------------------------------------------
  // Theme
  // --------------------------------------------------------------------------

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _prefs.setBool('isDarkMode', isDarkMode.value);
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  // --------------------------------------------------------------------------
  // Language
  // --------------------------------------------------------------------------

  void setLocale(Locale l) {
    locale.value = l;
    _prefs.setString('locale', l.languageCode);
    Get.updateLocale(l);
  }

  // --------------------------------------------------------------------------
  // Speed Limit Alerts (Phase 7)
  // --------------------------------------------------------------------------

  void toggleSpeedAlert() {
    speedAlertEnabled.value = !speedAlertEnabled.value;
    _prefs.setBool('speedAlertEnabled', speedAlertEnabled.value);
  }

  void setSpeedLimit(double kmh) {
    speedLimitKmh.value = kmh;
    _prefs.setDouble('speedLimitKmh', kmh);
  }

  // --------------------------------------------------------------------------
  // Supported locales
  // --------------------------------------------------------------------------

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
