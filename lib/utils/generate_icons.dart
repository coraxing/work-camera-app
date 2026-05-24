import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

void main() {
  final sourcePath = p.join(Directory.current.path, '..', 'icon_preview.png');
  final srcFile = File(sourcePath);

  if (!srcFile.existsSync()) {
    print('请将 icon_preview.png 放在项目根目录的上一级');
    exit(1);
  }

  final bytes = srcFile.readAsBytesSync();
  final original = img.decodeImage(bytes);
  if (original == null) {
    print('无法解析图片');
    exit(1);
  }

  final sizes = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  };

  final resDir = p.join(Directory.current.path, 'android', 'app', 'src', 'main', 'res');

  for (final entry in sizes.entries) {
    final sized = img.copyResize(original, width: entry.value, height: entry.value);
    final dir = Directory(p.join(resDir, 'mipmap-${entry.key}'));
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final outPath = p.join(dir.path, 'ic_launcher.png');
    File(outPath).writeAsBytesSync(img.encodePng(sized));
    print('Generated: $outPath (${entry.value}x${entry.value})');
  }

  print('Done. Launcher icons generated.');
}
