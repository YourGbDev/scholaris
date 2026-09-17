// lib/features/scholarships/presentation/widgets/identity_photo_dialog.dart
//
// Modal dialog displayed when a student begins the scholarship application flow
// while still having a default/placeholder avatar. Explains provider identity
// verification requirements and allows uploading from camera or gallery.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../profile/providers/avatar_provider.dart';

class IdentityPhotoRequiredDialog extends ConsumerWidget {
  const IdentityPhotoRequiredDialog({
    super.key,
    required this.userId,
    this.scholarshipTitle,
  });

  final String userId;
  final String? scholarshipTitle;

  static Future<bool> show(
    BuildContext context, {
    required String userId,
    String? scholarshipTitle,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => IdentityPhotoRequiredDialog(
        userId: userId,
        scholarshipTitle: scholarshipTitle,
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(avatarProvider(userId).notifier);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
            // Icon emblem
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEFF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFC3D2FF), width: 2),
              ),
              child: const Center(
                child: Icon(
                  Icons.add_a_photo_rounded,
                  size: 30,
                  color: kNavyTrust,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Identity Photo Required',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF161C27),
              ),
            ),
            const SizedBox(height: 6),

            // Subtitle
            Text(
              'Official Student Verification',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: kPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 14),

            // Explanation box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8E5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_user_rounded,
                        size: 16,
                        color: Color(0xFF145131),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Scholarship providers require an authentic, real photograph of you for identity verification before evaluating your application.',
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            height: 1.45,
                            color: const Color(0xFF404942),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Applications submitted with cartoon or placeholder avatars cannot be deliberated by scholarship committees.',
                    style: GoogleFonts.openSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFBA1A1A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const ValueKey('photo-upload-camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: Text(
                  'Take Photo with Camera',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  notifier.uploadRealPhoto(path: 'camera_verified_$userId.jpg');
                  Navigator.of(context).pop(true);
                },
              ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey('photo-upload-gallery'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: const BorderSide(color: kPrimary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.photo_library_rounded, size: 18, color: kPrimary),
                label: Text(
                  'Upload from Gallery',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
                onPressed: () {
                  notifier.uploadRealPhoto(path: 'gallery_verified_$userId.jpg');
                  Navigator.of(context).pop(true);
                },
              ),
            ),
          ],
          ),
        ),
      ),
      actions: [
        Center(
          child: TextButton(
            key: const ValueKey('photo-upload-cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.openSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF707971),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
