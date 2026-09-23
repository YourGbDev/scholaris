// lib/features/provider/presentation/individual/individual_settings_tab.dart
//
// Personal Benefactor Profile & Settings.
// Allows individual sponsors to manage their personal details, toggle
// view mode between individual and organization for evaluation, and sign out.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/shared/widgets/logout_confirmation_dialog.dart';
import '../../providers/provider_type_provider.dart';
import '../org/org_provider_theme.dart';

class IndividualSettingsTab extends ConsumerStatefulWidget {
  const IndividualSettingsTab({super.key});

  @override
  ConsumerState<IndividualSettingsTab> createState() =>
      _IndividualSettingsTabState();
}

class _IndividualSettingsTabState extends ConsumerState<IndividualSettingsTab> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _bioController = TextEditingController();

  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _initFields(String fullName, String? email) {
    if (!_initialized) {
      _nameController.text = fullName.isNotEmpty ? fullName : 'Dr. Jose Santos';
      _emailController.text = email ?? '';
      _bioController.text =
          'UP Diliman College of Engineering Alumnus Batch 1998. Passionate about empowering the next generation of Filipino engineers and technologists.';
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
          'full_name': _nameController.text.trim(),
        }).eq('id', user.id);
        ref.invalidate(currentProfileProvider);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: kOrgPrimary,
          content: Text('Benefactor profile updated successfully.'),
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
    final profile = profileAsync.valueOrNull;

    _initFields(profile?.fullName ?? '', profile?.email);

    return Container(
      color: kOrgCanvas,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Header
          Text('Benefactor Profile & Settings', style: orgHeadline(fontSize: 18)),
          const SizedBox(height: 2),
          Text(
            'Your personal sponsorship identity and account preferences.',
            style: orgBody(fontSize: 12, color: kOrgTextSecondary),
          ),

          const SizedBox(height: 18),

          // View Mode Switcher Tile (Org vs Individual)
          Container(
            padding: const EdgeInsets.all(14),
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
                    const Icon(Icons.swap_horiz_rounded,
                        size: 18, color: kOrgPrimary),
                    const SizedBox(width: 8),
                    Text('Console View Mode', style: orgHeadline(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Switch between Individual Benefactor view and Organization Console.',
                  style: orgBody(fontSize: 11, color: kOrgTextSecondary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Individual Benefactor'),
                        ),
                        selected: activeType == 'individual',
                        selectedColor: kOrgSidebarDark,
                        labelStyle: orgLabel(
                          color: activeType == 'individual'
                              ? Colors.white
                              : kOrgTextPrimary,
                          fontSize: 11,
                        ),
                        onSelected: (_) => setProviderType(ref, 'individual'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Org Console'),
                        ),
                        selected: activeType == 'organization',
                        selectedColor: kOrgSidebarDark,
                        labelStyle: orgLabel(
                          color: activeType == 'organization'
                              ? Colors.white
                              : kOrgTextPrimary,
                          fontSize: 11,
                        ),
                        onSelected: (_) => setProviderType(ref, 'organization'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Profile Form
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
                Text('Personal Benefactor Details',
                    style: orgHeadline(fontSize: 14)),
                const SizedBox(height: 14),

                Text('Full Name / Display Title',
                    style: orgLabel(fontSize: 11, color: kOrgTextSecondary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  style: orgBody(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: kOrgCanvas,
                    prefixIcon: const Icon(Icons.person_outline_rounded,
                        size: 18, color: kOrgTextMuted),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: kOrgBorder),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text('Personal Statement / Background',
                    style: orgLabel(fontSize: 11, color: kOrgTextSecondary)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _bioController,
                  maxLines: 3,
                  style: orgBody(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: kOrgCanvas,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: kOrgBorder),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: kOrgPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _isSaving ? null : _handleSave,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined, size: 16),
                    label: const Text('Save Profile Changes'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Sign Out
          Container(
            padding: const EdgeInsets.all(16),
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
                    Text('Provider Session', style: orgHeadline(fontSize: 14)),
                    Text('Sign out of your benefactor portal.',
                        style: orgBody(fontSize: 11, color: kOrgTextSecondary)),
                  ],
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kOrgError,
                    side: const BorderSide(color: kOrgError),
                  ),
                  onPressed: () async {
                    final confirmed =
                        await showLogoutConfirmationDialog(context);
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
    );
  }
}
