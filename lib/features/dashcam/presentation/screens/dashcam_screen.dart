/// DashcamScreen
/// Shows live camera feed with an overlay of current speed/trip stats.

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
        children: [
          // 1. Camera Preview Layer
          Obx(() {
            if (!controller.isInitialized.value ||
                controller.cameraController == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            return ConstrainedBox(
              constraints: const BoxConstraints.expand(),
              child: CameraPreview(controller.cameraController!),
            );
          }),

          // 2. Dashcam Overlay Status + Speed Data
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Obx(() {
              final tripCtrl = controller.tripController;
              final unit = settings.speedUnit.value;
              final speedKmh = tripCtrl.currentSpeed.value;
              final dispSpeed = unit == SpeedUnit.kmh
                  ? speedKmh
                  : GpsUtils.kmhToMph(speedKmh);
              final unitLabel = unit == SpeedUnit.kmh ? 'km/h' : 'mph';

              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // REC Indicator
                  if (controller.isRecording.value)
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'REC (Loop)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 4)
                            ],
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'STANDBY',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),

                  // Speed Overlay
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        dispSpeed.toStringAsFixed(0),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                        ),
                      ),
                      Text(
                        unitLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),

          // 3. UI Controls
          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
              onPressed: () => Get.back(),
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Obx(() {
              final isRecording = controller.isRecording.value;
              return Center(
                child: GestureDetector(
                  onTap: controller.toggleRecording,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isRecording
                            ? AppColors.error
                            : AppColors.primary,
                        shape: isRecording
                            ? BoxShape.rectangle
                            : BoxShape.circle,
                        borderRadius:
                            isRecording ? BorderRadius.circular(8) : null,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
