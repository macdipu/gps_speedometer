/// DashcamScreen
/// Professional action-camera / dashcam HUD with loop recording support.

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_theme.dart';
import '../../../../core/utils/gps_utils.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../controllers/dashcam_controller.dart';

class DashcamScreen extends StatelessWidget {
  DashcamScreen({super.key});

  final DashcamController controller = Get.find<DashcamController>();
  final SettingsController settings = Get.find<SettingsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera preview ──────────────────────────────────────────────
          Obx(() {
            if (!controller.isInitialized.value ||
                controller.cameraController == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            return SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.cameraController!.value.previewSize?.height ?? 1,
                  height: controller.cameraController!.value.previewSize?.width ?? 1,
                  child: CameraPreview(controller.cameraController!),
                ),
              ),
            );
          }),

          // ── Top HUD bar ─────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    // Back
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 28),
                      onPressed: Get.back,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),

                    // REC status + elapsed
                    Obx(() => controller.isRecording.value
                        ? _RecIndicator(
                            elapsed: controller.totalElapsedSeconds.value)
                        : const Text(
                            'STANDBY',
                            style: TextStyle(
                              color: Colors.white54,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 2,
                            ),
                          )),

                    const Spacer(),

                    // Switching clip indicator
                    Obx(() => controller.isSwitchingClip.value
                        ? const _PillBadge(
                            label: 'SAVING',
                            color: Colors.orange,
                          )
                        : const SizedBox.shrink()),

                    const SizedBox(width: 8),

                    // Resolution
                    Obx(() => _PillBadge(
                          label: controller.resolutionLabel.value,
                          color: Colors.white24,
                        )),
                  ],
                ),
              ),
            ),
          ),

          // ── Speed overlay (bottom-right) ────────────────────────────────
          Positioned(
            right: 16,
            bottom: 160,
            child: Obx(() {
              final unit = settings.speedUnit.value;
              final kmh = controller.tripController.currentSpeed.value;
              final disp = unit == SpeedUnit.kmh ? kmh : GpsUtils.kmhToMph(kmh);
              final unitLabel = unit == SpeedUnit.kmh ? 'km/h' : 'mph';
              return _SpeedBadge(speed: disp, unit: unitLabel);
            }),
          ),

          // ── Bottom overlay (loop info + controls) ──────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Loop info card — only when recording with loop enabled
                  Obx(() {
                    final recording = controller.isRecording.value;
                    final total = controller.clipTotalSeconds.value;
                    if (!recording || total == 0) return const SizedBox.shrink();

                    return _LoopInfoCard(controller: controller);
                  }),

                  const SizedBox(height: 12),

                  // Controls row
                  Obx(() {
                    final recording = controller.isRecording.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Lock button (only while recording)
                          if (recording) ...[
                            _LockButton(controller: controller),
                            const SizedBox(width: 32),
                          ],

                          _RecordButton(
                            isRecording: recording,
                            onTap: controller.toggleRecording,
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loop Info Card
// ─────────────────────────────────────────────────────────────────────────────

class _LoopInfoCard extends StatelessWidget {
  const _LoopInfoCard({required this.controller});
  final DashcamController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final elapsed = controller.clipElapsedSeconds.value;
      final total = controller.clipTotalSeconds.value;
      final remaining = (total - elapsed).clamp(0, total);
      final progress = total > 0 ? (elapsed / total).clamp(0.0, 1.0) : 0.0;
      final storageMb = controller.storageMbUsed.value;
      final storageStr = storageMb < 1024
          ? '${storageMb.toStringAsFixed(1)} MB'
          : '${(storageMb / 1024).toStringAsFixed(2)} GB';
      final segCount = controller.segmentCount.value;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                const Icon(Icons.loop,
                    color: AppColors.primary, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${'loop_recording'.tr}: ${(total ~/ 60)} min',
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 0.5),
                ),
                const Spacer(),
                if (segCount > 0)
                  Text(
                    '$segCount clips saved',
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Clip timer row
            Row(
              children: [
                const Icon(Icons.videocam,
                    color: Colors.white54, size: 13),
                const SizedBox(width: 6),
                Text(
                  'current_clip'.tr,
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  '${DashcamController.formatClock(elapsed)} / ${DashcamController.formatClock(total)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'RobotoMono',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation(
                  progress < 0.8
                      ? AppColors.primary
                      : progress < 0.95
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Next clip countdown + storage
            Row(
              children: [
                const Icon(Icons.timer_outlined,
                    color: Colors.white38, size: 13),
                const SizedBox(width: 6),
                Text(
                  'next_clip_in'.tr,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(width: 6),
                Text(
                  remaining >= 60
                      ? DashcamController.formatClock(remaining)
                      : '${remaining}s',
                  style: TextStyle(
                    color: remaining <= 10
                        ? Colors.orange
                        : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'RobotoMono',
                  ),
                ),
                const Spacer(),
                const Icon(Icons.folder_outlined,
                    color: Colors.white24, size: 13),
                const SizedBox(width: 4),
                Text(
                  storageStr,
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable HUD widgets
// ─────────────────────────────────────────────────────────────────────────────

class _RecIndicator extends StatelessWidget {
  const _RecIndicator({required this.elapsed});
  final int elapsed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BlinkingDot(),
        const SizedBox(width: 6),
        Text(
          'REC  ${DashcamController.formatClock(elapsed)}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 1,
            fontFamily: 'RobotoMono',
          ),
        ),
      ],
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.4 + _anim.value * 0.6),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SpeedBadge extends StatelessWidget {
  const _SpeedBadge({required this.speed, required this.unit});
  final double speed;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            speed.toStringAsFixed(0),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              height: 1.0,
              shadows: [Shadow(color: Colors.black, blurRadius: 8)],
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _LockButton extends StatelessWidget {
  const _LockButton({required this.controller});
  final DashcamController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final locked = controller.isCurrentClipLocked.value;
      return GestureDetector(
        onTap: controller.toggleLock,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: locked
                ? Colors.amber.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            border: Border.all(
              color: locked ? Colors.amber : Colors.white38,
              width: 2,
            ),
          ),
          child: Icon(
            locked ? Icons.lock : Icons.lock_open_outlined,
            color: locked ? Colors.amber : Colors.white54,
            size: 24,
          ),
        ),
      );
    });
  }
}

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
    );
    if (widget.isRecording) _anim.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_RecordButton old) {
    super.didUpdateWidget(old);
    if (widget.isRecording && !_anim.isAnimating) {
      _anim.repeat(reverse: true);
    } else if (!widget.isRecording && _anim.isAnimating) {
      _anim.stop();
      _anim.value = 0;
    }
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
          final pulse = widget.isRecording ? 1.0 + _anim.value * 0.08 : 1.0;
          return Transform.scale(
            scale: pulse,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  if (widget.isRecording)
                    BoxShadow(
                      color: Colors.red
                          .withOpacity(_anim.value * 0.6),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                ],
              ),
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: widget.isRecording ? Colors.red : AppColors.primary,
                  shape: widget.isRecording
                      ? BoxShape.rectangle
                      : BoxShape.circle,
                  borderRadius:
                      widget.isRecording ? BorderRadius.circular(10) : null,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
