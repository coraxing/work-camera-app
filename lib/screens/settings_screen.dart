import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/camera_profile.dart';
import '../database/database_helper.dart';

const List<Color> _accentColors = [
  Color(0xFFCF2E2E),
  Color(0xFFE6861A),
  Color(0xFF3B8BEB),
  Color(0xFF34A853),
  Color(0xFF9C27B0),
  Color(0xFF00ACC1),
  Color(0xFFFF6D00),
  Color(0xFF607D8B),
];

class SettingsScreen extends StatefulWidget {
  final CameraProfile? profile;

  const SettingsScreen({super.key, this.profile});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _db = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  late final CameraProfile _p;

  @override
  void initState() {
    super.initState();
    if (widget.profile != null) {
      _p = widget.profile!.copyWith();
    } else {
      _p = CameraProfile(id: const Uuid().v4(), name: '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile == null ? '添加相机' : '编辑相机'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('保存', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionLabel('相机名称'),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _p.name,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: '如：工地现场'),
              validator: (v) => (v == null || v.trim().isEmpty) ? '请输入名称' : null,
              onChanged: (v) => _p.name = v.trim(),
            ),
            const SizedBox(height: 24),

            _sectionLabel('主题色'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: List.generate(_accentColors.length, (i) {
                final selected = _p.colorIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _p.colorIndex = i),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _accentColors[i],
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : null,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            _sectionLabel('文件名模板'),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _p.filenameTemplate,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                helperText: '{相机名} {日期} {时间} {序号}',
                helperStyle: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
              ),
              onChanged: (v) => _p.filenameTemplate = v.trim(),
            ),
            const SizedBox(height: 24),

            _sectionLabel('存储子目录'),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _p.storagePath,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '如：工地现场/',
                helperText: '图片保存在 Pictures/工作记录/{子目录}',
                helperStyle: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
              ),
              onChanged: (v) => _p.storagePath = v.trim(),
            ),
            const SizedBox(height: 24),

            _sectionLabel('图片格式'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _p.imageFormat,
              dropdownColor: const Color(0xFF1C1C1C),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(),
              items: const [
                DropdownMenuItem(value: 'jpg', child: Text('JPEG（体积小）')),
                DropdownMenuItem(value: 'png', child: Text('PNG（无损）')),
              ],
              onChanged: (v) => setState(() => _p.imageFormat = v!),
            ),
            const SizedBox(height: 24),

            _sectionLabel('压缩质量'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _p.compressionQuality.toDouble(),
                    min: 10,
                    max: 100,
                    divisions: 9,
                    activeColor: const Color(0xFFCF2E2E),
                    inactiveColor: const Color(0xFF2C2C2C),
                    label: '${_p.compressionQuality}',
                    onChanged: (v) => setState(() => _p.compressionQuality = v.round()),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${_p.compressionQuality}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _sectionLabel('最大尺寸（0 = 不限制）'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _p.maxWidth == 0 ? '' : _p.maxWidth.toString(),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: '最大宽度'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _p.maxWidth = int.tryParse(v) ?? 0,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _p.maxHeight == 0 ? '' : _p.maxHeight.toString(),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: '最大高度'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _p.maxHeight = int.tryParse(v) ?? 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_p.name.isEmpty) return;
    if (widget.profile == null) {
      await _db.insertProfile(_p);
    } else {
      await _db.updateProfile(_p);
    }
    if (mounted) Navigator.pop(context, true);
  }
}
