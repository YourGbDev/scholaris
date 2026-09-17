// lib/features/profile/models/avatar_item.dart
//
// Defines cartoon/doodle avatar presets matching the Stitch mobile app design
// references (flat, illustrated, non-photorealistic playful doodles).

import 'package:flutter/material.dart';

class AvatarItem {
  final String id;
  final String name;
  final String subtitle;
  final Color backgroundColor;
  final Color strokeColor;
  final Color accentColor;

  const AvatarItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.backgroundColor,
    required this.strokeColor,
    required this.accentColor,
  });

  /// The standard set of 6 default cartoon/doodle-style avatars from Stitch designs.
  static const List<AvatarItem> presets = [
    AvatarItem(
      id: 'doodle_scholar',
      name: 'Iskolar Classic',
      subtitle: 'Glasses & UP Tassel',
      backgroundColor: Color(0xFFB3F1C6),
      strokeColor: Color(0xFF00351C),
      accentColor: Color(0xFFFABC28),
    ),
    AvatarItem(
      id: 'doodle_cheerful',
      name: 'Playful Iskolar',
      subtitle: 'Joyful & Energetic',
      backgroundColor: Color(0xFFD3EED8),
      strokeColor: Color(0xFF134E2D),
      accentColor: Color(0xFF2E7D32),
    ),
    AvatarItem(
      id: 'doodle_graduate',
      name: 'Graduate Iskolar',
      subtitle: 'Mortarboard Cap',
      backgroundColor: Color(0xFFCCE8E1),
      strokeColor: Color(0xFF0D47A1),
      accentColor: Color(0xFF1976D2),
    ),
    AvatarItem(
      id: 'doodle_explorer',
      name: 'Creative Iskolar',
      subtitle: 'Expressive & Bold',
      backgroundColor: Color(0xFFFFDAD6),
      strokeColor: Color(0xFF93000A),
      accentColor: Color(0xFFBA1A1A),
    ),
    AvatarItem(
      id: 'doodle_innovator',
      name: 'STEM Innovator',
      subtitle: 'Tech & Research',
      backgroundColor: Color(0xFFFFF0D4),
      strokeColor: Color(0xFF7A4B00),
      accentColor: Color(0xFFF57C00),
    ),
    AvatarItem(
      id: 'doodle_achiever',
      name: 'Civic Iskolar',
      subtitle: 'Leadership & Honor',
      backgroundColor: Color(0xFFE8EEFF),
      strokeColor: Color(0xFF1B2C6E),
      accentColor: Color(0xFF3F51B5),
    ),
  ];

  static const String defaultAvatarId = 'doodle_scholar';

  static AvatarItem findById(String id) {
    return presets.firstWhere(
      (item) => item.id == id,
      orElse: () => presets.first,
    );
  }
}
