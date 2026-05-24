import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/camera_profile.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  final _db = DatabaseHelper();
  List<CameraProfile> _profiles = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _db.purgeExpired();
    final list = await _db.getTrashProfiles();
    setState(() => _profiles = list);
  }

  String _remainingDays(DateTime deletedAt) {
    final restoreUntil = deletedAt.add(const Duration(days: 30));
    final diff = restoreUntil.difference(DateTime.now()).inDays;
    if (diff <= 0) return '即将清除';
    return '剩余 $diff 天';
  }

  Future<void> _restore(CameraProfile p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复相机分组', style: TextStyle(color: Colors.white)),
        content: Text(
          '确定要恢复「${p.name}」吗？',
          style: const TextStyle(color: Color(0xFF8E8E93)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('恢复', style: TextStyle(color: Color(0xFFCF2E2E))),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db.restore(p.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, size: 48, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            const Text('回收站为空', style: TextStyle(color: Color(0xFF8E8E93), fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _profiles.length,
      itemBuilder: (_, i) {
        final p = _profiles[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF2C2C2C), width: 0.5),
          ),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFCF2E2E).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_outline, color: Color(0xFFCF2E2E), size: 20),
            ),
            title: Text(p.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              _remainingDays(p.deletedAt!),
              style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
            ),
            trailing: TextButton(
              onPressed: () => _restore(p),
              child: const Text('恢复'),
            ),
          ),
        );
      },
    );
  }
}
