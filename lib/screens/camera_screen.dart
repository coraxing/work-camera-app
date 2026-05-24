import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import '../models/camera_profile.dart';
import '../database/database_helper.dart';
import '../utils/filename_utils.dart';
import 'photo_viewer_screen.dart';

const _zoomPresets = [0.6, 1.0, 2.0, 3.0, 4.3];

class CameraScreen extends StatefulWidget {
  final CameraProfile profile;
  final CameraDescription camera;

  const CameraScreen({super.key, required this.profile, required this.camera});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  bool _ready = false;
  String? _lastPhotoPath;
  bool _saving = false;

  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;

  Offset? _focusPoint;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _controller.initialize().then((_) async {
      _minZoom = await _controller.getMinZoomLevel();
      _maxZoom = await _controller.getMaxZoomLevel();
      _currentZoom = 1.0;
      await _loadLastPhoto();
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadLastPhoto() async {
    try {
      final baseDir = await _getBaseDir();
      final dirPath = widget.profile.storagePath.isEmpty
          ? baseDir
          : '$baseDir${widget.profile.storagePath}';
      final dir = Directory(dirPath);
      if (!await dir.exists()) return;

      final entries = await dir.list().toList();
      final paths = entries
          .whereType<File>()
          .where((f) {
            final ext = f.path.toLowerCase();
            return ext.endsWith('.jpg') || ext.endsWith('.jpeg') || ext.endsWith('.png');
          })
          .map((f) => f.path)
          .toList();
      if (paths.isNotEmpty) {
        paths.sort((a, b) => b.compareTo(a));
        _lastPhotoPath = paths.first;
      }
    } catch (_) {}
  }

  Future<void> _capture() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final file = await _controller.takePicture();
      await _save(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拍照失败: $e'), duration: const Duration(seconds: 2)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save(XFile capturedFile) async {
    final db = DatabaseHelper();
    final profile = widget.profile;

    final seqStr = await db.incrementDailyCount(profile.id);
    final filename = resolveFilename(profile.name, seqStr, customText: profile.customText);
    final ext = profile.imageFormat;
    final fullName = '$filename.$ext';

    final baseDir = await _getBaseDir();
    final dirPath = profile.storagePath.isEmpty ? baseDir : '$baseDir${profile.storagePath}';
    final dir = Directory(dirPath);
    if (!await dir.exists()) await dir.create(recursive: true);

    final destPath = p.join(dirPath, fullName);

    final bytes = await File(capturedFile.path).readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded != null) {
      img.Image output = decoded;
      if ((profile.maxWidth > 0 && output.width > profile.maxWidth) ||
          (profile.maxHeight > 0 && output.height > profile.maxHeight)) {
        final targetW =
            profile.maxWidth > 0 ? profile.maxWidth : (output.width * profile.maxHeight) ~/ output.height;
        final targetH =
            profile.maxHeight > 0 ? profile.maxHeight : (output.height * profile.maxWidth) ~/ output.width;
        output = img.copyResize(output, width: targetW, height: targetH);
      }
      final encoded = profile.imageFormat == 'png'
          ? img.encodePng(output)
          : img.encodeJpg(output, quality: profile.compressionQuality);
      await File(destPath).writeAsBytes(encoded);
    } else {
      await File(capturedFile.path).copy(destPath);
    }

    if (mounted) setState(() => _lastPhotoPath = destPath);
  }

  Future<String> _getBaseDir() async {
    final dir = await getExternalStorageDirectory();
    final pictures =
        dir?.path.replaceAll('Android/data/com.workcamera.app/files', 'Pictures');
    if (pictures != null && await Directory(pictures).exists()) {
      return '$pictures/工作记录/';
    }
    final appDir = await getApplicationDocumentsDirectory();
    return '${appDir.path}/工作记录/';
  }

  Future<void> _setZoom(double zoom) async {
    final clamped = zoom.clamp(_minZoom, _maxZoom);
    await _controller.setZoomLevel(clamped);
    setState(() => _currentZoom = clamped);
  }

  void _onTapUp(TapUpDetails details) {
    final size = context.size;
    if (size == null) return;
    final dx = (details.localPosition.dx / size.width).clamp(0.0, 1.0);
    final dy = (details.localPosition.dy / size.height).clamp(0.0, 1.0);
    _controller.setFocusPoint(Offset(dx, dy));
    setState(() => _focusPoint = details.localPosition);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _focusPoint = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFCF2E2E))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTapUp: _onTapUp,
                    child: CameraPreview(_controller),
                  ),
                ),
              ),
            ],
          ),

          if (_focusPoint != null)
            Positioned(
              left: _focusPoint!.dx - 28,
              top: _focusPoint!.dy - 28,
              child: IgnorePointer(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFCF2E2E), width: 2),
                  ),
                ),
              ),
            ),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 12,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                widget.profile.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
            ),
          ),

          // Right-side zoom buttons
          Positioned(
            right: 12,
            top: MediaQuery.of(context).padding.top + 60,
            bottom: 160,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _zoomPresets.map((z) {
                  final active = (_currentZoom - z).abs() < 0.05;
                  return GestureDetector(
                    onTap: () => _setZoom(z),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: active ? const Color(0xFFCF2E2E) : Colors.black45,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: active ? const Color(0xFFCF2E2E) : Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${z}x',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: active ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Bottom-left thumbnail
          if (_lastPhotoPath != null) _buildThumbnail(),

          // Bottom-center capture button
          Positioned(
            bottom: 44,
            left: 0,
            right: 0,
            child: _buildCaptureButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    return Positioned(
      bottom: 60,
      left: 20,
      child: GestureDetector(
        onTap: () async {
          final db = DatabaseHelper();
          final updatedProfile = await db.getProfile(widget.profile.id);
          if (updatedProfile != null && mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PhotoViewerScreen(profile: updatedProfile),
              ),
            );
            if (_lastPhotoPath != null && !File(_lastPhotoPath!).existsSync()) {
              setState(() => _lastPhotoPath = null);
            }
          }
        },
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white54, width: 1.5),
            image: DecorationImage(
              image: FileImage(File(_lastPhotoPath!)),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _capture,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFCF2E2E), width: 4),
            ),
            child: Center(
              child: _saving
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                          color: Color(0xFFCF2E2E), strokeWidth: 3),
                    )
                  : Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
