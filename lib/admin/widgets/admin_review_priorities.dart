import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/admin/presentation/admin_theme.dart';
import '../../features/provider/providers/provider_verification_provider.dart';
import '../../features/provider/repositories/support_concern_repository.dart';
import '../../features/safety/data/safety_report_repository.dart';
import '../../shared/theme/app_motion.dart';

/// Existing queues only: this does not create alerts or infer findings of fraud.
class AdminReviewPriorities extends ConsumerWidget {
  const AdminReviewPriorities({
    super.key,
    required this.onProviders,
    required this.onReports,
  });
  final VoidCallback onProviders;
  final VoidCallback onReports;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providers = ref.watch(adminProviderVerificationsProvider);
    final concerns = ref.watch(supportConcernsProvider(null));
    final safetyReportsAsync = ref.watch(adminSafetyReportsProvider);
    final providerCard = providers.when(
      skipLoadingOnRefresh: false,
      loading: () => _queue(
        context,
        badgeLabel: 'PROVIDER REGISTRATION',
        badgeIcon: Icons.hourglass_top_rounded,
        title: 'Loading provider applications…',
        detail: 'Organization and individual submissions',
        action: 'Open provider approvals',
        onTap: onProviders,
        isLoading: true,
      ),
      error: (_, _) => _queue(
        context,
        badgeLabel: 'SERVICE ALERT',
        badgeIcon: Icons.warning_amber_rounded,
        title: 'Provider applications unavailable',
        detail: 'Open the queue or try loading it again.',
        action: 'Retry provider applications',
        onTap: () => ref.invalidate(adminProviderVerificationsProvider),
        isError: true,
      ),
      data: (rows) {
        final pending = rows.where((r) => r.isPending).toList();
        final orgs = pending
            .where((r) => r.providerType == 'organization')
            .length;
        return _queue(
          context,
          badgeLabel: 'PROVIDER REGISTRATIONS',
          badgeIcon: Icons.verified_user_outlined,
          badgeCount: pending.length,
          title: '${pending.length} pending provider applications',
          detail:
              '$orgs organization${orgs == 1 ? '' : 's'} · ${pending.length - orgs} individual${pending.length - orgs == 1 ? '' : 's'}',
          action: 'Review providers',
          onTap: onProviders,
        );
      },
    );

    final safetyLoading = concerns.isLoading || safetyReportsAsync.isLoading;
    final safetyError = concerns.hasError || safetyReportsAsync.hasError;

    final Widget safetyCard;
    if (safetyLoading) {
      safetyCard = _queue(
        context,
        badgeLabel: 'STUDENT SAFETY',
        badgeIcon: Icons.hourglass_top_rounded,
        title: 'Loading safety reports…',
        detail: 'Private student reports',
        action: 'Open Reports & safety',
        onTap: onReports,
        isLoading: true,
      );
    } else if (safetyError) {
      safetyCard = _queue(
        context,
        badgeLabel: 'SERVICE ALERT',
        badgeIcon: Icons.warning_amber_rounded,
        title: 'Safety reports unavailable',
        detail: 'The queue could not be loaded. Please retry.',
        action: 'Retry safety reports',
        onTap: () {
          ref.invalidate(supportConcernsProvider(null));
          ref.invalidate(adminSafetyReportsProvider);
        },
        isError: true,
      );
    } else {
      final legacyRows = concerns.value ?? const [];
      final newReports = safetyReportsAsync.value ?? const [];

      final openLegacy = legacyRows
          .where(
            (r) =>
                r['category'] != 'payment_record_correction' &&
                ['open', 'under_review'].contains(r['status']),
          )
          .toList();
      final legacyUrgent = openLegacy
          .where(
            (r) => [
              'unsafe_request',
              'unsafe_meetup',
              'harassment',
              'threat',
            ].contains(r['category']),
          )
          .length;

      final openNew = newReports
          .where((r) => r.isOpen || r.isUnderReview)
          .toList();
      final newUrgent = openNew
          .where((r) => r.isUrgentCategory)
          .length;

      final totalOpen = openLegacy.length + openNew.length;
      final totalUrgent = legacyUrgent + newUrgent;

      safetyCard = _queue(
        context,
        badgeLabel: totalUrgent > 0 ? 'URGENT REVIEW' : 'STUDENT SAFETY',
        badgeIcon: totalUrgent > 0 ? Icons.flag_rounded : Icons.shield_outlined,
        badgeCount: totalUrgent > 0 ? totalUrgent : totalOpen,
        title: totalUrgent > 0
            ? '$totalUrgent urgent report${totalUrgent == 1 ? '' : 's'} need${totalUrgent == 1 ? 's' : ''} review'
            : totalOpen == 0
                ? 'No unresolved student reports'
                : '$totalOpen student report${totalOpen == 1 ? '' : 's'} awaiting review',
        detail:
            'Review concerns carefully. Reports are not findings of wrongdoing.',
        action: 'Review safety reports',
        onTap: onReports,
        urgent: totalUrgent > 0,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Needs your attention',
          style: adminHeaderStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Review providers, protect students, and keep decisions accountable.',
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, box) =>
              box.maxWidth >= 760 &&
                  MediaQuery.textScalerOf(context).scale(1) < 1.5
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: providerCard),
                    const SizedBox(width: 16),
                    Expanded(child: safetyCard),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    providerCard,
                    const SizedBox(height: 12),
                    safetyCard,
                  ],
                ),
        ),
      ],
    );
  }

  Widget _queue(
    BuildContext context, {
    required String badgeLabel,
    required IconData badgeIcon,
    int? badgeCount,
    required String title,
    required String detail,
    required String action,
    required VoidCallback onTap,
    bool urgent = false,
    bool isError = false,
    bool isLoading = false,
  }) {
    final Color badgeBg;
    final Color badgeFg;
    final Color cardBg;
    final Color borderColor;
    final Color buttonBg;
    final Color buttonFg;

    if (urgent) {
      badgeBg = const Color(0xFFFBE8E4);
      badgeFg = const Color(0xFF9A3412);
      cardBg = const Color(0xFFFFF7F5);
      borderColor = const Color(0xFFE2B3A7);
      buttonBg = const Color(0xFF9A3412);
      buttonFg = Colors.white;
    } else if (isError) {
      badgeBg = const Color(0xFFFEECEB);
      badgeFg = const Color(0xFFB42318);
      cardBg = const Color(0xFFFEF6F6);
      borderColor = const Color(0xFFFECDCA);
      buttonBg = const Color(0xFFB42318);
      buttonFg = Colors.white;
    } else {
      badgeBg = const Color(0xFFE2EFE7);
      badgeFg = kAdminBridgeGreen;
      cardBg = Colors.white;
      borderColor = kAdminHairline;
      buttonBg = kAdminBridgeGreen;
      buttonFg = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor),
        borderRadius: kAdminCardRadius,
        boxShadow: kAdminCardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 14, color: badgeFg),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: badgeFg,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeCount != null && badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeFg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: adminHeaderStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            detail,
            style: adminLabelStyle(fontSize: 13, color: kAdminTextSecondary),
          ),
          const SizedBox(height: 14),
          PressableScale(
            child: isError
                ? OutlinedButton.icon(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: buttonBg,
                      side: BorderSide(color: buttonBg),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      action,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  )
                : FilledButton.icon(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: buttonBg,
                      foregroundColor: buttonFg,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(
                      urgent ? Icons.priority_high_rounded : Icons.arrow_forward_rounded,
                      size: 16,
                    ),
                    label: Text(
                      action,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
