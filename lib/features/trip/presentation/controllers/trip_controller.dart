/// TripController — GetX Controller
/// Manages trip recording lifecycle, GPS point collection, and trip history.

import 'dart:async';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/utils/gps_utils.dart';
import '../../domain/entities/trip_entity.dart';
import '../../data/repositories/trip_repository_impl.dart';

class TripController extends GetxController {
  final _repo = TripRepositoryImpl();

  // --------------------------------------------------------------------------
  // Reactive state
  // --------------------------------------------------------------------------

  final isRecording = false.obs;
  final currentTripId = RxnInt();
  final trips = <TripEntity>[].obs;

  /// Live stats during recording
  final currentDistance = 0.0.obs;   // meters
  final currentSpeed = 0.0.obs;      // km/h
  final maxSpeed = 0.0.obs;          // km/h
  final elapsedSeconds = 0.obs;

  // --------------------------------------------------------------------------
  // Private state
  // --------------------------------------------------------------------------
  StreamSubscription<Position>? _posSub;
  Timer? _timer;
  Position? _lastPosition;
  double _totalDistance = 0.0;
  double _speedSum = 0.0;
  int _speedCount = 0;
  DateTime? _startTime;

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
    _lastPosition = null;
    currentDistance.value = 0.0;
    currentSpeed.value = 0.0;
    maxSpeed.value = 0.0;
    elapsedSeconds.value = 0;

    final tripId = await _repo.startTrip(_startTime!);
    currentTripId.value = tripId;
    isRecording.value = true;

    // Start GPS stream
    _posSub = Geolocator.getPositionStream(
      locationSettings: GpsUtils.locationSettings,
    ).listen((pos) => _onPosition(pos));

    // Start elapsed timer
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
    currentTripId.value = null;
    await _loadTrips();
  }

  Future<void> deleteTrip(int id) async {
    await _repo.deleteTrip(id);
    await _loadTrips();
  }

  Future<TripEntity?> getTrip(int id) async {
    return await _repo.getTripById(id);
  }

  // --------------------------------------------------------------------------
  // Private
  // --------------------------------------------------------------------------

  void _onPosition(Position pos) {
    final speedKmh = GpsUtils.msToKmh(GpsUtils.sanitizeSpeed(pos.speed));
    currentSpeed.value = speedKmh;

    if (speedKmh > maxSpeed.value) maxSpeed.value = speedKmh;

    // Accumulate speed for average
    _speedSum += speedKmh;
    _speedCount++;

    // Distance calculation
    if (_lastPosition != null) {
      final d = GpsUtils.haversineDistance(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        pos.latitude,
        pos.longitude,
      );
      _totalDistance += d;
      currentDistance.value = _totalDistance;
    }
    _lastPosition = pos;

    // Persist point to DB
    if (currentTripId.value != null) {
      _repo.addTripPoint(TripPointEntity(
        tripId: currentTripId.value!,
        latitude: pos.latitude,
        longitude: pos.longitude,
        speedKmh: speedKmh,
        accuracy: pos.accuracy,
        altitude: pos.altitude,
        timestamp: pos.timestamp,
      ));
    }
  }

  Future<void> _loadTrips() async {
    final all = await _repo.getAllTrips();
    trips.assignAll(all);
  }
}
