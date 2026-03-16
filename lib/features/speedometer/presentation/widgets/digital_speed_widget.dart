/// Digital Speed Widget — displays current speed as a large numeric display
/// with animated pulse on speed change.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_theme.dart';
import '../controllers/speedometer_controller.dart';

class DigitalSpeedWidget extends StatelessWidget {
  const DigitalSpeedWidget({super.key, required this.controller});
  final SpeedometerController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = controller.speedometer.value;
      final speed = s.displaySpeed;

      return Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF1A2035), AppColors.bgDark],
            radius: 1.2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Speed value
              TweenAnimationBuilder<double>(
                tween: Tween(end: speed),
                duration: const Duration(milliseconds: 300),
                builder: (_, val, __) => Text(
                  val.toStringAsFixed(0),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 96,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -4,
                    height: 1.0,
                  ),
                ),
              ),

              // Unit label
              Text(
                s.unitLabel.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 18,
                  letterSpacing: 6,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 32),

              // Speed bar
              _SpeedBar(speed: speed, maxDisplay: s.unit.name == 'kmh' ? 220 : 140),
            ],
          ),
        ),
      );
    });
  }
}

class _SpeedBar extends StatelessWidget {
  const _SpeedBar({required this.speed, required this.maxDisplay});
  final double speed;
  final double maxDisplay;

  @override
  Widget build(BuildContext context) {
    final fraction = (speed / maxDisplay).clamp(0.0, 1.0);
    final color = fraction < 0.5
        ? AppColors.gaugeLow
        : fraction < 0.8
            ? AppColors.gaugeMid
            : AppColors.gaugeHigh;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: fraction),
              duration: const Duration(milliseconds: 300),
              builder: (_, val, __) => LinearProgressIndicator(
                value: val,
                minHeight: 8,
                backgroundColor: AppColors.gaugeRing,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('0',
                  style: TextStyle(
                      color: AppColors.textDisabled, fontSize: 11)),
              Text('${maxDisplay.toInt()}',
                  style: const TextStyle(
                      color: AppColors.textDisabled, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
