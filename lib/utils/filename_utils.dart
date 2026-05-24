import 'package:intl/intl.dart';

String resolveFilename(String template, String cameraName, int seqNum) {
  final now = DateTime.now();
  return template
      .replaceAll('{相机名}', cameraName)
      .replaceAll('{日期}', DateFormat('yyyyMMdd').format(now))
      .replaceAll('{时间}', DateFormat('HHmmss').format(now))
      .replaceAll('{序号}', seqNum.toString().padLeft(3, '0'));
}
