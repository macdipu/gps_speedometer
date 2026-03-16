/// TripAnalysisScreen — shows acceleration stats, top speed, and segment breakdown.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/utils/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../controllers/analysis_controller.dart';

class TripAnalysisScreen extends StatefulWidget {
  const TripAnalysisScreen({super.key});

  @override
  State<TripAnalysisScreen> createState() => _TripAnalysisScreenState();
}

class _TripAnalysisScreenState extends State<TripAnalysisScreen> {
  final controller = Get.find<AnalysisController>();

  @override
  void initState() {
    super.initState();
    final id = Get.arguments as int?;
    if (id != null) controller.analyzeTrip(id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(title: const Text('Trip Analysis')),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final result = controller.analysisResult.value;
        if (result == null) {
          return const Center(
            child: Text('No data', style: TextStyle(color: AppColors.textSecondary)),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              _SectionHeader('Overview'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _AnalysisCard(
                    label: 'TOP SPEED',
                    value: '${result.topSpeedKmh.toStringAsFixed(1)} km/h',
                    icon: Icons.flash_on,
                    color: AppColors.accent,
                  ),
                  _AnalysisCard(
                    label: 'AVG SPEED',
                    value: '${result.avgSpeedKmh.toStringAsFixed(1)} km/h',
                    icon: Icons.speed,
                    color: AppColors.primary,
                  ),
                  _AnalysisCard(
                    label: 'DISTANCE',
                    value: Formatters.distance(result.totalDistanceMeters),
                    icon: Icons.route,
                    color: AppColors.info,
                  ),
                  _AnalysisCard(
                    label: 'DURATION',
                    value: Formatters.durationShort(
                        Duration(seconds: result.durationSeconds)),
                    icon: Icons.timer,
                    color: AppColors.gaugeLow,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Acceleration
              _SectionHeader('Acceleration'),
              const SizedBox(height: 12),
              _AccelerationCard(
                label: '0 → 60 km/h',
                event: result.acceleration0to60,
              ),
              const SizedBox(height: 12),
              _AccelerationCard(
                label: '0 → 100 km/h',
                event: result.acceleration0to100,
              ),

              const SizedBox(height: 28),

              // Segments
              if (result.segments.isNotEmpty) ...[
                _SectionHeader('Segment Breakdown'),
                const SizedBox(height: 12),
                ...result.segments.map((seg) => _SegmentRow(seg: seg)),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700));
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({
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
          Row(children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600)),
          ]),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AccelerationCard extends StatelessWidget {
  const _AccelerationCard({required this.label, required this.event});
  final String label;
  final dynamic event; // AccelerationEvent?

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.electric_bolt,
              color: AppColors.accent, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 15)),
          ),
          event != null
              ? Text(
                  '${event.seconds.toStringAsFixed(2)} s',
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 20,
                      fontWeight: FontWeight.w800),
                )
              : const Text('Not detected',
                  style: TextStyle(
                      color: AppColors.textDisabled, fontSize: 13)),
        ],
      ),
    );
  }
}

class _SegmentRow extends StatelessWidget {
  const _SegmentRow({required this.seg});
  final dynamic seg;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle),
            child: Center(
              child: Text('${seg.segmentNumber}',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Avg: ${seg.avgSpeedKmh.toStringAsFixed(1)} km/h',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Text(
            'Max: ${seg.maxSpeedKmh.toStringAsFixed(1)} km/h',
            style: const TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
