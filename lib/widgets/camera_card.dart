import 'dart:io';
import 'package:flutter/material.dart';
import '../models/camera_profile.dart';

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

class CameraCard extends StatelessWidget {
  final CameraProfile profile;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const CameraCard({
    super.key,
    required this.profile,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _accentColors[profile.colorIndex % _accentColors.length];

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2C2C2C), width: 0.5),
          image: profile.wallpaperPath != null &&
                  profile.wallpaperPath!.isNotEmpty
              ? DecorationImage(
                  image: FileImage(File(profile.wallpaperPath!)),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.55),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                color: accent,
                size: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              profile.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
