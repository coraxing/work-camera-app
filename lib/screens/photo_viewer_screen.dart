import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../models/camera_profile.dart';

class PhotoViewerScreen extends StatefulWidget {
  final CameraProfile profile;
  const PhotoViewerScreen({super.key, required this.profile});

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  List<String> _photoPaths = [];
  bool _loading = true;
  bool _gridMode = false;
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadPhotos();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadPhotos() async {
    try {
      final baseDir = await _getBaseDir();
      final dirPath = widget.profile.storagePath.isEmpty
          ? baseDir
          : '$baseDir${widget.profile.storagePath}';
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        setState(() {
          _photoPaths = [];
          _loading = false;
        });
        return;
      }
      final entries = await dir.list().toList();
      final paths = entries
          .whereType<File>()
          .where((f) {
            final ext = f.path.toLowerCase();
            return ext.endsWith('.jpg') ||
                ext.endsWith('.jpeg') ||
                ext.endsWith('.png');
          })
          .map((f) => f.path)
          .toList()
        ..sort((a, b) => b.compareTo(a));
      setState(() {
        _photoPaths = paths;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.profile.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_photoPaths.isNotEmpty)
            IconButton(
              icon: Icon(_gridMode
                  ? Icons.view_agenda_outlined
                  : Icons.grid_view_outlined),
              tooltip: _gridMode ? '全屏' : '网格',
              onPressed: () => setState(() => _gridMode = !_gridMode),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(color: Color(0xFFCF2E2E)))
          : _photoPaths.isEmpty
              ? const Center(
                  child: Text('暂无照片',
                      style: TextStyle(color: Color(0xFF8E8E93))))
              : _gridMode
                  ? _buildGrid()
                  : _buildFullScreen(),
    );
  }

  Widget _buildFullScreen() {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: _photoPaths.length,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemBuilder: (_, i) {
            return InteractiveViewer(
              maxScale: 4.0,
              child: Center(
                child: Image.file(File(_photoPaths[i]), fit: BoxFit.contain),
              ),
            );
          },
        ),
        if (_photoPaths.length > 1)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${_photoPaths.length}',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
      ),
      itemCount: _photoPaths.length,
      itemBuilder: (_, i) {
        return GestureDetector(
          onTap: () {
            _pageController = PageController(initialPage: i);
            setState(() {
              _currentIndex = i;
              _gridMode = false;
            });
          },
          child: Image.file(File(_photoPaths[i]), fit: BoxFit.cover),
        );
      },
    );
  }
}
