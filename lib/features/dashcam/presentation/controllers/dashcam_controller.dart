/// DashcamController
/// Manages camera lifecycle, loop video recording, per-clip countdown,
/// locked-clip protection, and storage quota enforcement.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../features/settings/presentation/controllers/settings_controller.dart';
import '../../../trip/presentation/controllers/trip_controller.dart';

class DashcamController extends GetxController {
  // ── Camera ─────────────────────────────────────────────────────────────────
  CameraController? cameraController;
  final isInitialized = false.obs;
  final isRecording = false.obs;

  // ── Recording counters ─────────────────────────────────────────────────────
  final totalElapsedSeconds = 0.obs;
  final clipElapsedSeconds = 0.obs;

  /// Duration of each loop clip in seconds. 0 = no loop (single continuous).
  final clipTotalSeconds = 0.obs;

  /// Number of completed segments saved this session.
  final segmentCount = 0.obs;

  // ── Storage & camera info ───────────────────────────────────────────────────
  final storageMbUsed = 0.0.obs;
  final resolutionLabel = '1080p'.obs;

  // ── Clip lock ──────────────────────────────────────────────────────────────
  /// True when the user wants the current clip saved as locked (not auto-deleted).
  final isCurrentClipLocked = false.obs;

  /// Brief flag set during the stop → restart transition.
  final isSwitchingClip = false.obs;

  // ── Internal ───────────────────────────────────────────────────────────────
  Timer? _uiTimer;
  Timer? _cycleTimer;
  DateTime? _recordingStart;
  DateTime? _clipStart;

  /// Paths of clips the user has locked — excluded from quota deletion.
  final Set<String> _lockedFiles = {};

  // ── Dependencies ───────────────────────────────────────────────────────────
  SettingsController get _settings => Get.find<SettingsController>();

