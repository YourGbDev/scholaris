// lib/features/profile/presentation/profile_tab_screen.dart
//
// "Profile" tab — a summary of the student's matching profile with quick
// actions: update their details, or sign out.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/features/account/presentation/account_settings_screen.dart';
import 'package:scholaris/features/applications/presentation/applications_screen.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/student_mascot.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';
import 'package:scholaris/shared/widgets/state_views.dart';
import '../models/student_profile.dart';
import '../providers/profile_setup_provider.dart';

class ProfileTabScreen extends ConsumerWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return SafeArea(
      child: ResponsiveContainer(
        child: profileAsync.when(
          loading: () => const LoadingView(),
          error: (error, stackTrace) => ErrorView(
            message: 'We could not load your profile.',
            onRetry: () => ref.invalidate(currentProfileProvider),
          ),
          data: (profile) => profile == null
              ? const EmptyView(
                  mascotPose: StudentMascotPose.thinking,
                  title: 'No profile yet',
                  message: 'Complete your profile to start matching.',
                )
              : _buildProfile(context, profile),
        ),
      ),
    );
  }

  Widget _buildProfile(BuildContext context, StudentProfile profile) {
    final details = <(IconData, String, String)>[
      (Icons.workspace_premium_outlined, 'GPA', profile.gpa.toStringAsFixed(2)),
      (Icons.school_outlined, 'Year level', '${profile.yearLevel}${_ordinal(profile.yearLevel)} Year'),
      (Icons.menu_book_outlined, 'Course', profile.course),
      (Icons.apartment_rounded, 'School', profile.school ?? 'Not specified'),
      (Icons.location_on_outlined, 'Region', profile.region),
      (Icons.account_balance_wallet_outlined, 'Family income', _incomeLabel(profile)),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: kPrimarySoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: kPrimary.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: const ClipOval(
                child: StudentMascot(
                  pose: StudentMascotPose.hero,
                  height: 58,
                  width: 58,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
                    style: poppins(fontSize: 20, fontWeight: FontWeight.w700, color: kPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    profile.nationality,
                    style: openSans(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
        _EliMilestoneCard(profile: profile),
        const SizedBox(height: 20),
        Text(
          'Your matching profile',
          style: poppins(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusCard)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: details
                  .map((d) => _DetailRow(icon: d.$1, label: d.$2, value: d.$3))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusCard),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: kPrimarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_outlined, color: kPrimary, size: 20),
            ),
            title: Text(
              'My Applications',
              style: poppins(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Track your applications and their status',
              style: openSans(fontSize: 12, color: Colors.black54),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black38),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ApplicationsScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusCard),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: kPrimarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.manage_accounts_outlined,
                color: kPrimary,
                size: 20,
              ),
            ),
            title: Text(
              'Account Settings',
              style: poppins(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Email, verification and password',
              style: openSans(fontSize: 12, color: Colors.black54),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black38),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AccountSettingsScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.go('/profile-setup/personal'),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Update profile'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Supabase.instance.client.auth.signOut(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: kError,
            side: const BorderSide(color: kError),
          ),
        ),
      ],
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

  String _ordinal(int n) {
    if (n == 1) return 'st';
    if (n == 2) return 'nd';
    if (n == 3) return 'rd';
    return 'th';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: kPrimary),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Text(label, style: openSans(fontSize: 13, color: Colors.black54)),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: poppins(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _EliMilestoneCard extends StatelessWidget {
  const _EliMilestoneCard({required this.profile});

  final StudentProfile profile;

  @override
  Widget build(BuildContext context) {
    final hasSchool =
        profile.school != null && profile.school!.trim().isNotEmpty;
    final hasIncome = profile.monthlyFamilyIncome != null;
    var filledCount = 6;
    if (hasSchool) filledCount++;
    if (hasIncome) filledCount++;
    final percentage = (filledCount / 8 * 100).round();
    final isComplete = percentage == 100;

    final StudentMascotPose pose =
        isComplete ? StudentMascotPose.celebrating : StudentMascotPose.thinking;
    final accentColor = isComplete ? kLumiGold : kAccent;

    final String advice;
    if (hasSchool && hasIncome) {
      advice =
          'Outstanding! Your matching profile is 100% complete. You have all the details unlocked to find your highest-match scholarships!';
    } else if (!hasSchool && !hasIncome) {
      advice =
          'Scholaris Tip: Add your school & family income to unlock university grants and need-based tuition assistance!';
    } else if (!hasSchool) {
      advice =
          'Scholaris Tip: Add your school or university to qualify for campus-partnered grants!';
    } else {
      advice =
          'Scholaris Tip: Add your family income bracket to qualify for need-based tuition waivers!';
    }

    return Container(
      key: const ValueKey('eli-profile-milestone-card'),
      margin: const EdgeInsets.only(top: 20, bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(kRadiusCard),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.28),
        ),
        boxShadow: const [
          BoxShadow(
            color: kCardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StudentMascot(
                pose: pose,
                height: 52,
                width: 52,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Matching Power',
                          style: poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: kPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isComplete
                                ? kPrimary.withValues(alpha: 0.12)
                                : kAccent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$percentage%',
                            style: poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isComplete
                                  ? kPrimary
                                  : const Color(0xFFB57A00),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: filledCount / 8.0,
                        minHeight: 6,
                        backgroundColor: kPrimarySoft,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isComplete ? kPrimary : kAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isComplete ? kPrimarySoft : const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              advice,
              style: openSans(
                fontSize: 12,
                color: isComplete ? kPrimary : const Color(0xFF92400E),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}