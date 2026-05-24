import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../database/database_helper.dart';
import '../models/camera_profile.dart';
import '../widgets/camera_card.dart';
import 'settings_screen.dart';
import 'camera_screen.dart';
import 'trash_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper();
  List<CameraProfile> _profiles = [];
  List<CameraDescription> _cameras = [];
  int _currentTab = 0; // 0=全部, 1=回收站

  @override
  void initState() {
    super.initState();
    _load();
    _initCameras();
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (_) {}
  }

  Future<void> _load() async {
    final list = await _db.getActiveProfiles();
    setState(() => _profiles = list);
  }

  Future<void> _openCamera(CameraProfile p) async {
    final status = await Permission.camera.request();
    if (!status.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('需要相机权限才能拍照')),
      );
      return;
    }
    if (_cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未检测到相机')),
        );
      }
      return;
    }
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CameraScreen(profile: p, camera: _cameras.first),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _deleteProfile(CameraProfile p) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除相机分组', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要删除「${p.name}」吗？\n\n删除后可在回收站保留 30 天，已拍照片不受影响。',
          style: const TextStyle(color: Color(0xFF8E8E93)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: Color(0xFFCF2E2E))),
          ),
        ],
      ),
    );
    if (first != true) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('再次确认', style: TextStyle(color: Colors.white)),
        content: Text(
          '「${p.name}」将被移入回收站。\n确认删除？',
          style: const TextStyle(color: Color(0xFF8E8E93)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('确认删除', style: TextStyle(color: Color(0xFFCF2E2E))),
          ),
        ],
      ),
    );
    if (second != true) return;

    await _db.softDelete(p.id);
    _load();
  }

  Future<void> _addOrEditProfile(CameraProfile? p) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => SettingsScreen(profile: p)),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('工作记录'),
      ),
      body: _currentTab == 0 ? _buildCameraGrid() : _buildTrashView(),
      floatingActionButton: _currentTab == 0
          ? FloatingActionButton(
              onPressed: () => _addOrEditProfile(null),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0D0D0D),
          border: Border(top: BorderSide(color: Color(0xFF2C2C2C), width: 0.5)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.camera_alt_outlined, '全部相机', 0),
            _buildNavItem(Icons.delete_outline, '回收站', 1),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final active = _currentTab == index;
    return GestureDetector(
      onTap: () {
            setState(() => _currentTab = index);
            if (index == 0) _load();
          },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active ? const Color(0xFFCF2E2E) : const Color(0xFF8E8E93),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? const Color(0xFFCF2E2E) : const Color(0xFF8E8E93),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraGrid() {
    if (_profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, size: 48, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text(
              '点击 + 添加相机分组',
              style: TextStyle(color: Color(0xFF8E8E93), fontSize: 15),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: _profiles.length,
        itemBuilder: (_, i) {
          final p = _profiles[i];
          return CameraCard(
            profile: p,
            onTap: () => _openCamera(p),
            onLongPress: () => _addOrEditProfile(p),
          );
        },
      ),
    );
  }

  Widget _buildTrashView() {
    return const TrashScreen();
  }
}
