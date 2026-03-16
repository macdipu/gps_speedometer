/// Analog Gauge Widget — custom-painted speedometer needle gauge.
/// Uses CustomPainter for a premium analog look.

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_theme.dart';
import '../controllers/speedometer_controller.dart';

class AnalogGaugeWidget extends StatelessWidget {
  const AnalogGaugeWidget({super.key, required this.controller});
  final SpeedometerController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final s = controller.speedometer.value;
      final maxVal = s.unit.name == 'kmh' ? 220.0 : 140.0;
      final fraction = (s.displaySpeed / maxVal).clamp(0.0, 1.0);

      return Container(
        color: AppColors.bgDark,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 300,
                height: 300,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: fraction),
                  duration: const Duration(milliseconds: 300),
                  builder: (_, val, __) => CustomPaint(
                    painter: _GaugePainter(fraction: val),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 60),
                          Text(
                            s.displaySpeed.toStringAsFixed(0),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            s.unitLabel,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              letterSpacing: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'MAX: ${s.maxSpeed.toStringAsFixed(1)} ${s.unitLabel}',
                style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.fraction});
  final double fraction;

  static const double _startAngle = 220.0;
  static const double _sweepAngle = 280.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;

    final bgPaint = Paint()
      ..color = AppColors.gaugeRing
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    final trackPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.gaugeLow, AppColors.gaugeMid, AppColors.gaugeHigh],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    final startRad = _degsToRads(_startAngle);
    final sweepRad = _degsToRads(_sweepAngle);

    // Background arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startRad,
      sweepRad,
      false,
      bgPaint,
    );

    // Filled arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startRad,
      sweepRad * fraction,
      false,
      trackPaint,
    );

    // Tick marks
    _drawTicks(canvas, center, radius - 22);

    // Needle
    _drawNeedle(canvas, center, radius - 32);
  }

  void _drawTicks(Canvas canvas, Offset center, double r) {
    final tickPaint = Paint()
      ..color = AppColors.textDisabled
      ..strokeWidth = 1.5;
    for (int i = 0; i <= 22; i++) {
      final angle = _degsToRads(_startAngle + (_sweepAngle / 22) * i);
      final innerR = i % 2 == 0 ? r - 12 : r - 6;
      final p1 = Offset(
          center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      final p2 = Offset(center.dx + innerR * math.cos(angle),
          center.dy + innerR * math.sin(angle));
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  void _drawNeedle(Canvas canvas, Offset center, double r) {
    final angle = _degsToRads(_startAngle + _sweepAngle * fraction);
    final tip =
        Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));

    final needlePaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, tip, needlePaint);

    // Center dot
    canvas.drawCircle(center, 8,
        Paint()..color = AppColors.bgCardLight);
    canvas.drawCircle(center, 5,
        Paint()..color = AppColors.accent);
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.fraction != fraction;

  static double _degsToRads(double deg) => deg * math.pi / 180.0;
}
