// lib/features/provider/presentation/individual/individual_settings_tab.dart
//
// Personal Benefactor Profile & Settings.
// Allows individual sponsors to manage their personal details, toggle
// view mode between individual and organization for evaluation, and sign out.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/shared/widgets/logout_confirmation_dialog.dart';

import '../../providers/provider_type_provider.dart';

import 'package:scholaris/shared/theme/app_motion.dart';

import '../../../../core/auth/landing_redirect.dart';
import '../org/org_provider_theme.dart';
import '../widgets/org_summary_disclosure.dart';

final individualProfileNameSaverProvider =
    Provider<Future<void> Function(String)>((ref) {
      return (name) async {
        final client = Supabase.instance.client;
        final user = client.auth.currentUser;
        if (user == null) {
          throw const AuthException('Sign in again to save your profile.');
        }
        await client
            .from('profiles')
            .update({'full_name': name})
            .eq('id', user.id)
            .select('id')
            .single();
      };
    });

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
  final _nameForm = GlobalKey<FormState>();
  String? _saveError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _initFields(String fullName, String? email) {
    if (!_initialized) {
      _nameController.text = fullName;
      _emailController.text = email ?? '';
      _bioController.text = '';
      _initialized = true;
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving || !_nameForm.currentState!.validate()) return;
    if (ref.read(currentUserIdProvider) == null) {
      setState(
        () => _saveError =
            'Your session ended. Sign in again to save your profile.',
      );
      return;
    }
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      await ref.read(individualProfileNameSaverProvider)(
        _nameController.text.trim(),
      );
      ref.invalidate(currentProfileProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: kOrgPrimary,
          content: Text('Benefactor profile updated successfully.'),
        ),
      );
    } on AuthException {
      if (!mounted) return;
      setState(
        () => _saveError =
            'Your session ended. Sign in again to save your profile.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _saveError = 'Your profile could not be saved. Check your connection and try again.',
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

    if (profileAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (profileAsync.hasError || profile == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your profile could not load.'),
            TextButton(
              onPressed: () => ref.invalidate(currentProfileProvider),
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    _initFields(profile.fullName, profile.email);

    return Container(
      color: kOrgCanvas,
      child: ListView(
        physics: const AppleBouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Header
          Text('Profile & settings', style: orgHeadline(fontSize: 28)),
          const SizedBox(height: 2),
          Text(
            'Your provider details and account preferences.',
            style: orgBody(fontSize: 14, color: kOrgTextSecondary),
          ),

          const SizedBox(height: 18),

          OrgSummaryDisclosure(
            title: 'Workspace options',
            summary: 'Provider view settings',
            child: StaggeredListItem(
              index: 0,
              child: Container(
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
                        const Icon(
                          Icons.swap_horiz_rounded,
                          size: 18,
                          color: kOrgPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Console View Mode',
                          style: orgHeadline(fontSize: 14),
                        ),
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
                          child: PressableScale(
                            scale: 0.98,
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
                              onSelected: (_) =>
                                  setProviderType(ref, 'individual'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PressableScale(
                            scale: 0.98,
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
                              onSelected: (_) =>
                                  setProviderType(ref, 'organization'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Profile Form
          StaggeredListItem(
            index: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kOrgSurfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kOrgBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Benefactor Details',
                    style: orgHeadline(fontSize: 14),
                  ),
                  const SizedBox(height: 14),

                  Text(
                    'Full Name / Display Title',
                    style: orgLabel(fontSize: 11, color: kOrgTextSecondary),
                  ),
                  const SizedBox(height: 6),
                  Form(
                    key: _nameForm,
                    child: TextFormField(
                      controller: _nameController,
                      enabled: !_isSaving,
                      maxLength: 100,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter your display name'
                          : value.trim().length > 100
                          ? 'Use 100 characters or fewer'
                          : null,
                      style: orgBody(fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: kOrgCanvas,
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          size: 18,
                          color: kOrgTextMuted,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: kOrgBorder),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Personal statement (not available yet)',
                    style: orgLabel(fontSize: 11, color: kOrgTextSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _bioController,
                    readOnly: true,
                    maxLines: 3,
                    style: orgBody(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: kOrgCanvas,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: kOrgBorder),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_saveError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _saveError!,
                          style: orgBody(color: kOrgError),
                        ),
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    child: PressableScale(
                      scale: 0.98,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: kOrgPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isSaving ? null : _handleSave,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined, size: 16),
                        label: const Text('Save Profile Changes'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sign Out
          StaggeredListItem(
            index: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kOrgSurfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kOrgBorder),
              ),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 16,
                runSpacing: 16,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Provider Session',
                        style: orgHeadline(fontSize: 14),
                      ),
                      Text(
                        'Sign out of your benefactor portal.',
                        style: orgBody(fontSize: 11, color: kOrgTextSecondary),
                      ),
                    ],
                  ),
                  PressableScale(
                    scale: 0.98,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kOrgError,
                        side: const BorderSide(color: kOrgError),
                        minimumSize: const Size(110, 44),
                      ),
                      onPressed: () async {
                        final confirmed = await showLogoutConfirmationDialog(
                          context,
                        );
                        if (confirmed) {
                          await handleProviderSignOut();
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, size: 16),
                      label: const Text('Sign Out'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
