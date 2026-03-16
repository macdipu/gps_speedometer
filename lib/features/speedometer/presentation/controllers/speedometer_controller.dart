/// SpeedometerController — GetX Controller
/// Manages real-time GPS speed tracking, unit switching, and session max-speed.
/// Follows Presentation layer of the Speedometer feature.

import 'dart:async';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/utils/gps_utils.dart';
import '../../domain/entities/speedometer_entity.dart';
import '../../data/repositories/speedometer_repository_impl.dart';

/// View modes for the speedometer screen
enum SpeedometerMode { digital, analog, hud, map }

class SpeedometerController extends GetxController {
  final _repo = SpeedometerRepositoryImpl();

  // --------------------------------------------------------------------------
  // Reactive state
  // --------------------------------------------------------------------------

  /// Current speedometer entity (speed, unit, heading, etc.)
  final speedometer = SpeedometerEntity.empty().obs;

  /// Active view mode
  final mode = SpeedometerMode.digital.obs;

  /// Whether GPS is currently connected
  final isConnected = false.obs;

  /// Error message if GPS fails
  final errorMessage = RxnString();

  /// Session max speed in display unit
  double _sessionMaxSpeed = 0.0;

  StreamSubscription<Position>? _positionSub;

  // --------------------------------------------------------------------------
  // Lifecycle
  // --------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();
    _startTracking();
  }

  @override
  void onClose() {
    _positionSub?.cancel();
    super.onClose();
  }

  // --------------------------------------------------------------------------
  // Public methods
  // --------------------------------------------------------------------------

  void switchUnit() {
    final newUnit = speedometer.value.unit == SpeedUnit.kmh
        ? SpeedUnit.mph
        : SpeedUnit.kmh;
    _sessionMaxSpeed = 0; // Reset max when switching units
    speedometer.value = speedometer.value.copyWith(unit: newUnit, maxSpeed: 0);
  }

  void setMode(SpeedometerMode m) => mode.value = m;

  // --------------------------------------------------------------------------
  // Private: GPS stream
  // --------------------------------------------------------------------------

  Future<void> _startTracking() async {
    try {
      await GpsUtils.ensurePermissions();
      isConnected.value = true;
      errorMessage.value = null;

      _positionSub = _repo.positionStream.listen(
        _onPosition,
        onError: _onError,
      );
    } catch (e) {
      errorMessage.value = e.toString();
      isConnected.value = false;
    }
  }

  void _onPosition(Position pos) {
    final rawSpeed = GpsUtils.sanitizeSpeed(pos.speed); // m/s
    final displaySpeed = GpsUtils.convertSpeed(rawSpeed, speedometer.value.unit);

    if (displaySpeed > _sessionMaxSpeed) {
      _sessionMaxSpeed = displaySpeed;
    }

    speedometer.value = SpeedometerEntity(
      speedMs: rawSpeed,
      unit: speedometer.value.unit,
      maxSpeed: _sessionMaxSpeed,
      accuracy: pos.accuracy,
      altitude: pos.altitude,
      latitude: pos.latitude,
      longitude: pos.longitude,
      heading: pos.heading,
      timestamp: pos.timestamp,
    );
  }

  void _onError(Object error) {
    errorMessage.value = error.toString();
    isConnected.value = false;
  }
}
