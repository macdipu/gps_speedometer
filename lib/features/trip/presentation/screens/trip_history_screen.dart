/// TripHistoryScreen — shows list of all recorded trips with summary cards.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../app_pages.dart';
import '../../../../core/utils/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/trip_entity.dart';
import '../controllers/trip_controller.dart';

class TripHistoryScreen extends StatelessWidget {
  TripHistoryScreen({super.key});

  final controller = Get.find<TripController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text('trips'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload, color: AppColors.primary),
            onPressed: controller.importGpx,
            tooltip: 'Import GPX',
          ),
        ],
      ),
      body: Obx(() {
        final trips = controller.trips;
        if (trips.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.route, size: 72, color: AppColors.textDisabled),
                const SizedBox(height: 16),
                Text(
                  'no_trips'.tr,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Go to the Trip tab and press START',
                  style: TextStyle(
                      color: AppColors.textDisabled, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: trips.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _TripCard(
            trip: trips[i],
            onTap: () => Get.toNamed(
              Routes.tripDetails,
              arguments: trips[i].id,
            ),
            onDelete: () => _confirmDelete(context, trips[i]),
            onAnalyze: () => Get.toNamed(
              Routes.tripAnalysis,
              arguments: trips[i].id,
            ),
          ),
        );
      }),
    );
  }

  void _confirmDelete(BuildContext context, TripEntity trip) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('Delete Trip',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('This action cannot be undone.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              controller.deleteTrip(trip.id!);
              Navigator.pop(context);
            },
            child: const Text('DELETE',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.trip,
    required this.onTap,
    required this.onDelete,
    required this.onAnalyze,
  });

  final TripEntity trip;
  final VoidCallback onTap, onDelete, onAnalyze;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.bgCardLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    trip.title ?? Formatters.dateTime(trip.startTime),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: onAnalyze,
                  icon: const Icon(Icons.bar_chart,
                      color: AppColors.primary, size: 20),
                  tooltip: 'Analyze',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.error, size: 20),
                  tooltip: 'Delete',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _TripStat(
                    icon: Icons.route,
                    label: Formatters.distance(trip.distanceMeters)),
                _TripStat(
                    icon: Icons.speed,
                    label:
                        '${trip.avgSpeedKmh.toStringAsFixed(1)} km/h avg'),
                _TripStat(
                    icon: Icons.flash_on,
                    label:
                        '${trip.maxSpeedKmh.toStringAsFixed(1)} km/h max'),
                _TripStat(
                    icon: Icons.timer,
                    label: Formatters.durationShort(trip.duration)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TripStat extends StatelessWidget {
  const _TripStat({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
