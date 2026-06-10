/// TripDetailsScreen — detailed view of a trip with route map and stats.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/utils/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/gpx_utils.dart';
import '../../../../core/utils/gps_utils.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../domain/entities/trip_entity.dart';
import '../controllers/trip_controller.dart';

class TripDetailsScreen extends StatefulWidget {
  const TripDetailsScreen({super.key});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  final controller = Get.find<TripController>();
  final settings = Get.find<SettingsController>();

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

  Future<void> _exportGpx() async {
    if (trip == null) return;
    try {
      final xmlString = GpxUtils.generateGpx(trip!);
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/trip_${trip!.startTime.millisecondsSinceEpoch}.gpx';
      final file = File(path);
      await file.writeAsString(xmlString);
      await Share.shareXFiles([XFile(path)], subject: 'GPX Export - Trip');
    } catch (e) {
      Get.snackbar('export_failed'.tr, e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: context.primaryColor)),
      );
    }

    if (trip == null) {
      return Scaffold(
        body: Center(
            child: Text('Trip not found',
                style: TextStyle(color: context.textSecondaryColor))),
      );
    }

    final points = trip!.points;
    final latLngs = points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final center =
        latLngs.isNotEmpty ? latLngs[_playbackIdx] : const LatLng(0, 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(trip!.title ?? 'Trip Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.download, color: context.primaryColor),
            onPressed: _exportGpx,
            tooltip: 'export_gpx'.tr,
          ),
          if (points.isNotEmpty)
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: context.primaryColor,
              ),
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
                        color: context.primaryColor,
                        strokeWidth: 3.5,
                      ),
                    ],
                  ),
                if (latLngs.isNotEmpty)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: latLngs.first,
                        width: 28,
                        height: 28,
                        child: const Icon(Icons.circle,
                            color: AppColors.success, size: 20),
                      ),
                      Marker(
                        point: latLngs[_playbackIdx],
                        width: 32,
                        height: 32,
                        child: const Icon(Icons.navigation,
                            color: AppColors.accent, size: 28),
                      ),
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
                  _statRow(context, 'Start',
                      Formatters.dateTime(trip!.startTime)),
                  _statRow(
                      context,
                      'End',
                      trip!.endTime != null
                          ? Formatters.dateTime(trip!.endTime!)
                          : '—'),
                  _statRow(context, 'Duration',
                      Formatters.duration(trip!.duration)),
                  _statRow(context, 'Distance',
                      Formatters.distance(trip!.distanceMeters)),
                  // Speed stats: reactive to unit changes
                  Obx(() {
                    final unit = settings.speedUnit.value;
                    final label = unit == SpeedUnit.kmh ? 'km/h' : 'mph';
                    final avg = unit == SpeedUnit.kmh
                        ? trip!.avgSpeedKmh
                        : GpsUtils.kmhToMph(trip!.avgSpeedKmh);
                    final max = unit == SpeedUnit.kmh
                        ? trip!.maxSpeedKmh
                        : GpsUtils.kmhToMph(trip!.maxSpeedKmh);
                    return Column(children: [
                      _statRow(context, 'Avg Speed',
                          '${avg.toStringAsFixed(1)} $label'),
                      _statRow(context, 'Max Speed',
                          '${max.toStringAsFixed(1)} $label'),
                    ]);
                  }),
                  _statRow(context, 'GPS Points', '${points.length}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                  color: context.textSecondaryColor, fontSize: 14)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  color: context.textPrimaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
