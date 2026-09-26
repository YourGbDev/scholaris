// lib/features/provider/presentation/widgets/provider_verification_banner.dart
//
// Persistent Verification Status Banner for Provider Consoles.
// Appears at the top of the provider shells without blocking access.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/provider_verification_provider.dart';

class ProviderVerificationBanner extends ConsumerWidget {
  const ProviderVerificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationAsync = ref.watch(currentUserVerificationProvider);

    return verificationAsync.when(
      data: (verification) {
        if (verification == null || verification.status == 'approved') {
          return const SizedBox.shrink();
        }

        if (verification.status == 'rejected') {
          final note = verification.reviewNote?.trim().isNotEmpty == true
              ? ': "${verification.reviewNote!.trim()}"'
              : '';
          return _buildBanner(
            status: 'rejected',
            title: 'Accreditation Status: Revisions Requested',
            message:
                'The committee noted$note. You can update your documentation to resume review.',
            context: context,
            onUpdateDocuments: () {
              context.go(
                  '/become-provider?type=${verification.providerType}&resubmit=true');
            },
          );
        }

        // Pending
        return _buildBanner(
          status: 'pending',
          title: 'Accreditation Status: Verification Pending',
          message:
              'Your submission from ${_formatDate(verification.submittedAt)} is under review by the Scholaris accreditation committee.',
          context: context,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return 'recently';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Widget _buildBanner({
    required String status,
    required String title,
    required String message,
    required BuildContext context,
    VoidCallback? onUpdateDocuments,
  }) {
    final isRejected = status == 'rejected';
    final isPending = status == 'pending';

    final Color bgColor = isRejected
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFFFFBEB);
    final Color borderColor = isRejected
        ? const Color(0xFFFECACA)
        : const Color(0xFFFDE68A);
    final Color iconColor = isRejected
        ? const Color(0xFFDC2626)
        : const Color(0xFFD97706);
    final Color titleColor = isRejected
        ? const Color(0xFF991B1B)
        : const Color(0xFF92400E);
    final Color bodyColor = isRejected
        ? const Color(0xFFB91C1C)
        : const Color(0xFFB45309);

    final icon = isRejected
        ? Icons.error_outline_rounded
        : Icons.hourglass_top_rounded;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: bodyColor,
                    height: 1.35,
                  ),
                ),
                if (isRejected && onUpdateDocuments != null) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onUpdateDocuments,
                    icon: const Icon(Icons.upload_file_rounded, size: 14),
                    label: const Text('Update Documents & Resubmit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF991B1B),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      textStyle: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isPending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                'PENDING',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: iconColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
