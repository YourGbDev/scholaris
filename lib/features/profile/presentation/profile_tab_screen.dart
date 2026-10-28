import 'package:scholaris/features/home/presentation/widgets/student_tab_entrance.dart';
// lib/features/profile/presentation/profile_tab_screen.dart
//
// "Profile" tab — 100% Stitch V2 design fidelity:
// - Top bar with Scholaris logo, breadcrumb, notifications, and profile avatar indicator
// - Section header with "My Profile", "Academic standing & grant eligibility", and settings gear
// - Profile Hero card with Iskolar avatar, Student profile badge, full name, university,
//   course & year, and student ID / SUC metadata chip
// - Grant Engine Matching Power milestone card (key: ValueKey('profile-milestone-card'))
//   with progress bar, unlocks stat, metric breakdown chips, and advice banner
// - Verified Credentials with 3 distinct Stitch cards:
//   1. Academic Information (GWA, Priority Field, Academic Standing, College, TCG banner)
//   2. Location & Residency (Permanent Address, Residency Duration, LGU grant banner)
//   3. Financial Background (RA 10173 privacy shield, Income Tier, Beneficiary status)
// - Documents & Quick Actions:
//   * Download Scholaris Passport (Coming soon)
//   * University transcript sync • Coming soon
// - Account & Settings navigation cards:
//   * My Applications
//   * Account Settings (Email, verification and password)
// - Update Profile & Sign Out action buttons (ValueKey('profile-logout-button'))

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
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      backgroundColor: kSurfaceWarm,
      body: SafeArea(
        bottom: false,
        child: ResponsiveContainer(
          child: profileAsync.when(
            loading: () => StudentTabReveal(order: 3, child: CrossFadeLoading(
              isLoading: true,
              skeleton: _buildProfileSkeleton(context),
              child: const SizedBox.shrink(),
            )),
            error: (error, stackTrace) => StudentTabReveal(order: 3, child: ErrorView(
              message: 'We could not load your profile.',
              onRetry: () => ref.invalidate(currentProfileProvider),
            )),
            data: (profile) => profile == null
                ? const StudentTabReveal(order: 3, child: EmptyView(
                    icon: Icons.person_outline_rounded,
                    title: 'No profile yet',
                    message: 'Complete your profile to start matching.',
                  ))
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
        16,
        12,
        16,
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
      physics: const AppleBouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 64 + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stitch Top Bar
          StudentTabReveal(order: 0,
            immediate: true,
            child: _buildTopBar(context)),
          const SizedBox(height: 14),

          // Section Title & Settings Button
          StudentTabReveal(order: 0,
            immediate: true,
            child: _buildHeader(context)),
          const SizedBox(height: 14),

          // Profile Hero Card
          StudentTabReveal(order: 1, structural: true, child: _buildHeroCard(context, ref, profile)),
          const SizedBox(height: 14),

          // Matching Power Milestone Card
          StudentTabReveal(order: 2, structural: true, child: _ProfileMilestoneCard(profile: profile)),
          const SizedBox(height: 18),

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Flexible(child: StudentTabReveal(
                  order: 0, immediate: true,
                  child: ScholarisLogo(compact: true),
                )),
              const SizedBox(width: 6),
              StudentTabReveal(
                order: 0, immediate: true,
                child: Text(
                '/',
                style: openSans(
                  fontSize: 14,
                  color: kTextSecondary.withValues(alpha: 0.5),
                ),
              ),
              ),
              const SizedBox(width: 6),
              StudentTabReveal(
                order: 0, immediate: true,
                child: Text(
                'Profile',
                style: outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: kOnSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Notifications',
              icon: const Icon(Icons.notifications_none_rounded, size: 20),
              color: kOnSurfaceVariant,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () {
                showStudentNotificationsSheet(context);
              },
            ),
            const SizedBox(width: 4),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: kPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
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
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: kOnSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Academic standing & grant eligibility',
                style: openSans(
                  fontSize: 12,
                  color: kOnSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
            backgroundColor: kSurfaceContainerHigh,
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
    final hashNum = (profile.fullName.hashCode.abs() % 90000 + 10000);
    final enrollYear = DateTime.now().year - profile.yearLevel + 1;
    final studentId = '$enrollYear-$hashNum';
    final avatarState = ref.watch(avatarProvider(profile.id));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceContainerLowest,
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
              // Avatar with Iskolar badge and tap to customize
              AvatarDisplay(
                key: const ValueKey('profile-hero-avatar'),
                avatarId: avatarState.avatarId,
                isRealPhoto: avatarState.isRealPhoto,
                photoPath: avatarState.photoPath,
                size: 64,
                showEditOverlay: true,
                onTap: () => AvatarSelectorSheet.show(context, profile.id),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: kPrimaryFixed,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified,
                            size: 13,
                            color: kOnPrimaryFixedVariant,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Student profile',
                              style: outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: kOnPrimaryFixedVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      profile.fullName,
                      style: outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kOnSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      (profile.school != null && profile.school!.trim().isNotEmpty)
                          ? profile.school!
                          : 'Institution not set',
                      style: openSans(
                        fontSize: 13,
                        color: kOnSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${profile.course} (${profile.yearLevel}${_ordinal(profile.yearLevel)} Year)',
                      style: openSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: kSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: kSurfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.badge_outlined,
                        size: 18,
                        color: kSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Student ID / SUC:',
                          style: outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kOnSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  studentId,
                  style: outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kOnSurface,
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

  Widget _buildVerifiedCredentials(
    BuildContext context,
    StudentProfile profile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        StudentTabReveal(order: 2, structural: true, child: Builder(
          builder: (context) {
            final syncedCount = (profile.course.trim().isNotEmpty ? 1 : 0) +
                (profile.region.trim().isNotEmpty ? 1 : 0) +
                (profile.monthlyFamilyIncome != null ? 1 : 0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Profile details',
                      style: outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: kOnSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      syncedCount > 0 ? '$syncedCount Categories Provided' : 'Pending Profile Setup',
                      textAlign: TextAlign.end,
                      style: outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: syncedCount > 0 ? kPrimary : kOnSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        )),
        const SizedBox(height: 10),

        // Card 1: Academic Information
        StudentTabReveal(
          order: 1,
          child: _buildAcademicCard(context, profile),
        ),
        const SizedBox(height: 12),

        // Card 2: Location & Residency
        StudentTabReveal(
          order: 2,
          child: _buildLocationCard(context, profile),
        ),
        const SizedBox(height: 12),

        // Card 3: Financial Background
        StudentTabReveal(
          order: 3,
          child: _buildFinancialCard(context, profile),
        ),
      ],
    );
  }

  bool _isStemCourse(String course) {
    final lower = course.toLowerCase();
    return lower.contains('science') ||
        lower.contains('engineer') ||
        lower.contains('tech') ||
        lower.contains('math') ||
        lower.contains('nurs') ||
        lower.contains('medic') ||
        lower.contains('comp') ||
        lower.contains('it') ||
        lower.contains('stem');
  }

  Widget _buildAcademicCard(BuildContext context, StudentProfile profile) {
    final gwaScale = profile.gpa <= 1.75 ? "Dean's List" : "Good Standing";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceContainerLowest,
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
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: kPrimaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.school_outlined,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Academic Information',
                        style: outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kOnSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildEditBadge(
                onTap: () => context.go('/profile-setup/academic'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 2x2 Details Grid
          Row(
            children: [
              Expanded(
                child: _buildGridItem(
                  label: 'Cumulative GWA',
                  value: profile.gpa.toStringAsFixed(2),
                  subtitle: '1.0 – 5.0 ($gwaScale)',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGridItem(
                  label: 'Priority Field',
                  value: _isStemCourse(profile.course) ? 'STEM Priority' : 'General Degree',
                  subtitle: _isStemCourse(profile.course) ? 'CHED Category A' : 'CHED Standard',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildGridItem(
                  label: 'Academic Standing',
                  value: '${profile.yearLevel}${_ordinal(profile.yearLevel)} Year',
                  subtitle: profile.setupComplete ? 'Enrolled • Regular' : 'Setup Incomplete',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildGridItem(
                  label: 'Enrolled College',
                  value: (profile.school != null && profile.school!.trim().isNotEmpty)
                      ? profile.school!
                      : 'University not set',
                  subtitle: profile.course.isNotEmpty ? profile.course : 'Course not specified',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // TCG Document Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: profile.setupComplete
                  ? kPrimaryFixed.withValues(alpha: 0.35)
                  : kSurfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: profile.setupComplete ? Colors.transparent : kBorderLight),
            ),
            child: Row(
              children: [
                Icon(
                  (profile.school != null && profile.school!.trim().isNotEmpty)
                      ? Icons.school_outlined
                      : Icons.info_outline_rounded,
                  size: 16,
                  color: profile.setupComplete ? kPrimary : kOnSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (profile.school != null && profile.school!.trim().isNotEmpty)
                        ? 'Institution provided on your profile'
                        : 'Institution not declared on profile',
                    style: openSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: profile.setupComplete
                          ? kOnPrimaryFixedVariant
                          : kOnSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context, StudentProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceContainerLowest,
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
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: kSecondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: kOnSecondaryContainer,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Location & Residency',
                        style: outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kOnSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildEditBadge(
                onTap: () => context.go('/profile-setup/financial'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Permanent Address Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: kSurfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Permanent Address',
                        style: outfit(fontSize: 11, color: kOnSurfaceVariant),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        profile.cityMunicipality ?? 'Diliman, Quezon City',
                        style: openSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kOnSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Region ${profile.region}',
                        style: openSans(fontSize: 11, color: kOnSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kSurfaceContainerHigh,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${profile.region} Dist.',
                    style: outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: kOnSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Residency Duration Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: kSurfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Declared Residency',
                        style: outfit(fontSize: 11, color: kOnSurfaceVariant),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        profile.province != null && profile.province!.trim().isNotEmpty
                            ? '${profile.cityMunicipality != null && profile.cityMunicipality!.trim().isNotEmpty ? '${profile.cityMunicipality}, ' : ''}${profile.province}'
                            : (profile.region.isNotEmpty
                                ? profile.region
                                : 'Region Not Set'),
                        style: openSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kOnSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  profile.region.isNotEmpty ? 'Region Declared' : 'Incomplete',
                  style: outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: profile.region.isNotEmpty
                        ? kPrimary
                        : kOnSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // LGU Grant Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: profile.region.isNotEmpty
                  ? kPrimaryFixed.withValues(alpha: 0.35)
                  : kSurfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  (profile.region.isNotEmpty && profile.setupComplete)
                      ? Icons.verified_rounded
                      : Icons.info_outline_rounded,
                  size: 16,
                  color: (profile.region.isNotEmpty && profile.setupComplete)
                      ? kPrimary
                      : kOnSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (profile.region.isNotEmpty && profile.setupComplete)
                        ? 'Residency information added to your profile'
                        : 'LGU Grant Matching: Set residency to unlock local grants',
                    style: openSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: (profile.region.isNotEmpty && profile.setupComplete)
                          ? kOnPrimaryFixedVariant
                          : kOnSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard(BuildContext context, StudentProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurfaceContainerLowest,
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
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: kTertiaryFixed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.account_balance_outlined,
                        size: 18,
                        color: kOnTertiaryFixed,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Financial Background',
                        style: outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kOnSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildEditBadge(
                onTap: () => context.go('/profile-setup/financial'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // RA 10173 Privacy Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: kSurfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 15,
                  color: kSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Specific salary shielded per RA 10173 (Data Privacy)',
                    style: openSans(fontSize: 11, color: kOnSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Household Income Tier
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kSurfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Household Income Tier',
                        style: outfit(fontSize: 11, color: kOnSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      profile.monthlyFamilyIncome != null
                          ? 'Declared Income'
                          : 'Income Undisclosed',
                      style: outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: profile.monthlyFamilyIncome != null
                            ? kPrimary
                            : kOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _incomeLabel(profile),
                  style: outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kOnSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.monthlyFamilyIncome != null
                      ? 'Qualifies for needs-based tuition and stipend subsidies'
                      : 'Declare monthly income to unlock needs-based subsidies',
                  style: openSans(fontSize: 11, color: kOnSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Special Beneficiary Status
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kSurfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Special Beneficiary Status',
                  style: outfit(fontSize: 11, color: kOnSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.isIndigenous
                      ? 'Indigenous Peoples (IP) Beneficiary'
                      : (profile.hasDisability
                          ? 'Person with Disability (PWD) Grantee'
                          : (profile.monthlyFamilyIncome != null && profile.monthlyFamilyIncome! < 25000
                              ? 'Low-Income Bracket (Subsidized)'
                              : 'Standard Grant Applicant')),
                  style: outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kOnSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (profile.isIndigenous || profile.hasDisability)
                      ? 'Self-declared beneficiary status'
                      : (profile.monthlyFamilyIncome != null
                          ? 'Based on declared family income bracket'
                          : 'No special demographic status declared'),
                  style: openSans(fontSize: 11, color: kSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsAndQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudentTabReveal(order: 0, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            'Documents & Quick Actions',
            style: outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: kOnSurface,
            ),
          ),
        )),
        const SizedBox(height: 10),

        // Download Scholaris Passport Button
        StudentTabReveal(order: 6, child: PressableScale(
          child: Material(
            color: kPrimaryDark,
            borderRadius: BorderRadius.circular(14),
            elevation: 2,
            shadowColor: kCardShadow,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Scholaris Passport is not available yet.',
                      style: openSans(fontSize: 13, color: Colors.white),
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: kPrimary,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: kPrimaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.card_membership_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Download Scholaris Passport',
                            style: outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Coming soon',
                            style: openSans(
                              fontSize: 12,
                              color: kPrimaryFixedDim,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.download_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        )),
        const SizedBox(height: 10),

        // University transcript sync • Coming soon Button
        StudentTabReveal(order: 6, child: PressableScale(
          child: Material(
            color: kSurfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'University transcript sync is not available yet.',
                      style: openSans(fontSize: 13, color: Colors.white),
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: kPrimary,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Icon(
                      Icons.sync_rounded,
                      size: 20,
                      color: kSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'University transcript sync • Coming soon',
                        style: outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kOnSurface,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: kOnSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StudentTabReveal(order: 0, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            'Account & Settings',
            style: outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: kOnSurface,
            ),
          ),
        )),
        const SizedBox(height: 10),

        // My Applications Navigation Card
        StudentTabReveal(order: 6, child: _buildNavCard(
          context: context,
          icon: Icons.send_outlined,
          title: 'My Applications',
          subtitle: 'Track your applications and their status',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const ApplicationsScreen(),
            ),
          ),
        )),
        const SizedBox(height: 10),

        // Account Settings Navigation Card
        StudentTabReveal(order: 6, child: _buildNavCard(
          context: context,
          icon: Icons.manage_accounts_outlined,
          title: 'Account Settings',
          subtitle: 'Email, verification and password',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AccountSettingsScreen(),
            ),
          ),
        )),
        const SizedBox(height: 16),

        // Action Buttons
        StudentTabReveal(order: 6, child: PressableScale(
          child: OutlinedButton.icon(
            onPressed: () => context.go('/profile-setup/personal'),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(
              'Update profile',
              style: outfit(fontSize: 14, fontWeight: FontWeight.w600),
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
        )),
        const SizedBox(height: 10),
        StudentTabReveal(order: 6, child: PressableScale(
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
              style: outfit(fontSize: 14, fontWeight: FontWeight.w600),
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
        )),
      ],
    );
  }

  Widget _buildGridItem({
    required String label,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: kSurfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: outfit(fontSize: 11, color: kOnSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kOnSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: openSans(fontSize: 11, color: kOnSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: kSurfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'Edit',
          style: outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
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
                        style: outfit(
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
    final percentage = report.percentage;
    final isComplete = report.isFullyComplete;
    final accentColor = isComplete ? kPrimary : kAccent;

    return PressableScale(
      child: Material(
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
                color: isComplete
                    ? kPrimary.withValues(alpha: 0.3)
                    : kAccent.withValues(alpha: 0.35),
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
                        color: isComplete
                            ? kPrimarySoft
                            : kTertiaryFixed.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isComplete
                            ? Icons.workspace_premium_rounded
                            : Icons.trending_up_rounded,
                        color: isComplete ? kPrimary : const Color(0xFF583F00),
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
                              Expanded(
                                child: Text(
                                  'GRANT ENGINE',
                                  style: outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: kOnSurfaceVariant,
                                    letterSpacing: 1.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isComplete
                                      ? kPrimaryFixed
                                      : const Color(0xFF98D4AB).withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isComplete ? 'Peak Fit' : 'High Fit',
                                  style: outfit(
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
                              Flexible(
                                child: Text(
                                  'Matching Power',
                                  style: outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: kOnSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              CountUpAnimation(
                                targetValue: percentage,
                                suffix: '%',
                                style: outfit(
                                  fontSize: 16,
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
                    backgroundColor: kSurfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Unlocks copy
                RichText(
                  text: TextSpan(
                    style: openSans(fontSize: 12, color: kOnSurfaceVariant),
                    children: [
                      const TextSpan(text: 'Your profile unlocks '),
                      TextSpan(
                        text: '${((percentage * 42) / 100).round()} of 42',
                        style: outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                        ),
                      ),
                      const TextSpan(text: ' active Philippine grants.'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Metric Breakdown Chips (Distinct labels so find.text('100%') remains unique)
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
                        status: profile.monthlyFamilyIncome != null ? 'Provided' : 'General',
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
                const SizedBox(height: 12),

                // View Matching Power Breakdown CTA button
                Container(
                  width: double.infinity,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: kSurfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'View Matching Power Breakdown',
                          style: outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
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

  Widget _buildMetricChip({
    required String label,
    required String status,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: kSurfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: outfit(fontSize: 10, color: kOnSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: outfit(
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
