/// HUD Overlay Widget — neon green speed overlay, designed to reflect in windshield.
/// Full-screen black background with mirrored/flipped text for HUD projection.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_theme.dart';
import '../controllers/speedometer_controller.dart';

class HudOverlayWidget extends StatefulWidget {
  const HudOverlayWidget({super.key, required this.controller});
  final SpeedometerController controller;

  @override
  State<HudOverlayWidget> createState() => _HudOverlayWidgetState();
}

class _HudOverlayWidgetState extends State<HudOverlayWidget> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.controller.setMode(SpeedometerMode.digital),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Obx(() {
          final s = widget.controller.speedometer.value;
          return Transform(
            // Mirror horizontally for HUD windshield reflection
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, 1.0),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    s.displaySpeed.toStringAsFixed(0),
                    style: const TextStyle(
                      color: AppColors.hudGreen,
                      fontSize: 120,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                            color: AppColors.hudGreen,
                            blurRadius: 20),
                      ],
                    ),
                  ),
                  Text(
                    s.unitLabel.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.hudGreen,
                      fontSize: 28,
                      letterSpacing: 12,
                      shadows: [
                        Shadow(
                            color: AppColors.hudGreen,
                            blurRadius: 10),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'TAP TO EXIT HUD',
                    style: TextStyle(
                      color: AppColors.hudGreen.withOpacity(0.4),
                      fontSize: 12,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
