/// AnalysisController — GetX Controller
/// Provides trip analysis: acceleration detection (0→60, 0→100),
/// segment analysis, and statistics for a selected trip.

import 'dart:math' as math;
import 'package:get/get.dart';

import '../../domain/entities/analysis_entity.dart';
import '../../../trip/domain/entities/trip_entity.dart';
import '../../../trip/data/repositories/trip_repository_impl.dart';

class AnalysisController extends GetxController {
  final _repo = TripRepositoryImpl();

  // --------------------------------------------------------------------------
  // Reactive state
  // --------------------------------------------------------------------------

  final selectedTrip = Rxn<TripEntity>();
  final analysisResult = Rxn<TripAnalysisEntity>();
  final isLoading = false.obs;

  // --------------------------------------------------------------------------
  // Public methods
  // --------------------------------------------------------------------------

  Future<void> analyzeTrip(int tripId) async {
    isLoading.value = true;
    selectedTrip.value = await _repo.getTripById(tripId);
    if (selectedTrip.value != null) {
      analysisResult.value = _computeAnalysis(selectedTrip.value!);
    }
    isLoading.value = false;
  }

  // --------------------------------------------------------------------------
  // Private: analysis computation
  // --------------------------------------------------------------------------

  TripAnalysisEntity _computeAnalysis(TripEntity trip) {
    final points = trip.points;

    double topSpeed = 0;
    double totalSpeed = 0;
    int count = 0;

    // Acceleration events: track 0→60 and 0→100
    AccelerationEvent? acc60;
    AccelerationEvent? acc100;
    int? zeroIdx; // index where speed dropped to ~0

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.speedKmh > topSpeed) topSpeed = p.speedKmh;
      totalSpeed += p.speedKmh;
      count++;

      // Detect standing start (< 2 km/h)
      if (p.speedKmh < 2.0) {
        zeroIdx = i;
        acc60 = null;
        acc100 = null;
      }

      // 0 → 60
      if (acc60 == null && zeroIdx != null && p.speedKmh >= 60.0) {
        final startMs = points[zeroIdx].timestamp.millisecondsSinceEpoch;
        final endMs = p.timestamp.millisecondsSinceEpoch;
        final secs = (endMs - startMs) / 1000.0;
        acc60 = AccelerationEvent(
          targetKmh: 60,
          seconds: secs,
          startIndex: zeroIdx,
          endIndex: i,
        );
      }

      // 0 → 100
      if (acc100 == null && zeroIdx != null && p.speedKmh >= 100.0) {
        final startMs = points[zeroIdx].timestamp.millisecondsSinceEpoch;
        final endMs = p.timestamp.millisecondsSinceEpoch;
        final secs = (endMs - startMs) / 1000.0;
        acc100 = AccelerationEvent(
          targetKmh: 100,
          seconds: secs,
          startIndex: zeroIdx,
          endIndex: i,
        );
      }
    }

    final avgSpeed = count > 0 ? totalSpeed / count : 0.0;
    final segments = _buildSegments(points);

    return TripAnalysisEntity(
      tripId: trip.id!,
      topSpeedKmh: topSpeed,
      avgSpeedKmh: avgSpeed,
      totalDistanceMeters: trip.distanceMeters,
      durationSeconds: trip.durationSeconds,
      acceleration0to60: acc60,
      acceleration0to100: acc100,
      segments: segments,
    );
  }

  /// Divides trip into segments of ~1 km.
  List<TripSegment> _buildSegments(List<TripPointEntity> points) {
    if (points.isEmpty) return [];

    final segments = <TripSegment>[];
    int startIdx = 0;
    double segDist = 0;
    double segMaxSpeed = 0;
    double segSpeedSum = 0;
    int segCount = 0;

    for (int i = 1; i < points.length; i++) {
      final curr = points[i];
      // distance between consecutive points is not stored; approximate via speed×time
      segDist += 0; // placeholder — use actual stored distance if available
      segMaxSpeed = math.max(segMaxSpeed, curr.speedKmh);
      segSpeedSum += curr.speedKmh;
      segCount++;

      if (segCount >= 20 || i == points.length - 1) {
        segments.add(TripSegment(
          segmentNumber: segments.length + 1,
          startIndex: startIdx,
          endIndex: i,
          maxSpeedKmh: segMaxSpeed,
          avgSpeedKmh: segCount > 0 ? segSpeedSum / segCount : 0,
          distanceMeters: segDist,
        ));
        startIdx = i;
        segDist = 0;
        segMaxSpeed = 0;
        segSpeedSum = 0;
        segCount = 0;
      }
    }
    return segments;
  }
}
