import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import '../models/camera_profile.dart';
import '../database/database_helper.dart';
import '../utils/filename_utils.dart';

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
  XFile? _capturedFile;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _controller.initialize().then((_) {
      setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_capturedFile != null) return;
    final file = await _controller.takePicture();
    setState(() => _capturedFile = file);
  }

  void _retake() => setState(() => _capturedFile = null);

  Future<void> _save() async {
    if (_capturedFile == null) return;

    final db = DatabaseHelper();
    final profile = widget.profile;
    await db.incrementPhotoCount(profile.id);

    final newSeq = profile.photoCount + 1;
    final filename = resolveFilename(profile.filenameTemplate, profile.name, newSeq);
    final ext = profile.imageFormat;
    final fullName = '$filename.$ext';

    final baseDir = await _getBaseDir();
    final dirPath = profile.storagePath.isEmpty ? baseDir : '$baseDir${profile.storagePath}';
    final dir = Directory(dirPath);
    if (!await dir.exists()) await dir.create(recursive: true);

    final destPath = p.join(dirPath, fullName);

    final bytes = await File(_capturedFile!.path).readAsBytes();
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
      await File(_capturedFile!.path).copy(destPath);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已保存：$fullName'), duration: const Duration(seconds: 1)),
      );
      Navigator.pop(context, true);
    }
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
        fit: StackFit.expand,
        children: [
          if (_capturedFile != null)
            Image.file(File(_capturedFile!.path), fit: BoxFit.cover)
          else
            CameraPreview(_controller),

          // Top bar — minimal
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

          // Bottom controls
          Positioned(
            bottom: 44,
            left: 0,
            right: 0,
            child: _capturedFile == null ? _buildCaptureButton() : _buildReviewButtons(),
          ),
        ],
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
              child: Container(
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

  Widget _buildReviewButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _reviewBtn(Icons.refresh, '重拍', () => _retake(), isPrimary: false),
        _reviewBtn(Icons.check, '保存', _save, isPrimary: true),
      ],
    );
  }

  Widget _reviewBtn(IconData icon, String label, VoidCallback onTap,
      {required bool isPrimary}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFFCF2E2E) : const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
