import 'package:flutter/material.dart';

/// One entry in the preset avatar gallery.
class AvatarPreset {
  final Color bg;
  final IconData icon;
  const AvatarPreset(this.bg, this.icon);
}

/// The pickable preset avatars. The stored `avatarId` is an index into this list.
const List<AvatarPreset> kAvatarPresets = [
  AvatarPreset(Color(0xFF1A9882), Icons.face),
  AvatarPreset(Color(0xFF4A6CF7), Icons.face_2),
  AvatarPreset(Color(0xFF9C5FCB), Icons.face_3),
  AvatarPreset(Color(0xFFE07A3E), Icons.face_4),
  AvatarPreset(Color(0xFFD44FAB), Icons.face_5),
  AvatarPreset(Color(0xFF2E9E5B), Icons.face_6),
  AvatarPreset(Color(0xFF5B6BD6), Icons.sentiment_satisfied_alt),
  AvatarPreset(Color(0xFFE0544D), Icons.emoji_emotions),
  AvatarPreset(Color(0xFF8D6E63), Icons.self_improvement),
  AvatarPreset(Color(0xFF1499A8), Icons.psychology_alt),
  AvatarPreset(Color(0xFFE0A92B), Icons.spa),
  AvatarPreset(Color(0xFF5B8DB8), Icons.person),
];

/// Renders a user's avatar from a preset id, falling back to initials (or a
/// person icon) when no preset is set.
class UserAvatar extends StatelessWidget {
  final int? avatarId;
  final String? name;
  final double size;

  const UserAvatar({
    super.key,
    required this.avatarId,
    this.name,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    if (avatarId != null && avatarId! >= 0 && avatarId! < kAvatarPresets.length) {
      final preset = kAvatarPresets[avatarId!];
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: preset.bg, shape: BoxShape.circle),
        child: Icon(preset.icon, color: Colors.white, size: size * 0.55),
      );
    }

    final initials = _initials(name);
    if (initials.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
            color: Color(0xFFE0EEF8), shape: BoxShape.circle),
        child: Icon(Icons.person, color: const Color(0xFF5B8DB8), size: size * 0.55),
      );
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
          color: Color(0xFF1A9882), shape: BoxShape.circle),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static String _initials(String? name) {
    if (name == null) return '';
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
