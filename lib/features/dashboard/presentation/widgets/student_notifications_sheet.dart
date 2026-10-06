// lib/features/dashboard/presentation/widgets/student_notifications_sheet.dart
//
// Apple HIG-compliant student notification bottom sheet.
// Derives live notifications from real student applications and profile status,
// completely eliminating mock/fake notifications while remaining actionable.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:scholaris/features/account/presentation/account_settings_screen.dart';
import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/providers/applications_provider.dart';
import 'package:scholaris/features/home/presentation/home_screen.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/features/scholarships/providers/scholarships_provider.dart';
import 'package:scholaris/shared/theme/app_motion.dart';
import 'package:scholaris/shared/theme/app_theme.dart';

Future<void> showStudentNotificationsSheet(BuildContext context) {
  HapticFeedback.lightImpact();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const StudentNotificationsSheet(),
  );
}

class StudentNotificationItem {
  const StudentNotificationItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.badgeText,
    this.onTap,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String? badgeText;
  final VoidCallback? onTap;
}

class StudentNotificationsSheet extends ConsumerWidget {
  const StudentNotificationsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaQuery = MediaQuery.of(context);
    final appsAsync = ref.watch(applicationsProvider);
    final scholarshipsAsync = ref.watch(scholarshipsProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    final apps = appsAsync.valueOrNull ?? [];
    final scholarships = scholarshipsAsync.valueOrNull ?? [];
    final profile = profileAsync.valueOrNull;

    final items = _deriveNotifications(
      context: context,
      ref: ref,
      apps: apps,
      scholarships: scholarships,
      profile: profile,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.75,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: mediaQuery.viewPadding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: kPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Notifications',
                        style: outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF161C27),
                        ),
                      ),
                      if (items.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCF3E5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${items.length} Active',
                            style: outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: kPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              PressableScale(
                child: IconButton(
                  constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                  padding: const EdgeInsets.all(10),
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: Color(0xFF707971),
                    size: 20,
                  ),
                  tooltip: 'Notification Preferences',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      ScholarisPageRoute(
                        builder: (_) => const AccountSettingsScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content Area
          if (items.isEmpty)
            _buildEmptyState(context)
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const AppleBouncingScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) {
                  final item = items[index];
                  return _buildNotificationCard(item);
                },
              ),
            ),
        ],
      ),
    );
  }

  List<StudentNotificationItem> _deriveNotifications({
    required BuildContext context,
    required WidgetRef ref,
    required List<Application> apps,
    required List<Scholarship> scholarships,
    required StudentProfile? profile,
  }) {
    final list = <StudentNotificationItem>[];

    // 1. Incomplete Profile Notice
    if (profile != null) {
      final isGpaMissing = profile.gpa <= 0;
      final isSchoolMissing = profile.school?.isEmpty ?? true;
      if (isGpaMissing || isSchoolMissing) {
        list.add(
          StudentNotificationItem(
            id: 'profile_incomplete',
            title: 'Complete Your Academic Profile',
            subtitle: isGpaMissing && isSchoolMissing
                ? 'Add your current GWA & institution to unlock high-fit scholarships.'
                : (isGpaMissing
                    ? 'Declare your current GWA to calculate accurate match probabilities.'
                    : 'Add your school/university to find campus-specific grants.'),
            icon: Icons.person_outline_rounded,
            iconColor: const Color(0xFF0058BC),
            iconBgColor: const Color(0xFFE7F0FF),
            badgeText: 'Action Required',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
              ref.read(homeTabIndexProvider.notifier).selectTab(3);
            },
          ),
        );
      }
    }

    // 2. Live Application Status Notices
    for (final app in apps) {
      final sch = scholarships
          .cast<Scholarship?>()
          .firstWhere((s) => s?.id == app.scholarshipId, orElse: () => null);
      final schTitle = sch?.title ?? 'Grant Application';

      switch (app.status) {
        case ApplicationStatus.approved:
        case ApplicationStatus.awarded:
          list.add(
            StudentNotificationItem(
              id: 'app_approved_${app.id}',
              title: app.status == ApplicationStatus.awarded
                  ? 'Grant Awarded!'
                  : 'Application Approved!',
              subtitle:
                  'Congratulations! Your submission for $schTitle has been ${app.status == ApplicationStatus.awarded ? "awarded" : "approved"}.',
              icon: Icons.verified_rounded,
              iconColor: const Color(0xFF0F4D2E),
              iconBgColor: const Color(0xFFDCF3E5),
              badgeText:
                  app.status == ApplicationStatus.awarded ? 'Awarded' : 'Approved',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
                context.push('/application/${app.id}');
              },
            ),
          );
        case ApplicationStatus.submitted:
          list.add(
            StudentNotificationItem(
              id: 'app_submitted_${app.id}',
              title: 'Application Under Review',
              subtitle: '$schTitle • Dossier is queued for provider evaluation.',
              icon: Icons.hourglass_top_rounded,
              iconColor: const Color(0xFF623A00),
              iconBgColor: const Color(0xFFFEF7E6),
              badgeText: 'Submitted',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
                context.push('/application/${app.id}');
              },
            ),
          );
        case ApplicationStatus.underReview:
          list.add(
            StudentNotificationItem(
              id: 'app_evaluating_${app.id}',
              title: 'Evaluation In Progress',
              subtitle: '$schTitle • Committee is currently scoring candidate qualifications.',
              icon: Icons.pending_actions_rounded,
              iconColor: const Color(0xFF0058BC),
              iconBgColor: const Color(0xFFE7F0FF),
              badgeText: 'In Review',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
                context.push('/application/${app.id}');
              },
            ),
          );
        case ApplicationStatus.rejected:
          list.add(
            StudentNotificationItem(
              id: 'app_declined_${app.id}',
              title: 'Application Decision',
              subtitle: '$schTitle • Review completed. Tap to view provider remarks and alternatives.',
              icon: Icons.info_outline_rounded,
              iconColor: const Color(0xFFBA1A1A),
              iconBgColor: const Color(0xFFFFEDEC),
              badgeText: 'Completed',
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
                context.push('/application/${app.id}');
              },
            ),
          );
        case ApplicationStatus.draft:
        case ApplicationStatus.withdrawn:
          // Drafts and withdrawn applications do not create active notifications.
          break;
      }
    }

    return list;
  }

  Widget _buildNotificationCard(StudentNotificationItem item) {
    return PressableScale(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: item.iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: outfit(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF161C27),
                              ),
                            ),
                          ),
                          if (item.badgeText != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: item.iconBgColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.badgeText!,
                                style: outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: item.iconColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: openSans(
                          fontSize: 12,
                          color: const Color(0xFF707971),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.onTap != null) ...[
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFDCF3E5),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: kPrimary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "You're All Caught Up",
            style: outfit(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF161C27),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "You have no unread alerts. You'll receive real-time notifications here when providers update your applications or request documentation.",
            textAlign: TextAlign.center,
            style: openSans(
              fontSize: 12.5,
              color: const Color(0xFF707971),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          PressableScale(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: kPrimary,
                  side: const BorderSide(color: Color(0xFFB3F1C6), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    ScholarisPageRoute(
                      builder: (_) => const AccountSettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings_outlined, size: 16),
                label: Text(
                  'Notification Preferences',
                  style: outfit(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
