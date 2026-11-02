import 'package:scholaris/features/home/presentation/widgets/student_tab_entrance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/features/account/presentation/account_settings_screen.dart';
import 'package:scholaris/features/applications/presentation/applications_screen.dart';
import 'package:scholaris/features/dashboard/presentation/widgets/student_notifications_sheet.dart';
import 'package:scholaris/shared/theme/app_motion.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/logout_confirmation_dialog.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/scholaris_logo.dart';
import 'package:scholaris/shared/widgets/state_views.dart';

import '../models/student_profile.dart';
import '../providers/avatar_provider.dart';
import '../providers/profile_setup_provider.dart';
import '../services/matching_power_service.dart';
import 'matching_power_sheet.dart';
import 'widgets/avatar_display.dart';
import 'widgets/avatar_selector_sheet.dart';

class ProfileTabScreen extends ConsumerWidget {
  const ProfileTabScreen({
    super.key,
    this.guideTargets = const [],
    this.scrollController,
  });
  final List<GlobalKey> guideTargets;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: kStudentCanvas,
      body: SafeArea(
        bottom: false,
        child: ResponsiveContainer(
          child: profileAsync.when(
            loading: () => StudentTabReveal(
              order: 3,
              child: CrossFadeLoading(
                isLoading: true,
                skeleton: _buildProfileSkeleton(context),
                child: const SizedBox.shrink(),
              ),
            ),
            error: (error, stackTrace) => StudentTabReveal(
              order: 3,
              child: ErrorView(
                message: 'We could not load your profile.',
                onRetry: () => ref.invalidate(currentProfileProvider),
              ),
            ),
            data: (profile) => profile == null
                ? const StudentTabReveal(
                    order: 3,
                    child: EmptyView(
                      icon: Icons.person_outline_rounded,
                      title: 'No profile yet',
                      message: 'Complete your profile to start matching.',
                    ),
                  )
                : _buildProfileContent(context, ref, profile),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSkeleton(BuildContext context) {
    return SingleChildScrollView(
      physics: const AppleBouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 64 + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBand(width: 120, height: 24, borderRadius: 6),
              SkeletonBand(width: 32, height: 32, borderRadius: 16),
            ],
          ),
          SizedBox(height: 14),
          SkeletonBand(width: 150, height: 28, borderRadius: 6),
          SizedBox(height: 14),
          SkeletonBand(height: 140, borderRadius: 16),
          SizedBox(height: 14),
          SkeletonBand(height: 120, borderRadius: 16),
          SizedBox(height: 18),
          SkeletonBand(height: 160, borderRadius: 16),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
    BuildContext context,
    WidgetRef ref,
    StudentProfile profile,
  ) {
    return SingleChildScrollView(
      controller: scrollController,
      physics: const AppleBouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 64 + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stitch Top Bar
          StudentTabReveal(
            order: 0,
            immediate: true,
            child: _buildTopBar(context),
          ),
          const SizedBox(height: 16),

          // Section Title & Settings Button
          StudentTabReveal(
            order: 0,
            immediate: true,
            child: _buildHeader(context),
          ),
          const SizedBox(height: 16),

          // Profile Hero Card
          StudentTabReveal(
            order: 1,
            structural: true,
            child: _buildHeroCard(context, ref, profile),
          ),
          const SizedBox(height: 16),

          // Matching Power Milestone Card
          StudentTabReveal(
            order: 2,
            structural: true,
            child: _ProfileMilestoneCard(profile: profile),
          ),
          const SizedBox(height: 24),

          // Verified Credentials Section (3 Stitch Cards)
          _buildVerifiedCredentials(context, profile),
          const SizedBox(height: 20),

          // Documents & Quick Actions Section
          _buildDocumentsAndQuickActions(context),
          const SizedBox(height: 20),

          // Account & Settings Section
          _buildAccountSection(context),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_none_rounded, size: 20),
          color: kTextSecondary,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: () => showStudentNotificationsSheet(context),
        ),
        const SizedBox(width: 8),
        const CircleAvatar(
          radius: 14,
          backgroundColor: kPrimary,
          child: Icon(Icons.person, size: 16, color: Colors.white),
        ),
      ],
    );
    if (MediaQuery.textScalerOf(context).scale(18) > 25) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScholarisLogo(compact: true),
          Align(alignment: Alignment.centerRight, child: actions),
        ],
      );
    }
    return Row(
      children: [
        const Expanded(child: ScholarisLogo(compact: true)),
        const SizedBox(width: 8),
        actions,
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: StudentTabReveal(
            order: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Profile',
                  style: outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: kOnSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your details and account',
                  style: openSans(fontSize: 12, color: kOnSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: 'Account Settings',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AccountSettingsScreen(),
            ),
          ),
          style: IconButton.styleFrom(
            backgroundColor: kStudentSurfaceSubtle,
            padding: const EdgeInsets.all(10),
            shape: const CircleBorder(),
          ),
          icon: const Icon(
            Icons.settings_outlined,
            size: 20,
            color: kOnSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(
    BuildContext context,
    WidgetRef ref,
    StudentProfile profile,
  ) {
    final avatarState = ref.watch(avatarProvider(profile.id));
    final identity = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.fullName,
          style: outfit(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: kOnSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          (profile.school != null && profile.school!.trim().isNotEmpty)
              ? profile.school!
              : 'Institution not set',
          style: openSans(fontSize: 13, color: kOnSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          '${profile.course} (${profile.yearLevel}${_ordinal(profile.yearLevel)} Year)',
          style: openSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: kTextSecondary,
          ),
        ),
      ],
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: kSoftCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stackIdentity =
                  MediaQuery.textScalerOf(context).scale(14) > 20;
              return Wrap(
                spacing: 14,
                runSpacing: 12,
                children: [
                  AvatarDisplay(
                    key: const ValueKey('profile-hero-avatar'),
                    avatarId: avatarState.avatarId,
                    isRealPhoto: avatarState.isRealPhoto,
                    photoPath: avatarState.photoPath,
                    size: 64,
                    showEditOverlay: true,
                    onTap: () => AvatarSelectorSheet.show(context, profile.id),
                  ),
                  SizedBox(
                    width: stackIdentity
                        ? constraints.maxWidth
                        : constraints.maxWidth - 78,
                    child: identity,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedCredentials(
    BuildContext context,
    StudentProfile profile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        StudentTabReveal(
          order: 2,
          structural: true,
          child: Text(
            'Profile details',
            style: geist(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: kOnSurface,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Card 1: Academic Information
        StudentTabReveal(
          order: 1,
          child: KeyedSubtree(
            key: guideTargets.isNotEmpty ? guideTargets[0] : null,
            child: _buildAcademicCard(context, profile),
          ),
        ),
        const SizedBox(height: 12),

        // Card 2: Location & Residency
        StudentTabReveal(
          order: 2,
          child: KeyedSubtree(
            key: guideTargets.length > 1 ? guideTargets[1] : null,
            child: _buildLocationCard(context, profile),
          ),
        ),
        const SizedBox(height: 12),

        // Card 3: Financial Background
        StudentTabReveal(
          order: 3,
          child: KeyedSubtree(
            key: guideTargets.length > 2 ? guideTargets[2] : null,
            child: _buildFinancialCard(context, profile),
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicCard(BuildContext context, StudentProfile profile) {
    return _buildDetailsCard(
      title: 'Academic Information',
      icon: Icons.school_outlined,
      onEdit: () => context.go('/profile-setup/academic'),
      children: [
        _buildGridItem(
          label: 'Reported grade',
          value: profile.gpa > 0
              ? profile.gpa.toStringAsFixed(2)
              : 'Not provided',
          subtitle: profile.gpaScale != null
              ? gradingScaleLabel(profile.gpaScale)
              : '',
        ),
        _buildGridItem(
          label: 'Course / Degree Program',
          value: profile.course.trim().isNotEmpty
              ? profile.course
              : 'Not provided',
          subtitle: '',
        ),
        _buildGridItem(
          label: 'Year level',
          value: profile.yearLevel > 0
              ? '${profile.yearLevel}${_ordinal(profile.yearLevel)} Year'
              : 'Not provided',
          subtitle: '',
        ),
        _buildGridItem(
          label: 'School or University',
          value: profile.school?.trim().isNotEmpty == true
              ? profile.school!
              : 'Not provided',
          subtitle: '',
        ),
      ],
    );
  }

  Widget _buildLocationCard(BuildContext context, StudentProfile profile) {
    final address = [
      profile.cityMunicipality,
      profile.province,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(', ');
    return _buildDetailsCard(
      title: 'Location & Residency',
      icon: Icons.location_on_outlined,
      onEdit: () => context.go('/profile-setup/financial'),
      children: [
        _buildGridItem(
          label: 'City / Municipality & Province',
          value: address.isNotEmpty ? address : 'Not provided',
          subtitle: '',
        ),
        _buildGridItem(
          label: 'Region',
          value: profile.region.trim().isNotEmpty
              ? profile.region
              : 'Not provided',
          subtitle: '',
        ),
      ],
    );
  }

  Widget _buildFinancialCard(BuildContext context, StudentProfile profile) {
    final demographics = [
      if (profile.isIndigenous) 'Indigenous Peoples (IP)',
      if (profile.hasDisability) 'Person with Disability (PWD)',
    ].join(', ');
    return _buildDetailsCard(
      title: 'Financial Background',
      icon: Icons.account_balance_outlined,
      onEdit: () => context.go('/profile-setup/financial'),
      children: [
        _buildGridItem(
          label: 'Monthly family income',
          value: _incomeLabel(profile),
          subtitle: 'Scholarship requirements vary by program.',
        ),
        _buildGridItem(
          label: 'Self-declared demographic details',
          value: demographics.isNotEmpty
              ? demographics
              : 'No special demographic status declared',
          subtitle: '',
        ),
      ],
    );
  }

  Widget _buildDetailsCard({
    required String title,
    required IconData icon,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: kSoftCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: kTextSecondary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: geist(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kOnSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildEditBadge(onTap: onEdit),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDocumentsAndQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudentTabReveal(
          order: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              'Documents & Quick Actions',
              style: outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: kOnSurface,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        _buildComingSoonRow(
          Icons.card_membership_outlined,
          'Scholaris Passport',
        ),
        const SizedBox(height: 10),
        _buildComingSoonRow(Icons.sync_rounded, 'University transcript sync'),
      ],
    );
  }

  Widget _buildComingSoonRow(IconData icon, String title) {
    return Semantics(
      enabled: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: kSoftCardDecoration,
        child: Row(
          children: [
            Icon(icon, size: 20, color: kTextSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: geist(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Coming soon',
                    style: geist(fontSize: 12, color: kTextSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudentTabReveal(
          order: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              'Account & Settings',
              style: outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: kOnSurface,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // My Applications Navigation Card
        StudentTabReveal(
          order: 6,
          child: _buildNavCard(
            context: context,
            icon: Icons.send_outlined,
            title: 'My Applications',
            subtitle: 'Track your applications and their status',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ApplicationsScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Account Settings Navigation Card
        StudentTabReveal(
          order: 6,
          child: _buildNavCard(
            context: context,
            icon: Icons.manage_accounts_outlined,
            title: 'Account Settings',
            subtitle: 'Email, verification and password',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AccountSettingsScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Action Buttons
        StudentTabReveal(
          order: 6,
          child: PressableScale(
            child: OutlinedButton.icon(
              onPressed: () => context.go('/profile-setup/personal'),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(
                'Update profile',
                style: outfit(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: kPrimary,
                side: const BorderSide(color: kPrimary, width: 1.5),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        StudentTabReveal(
          order: 6,
          child: PressableScale(
            child: OutlinedButton.icon(
              key: const ValueKey('profile-logout-button'),
              onPressed: () async {
                final confirmed = await showLogoutConfirmationDialog(context);
                if (confirmed) {
                  try {
                    await Supabase.instance.client.auth.signOut();
                  } catch (_) {}
                }
              },
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(
                'Sign out',
                style: outfit(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: kError,
                side: const BorderSide(color: kError, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem({
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: geist(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: kTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: outfit(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kOnSurface,
            ),
          ),
          if (subtitle.isNotEmpty) const SizedBox(height: 4),
          if (subtitle.isNotEmpty)
            Text(
              subtitle,
              style: geist(fontSize: 12, color: kTextSecondary, height: 1.45),
            ),
        ],
      ),
    );
  }

  Widget _buildEditBadge({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kStudentSurfaceSubtle,
          borderRadius: BorderRadius.circular(14),
          border: kCardBorderCrisp,
        ),
        child: Text(
          'Edit',
          style: outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildNavCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusCard),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadiusCard),
          child: Container(
            decoration: kSoftCardDecoration,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kStudentSurfaceSubtle,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: kPrimary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: kTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: openSans(fontSize: 12, color: kTextSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: kTextSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _incomeLabel(StudentProfile profile) {
    if (profile.monthlyFamilyIncome == null) {
      return 'Income Undisclosed';
    }
    final amount = profile.monthlyFamilyIncome!;
    final formatted = amount >= 1000
        ? '${(amount / 1000).toStringAsFixed(amount >= 10000 ? 0 : 1)}k'
        : amount.toStringAsFixed(0);
    final bracket = amount < 25000
        ? 'Low Income'
        : (amount <= 70000 ? 'Lower-Middle' : 'Middle-to-High');
    return '₱$formatted / month ($bracket)';
  }

  String _ordinal(int n) => switch (n) {
    1 => 'st',
    2 => 'nd',
    3 => 'rd',
    _ => 'th',
  };
}

class _ProfileMilestoneCard extends StatelessWidget {
  const _ProfileMilestoneCard({required this.profile});
  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    final report = MatchingPowerService.evaluate(profile);
    return PressableScale(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(kRadiusCard),
        child: InkWell(
          key: const ValueKey('profile-milestone-card'),
          borderRadius: BorderRadius.circular(kRadiusCard),
          onTap: () => showMatchingPowerSheet(context, profile),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: kSoftCardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Text(
                      'Profile completeness',
                      style: geist(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kOnSurface,
                      ),
                    ),
                    CountUpAnimation(
                      targetValue: report.percentage,
                      suffix: '%',
                      style: geist(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: report.ratio,
                    minHeight: 4,
                    backgroundColor: kStudentDivider,
                    valueColor: const AlwaysStoppedAnimation<Color>(kPrimary),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${report.completedCount} of ${report.totalCount} details provided',
                  style: geist(fontSize: 12, color: kTextSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  report.isFullyComplete
                      ? 'Your profile details are complete. Keep them up to date.'
                      : 'Add your missing details to keep your profile up to date.',
                  style: geist(
                    fontSize: 12,
                    color: kTextSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          report.isFullyComplete
                              ? 'View details'
                              : 'Add missing details',
                          style: geist(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: kPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