  TripController get tripController => Get.find<TripController>();

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _initCamera();
  }

  @override
  void onClose() {
    _stopAll();
    cameraController?.dispose();
    super.onClose();
  }

  // ── Camera initialisation ──────────────────────────────────────────────────

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await cameraController!.initialize();

      final size = cameraController!.value.previewSize;
      if (size != null) {
        final h = math.max(size.width, size.height).toInt();
        resolutionLabel.value = _resLabel(h);
      }

      isInitialized.value = true;
    } catch (e) {
      Get.snackbar(
        'Camera Error',
        'Could not initialize camera',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<void> toggleRecording() async {
    if (!isInitialized.value) return;
    isRecording.value ? await _stopAll() : await _startRecording();
  }

  /// Toggles locked status for the clip currently being recorded.
  void toggleLock() {
    isCurrentClipLocked.value = !isCurrentClipLocked.value;
  }

  // ── Recording start / stop ─────────────────────────────────────────────────

  Future<void> _startRecording() async {
    if (cameraController == null) return;
    try {
      final loop = _settings.loopDuration.value;
      clipTotalSeconds.value = loop.minutes * 60;

      await _manageStorageQuota();
      await cameraController!.startVideoRecording();

      _recordingStart = DateTime.now();
      _clipStart = _recordingStart;
      totalElapsedSeconds.value = 0;
      clipElapsedSeconds.value = 0;
      segmentCount.value = 0;
      isCurrentClipLocked.value = false;
      isSwitchingClip.value = false;
      isRecording.value = true;

      _startUiTimer();
      if (clipTotalSeconds.value > 0) {
        _scheduleCycleTimer(clipTotalSeconds.value);
      }

      unawaited(_updateStorageUsed());
    } catch (e) {
      Get.snackbar('Error', 'Failed to start recording',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _stopAll() async {
    isRecording.value = false;
    _uiTimer?.cancel();
    _cycleTimer?.cancel();
    _uiTimer = null;
    _cycleTimer = null;

    if (cameraController?.value.isRecordingVideo ?? false) {
      try {
        final file = await cameraController!.stopVideoRecording();
        await _saveChunk(file, locked: isCurrentClipLocked.value);
      } catch (_) {}
    }

    isCurrentClipLocked.value = false;
    isSwitchingClip.value = false;
    unawaited(_updateStorageUsed());
  }

  // ── Clip cycling ───────────────────────────────────────────────────────────

  void _scheduleCycleTimer(int seconds) {
    _cycleTimer?.cancel();
    _cycleTimer = Timer(Duration(seconds: seconds), _cycleClip);
  }

  Future<void> _cycleClip() async {
    if (!isRecording.value || cameraController == null) return;
    isSwitchingClip.value = true;

    try {
      final locked = isCurrentClipLocked.value;

      // Stop current clip and save
      final file = await cameraController!.stopVideoRecording();
      await _saveChunk(file, locked: locked);
      unawaited(_manageStorageQuota());

      // Start next clip immediately
      await cameraController!.startVideoRecording();

      _clipStart = DateTime.now();
      clipElapsedSeconds.value = 0;
      isCurrentClipLocked.value = false;
      segmentCount.value++;

      _showSegmentToast();

      if (clipTotalSeconds.value > 0) {
        _scheduleCycleTimer(clipTotalSeconds.value);
      }
    } catch (e) {
      // Try to recover recording after a cycle failure.
      try {
        if (!(cameraController?.value.isRecordingVideo ?? false)) {
          await cameraController!.startVideoRecording();
          _clipStart = DateTime.now();
          clipElapsedSeconds.value = 0;
          if (clipTotalSeconds.value > 0) {
            _scheduleCycleTimer(clipTotalSeconds.value);
          }
        }
      } catch (_) {
        isRecording.value = false;
        _uiTimer?.cancel();
      }
    } finally {
      isSwitchingClip.value = false;
    }
  }

  void _showSegmentToast() {
    Get.rawSnackbar(
      message: 'new_segment_started'.tr,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.black87,
      messageText: Row(children: [
        const Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
        const SizedBox(width: 8),
        Text(
          'new_segment_started'.tr,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ]),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.all(8),
      borderRadius: 10,
    );
  }

  // ── 1-second UI ticker ─────────────────────────────────────────────────────

  void _startUiTimer() {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_recordingStart != null) {
        totalElapsedSeconds.value =
            DateTime.now().difference(_recordingStart!).inSeconds;
      }
      if (_clipStart != null) {
        clipElapsedSeconds.value =
            DateTime.now().difference(_clipStart!).inSeconds;
      }
    });
  }

  // ── File management ────────────────────────────────────────────────────────

  Future<void> _saveChunk(XFile file, {required bool locked}) async {
    final dir = await _getDashcamDir();
    final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final name = 'VID_$ts.mp4';
    final dest = '${dir.path}/$name';
    await File(file.path).rename(dest);
    if (locked) _lockedFiles.add(dest);
  }

  Future<Directory> _getDashcamDir() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/dashcam');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<void> _manageStorageQuota() async {
    final dir = await _getDashcamDir();

    // Collect all files and their sizes
    final allFiles = dir.listSync().whereType<File>().toList();
    int total = 0;
    for (final f in allFiles) {
      total += f.lengthSync();
    }

    // Only consider unlocked files as deletion candidates
    final unlocked = allFiles
        .where((f) => !_lockedFiles.contains(f.path))
        .toList()
      ..sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

    const maxBytes = 500 * 1024 * 1024; // 500 MB hard cap
    while (total > maxBytes && unlocked.isNotEmpty) {
      final oldest = unlocked.removeAt(0);
      total -= oldest.lengthSync();
      await oldest.delete();
    }
  }

  Future<void> _updateStorageUsed() async {
    try {
      final dir = await _getDashcamDir();
      int total = 0;
      for (final f in dir.listSync().whereType<File>()) {
        total += f.lengthSync();
      }
      storageMbUsed.value = total / (1024 * 1024);
    } catch (_) {}
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _resLabel(int maxDimension) {
    if (maxDimension >= 2160) return '4K';
    if (maxDimension >= 1440) return '1440p';
    if (maxDimension >= 1080) return '1080p';
    if (maxDimension >= 720) return '720p';
    return '480p';
  }

  /// Formats seconds as MM:SS.
  static String formatClock(int totalSecs) {
    final m = (totalSecs ~/ 60).toString().padLeft(2, '0');
    final s = (totalSecs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

