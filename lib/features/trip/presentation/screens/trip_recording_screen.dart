/// TripRecordingScreen — Start/Stop trip recording with live stats display.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../controllers/trip_controller.dart';

class TripRecordingScreen extends StatelessWidget {
  TripRecordingScreen({super.key});

  final controller = Get.find<TripController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Trip Recording')),
      body: Obx(() {
        final recording = controller.isRecording.value;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Big record pulse circle
              _RecordButton(
                isRecording: recording,
                onTap: recording ? controller.stopTrip : controller.startTrip,
              ),

              const SizedBox(height: 48),

              if (recording) ...[
                // Live stats grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.6,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _LiveStatCard(
                      label: 'ELAPSED',
                      value: Formatters.duration(
                          Duration(seconds: controller.elapsedSeconds.value)),
                      icon: Icons.timer,
                      color: AppColors.primary,
                    ),
                    _LiveStatCard(
                      label: 'DISTANCE',
                      value: Formatters.distance(
                          controller.currentDistance.value),
                      icon: Icons.route,
                      color: AppColors.info,
                    ),
                    _LiveStatCard(
                      label: 'SPEED',
                      value:
                          '${controller.currentSpeed.value.toStringAsFixed(1)} km/h',
                      icon: Icons.speed,
                      color: AppColors.gaugeLow,
                    ),
                    _LiveStatCard(
                      label: 'MAX SPEED',
                      value:
                          '${controller.maxSpeed.value.toStringAsFixed(1)} km/h',
                      icon: Icons.flash_on,
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ] else ...[
                // Empty state
                Column(
                  children: [
                    Icon(Icons.play_circle_outline,
                        size: 80,
                        color: AppColors.textDisabled),
                    const SizedBox(height: 16),
                    const Text(
                      'Press START to begin recording\nyour trip',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 16),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}

// ---------------------------------------------------------------------------

class _RecordButton extends StatefulWidget {
  const _RecordButton({required this.isRecording, required this.onTap});
  final bool isRecording;
  final VoidCallback onTap;

  @override
  State<_RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<_RecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final scale = widget.isRecording ? 1.0 + _anim.value * 0.06 : 1.0;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isRecording
                    ? AppColors.error.withOpacity(0.15)
                    : AppColors.primary.withOpacity(0.15),
                border: Border.all(
                  color: widget.isRecording
                      ? AppColors.error
                      : AppColors.primary,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isRecording
                            ? AppColors.error
                            : AppColors.primary)
                        .withOpacity(widget.isRecording ? _anim.value * 0.5 : 0.3),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isRecording ? Icons.stop : Icons.play_arrow,
                    size: 48,
                    color: widget.isRecording
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                  Text(
                    widget.isRecording ? 'STOP' : 'START',
                    style: TextStyle(
                      color: widget.isRecording
                          ? AppColors.error
                          : AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _LiveStatCard extends StatelessWidget {
  const _LiveStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 11,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
