// lib/features/profile/presentation/widgets/avatar_selector_sheet.dart
//
// Modal sheet allowing the student to choose among the 6 doodle avatars or
// upload a verified real photo from camera or gallery.

import 'package:scholaris/shared/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/theme/app_motion.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../models/avatar_item.dart';
import '../../providers/avatar_provider.dart';
import 'avatar_display.dart';

class AvatarSelectorSheet extends ConsumerWidget {
  const AvatarSelectorSheet({super.key, required this.userId});

  final String userId;

  static Future<void> show(BuildContext context, String userId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AvatarSelectorSheet(userId: userId),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatarState = ref.watch(avatarProvider(userId));
    final notifier = ref.read(avatarProvider(userId).notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Avatar',
                        style: AppTypography.style(
                          AppTextRole.sectionTitle,
                          fontSize: 17,
                          color: kNavyTrust,
                          height: 1.2,
                          letterSpacing: -0.15,
                        ),
                      ),
                      Text(
                        'Choose a cartoon doodle or upload a real photo.',
                        style: AppTypography.style(
                          AppTextRole.subtitle,
                          fontSize: 12,
                          color: const Color(0xFF707971),
                          height: 1.4,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  padding: const EdgeInsets.all(10),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Upfront Deliberation Notice
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFF8D6E63),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Note: Doodle avatars are great for browsing, but submitting applications requires a verified face photo for scholarship committee deliberation.',
                      style: AppTypography.style(
                        AppTextRole.caption,
                        fontSize: 11,
                        color: const Color(0xFF5D4037),
                        height: 1.4,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Live preview
            Center(
              child: Column(
                children: [
                  AvatarDisplay(
                    avatarId: avatarState.avatarId,
                    isRealPhoto: avatarState.isRealPhoto,
                    photoPath: avatarState.photoPath,
                    size: 72,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    avatarState.isRealPhoto
                        ? 'Verified Real Photo'
                        : AvatarItem.findById(avatarState.avatarId).name,
                    style: AppTypography.style(
                      AppTextRole.label,
                      fontSize: 13,
                      color: kNavyTrust,
                      height: 1.2,
                      letterSpacing: -0.15,
                    ),
                  ),
                  Text(
                    avatarState.isRealPhoto
                        ? 'Eligible for scholarship deliberation'
                        : 'Placeholder Avatar',
                    style: AppTypography.style(
                      AppTextRole.subtitle,
                      fontSize: 11,
                      color: avatarState.isRealPhoto
                          ? kPrimary
                          : const Color(0xFFBA1A1A),
                      height: 1.4,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Text(
              'Cartoon Doodle Avatars',
              style: AppTypography.style(
                AppTextRole.sectionTitle,
                fontSize: 13,
                color: kNavyTrust,
                height: 1.2,
                letterSpacing: -0.15,
              ),
            ),
            const SizedBox(height: 8),

            // Doodle Grid / Row
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AvatarItem.presets.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final preset = AvatarItem.presets[index];
                  final isSelected =
                      !avatarState.isRealPhoto &&
                      avatarState.avatarId == preset.id;

                  return PressableScale(
                    child: Semantics(
                      label: '${preset.name} doodle avatar',
                      button: true,
                      selected: isSelected,
                      child: GestureDetector(
                        key: ValueKey('avatar-option-${preset.id}'),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          notifier.selectDoodle(preset.id);
                        },
                        child: Container(
                          width: 72,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? kPrimary.withValues(alpha: 0.08)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? kPrimary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AvatarDisplay(
                                avatarId: preset.id,
                                isRealPhoto: false,
                                size: 46,
                                showVerifiedBadge: false,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                preset.name.split(' ').first,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.style(
                                  AppTextRole.label,
                                  fontSize: 10,
                                  color: isSelected
                                      ? kPrimary
                                      : const Color(0xFF404942),
                                  height: 1.4,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            Text(
              'Identity Verification Photo',
              style: AppTypography.style(
                AppTextRole.sectionTitle,
                fontSize: 13,
                color: kNavyTrust,
                height: 1.2,
                letterSpacing: -0.15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Scholarship providers require a real photograph for official verification.',
              style: AppTypography.style(
                AppTextRole.subtitle,
                fontSize: 11,
                color: const Color(0xFF707971),
                height: 1.4,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: PressableScale(
                    child: OutlinedButton.icon(
                      key: const ValueKey('avatar-camera-btn'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: kPrimary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(
                        Icons.camera_alt_rounded,
                        size: 18,
                        color: kPrimary,
                      ),
                      label: Text(
                        'Take Photo',
                        style: AppTypography.style(
                          AppTextRole.button,
                          fontSize: 12,
                          color: kPrimary,
                          height: 1.2,
                          letterSpacing: -0.15,
                        ),
                      ),
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await notifier.uploadRealPhoto(
                          path: 'camera_photo_$userId.jpg',
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Verified real photo set successfully!',
                              ),
                              backgroundColor: Color(0xFF145131),
                            ),
                          );
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PressableScale(
                    child: ElevatedButton.icon(
                      key: const ValueKey('avatar-gallery-btn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                      label: Text(
                        'From Gallery',
                        style: AppTypography.style(
                          AppTextRole.button,
                          fontSize: 12,
                          height: 1.2,
                          letterSpacing: -0.15,
                        ),
                      ),
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        await notifier.uploadRealPhoto(
                          path: 'gallery_photo_$userId.jpg',
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Verified real photo uploaded successfully!',
                              ),
                              backgroundColor: Color(0xFF145131),
                            ),
                          );
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
