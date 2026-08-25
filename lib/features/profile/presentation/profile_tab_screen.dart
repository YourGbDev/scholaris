// lib/features/profile/presentation/profile_tab_screen.dart
//
// "Profile" tab — a summary of the student's matching profile with quick
// actions: update their details, or sign out.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/state_views.dart';
import '../models/student_profile.dart';
import '../providers/profile_setup_provider.dart';

class ProfileTabScreen extends ConsumerWidget {
  const ProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return SafeArea(
      child: profileAsync.when(
        loading: () => const LoadingView(),
        error: (_, _) => const EmptyView(
          icon: Icons.error_outline_rounded,
          title: 'Profile unavailable',
          message: 'We could not load your profile.',
        ),
        data: (profile) => profile == null
            ? const EmptyView(
                icon: Icons.person_outline_rounded,
                title: 'No profile yet',
                message: 'Complete your profile to start matching.',
              )
            : _buildProfile(context, profile),
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: kPrimarySoft, shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded, size: 32, color: kPrimary),
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
        const SizedBox(height: 24),
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