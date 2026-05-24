import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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

            _sectionLabel('卡片壁纸'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickWallpaper,
              child: Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1C),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2C2C2C)),
                  image: _p.wallpaperPath != null &&
                          _p.wallpaperPath!.isNotEmpty
                      ? DecorationImage(
                          image: FileImage(File(_p.wallpaperPath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _p.wallpaperPath == null || _p.wallpaperPath!.isEmpty
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              color: Color(0xFF8E8E93), size: 28),
                          SizedBox(height: 4),
                          Text('点击选择壁纸',
                              style: TextStyle(
                                  color: Color(0xFF8E8E93), fontSize: 12)),
                        ],
                      )
                    : Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('更换',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 11)),
                        ),
                      ),
              ),
            ),
            if (_p.wallpaperPath != null && _p.wallpaperPath!.isNotEmpty)
              TextButton(
                onPressed: () => setState(() => _p.wallpaperPath = null),
                child: const Text('清除壁纸', style: TextStyle(fontSize: 12)),
              ),
            const SizedBox(height: 24),

            _sectionLabel('文件名预览'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1C),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2C2C2C)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 14, color: Color(0xFF8E8E93)),
                  const SizedBox(width: 8),
                  Text(
                    _computeTemplatePreview(),
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _sectionLabel('自定义文本'),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _p.customText ?? '',
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '可选，如：甲方验收',
                helperText: '填入后文件名变为：{相机名}_{自定义文本}_{日期}_{序号}',
                helperStyle: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
              ),
              onChanged: (v) =>
                  setState(() => _p.customText = v.trim().isEmpty ? null : v.trim()),
            ),
            const SizedBox(height: 24),

            _sectionLabel('存储子目录'),
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

  String _computeTemplatePreview() {
    if (_p.customText != null && _p.customText!.trim().isNotEmpty) {
      return '{相机名}_${_p.customText!.trim()}_{日期}_{序号}';
    }
    return '{相机名}_{日期}_{序号}';
  }

  Future<void> _pickWallpaper() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (picked == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final wallpaperDir = Directory('${appDir.path}/wallpapers');
    if (!await wallpaperDir.exists()) await wallpaperDir.create(recursive: true);

    final destPath = '${wallpaperDir.path}/${_p.id}.jpg';
    await File(picked.path).copy(destPath);

    setState(() => _p.wallpaperPath = destPath);
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
