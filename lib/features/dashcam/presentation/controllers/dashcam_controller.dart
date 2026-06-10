/// DashcamController
/// Manages camera lifecycle, loop video recording, and storage quotas.

import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../../../trip/presentation/controllers/trip_controller.dart';

class DashcamController extends GetxController {
  CameraController? cameraController;
  final isInitialized = false.obs;
  final isRecording = false.obs;

  final int chunkDurationMinutes = 3;
  final int maxStorageMb = 500;

  Timer? _chunkTimer;

  final TripController _tripController = Get.find<TripController>();

  TripController get tripController => _tripController;

  @override
  void onInit() {
    super.onInit();
    _initCamera();
  }

  @override
  void onClose() {
    _stopLoopRecording();
    cameraController?.dispose();
    super.onClose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: true,
      );

      await cameraController!.initialize();
      isInitialized.value = true;
    } catch (e) {
      Get.snackbar('Camera Error', 'Could not initialize camera: $e');
    }
  }

  Future<void> toggleRecording() async {
    if (!isInitialized.value) return;

    if (isRecording.value) {
      await _stopLoopRecording();
    } else {
      await _startLoopRecording();
    }
  }

  Future<void> _startLoopRecording() async {
    if (cameraController == null) return;

    try {
      await _manageStorageQuota();
      await cameraController!.startVideoRecording();
      isRecording.value = true;

      _chunkTimer = Timer.periodic(
        Duration(minutes: chunkDurationMinutes),
        (_) => _cycleVideoChunk(),
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to start dashcam: $e');
    }
  }

  Future<void> _cycleVideoChunk() async {
    if (!isRecording.value || cameraController == null) return;

    try {
      final file = await cameraController!.stopVideoRecording();
      await _saveVideoChunk(file);
      await _manageStorageQuota();
      await cameraController!.startVideoRecording();
    } catch (e) {
      await _stopLoopRecording();
    }
  }

  Future<void> _stopLoopRecording() async {
    isRecording.value = false;
    _chunkTimer?.cancel();

    if (cameraController?.value.isRecordingVideo ?? false) {
      try {
        final file = await cameraController!.stopVideoRecording();
        await _saveVideoChunk(file);
      } catch (_) {}
    }
  }

  Future<void> _saveVideoChunk(XFile file) async {
    final dir = await _getDashcamDirectory();
    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-');
    final newPath = '${dir.path}/dashcam_$timestamp.mp4';
    await File(file.path).rename(newPath);
  }

  Future<Directory> _getDashcamDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/dashcam');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<void> _manageStorageQuota() async {
    final dir = await _getDashcamDirectory();
    final files = dir.listSync().whereType<File>().toList();
    files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

    int totalSize = 0;
    for (var f in files) {
      totalSize += f.lengthSync();
    }

    final maxBytes = maxStorageMb * 1024 * 1024;

    while (totalSize > maxBytes && files.isNotEmpty) {
      final oldest = files.removeAt(0);
      totalSize -= oldest.lengthSync();
      oldest.deleteSync();
    }
  }
}
