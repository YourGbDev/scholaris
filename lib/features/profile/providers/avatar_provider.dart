// lib/features/profile/providers/avatar_provider.dart
//
// Manages the student's avatar state and persistence.
// Decoupled from the Supabase database (profiles table schema has no avatar column).
// Backed by SharedPreferences scoped by user ID.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/controllers/auth_controller.dart';
import '../models/avatar_item.dart';

class AvatarState {
  final String avatarId;
  final bool isRealPhoto;
  final String? photoPath;
  final bool isSkipped;

  const AvatarState({
    this.avatarId = AvatarItem.defaultAvatarId,
    this.isRealPhoto = false,
    this.photoPath,
    this.isSkipped = false,
  });

  AvatarState copyWith({
    String? avatarId,
    bool? isRealPhoto,
    String? photoPath,
    bool? isSkipped,
    bool clearPhotoPath = false,
  }) {
    return AvatarState(
      avatarId: avatarId ?? this.avatarId,
      isRealPhoto: isRealPhoto ?? this.isRealPhoto,
      photoPath: clearPhotoPath ? null : (photoPath ?? this.photoPath),
      isSkipped: isSkipped ?? this.isSkipped,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvatarState &&
          runtimeType == other.runtimeType &&
          avatarId == other.avatarId &&
          isRealPhoto == other.isRealPhoto &&
          photoPath == other.photoPath &&
          isSkipped == other.isSkipped;

  @override
  int get hashCode =>
      avatarId.hashCode ^
      isRealPhoto.hashCode ^
      photoPath.hashCode ^
      isSkipped.hashCode;
}

class AvatarNotifier extends StateNotifier<AvatarState> {
  AvatarNotifier({
    required this.userId,
    AvatarState? initialState,
  }) : super(initialState ?? const AvatarState()) {
    if (initialState == null) {
      _loadFromPrefs();
    }
  }

  final String userId;

  String get _keyAvatarId => 'user_avatar_id_$userId';
  String get _keyIsReal => 'user_avatar_is_real_$userId';
  String get _keyPhotoPath => 'user_avatar_path_$userId';
  String get _keySkipped => 'user_avatar_skipped_$userId';

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_keyAvatarId);
      final isReal = prefs.getBool(_keyIsReal) ?? false;
      final path = prefs.getString(_keyPhotoPath);
      final skipped = prefs.getBool(_keySkipped) ?? false;

      state = AvatarState(
        avatarId: savedId ?? AvatarItem.defaultAvatarId,
        isRealPhoto: isReal,
        photoPath: path,
        isSkipped: skipped,
      );
    } catch (_) {
      // Fallback to default in-memory state on storage errors
    }
  }

  Future<void> selectDoodle(String avatarId) async {
    state = state.copyWith(
      avatarId: avatarId,
      isRealPhoto: false,
      clearPhotoPath: true,
      isSkipped: false,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAvatarId, avatarId);
      await prefs.setBool(_keyIsReal, false);
      await prefs.remove(_keyPhotoPath);
      await prefs.setBool(_keySkipped, false);
    } catch (_) {}
  }

  Future<void> uploadRealPhoto({String? path}) async {
    final photoPath = path ?? 'verified_id_photo_$userId.jpg';
    state = state.copyWith(
      isRealPhoto: true,
      photoPath: photoPath,
      isSkipped: false,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsReal, true);
      await prefs.setString(_keyPhotoPath, photoPath);
      await prefs.setBool(_keySkipped, false);
    } catch (_) {}
  }

  Future<void> skipToDefault() async {
    state = state.copyWith(
      avatarId: AvatarItem.defaultAvatarId,
      isRealPhoto: false,
      clearPhotoPath: true,
      isSkipped: true,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAvatarId, AvatarItem.defaultAvatarId);
      await prefs.setBool(_keyIsReal, false);
      await prefs.remove(_keyPhotoPath);
      await prefs.setBool(_keySkipped, true);
    } catch (_) {}
  }

  Future<void> reset() async {
    state = const AvatarState();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAvatarId);
      await prefs.remove(_keyIsReal);
      await prefs.remove(_keyPhotoPath);
      await prefs.remove(_keySkipped);
    } catch (_) {}
  }
}

final avatarProvider =
    StateNotifierProvider.family<AvatarNotifier, AvatarState, String>(
  (ref, userId) => AvatarNotifier(userId: userId),
);

final currentAvatarProvider = Provider<AvatarState>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const AvatarState();
  return ref.watch(avatarProvider(userId));
});
