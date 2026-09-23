// lib/features/provider/presentation/org/org_disbursements_tab.dart
//
// Grant Disbursements & Award Commitment Ledger based on Stitch mockup
// (scholaris_provider_console_disbursements_financial_ledger).
// Shows confirmed grants, committed endowments, and awarded student rosters.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../applications/models/application.dart';
import '../../../applications/providers/applications_provider.dart';
import '../../../profile/models/student_profile.dart';
import '../../../scholarships/models/scholarship.dart';
import '../../../scholarships/providers/scholarships_provider.dart';
import '../../providers/provider_scholarships_provider.dart';
import 'org_provider_theme.dart';

class OrgDisbursementsTab extends ConsumerWidget {
  const OrgDisbursementsTab({super.key});

  int _getAwardAmount(dynamic s) {
    if (s is Scholarship) {
      return s.awardAmount;
    }
    return 50000;
  }

  String _formatCurrency(int amount) {
    return '₱${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingAppsAsync = ref.watch(incomingApplicationsProvider);
    final scholarshipsAsync = ref.watch(scholarshipsProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    return Container(
      color: kOrgCanvas,
      child: incomingAppsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: kOrgPrimary),
        ),
        error: (err, _) => Center(
          child: Text('Error loading disbursements ledger: $err',
              style: orgBody(color: kOrgError)),
        ),
        data: (apps) {
          final profiles = ref.watch(providerApplicantProfilesProvider).valueOrNull ??
              <String, StudentProfile>{};
          final scholarshipsMap = <String, Scholarship>{
            for (final Scholarship s in (scholarshipsAsync.valueOrNull ?? <Scholarship>[])) s.id: s
          };

          // Filter for approved / awarded scholars
          final awardedApps = apps
              .where((a) =>
                  a.status == ApplicationStatus.approved ||
                  a.status == ApplicationStatus.awarded)
              .toList();

          final totalCommitted = awardedApps.length * 50000;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('CONSOLE',
                                style: orgLabel(fontSize: 10, color: kOrgTextMuted)),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right_rounded,
                                size: 14, color: kOrgTextMuted),
                            const SizedBox(width: 4),
                            Text('DISBURSEMENTS',
                                style: orgLabel(fontSize: 10, color: kOrgPrimary)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Grant Disbursements & Financial Ledger',
                            style: orgHeadline(fontSize: isDesktop ? 22 : 18)),
                        const SizedBox(height: 2),
                        Text(
                          'Track institutional grant allocations, committed stipends, and awarded student beneficiaries.',
                          style: orgBody(fontSize: 12, color: kOrgTextSecondary),
                        ),
                      ],
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: kOrgSurfaceWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kOrgBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_rounded,
                              size: 16, color: kOrgPrimary),
                          const SizedBox(width: 6),
                          Text('Grant Registry Verified',
                              style: orgLabel(fontSize: 11, color: kOrgPrimary)),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // 3 Top Summary Stat Cards
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cardWidth = isDesktop
                        ? (constraints.maxWidth - 24) / 3
                        : constraints.maxWidth;

                    final cards = [
                      _buildSummaryTile(
                        title: 'TOTAL COMMITTED GRANT FUNDS',
                        value: _formatCurrency(totalCommitted),
                        subtitle: 'Allocated for active awardees',
                        icon: Icons.payments_rounded,
                        accentColor: kOrgPrimary,
                        width: cardWidth,
                      ),
                      _buildSummaryTile(
                        title: 'CONFIRMED BENEFICIARIES',
                        value: '${awardedApps.length}',
                        subtitle: 'Scholars receiving full support',
                        icon: Icons.school_rounded,
                        accentColor: kOrgAccentGold,
                        width: cardWidth,
                      ),
                      _buildSummaryTile(
                        title: 'ACTIVE GRANT PROGRAMS',
                        value: '${scholarshipsMap.length}',
                        subtitle: 'Institutional funding opportunities',
                        icon: Icons.account_balance_rounded,
                        accentColor: kOrgCivicNavy,
                        width: cardWidth,
                      ),
                    ];

                    return isDesktop
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: cards,
                          )
                        : Column(
                            children: [
                              cards[0],
                              const SizedBox(height: 10),
                              cards[1],
                              const SizedBox(height: 10),
                              cards[2],
                            ],
                          );
                  },
                ),

                const SizedBox(height: 20),

                // Awarded Beneficiaries List
                Text('Awarded Beneficiary Ledger', style: orgHeadline(fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  'Certified list of students whose applications have been endorsed for grant funding.',
                  style: orgBody(fontSize: 12, color: kOrgTextSecondary),
                ),
                const SizedBox(height: 14),

                if (awardedApps.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: kOrgSurfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kOrgBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 48, color: kOrgTextMuted.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text('No awarded scholars yet',
                            style: orgHeadline(fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(
                          'Once you approve applications in the Review queue, they will appear here with confirmed grant amounts.',
                          style: orgBody(fontSize: 13, color: kOrgTextSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: awardedApps.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final app = awardedApps[index];
                      final profile = profiles[app.userId];
                      final scholarship = scholarshipsMap[app.scholarshipId];

                      final studentName = profile?.fullName.isNotEmpty == true
                          ? profile!.fullName
                          : 'Scholar #${app.id.substring(0, 6).toUpperCase()}';

                      final studentSchool = profile?.school?.isNotEmpty == true
                          ? profile!.school!
                          : 'Partner University';

                      final studentCourse = profile?.course.isNotEmpty == true
                          ? profile!.course
                          : 'Degree Program';

                      final awardAmount = _formatCurrency(_getAwardAmount(scholarship));

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kOrgSurfaceWhite,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: kOrgBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: kOrgBadgeApprovedBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.check_circle_rounded,
                                  color: kOrgPrimary, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(studentName,
                                      style: orgHeadline(fontSize: 14)),
                                  Text('$studentCourse • $studentSchool',
                                      style: orgBody(
                                          fontSize: 12,
                                          color: kOrgTextSecondary)),
                                ],
                              ),
                            ),
                            if (isDesktop)
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('SPONSORED GRANT',
                                        style: orgLabel(
                                            fontSize: 9, color: kOrgTextMuted)),
                                    Text(scholarship?.title ?? 'Merit Grant',
                                        overflow: TextOverflow.ellipsis,
                                        style: orgHeadline(fontSize: 12)),
                                  ],
                                ),
                              ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('AWARD AMOUNT',
                                    style: orgLabel(
                                        fontSize: 9, color: kOrgTextMuted)),
                                Text(awardAmount,
                                    style: orgHeadline(
                                        fontSize: 15, color: kOrgPrimary)),
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: kOrgBadgeApprovedBg,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('Award Confirmed',
                                      style: orgLabel(
                                          fontSize: 9,
                                          color: kOrgBadgeApprovedText)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kOrgSurfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kOrgBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: orgLabel(fontSize: 10, color: kOrgTextMuted)),
                const SizedBox(height: 4),
                Text(value, style: orgHeadline(fontSize: 22, color: kOrgPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: orgBody(fontSize: 11, color: kOrgTextSecondary)),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
        ],
      ),
    );
  }
}
