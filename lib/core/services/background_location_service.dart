/// BackgroundLocationService
/// Manages a background isolate (flutter_background_service) that keeps
/// Geolocator broadcasting position updates even when the app is minimized.
///
/// Architecture:
/// - The background isolate streams GPS positions to SharedPreferences so the
///   foreground TripController can read them when it wakes up.
/// - A simple sendData / onData channel bridges the isolate with the UI.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Keys used for inter-isolate communication
const _kLatKey = 'bg_lat';
const _kLngKey = 'bg_lng';
const _kSpeedKey = 'bg_speed_kmh';
const _kAltKey = 'bg_altitude';
const _kTsKey = 'bg_timestamp';

class BackgroundLocationService {
  static final BackgroundLocationService _instance =
      BackgroundLocationService._();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._();

  // --------------------------------------------------------------------------
  // Initialisation — call once from main()
  // --------------------------------------------------------------------------

  static Future<void> init() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'gps_speedometer_bg',
        initialNotificationTitle: 'GPS Speedometer',
        initialNotificationContent: 'Recording trip in background…',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Public control surface
  // --------------------------------------------------------------------------

  Future<void> startService() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }

  bool get isRunning => false; // Use stream-based check if needed

  // --------------------------------------------------------------------------
  // Background isolate entry point (runs in separate isolate)
  // --------------------------------------------------------------------------

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    // Allow the foreground to stop us gracefully
    service.on('stopService').listen((_) async {
      await service.stopSelf();
    });

    // Update notification content periodically
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // metres
      ),
    ).listen((pos) async {
      final speedKmh = (pos.speed < 0 ? 0 : pos.speed) * 3.6;

      // Persist to SharedPreferences so the UI can read on resume
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kLatKey, pos.latitude);
      await prefs.setDouble(_kLngKey, pos.longitude);
      await prefs.setDouble(_kSpeedKey, speedKmh);
      await prefs.setDouble(_kAltKey, pos.altitude);
      await prefs.setString(_kTsKey, pos.timestamp.toIso8601String());

      // Also broadcast over the service channel so live UI can pick it up
      service.invoke('position', {
        'lat': pos.latitude,
        'lng': pos.longitude,
        'speed_kmh': speedKmh,
        'altitude': pos.altitude,
        'timestamp': pos.timestamp.toIso8601String(),
        'accuracy': pos.accuracy,
        'heading': pos.heading,
      });

      // Update the persistent notification with current speed
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: 'GPS Speedometer — Recording',
          content: '🚗 ${speedKmh.toStringAsFixed(1)} km/h',
        );
      }
    });
  }

  /// iOS requires a separate top-level entry point for background fetch
  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    return true;
  }
}
