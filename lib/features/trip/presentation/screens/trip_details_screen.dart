/// TripDetailsScreen — detailed view of a trip with route map and stats.

import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
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

  void _shareCard() {
    if (trip == null) return;
    final unit = settings.speedUnit.value;
    final label = unit == SpeedUnit.kmh ? 'km/h' : 'mph';
    final avg = unit == SpeedUnit.kmh
        ? trip!.avgSpeedKmh
        : GpsUtils.kmhToMph(trip!.avgSpeedKmh);
    final max = unit == SpeedUnit.kmh
        ? trip!.maxSpeedKmh
        : GpsUtils.kmhToMph(trip!.maxSpeedKmh);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SharePreviewSheet(
        trip: trip!,
        avgSpeed: avg,
        maxSpeed: max,
        speedLabel: label,
      ),
    );
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
            icon: const Icon(Icons.share_outlined),
            onPressed: _shareCard,
            tooltip: 'Share trip',
          ),
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
                        width: 28, height: 28,
                        child: const Icon(Icons.circle,
                            color: AppColors.success, size: 20),
                      ),
                      Marker(
                        point: latLngs[_playbackIdx],
                        width: 32, height: 32,
                        child: const Icon(Icons.navigation,
                            color: AppColors.accent, size: 28),
                      ),
                      Marker(
                        point: latLngs.last,
                        width: 28, height: 28,
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

// ─────────────────────────────────────────────────────────────────────────────
// Share Preview Sheet
// ─────────────────────────────────────────────────────────────────────────────

class _SharePreviewSheet extends StatefulWidget {
  const _SharePreviewSheet({
    required this.trip,
    required this.avgSpeed,
    required this.maxSpeed,
    required this.speedLabel,
  });

  final TripEntity trip;
  final double avgSpeed, maxSpeed;
  final String speedLabel;

  @override
  State<_SharePreviewSheet> createState() => _SharePreviewSheetState();
}

class _SharePreviewSheetState extends State<_SharePreviewSheet> {
  final _cardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _doShare() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/trip_share_${widget.trip.id ?? 0}.png');
      await file.writeAsBytes(bytes);

      if (mounted) Navigator.of(context).pop();

      await Share.shareXFiles(
        [XFile(file.path)],
        subject:
            'Trip · ${Formatters.distance(widget.trip.distanceMeters)} · ${Formatters.duration(widget.trip.duration)}',
      );
    } catch (e) {
      Get.snackbar('Share Failed', e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: context.cardBorderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text('Preview',
                    style: TextStyle(
                        color: context.textPrimaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Text('Tap Share to export as image',
                    style: TextStyle(
                        color: context.textDisabledColor, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Card preview — this is what gets captured
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: RepaintBoundary(
              key: _cardKey,
              child: _TripShareCard(
                trip: widget.trip,
                avgSpeed: widget.avgSpeed,
                maxSpeed: widget.maxSpeed,
                speedLabel: widget.speedLabel,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Share button
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 0, 20, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _sharing ? null : _doShare,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                icon: _sharing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.share_outlined),
                label: Text(_sharing ? 'Saving...' : 'Share',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Share Card — captured as PNG from the preview sheet
// ─────────────────────────────────────────────────────────────────────────────

class _TripShareCard extends StatelessWidget {
  const _TripShareCard({
    required this.trip,
    required this.avgSpeed,
    required this.maxSpeed,
    required this.speedLabel,
  });

  final TripEntity trip;
  final double avgSpeed, maxSpeed;
  final String speedLabel;

  static const _bg     = Color(0xFF0B1320);
  static const _card   = Color(0xFF111E30);
  static const _accent = Color(0xFF3B82F6);
  static const _green  = Color(0xFF22C55E);
  static const _amber  = Color(0xFFF59E0B);
  static const _text   = Color(0xFFE2E8F0);
  static const _sub    = Color(0xFF94A3B8);
  static const _border = Color(0xFF1E3050);

  @override
  Widget build(BuildContext context) {
    final points = trip.points
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();

    final dateStr = DateFormat('EEE, MMM d yyyy').format(trip.startTime);
    final timeStr = DateFormat('h:mm a').format(trip.startTime);

    return SizedBox(
      width: 400,
      child: Material(
        color: _bg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(dateStr, timeStr),
            _buildRouteSection(points),
            _buildStatsGrid(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String date, String time) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF0F2744)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _accent.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.speed, color: _accent, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('GPS SPEEDOMETER',
                  style: TextStyle(
                      color: _accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2)),
              const SizedBox(height: 2),
              Text(trip.title ?? 'Trip Recording',
                  style: const TextStyle(
                      color: _text,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(date,
                  style: const TextStyle(color: _sub, fontSize: 11)),
              const SizedBox(height: 2),
              Text(time,
                  style: const TextStyle(
                      color: _text, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSection(List<LatLng> points) {
    return Container(
      width: double.infinity,
      height: 220,
      color: const Color(0xFF0D1927),
      child: Stack(
        children: [
          // Dot grid background
          CustomPaint(
            size: const Size(400, 220),
            painter: _DotGridPainter(),
          ),
          // Route
          ClipRect(
            child: CustomPaint(
              size: const Size(400, 220),
              painter: _RoutePainter(points: points, accent: _accent, green: _green),
            ),
          ),
          // Labels
          Positioned(
            left: 14, bottom: 12,
            child: Row(children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                    color: _green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              const Text('Start', style: TextStyle(color: _sub, fontSize: 10)),
              const SizedBox(width: 12),
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                    color: Color(0xFFEF4444), shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              const Text('End', style: TextStyle(color: _sub, fontSize: 10)),
            ]),
          ),
          if (points.isEmpty)
            const Center(
              child: Text('No route data',
                  style: TextStyle(color: _sub, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Container(
      color: _card,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: _statCell(Icons.route_outlined, 'DISTANCE',
                Formatters.distance(trip.distanceMeters), _accent)),
            const SizedBox(width: 10),
            Expanded(child: _statCell(Icons.timer_outlined, 'DURATION',
                Formatters.duration(trip.duration), _amber)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _statCell(Icons.speed_outlined, 'AVG SPEED',
                '${avgSpeed.toStringAsFixed(1)} $speedLabel', _green)),
            const SizedBox(width: 10),
            Expanded(child: _statCell(Icons.flash_on_outlined, 'MAX SPEED',
                '${maxSpeed.toStringAsFixed(1)} $speedLabel', const Color(0xFFEC4899))),
          ]),
        ],
      ),
    );
  }

  Widget _statCell(
      IconData icon, String label, String value, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: accent, size: 14),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2)),
          ]),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: _text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3)),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF080F1A),
        border: Border(top: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_car, color: _sub, size: 14),
          const SizedBox(width: 6),
          const Text('GPS Speedometer',
              style: TextStyle(
                  color: _sub,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3)),
          const Spacer(),
          Text('${trip.points.length} GPS pts',
              style: const TextStyle(color: _sub, fontSize: 10)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A2E45)
      ..strokeWidth = 1;
    const gap = 20.0;
    for (double x = 0; x < size.width; x += gap) {
      for (double y = 0; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), 1.2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter _) => false;
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter({
    required this.points,
    required this.accent,
    required this.green,
  });

  final List<LatLng> points;
  final Color accent;
  final Color green;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) {
      if (points.length == 1) {
        canvas.drawCircle(Offset(size.width / 2, size.height / 2), 6,
            Paint()..color = green);
      }
      return;
    }

    const pad = 32.0;
    double minLat = points.map((p) => p.latitude).reduce(math.min);
    double maxLat = points.map((p) => p.latitude).reduce(math.max);
    double minLng = points.map((p) => p.longitude).reduce(math.min);
    double maxLng = points.map((p) => p.longitude).reduce(math.max);

    // Ensure non-zero span
    final latSpan = (maxLat - minLat).abs().clamp(0.0001, 360.0);
    final lngSpan = (maxLng - minLng).abs().clamp(0.0001, 360.0);

    final w = size.width - pad * 2;
    final h = size.height - pad * 2;

    // Preserve aspect ratio
    final scaleX = w / lngSpan;
    final scaleY = h / latSpan;
    final scale = math.min(scaleX, scaleY);
    final offsetX = pad + (w - lngSpan * scale) / 2;
    final offsetY = pad + (h - latSpan * scale) / 2;

    Offset project(LatLng ll) => Offset(
          offsetX + (ll.longitude - minLng) * scale,
          offsetY + (maxLat - ll.latitude) * scale,
        );

    // Glow / shadow pass
    final glowPaint = Paint()
      ..color = accent.withValues(alpha: 0.18)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = ui.Path()..moveTo(project(points.first).dx, project(points.first).dy);
    for (final p in points.skip(1)) {
      path.lineTo(project(p).dx, project(p).dy);
    }
    canvas.drawPath(path, glowPaint);

    // Main route line
    final routePaint = Paint()
      ..color = accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, routePaint);

    // Start marker
    final start = project(points.first);
    canvas.drawCircle(start, 6,
        Paint()..color = const Color(0xFF1A2E45));
    canvas.drawCircle(start, 5, Paint()..color = green);

    // End marker
    final end = project(points.last);
    canvas.drawCircle(end, 6,
        Paint()..color = const Color(0xFF1A2E45));
    canvas.drawCircle(end, 5, Paint()..color = const Color(0xFFEF4444));
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.points != points;
}
