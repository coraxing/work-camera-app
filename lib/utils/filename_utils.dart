import 'package:intl/intl.dart';

String resolveFilename(String cameraName, String seqStr, {String? customText}) {
  final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
  if (customText != null && customText.trim().isNotEmpty) {
    return '${cameraName}_${customText.trim()}_${dateStr}_$seqStr';
  }
  return '${cameraName}_${dateStr}_$seqStr';
}
