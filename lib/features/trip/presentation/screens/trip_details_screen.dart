/// TripDetailsScreen — detailed view of a trip with route map and stats.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/trip_entity.dart';
import '../controllers/trip_controller.dart';

class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({super.key});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  final controller = Get.find<TripController>();
  TripEntity? trip;
  bool loading = true;

  // Playback
  int _playbackIdx = 0;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    final id = Get.arguments as int?;
    if (id != null) _loadTrip(id);
  }

  Future<void> _loadTrip(int id) async {
    final t = await controller.getTrip(id);
    if (mounted) setState(() { trip = t; loading = false; });
  }

  void _togglePlayback() {
    if (trip == null || trip!.points.isEmpty) return;
    setState(() => _isPlaying = !_isPlaying);
    if (_isPlaying) _runPlayback();
  }

  void _runPlayback() async {
    while (_isPlaying && _playbackIdx < trip!.points.length - 1) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) setState(() => _playbackIdx++);
    }
    if (mounted) setState(() => _isPlaying = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (trip == null) {
      return const Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(
            child: Text('Trip not found',
                style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    final points = trip!.points;
    final latLngs = points
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    final center = latLngs.isNotEmpty
        ? latLngs[_playbackIdx]
        : LatLng(23.8103, 90.4125);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: Text(trip!.title ?? 'Trip Details'),
        actions: [
          if (points.isNotEmpty)
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow,
                  color: AppColors.primary),
              onPressed: _togglePlayback,
              tooltip: 'Playback route',
            ),
        ],
      ),
      body: Column(
        children: [
          // Map with route
          SizedBox(
            height: 300,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 14,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.chowdhuryelab.gps_speedometer',
                ),
                if (latLngs.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: latLngs,
                        color: AppColors.primary,
                        strokeWidth: 3.5,
                      ),
                    ],
                  ),
                if (latLngs.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      // Start marker
                      Marker(
                        point: latLngs.first,
                        width: 28,
                        height: 28,
                        child: const Icon(Icons.circle,
                            color: AppColors.success, size: 20),
                      ),
                      // Playback position
                      Marker(
                        point: latLngs[_playbackIdx],
                        width: 32,
                        height: 32,
                        child: const Icon(Icons.navigation,
                            color: AppColors.accent, size: 28),
                      ),
                      // End marker
                      Marker(
                        point: latLngs.last,
                        width: 28,
                        height: 28,
                        child: const Icon(Icons.flag,
                            color: AppColors.error, size: 24),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Stats
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _statRow('Start', Formatters.dateTime(trip!.startTime)),
                  _statRow(
                      'End',
                      trip!.endTime != null
                          ? Formatters.dateTime(trip!.endTime!)
                          : '—'),
                  _statRow(
                      'Duration', Formatters.duration(trip!.duration)),
                  _statRow(
                      'Distance',
                      Formatters.distance(trip!.distanceMeters)),
                  _statRow(
                      'Avg Speed',
                      '${trip!.avgSpeedKmh.toStringAsFixed(1)} km/h'),
                  _statRow(
                      'Max Speed',
                      '${trip!.maxSpeedKmh.toStringAsFixed(1)} km/h'),
                  _statRow('GPS Points', '${points.length}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
