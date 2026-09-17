// lib/features/profile/presentation/widgets/avatar_selector_sheet.dart
//
// Modal sheet allowing the student to choose among the 6 doodle avatars or
// upload a verified real photo from camera or gallery.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../models/avatar_item.dart';
import '../../providers/avatar_provider.dart';
import 'avatar_display.dart';

class AvatarSelectorSheet extends ConsumerWidget {
  const AvatarSelectorSheet({
    super.key,
    required this.userId,
  });

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
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: kNavyTrust,
                        ),
                      ),
                      Text(
                        'Choose a cartoon doodle or upload a real photo.',
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          color: const Color(0xFF707971),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

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
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kNavyTrust,
                    ),
                  ),
                  Text(
                    avatarState.isRealPhoto
                        ? 'Eligible for scholarship deliberation'
                        : 'Placeholder Avatar',
                    style: GoogleFonts.openSans(
                      fontSize: 11,
                      color: avatarState.isRealPhoto
                          ? kPrimary
                          : const Color(0xFFBA1A1A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Text(
              'Cartoon Doodle Avatars',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kNavyTrust,
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
                      !avatarState.isRealPhoto && avatarState.avatarId == preset.id;

                  return GestureDetector(
                    key: ValueKey('avatar-option-${preset.id}'),
                    onTap: () {
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
                            style: GoogleFonts.openSans(
                              fontSize: 10,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected ? kPrimary : const Color(0xFF404942),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),

            Text(
              'Identity Verification Photo',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kNavyTrust,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Scholarship providers require a real photograph for official verification.',
              style: GoogleFonts.openSans(
                fontSize: 11,
                color: const Color(0xFF707971),
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const ValueKey('avatar-camera-btn'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: kPrimary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.camera_alt_rounded, size: 18, color: kPrimary),
                    label: Text(
                      'Take Photo',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kPrimary,
                      ),
                    ),
                    onPressed: () async {
                      await notifier.uploadRealPhoto(path: 'camera_photo_$userId.jpg');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Verified real photo set successfully!'),
                            backgroundColor: Color(0xFF145131),
                          ),
                        );
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
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
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () async {
                      await notifier.uploadRealPhoto(path: 'gallery_photo_$userId.jpg');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Verified real photo uploaded successfully!'),
                            backgroundColor: Color(0xFF145131),
                          ),
                        );
                        Navigator.of(context).pop();
                      }
                    },
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
