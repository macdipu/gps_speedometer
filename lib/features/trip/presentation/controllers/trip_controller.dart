/// TripController — GetX Controller
/// Manages trip recording lifecycle, GPS point collection, and trip history.
/// Phase 6: Starts/stops the BackgroundLocationService when recording.
/// Phase 7: Triggers SpeedAlertService on every GPS position update.

import 'dart:io';
import 'dart:async';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:file_picker/file_picker.dart';

import '../../../../core/utils/gps_utils.dart';
import '../../../../core/utils/gpx_utils.dart';
import '../../../../core/services/speed_alert_service.dart';
import '../../domain/entities/trip_entity.dart';
import '../../data/repositories/trip_repository_impl.dart';

class TripController extends GetxController {
  final _repo = TripRepositoryImpl();
  final _alertService = SpeedAlertService();

  // --------------------------------------------------------------------------
  // Reactive state
  // --------------------------------------------------------------------------

  final isRecording = false.obs;
  final currentTripId = RxnInt();
  final trips = <TripEntity>[].obs;
  final livePoints = <TripPointEntity>[].obs;

  final currentDistance = 0.0.obs;
  final currentSpeed = 0.0.obs;
  final maxSpeed = 0.0.obs;
  final elapsedSeconds = 0.obs;
  final isOverSpeedLimit = false.obs;

  // --------------------------------------------------------------------------
  // Private state
  // --------------------------------------------------------------------------
  StreamSubscription<Position>? _posSub;
  Timer? _timer;
  double? _lastLat;
  double? _lastLng;
  double _totalDistance = 0.0;
  double _speedSum = 0.0;
  int _speedCount = 0;
  DateTime? _startTime;
  DateTime? _lastPositionTs;

  // --------------------------------------------------------------------------
  // Lifecycle
  // --------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _loadTrips();
  }

  @override
  void onClose() {
    _posSub?.cancel();
    _timer?.cancel();
    super.onClose();
  }

  // --------------------------------------------------------------------------
  // Trip control
  // --------------------------------------------------------------------------

  Future<void> startTrip() async {
    await GpsUtils.ensurePermissions();

    _startTime = DateTime.now();
    _totalDistance = 0.0;
    _speedSum = 0.0;
    _speedCount = 0;
    _lastLat = null;
    _lastLng = null;
    _lastPositionTs = null;
    currentDistance.value = 0.0;
    currentSpeed.value = 0.0;
    maxSpeed.value = 0.0;
    elapsedSeconds.value = 0;
    isOverSpeedLimit.value = false;
    livePoints.clear();

    final tripId = await _repo.startTrip(_startTime!);
    currentTripId.value = tripId;
    isRecording.value = true;

    _posSub = Geolocator.getPositionStream(
      locationSettings: GpsUtils.locationSettings,
    ).listen((pos) => _onPosition(pos));

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds.value++;
    });
  }

  Future<void> stopTrip() async {
    if (!isRecording.value || currentTripId.value == null) return;

    _posSub?.cancel();
    _timer?.cancel();

    final avgSpeed = _speedCount > 0 ? _speedSum / _speedCount : 0.0;
    final endTime = DateTime.now();

    await _repo.stopTrip(
      currentTripId.value!,
      distanceMeters: _totalDistance,
      avgSpeedKmh: avgSpeed,
      maxSpeedKmh: maxSpeed.value,
      durationSeconds: elapsedSeconds.value,
      endTime: endTime,
    );

    isRecording.value = false;
    isOverSpeedLimit.value = false;
    currentTripId.value = null;
    await _loadTrips();
  }

  Future<void> deleteTrip(int id) async {
    await _repo.deleteTrip(id);
    await _loadTrips();
  }

  Future<void> importGpx() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gpx'],
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final trip = await GpxUtils.parseGpx(file);

      if (trip == null) {
        Get.snackbar('Import Failed', 'Invalid GPX format or no track points.');
        return;
      }

      double dist = 0.0;
      double maxSpd = 0.0;
      double spdSum = 0.0;

      for (int i = 0; i < trip.points.length; i++) {
        final pt = trip.points[i];
        if (pt.speedKmh > maxSpd) maxSpd = pt.speedKmh;
        spdSum += pt.speedKmh;

        if (i > 0) {
          final prev = trip.points[i - 1];
          dist += GpsUtils.haversineDistance(
              prev.latitude, prev.longitude, pt.latitude, pt.longitude);
        }
      }

      final avgSpd = trip.points.isNotEmpty ? spdSum / trip.points.length : 0.0;

      final updatedTrip = trip.copyWith(
        distanceMeters: dist,
        maxSpeedKmh: maxSpd,
        avgSpeedKmh: avgSpd,
      );

      await _repo.saveImportedTrip(updatedTrip);
      await _loadTrips();
      Get.snackbar('Success', 'GPX imported successfully!');
    } catch (e) {
      Get.snackbar('Import Error', 'Could not read file: $e');
    }
  }

  Future<TripEntity?> getTrip(int id) async {
    return await _repo.getTripById(id);
  }

  // --------------------------------------------------------------------------
  // Private
  // --------------------------------------------------------------------------

  void _onPosition(Position pos) {
    final ts = pos.timestamp;
    if (_isDuplicate(ts)) return;
    final speedKmh = GpsUtils.msToKmh(GpsUtils.sanitizeSpeed(pos.speed));
    _processPositionData(
      pos.latitude, pos.longitude, speedKmh,
      pos.altitude, pos.accuracy, ts,
    );
  }

  bool _isDuplicate(DateTime ts) {
    if (_lastPositionTs == null) return false;
    return ts.difference(_lastPositionTs!).inMilliseconds.abs() < 800;
  }

  void _processPositionData(
    double lat,
    double lng,
    double speedKmh,
    double altitude,
    double accuracy,
    DateTime timestamp,
  ) {
    _lastPositionTs = timestamp;
    currentSpeed.value = speedKmh;
    if (speedKmh > maxSpeed.value) maxSpeed.value = speedKmh;
    _speedSum += speedKmh;
    _speedCount++;

    if (_lastLat != null && _lastLng != null) {
      final d = GpsUtils.haversineDistance(_lastLat!, _lastLng!, lat, lng);
      _totalDistance += d;
      currentDistance.value = _totalDistance;
    }
    _lastLat = lat;
    _lastLng = lng;

    if (currentTripId.value != null) {
      final point = TripPointEntity(
        tripId: currentTripId.value!,
        latitude: lat,
        longitude: lng,
        speedKmh: speedKmh,
        accuracy: accuracy,
        altitude: altitude,
        timestamp: timestamp,
      );
      _repo.addTripPoint(point);
      livePoints.add(point);
    }

    _alertService.checkSpeed(speedKmh);
  }

  Future<void> _loadTrips() async {
    final all = await _repo.getAllTrips();
    trips.assignAll(all);
  }
}
