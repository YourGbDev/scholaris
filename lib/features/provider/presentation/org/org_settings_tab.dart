// lib/features/provider/presentation/org/org_settings_tab.dart
//
// Organization Profile & Governance Settings based on Stitch mockup
// (scholaris_provider_console_team_governance_settings).
// Manages institutional identity, provider_type switching, and security.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/shared/widgets/logout_confirmation_dialog.dart';
import '../../providers/provider_type_provider.dart';
import 'org_provider_theme.dart';

class OrgSettingsTab extends ConsumerStatefulWidget {
  const OrgSettingsTab({super.key});

  @override
  ConsumerState<OrgSettingsTab> createState() => _OrgSettingsTabState();
}

class _OrgSettingsTabState extends ConsumerState<OrgSettingsTab> {
  final _orgNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _accreditationController = TextEditingController();

  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _orgNameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _accreditationController.dispose();
    super.dispose();
  }

  void _initFields(String fullName, String? email) {
    if (!_initialized) {
      _orgNameController.text = fullName.isNotEmpty ? fullName : 'Metrobank Foundation Partner';
      _contactPersonController.text = fullName;
      _emailController.text = email ?? '';
      _phoneController.text = '+63 917 123 4567';
      _accreditationController.text = 'CHED-RO6-ACC-2024';
      _initialized = true;
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        await client.from('profiles').update({
          'full_name': _orgNameController.text.trim(),
        }).eq('id', user.id);
        ref.invalidate(currentProfileProvider);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: kOrgPrimary,
          content: Text('Institutional profile updated successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: kOrgError,
          content: Text('Failed to update profile: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final activeType = ref.watch(activeProviderTypeProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 768;

    final profile = profileAsync.valueOrNull;
    _initFields(profile?.fullName ?? '', profile?.email);

    return Container(
      color: kOrgCanvas,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Row(
              children: [
                Text('CONSOLE', style: orgLabel(fontSize: 10, color: kOrgTextMuted)),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded, size: 14, color: kOrgTextMuted),
                const SizedBox(width: 4),
                Text('SETTINGS', style: orgLabel(fontSize: 10, color: kOrgPrimary)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Organization & Governance Settings',
                style: orgHeadline(fontSize: isDesktop ? 22 : 18)),
            const SizedBox(height: 2),
            Text(
              'Manage institutional accreditation details, provider console mode, and security sign-off.',
              style: orgBody(fontSize: 12, color: kOrgTextSecondary),
            ),

            const SizedBox(height: 20),

            // Provider Type Switcher (Demo / Testing Toggle)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kOrgSurfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kOrgBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.swap_horiz_rounded, size: 20, color: kOrgPrimary),
                      const SizedBox(width: 8),
                      Text('Provider Console View Mode', style: orgHeadline(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Switch between the Institutional/Organization Console and the Individual Benefactor variant.',
                    style: orgBody(fontSize: 12, color: kOrgTextSecondary),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setProviderType(ref, 'organization'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: activeType == 'organization'
                                  ? kOrgSidebarDark
                                  : kOrgCanvas,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: activeType == 'organization'
                                    ? kOrgSidebarDark
                                    : kOrgBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.corporate_fare_rounded,
                                    size: 18,
                                    color: activeType == 'organization'
                                        ? Colors.white
                                        : kOrgTextSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Organization Provider',
                                        style: orgHeadline(
                                          fontSize: 12,
                                          color: activeType == 'organization'
                                              ? Colors.white
                                              : kOrgTextPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Desktop-first • Multi-grant portfolio & analytics',
                                        style: orgLabel(
                                          fontSize: 10,
                                          color: activeType == 'organization'
                                              ? Colors.white70
                                              : kOrgTextMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (activeType == 'organization')
                                  const Icon(Icons.check_circle_rounded,
                                      size: 16, color: kOrgAccentGold),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => setProviderType(ref, 'individual'),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: activeType == 'individual'
                                  ? kOrgSidebarDark
                                  : kOrgCanvas,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: activeType == 'individual'
                                    ? kOrgSidebarDark
                                    : kOrgBorder,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.person_outline_rounded,
                                    size: 18,
                                    color: activeType == 'individual'
                                        ? Colors.white
                                        : kOrgTextSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Individual Benefactor',
                                        style: orgHeadline(
                                          fontSize: 12,
                                          color: activeType == 'individual'
                                              ? Colors.white
                                              : kOrgTextPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Mobile-first • 1–2 scholarships & direct review',
                                        style: orgLabel(
                                          fontSize: 10,
                                          color: activeType == 'individual'
                                              ? Colors.white70
                                              : kOrgTextMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (activeType == 'individual')
                                  const Icon(Icons.check_circle_rounded,
                                      size: 16, color: kOrgAccentGold),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Organization Information Form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kOrgSurfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kOrgBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Institutional Partner Credentials', style: orgHeadline(fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    'Official organization details shown on your scholarship postings.',
                    style: orgBody(fontSize: 12, color: kOrgTextSecondary),
                  ),
                  const SizedBox(height: 16),

                  _buildFormInput(
                    label: 'Organization / Foundation Name',
                    controller: _orgNameController,
                    icon: Icons.account_balance_rounded,
                  ),
                  const SizedBox(height: 12),

                  _buildFormInput(
                    label: 'Primary Representative / Contact Person',
                    controller: _contactPersonController,
                    icon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 12),

                  _buildFormInput(
                    label: 'Official Liaison Email',
                    controller: _emailController,
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 12),

                  _buildFormInput(
                    label: 'Accreditation Reference / Partner ID',
                    controller: _accreditationController,
                    icon: Icons.verified_user_outlined,
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: kOrgPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isSaving ? null : _handleSave,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_rounded, size: 16),
                        label: Text('Save Institutional Profile',
                            style: orgLabel(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Account Security & Sign Out
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kOrgSurfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kOrgBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Session Management', style: orgHeadline(fontSize: 14)),
                      Text('Securely terminate your administrative provider session.',
                          style: orgBody(fontSize: 12, color: kOrgTextSecondary)),
                    ],
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kOrgError,
                      side: const BorderSide(color: kOrgError),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final confirmed = await showLogoutConfirmationDialog(context);
                      if (confirmed) {
                        try {
                          await Supabase.instance.client.auth.signOut();
                        } catch (_) {}
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, size: 16),
                    label: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: orgLabel(fontSize: 11, color: kOrgTextSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          style: orgBody(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: kOrgCanvas,
            prefixIcon: Icon(icon, size: 18, color: kOrgTextMuted),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kOrgBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kOrgBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: kOrgPrimary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
