/// SpeedometerScreen
/// The main speedometer UI with tab-based switching between:
/// Digital, Analog, HUD, and Map modes.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_theme.dart';
import '../controllers/speedometer_controller.dart';
import '../widgets/analog_gauge_widget.dart';
import '../widgets/digital_speed_widget.dart';
import '../widgets/hud_overlay_widget.dart';
import '../widgets/map_speedometer_widget.dart';

class SpeedometerScreen extends StatelessWidget {
  SpeedometerScreen({super.key});

  final controller = Get.find<SpeedometerController>();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // HUD mode uses a special full-screen overlay
      if (controller.mode.value == SpeedometerMode.hud) {
        return HudOverlayWidget(controller: controller);
      }

      return Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          title: const Text('GPS Speedometer'),
          actions: [
            // Unit toggle button
            TextButton(
              onPressed: controller.switchUnit,
              child: Obx(() => Text(
                    controller.speedometer.value.unitLabel.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  )),
            ),
          ],
        ),
        body: Column(
          children: [
            // GPS status bar
            Obx(() => _GpsStatusBar(
                  isConnected: controller.isConnected.value,
                  accuracy: controller.speedometer.value.accuracy,
                  error: controller.errorMessage.value,
                )),

            // Mode tabs
            _ModeTabs(controller: controller),

            // Speed display area
            Expanded(
              child: Obx(() {
                switch (controller.mode.value) {
                  case SpeedometerMode.digital:
                    return DigitalSpeedWidget(controller: controller);
                  case SpeedometerMode.analog:
                    return AnalogGaugeWidget(controller: controller);
                  case SpeedometerMode.map:
                    return MapSpeedometerWidget(controller: controller);
                  default:
                    return DigitalSpeedWidget(controller: controller);
                }
              }),
            ),

            // Bottom stats bar
            _StatsBar(controller: controller),
          ],
        ),
      );
    });
  }
}

// ---------------------------------------------------------------------------

class _GpsStatusBar extends StatelessWidget {
  const _GpsStatusBar({
    required this.isConnected,
    required this.accuracy,
    this.error,
  });

  final bool isConnected;
  final double accuracy;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.bgCard,
      child: Row(
        children: [
          Icon(
            Icons.gps_fixed,
            size: 16,
            color: isConnected ? AppColors.primary : AppColors.error,
          ),
          const SizedBox(width: 6),
          Text(
            error != null
                ? 'GPS Error: ${error!}'
                : isConnected
                    ? 'GPS Connected  •  ±${accuracy.toStringAsFixed(0)}m'
                    : 'Connecting...',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.controller});
  final SpeedometerController controller;

  @override
  Widget build(BuildContext context) {
    const modes = [
      (SpeedometerMode.digital, Icons.display_settings, 'Digital'),
      (SpeedometerMode.analog, Icons.speed, 'Analog'),
      (SpeedometerMode.hud, Icons.remove_red_eye, 'HUD'),
      (SpeedometerMode.map, Icons.map, 'Map'),
    ];

    return Container(
      color: AppColors.bgCard,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: modes.map((m) {
          return Obx(() {
            final isActive = controller.mode.value == m.$1;
            return GestureDetector(
              onTap: () => controller.setMode(m.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primary
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(m.$2,
                        size: 16,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      m.$3,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _StatsBar extends StatelessWidget {
  const _StatsBar({required this.controller});
  final SpeedometerController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = controller.speedometer.value;
      return Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        color: AppColors.bgCard,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              label: 'MAX',
              value: s.maxSpeed.toStringAsFixed(1),
              unit: s.unitLabel,
              color: AppColors.accent,
            ),
            _StatItem(
              label: 'ALT',
              value: s.altitude.toStringAsFixed(0),
              unit: 'm',
              color: AppColors.info,
            ),
            _StatItem(
              label: 'HEADING',
              value: s.heading.toStringAsFixed(0),
              unit: '°',
              color: AppColors.primary,
            ),
          ],
        ),
      );
    });
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  final String label, value, unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                letterSpacing: 1.5)),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                  text: value,
                  style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w700)),
              TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
