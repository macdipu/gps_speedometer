/// SettingsScreen — configure speed unit, theme, language, and speed alerts.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_theme.dart';
import '../../../../core/utils/gps_utils.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  SettingsScreen({super.key});

  final controller = Get.find<SettingsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: Text('settings'.tr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Speed Unit
          _SettingsSection(
            title: 'speed_unit'.tr,
            child: Obx(() => Row(
                  children: [
                    _UnitChip(
                      label: 'km/h',
                      selected:
                          controller.speedUnit.value == SpeedUnit.kmh,
                      onTap: () =>
                          controller.setSpeedUnit(SpeedUnit.kmh),
                    ),
                    const SizedBox(width: 12),
                    _UnitChip(
                      label: 'mph',
                      selected:
                          controller.speedUnit.value == SpeedUnit.mph,
                      onTap: () =>
                          controller.setSpeedUnit(SpeedUnit.mph),
                    ),
                  ],
                )),
          ),

          const SizedBox(height: 16),

          // Theme
          _SettingsSection(
            title: 'theme'.tr,
            child: Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('dark_mode'.tr,
                        style:
                            const TextStyle(color: AppColors.textPrimary)),
                    Switch(
                      value: controller.isDarkMode.value,
                      onChanged: (_) => controller.toggleTheme(),
                      activeColor: AppColors.primary,
                    ),
                  ],
                )),
          ),

          const SizedBox(height: 16),

          // ── Phase 7: Speed Limit Alerts ──────────────────────────────────
          _SettingsSection(
            title: 'Speed Limit Alert',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Toggle row
                Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Enable audio alert',
                              style: TextStyle(color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 2),
                            Obx(() => Text(
                                  controller.speedAlertEnabled.value
                                      ? 'Speaks when you exceed the limit'
                                      : 'Alert is off',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                )),
                          ],
                        ),
                        Switch(
                          value: controller.speedAlertEnabled.value,
                          onChanged: (_) => controller.toggleSpeedAlert(),
                          activeColor: AppColors.accent,
                        ),
                      ],
                    )),

                const SizedBox(height: 16),

                // Speed limit slider
                Obx(() {
                  final isKmh = controller.speedUnit.value == SpeedUnit.kmh;
                  final limitKmh = controller.speedLimitKmh.value;
                  // Display in user's preferred unit
                  final displayLimit =
                      isKmh ? limitKmh : GpsUtils.kmhToMph(limitKmh);
                  final unit = isKmh ? 'km/h' : 'mph';
                  final minVal = isKmh ? 20.0 : 10.0;
                  final maxVal = isKmh ? 200.0 : 125.0;
                  final displayClamped =
                      displayLimit.clamp(minVal, maxVal);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Speed limit',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: controller.speedAlertEnabled.value
                                  ? AppColors.accent.withOpacity(0.15)
                                  : AppColors.bgCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: controller.speedAlertEnabled.value
                                    ? AppColors.accent
                                    : AppColors.textDisabled,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${displayClamped.toStringAsFixed(0)} $unit',
                              style: TextStyle(
                                color: controller.speedAlertEnabled.value
                                    ? AppColors.accent
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: displayClamped,
                        min: minVal,
                        max: maxVal,
                        divisions: isKmh ? 36 : 23,
                        activeColor: controller.speedAlertEnabled.value
                            ? AppColors.accent
                            : AppColors.textDisabled,
                        inactiveColor:
                            AppColors.textDisabled.withOpacity(0.3),
                        onChanged: controller.speedAlertEnabled.value
                            ? (val) {
                                // Convert back to km/h if user picked mph
                                final kmh = isKmh
                                    ? val
                                    : GpsUtils.mphToKmh(val);
                                controller.setSpeedLimit(kmh);
                              }
                            : null,
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Language
          _SettingsSection(
            title: '${'language'.tr} (${SettingsController.supportedLocales.length}+)',
            child: Obx(() => Column(
                  children: SettingsController.supportedLocales
                      .map((l) => _LanguageTile(
                            code: l['code'] as String,
                            label: l['label'] as String,
                            selected: controller.locale.value.languageCode ==
                                l['code'],
                            onTap: () => controller
                                .setLocale(Locale(l['code'] as String)),
                          ))
                      .toList(),
                )),
          ),

          const SizedBox(height: 32),

          // About
          const Center(
            child: Column(
              children: [
                Icon(Icons.speed, color: AppColors.primary, size: 40),
                SizedBox(height: 8),
                Text('GPS Speedometer',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                SizedBox(height: 4),
                Text('v1.0.0  •  chowdhuryelab',
                    style: TextStyle(
                        color: AppColors.textDisabled, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  const _UnitChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.textDisabled,
            width: 1.5,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String code, label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Text(code.toUpperCase(),
          style: const TextStyle(
              color: AppColors.textDisabled,
              fontSize: 11,
              fontFamily: 'monospace',
              letterSpacing: 1)),
      title: Text(label,
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 14)),
      trailing: selected
          ? const Icon(Icons.check_circle,
              color: AppColors.primary, size: 20)
          : null,
    );
  }
}
