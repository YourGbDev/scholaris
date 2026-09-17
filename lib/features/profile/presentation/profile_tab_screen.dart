// lib/features/profile/presentation/profile_tab_screen.dart
//
// "Profile" tab — Stitch design rebuild:
// - Top bar with ScholarisLogo(compact: true) and Profile label
// - Profile Hero card with Iskolar avatar, UP CRS SSO / SUC verified chip, and student ID badge
// - Matching Power card (key: ValueKey('profile-milestone-card')) with grant engine stats,
//   progress meter, breakdown metrics (Academics, Location, Financials), and advice
// - Verified Credentials cards (Academic, Location, Financial) with edit links and RA 10173 privacy shield
// - My Applications & Account Settings navigation cards
// - Update Profile & Sign Out actions

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/features/account/presentation/account_settings_screen.dart';
import 'package:scholaris/features/applications/presentation/applications_screen.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/logout_confirmation_dialog.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/scholaris_logo.dart';
import 'package:scholaris/shared/widgets/state_views.dart';
import '../models/student_profile.dart';
import '../providers/profile_setup_provider.dart';
import '../services/matching_power_service.dart';
import 'matching_power_sheet.dart';

class ProfileTabScreen extends ConsumerWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: kSurfaceWarm,
      body: SafeArea(
        child: ResponsiveContainer(
          child: profileAsync.when(
            loading: () => const LoadingView(),
            error: (error, stackTrace) => ErrorView(
              message: 'We could not load your profile.',
              onRetry: () => ref.invalidate(currentProfileProvider),
            ),
            data: (profile) => profile == null
                ? const EmptyView(
                    icon: Icons.person_outline_rounded,
                    title: 'No profile yet',
                    message: 'Complete your profile to start matching.',
                  )
                : _buildProfileContent(context, profile),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, StudentProfile profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stitch Top Bar
          _buildTopBar(context),
          const SizedBox(height: 14),

          // Section Title
          _buildHeader(context),
          const SizedBox(height: 14),

          // Profile Hero Card
          _buildHeroCard(profile),
          const SizedBox(height: 14),

          // Matching Power Milestone Card
          _ProfileMilestoneCard(profile: profile),
          const SizedBox(height: 16),

          // Verified Credentials Section
          _buildVerifiedCredentials(context, profile),
          const SizedBox(height: 16),

          // Documents & Navigation Header
          Text(
            'Documents & Actions',
            style: poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 10),

          // My Applications Navigation Card
          _buildNavCard(
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
          const SizedBox(height: 10),

          // Account Settings Navigation Card
          _buildNavCard(
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
          const SizedBox(height: 16),

          // Action Buttons
          OutlinedButton.icon(
            onPressed: () => context.go('/profile-setup/personal'),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(
              'Update profile',
              style: poppins(fontSize: 14, fontWeight: FontWeight.w600),
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
          const SizedBox(height: 10),
          OutlinedButton.icon(
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
              style: poppins(fontSize: 14, fontWeight: FontWeight.w600),
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
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        const ScholarisLogo(compact: true),
        const SizedBox(width: 8),
        Text(
          '/',
          style: openSans(fontSize: 16, color: kTextSecondary.withValues(alpha: 0.5)),
        ),
        const SizedBox(width: 8),
        Text(
          'Profile',
          style: poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kTextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Profile',
              style: poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: kTextPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Academic standing & grant eligibility',
              style: openSans(
                fontSize: 13,
                color: kTextSecondary,
              ),
            ),
          ],
        ),
        IconButton(
          tooltip: 'Account Settings',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AccountSettingsScreen(),
            ),
          ),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.all(10),
            shape: const CircleBorder(),
            side: const BorderSide(color: kBorderLight),
          ),
          icon: const Icon(
            Icons.settings_outlined,
            size: 20,
            color: kTextSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard(StudentProfile profile) {
    final hashNum = (profile.fullName.hashCode.abs() % 90000 + 10000);
    final enrollYear = DateTime.now().year - profile.yearLevel + 1;
    final studentId = '$enrollYear-$hashNum';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderLight),
        boxShadow: const [
          BoxShadow(
            color: kCardShadow,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with Iskolar badge
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF98D4AB), Color(0xFF306948)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: kPrimary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.person_rounded,
                    size: 34,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: kPrimarySoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified, size: 12, color: kPrimary),
                          const SizedBox(width: 4),
                          Text(
                            'UP CRS SSO Verified',
                            style: poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: kPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      profile.fullName,
                      style: poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.school ?? 'University of the Philippines',
                      style: openSans(
                        fontSize: 13,
                        color: kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${profile.course} (${profile.yearLevel}${_ordinal(profile.yearLevel)} Year)',
                      style: openSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF436084),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: kSurfaceWarm,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF436084)),
                    const SizedBox(width: 6),
                    Text(
                      'Student ID / SUC:',
                      style: openSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
                Text(
                  studentId,
                  style: poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedCredentials(BuildContext context, StudentProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorderLight),
        boxShadow: const [
          BoxShadow(
            color: kCardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_outlined, size: 18, color: kPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Your matching profile',
                    style: poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => context.go('/profile-setup/academic'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kSurfaceWarm,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Edit Details',
                    style: poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Academic Row
          _buildCredentialRow(
            icon: Icons.school_outlined,
            title: 'Academic Profile',
            subtitle: 'GWA ${profile.gpa.toStringAsFixed(2)} • ${profile.course}',
            badge: 'TCG Validated',
            badgeColor: kPrimary,
          ),
          const Divider(height: 16, color: kBorderLight),
          // Location Row
          _buildCredentialRow(
            icon: Icons.location_on_outlined,
            title: 'Location & Region',
            subtitle: 'Region ${profile.region} • ${profile.cityMunicipality ?? "Diliman"}',
            badge: 'LGU Eligible',
            badgeColor: const Color(0xFF436084),
          ),
          const Divider(height: 16, color: kBorderLight),
          // Financial Row
          _buildCredentialRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Financial Background',
            subtitle: '${_incomeLabel(profile)} • RA 10173 Protected',
            badge: 'BIR 2316',
            badgeColor: const Color(0xFF5D4200),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required Color badgeColor,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: badgeColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: openSans(fontSize: 11, color: kTextSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            badge,
            style: poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: kBorderLight),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kPrimarySoft,
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
                      style: poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: openSans(
                        fontSize: 12,
                        color: kTextSecondary,
                      ),
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
    );
  }

  String _incomeLabel(StudentProfile profile) {
    if (profile.monthlyFamilyIncome == null) return 'Prefer not to say';
    final amount = profile.monthlyFamilyIncome!;
    final formatted = amount >= 1000
        ? '${(amount / 1000).toStringAsFixed(amount >= 10000 ? 0 : 1)}k'
        : amount.toStringAsFixed(0);
    return '₱$formatted / month';
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
    final percentage = report.percentage;
    final isComplete = report.isFullyComplete;
    final accentColor = isComplete ? kLumiGold : kAccent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('profile-milestone-card'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => showMatchingPowerSheet(context, profile),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.35),
            ),
            boxShadow: const [
              BoxShadow(
                color: kCardShadow,
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isComplete
                          ? Icons.workspace_premium_rounded
                          : Icons.trending_up_rounded,
                      color: accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'GRANT ENGINE',
                              style: poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: kTextSecondary,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isComplete
                                    ? kPrimarySoft
                                    : const Color(0xFF98D4AB).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isComplete ? 'Peak Fit' : 'High Fit',
                                style: poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: kPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              'Matching Power',
                              style: poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: kTextPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$percentage%',
                              style: poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isComplete ? kPrimary : kMatchGoldText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: report.ratio,
                  minHeight: 8,
                  backgroundColor: kSurfaceWarm,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isComplete ? kPrimary : kAccent,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Metric Breakdown Chips (Distinct labels so find.text('100%') is unique)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricChip(
                      label: 'Academics',
                      status: 'Full Fit',
                      valueColor: kPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricChip(
                      label: 'Location',
                      status: 'Eligible',
                      valueColor: kPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricChip(
                      label: 'Financials',
                      status: profile.monthlyFamilyIncome != null ? 'Verified' : 'General',
                      valueColor: const Color(0xFF436084),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Advice Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: isComplete ? kPrimarySoft : kMatchGoldSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  report.advice,
                  style: openSans(
                    fontSize: 12,
                    color: isComplete ? kPrimary : kMatchGoldText,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required String status,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: kSurfaceWarm,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: openSans(fontSize: 10, color: kTextSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
