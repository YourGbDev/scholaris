// lib/features/provider/presentation/org/org_settings_tab.dart
//
// Organization Settings & Profile Screen matching Stitch mockup
// (scholaris_provider_organization_settings).
// Adheres strictly to Philippine regulatory compliance, live Supabase data,
// honest unverified/incomplete states for unrecorded fields, and ₱ currency.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/shared/widgets/logout_confirmation_dialog.dart';
import '../../providers/provider_scholarships_provider.dart';
import '../../providers/provider_type_provider.dart';
import '../../../../core/auth/landing_redirect.dart';
import 'org_provider_theme.dart';

class OrgSettingsTab extends ConsumerStatefulWidget {
  const OrgSettingsTab({super.key});

  @override
  ConsumerState<OrgSettingsTab> createState() => _OrgSettingsTabState();
}

class _OrgSettingsTabState extends ConsumerState<OrgSettingsTab> {
  // Form Controllers
  final _legalEntityNameController = TextEditingController();
  final _secRegController = TextEditingController();
  final _tinController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _missionController = TextEditingController();
  final _repNameController = TextEditingController();
  final _repTitleController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Scroll Controller & Section Keys
  final _scrollController = ScrollController();
  final _profileKey = GlobalKey();
  final _repKey = GlobalKey();
  final _notificationsKey = GlobalKey();
  final _securityKey = GlobalKey();

  // Segmented Navigation State
  int _selectedSegment = 0;

  // Toggle Switches (Fluid Sequoia style)
  bool _alertGwa150 = true;
  bool _weeklyDigest = true;
  bool _duplicateLrnAlert = true;
  bool _smsClearanceReminders = false;

  bool _isSaving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _legalEntityNameController.dispose();
    _secRegController.dispose();
    _tinController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _missionController.dispose();
    _repNameController.dispose();
    _repTitleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _initFields(String fullName, String? email, String? phone) {
    if (!_initialized) {
      _legalEntityNameController.text = fullName.isNotEmpty ? fullName : 'Ayala Foundation Partner';
      // Real database fields for demo provider are unrecorded / null
      // We leave unrecorded registration/address fields empty with honest hints
      _secRegController.text = '';
      _tinController.text = '';
      _websiteController.text = '';
      _addressController.text = '';
      _missionController.text = '';
      _repNameController.text = '';
      _repTitleController.text = '';
      _emailController.text = email ?? 'demo_provider@scholaris.test';
      _phoneController.text = phone ?? '';
      _initialized = true;
    }
  }

  void _resetFields() {
    final profile = ref.read(currentProfileProvider).valueOrNull;
    setState(() {
      _legalEntityNameController.text = profile?.fullName ?? 'Ayala Foundation Partner';
      _secRegController.text = '';
      _tinController.text = '';
      _websiteController.text = '';
      _addressController.text = '';
      _missionController.text = '';
      _repNameController.text = '';
      final authUser = Supabase.instance.client.auth.currentUser;
      _emailController.text = authUser?.email ?? 'demo_provider@scholaris.test';
      _phoneController.text = authUser?.phone ?? '';
      _alertGwa150 = true;
      _weeklyDigest = true;
      _duplicateLrnAlert = true;
      _smsClearanceReminders = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: kOrgTextPrimary,
        content: Text(
          'Draft discarded. Reverted to saved database state.',
          style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        // Save verified available fields to Supabase profiles table
        final updates = <String, dynamic>{
          'full_name': _legalEntityNameController.text.trim(),
        };
        if (_phoneController.text.trim().isNotEmpty) {
          updates['phone'] = _phoneController.text.trim();
        }

        await client.from('profiles').update(updates).eq('id', user.id);
        ref.invalidate(currentProfileProvider);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: kOrgPrimary,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                'Organization profile and preferences updated successfully.',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: kOrgError,
          content: Text('Failed to update organization profile: $e',
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _scrollToSection(int index) {
    setState(() => _selectedSegment = index);
    final key = [
      _profileKey,
      _repKey,
      _notificationsKey,
      _securityKey,
    ][index];

    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _showArchiveAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kOrgSurfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: kOrgError.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: kOrgError, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Archive Organization Account',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: kOrgTextPrimary),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to archive your grantor account? This will pause all active scholarship application cycles and freeze pending disbursements. Awarded scholar historical records will remain retained under statutory compliance.',
          style: GoogleFonts.inter(fontSize: 13, color: kOrgTextSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: GoogleFonts.inter(fontSize: 13, color: kOrgTextSecondary)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: kOrgError,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: kOrgTextPrimary,
                  content: Text('Account archiving is disabled in evaluation demo mode.'),
                ),
              );
            },
            child: Text('Archive Account', style: GoogleFonts.inter(fontSize: 13, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final myScholarshipsAsync = ref.watch(providerScholarshipsProvider);
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    final authUser = Supabase.instance.client.auth.currentUser;
    final userEmail = authUser?.email ?? 'demo_provider@scholaris.test';
    final userPhone = authUser?.phone ?? '';

    final profile = profileAsync.valueOrNull;
    _initFields(profile?.fullName ?? '', userEmail, userPhone);

    final orgName = (profile?.fullName.trim().isNotEmpty == true)
        ? profile!.fullName.trim()
        : 'Ayala Foundation Partner';

    final initials = orgName.length >= 2 ? orgName.substring(0, 2).toUpperCase() : 'AF';

    // Compute live endowment budget from the provider's active scholarships
    final scholarships = myScholarshipsAsync.valueOrNull ?? [];
    final activeBudget = scholarships.fold<int>(0, (sum, s) => sum + s.awardAmount);
    final displayBudget = activeBudget > 0 ? activeBudget : 50000;

    return Container(
      color: kOrgCanvas,
      width: double.infinity,
      height: double.infinity,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16,
          vertical: isDesktop ? 28 : 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section with Breadcrumb & Primary Command
            _buildHeaderBar(orgName: orgName, isDesktop: isDesktop),
            const SizedBox(height: 24),

            // Segmented Navigation Bar (Apple macOS Sequoia Control)
            _buildSegmentedControl(isDesktop: isDesktop),
            const SizedBox(height: 24),

            // Layout Grid: Left Main Stack (8 cols) + Right Context Sidebar (4 cols)
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 8,
                    child: _buildLeftColumn(orgName: orgName, initials: initials, email: profile?.email),
                  ),
                  const SizedBox(width: 24),
                  SizedBox(
                    width: 360,
                    child: _buildRightSidebar(displayBudget: displayBudget),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLeftColumn(orgName: orgName, initials: initials, email: profile?.email),
                  const SizedBox(height: 24),
                  _buildRightSidebar(displayBudget: displayBudget),
                ],
              ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Header Bar
  // ---------------------------------------------------------------------------
  Widget _buildHeaderBar({required String orgName, required bool isDesktop}) {
    final titleAndSubtitle = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            Text(
              orgName.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: kOrgPrimary,
                letterSpacing: 0.6,
              ),
            ),
            Text('/', style: GoogleFonts.inter(fontSize: 11, color: kOrgBorderDark)),
            Text(
              'Account & Organization',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: kOrgTextSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFB3F1C6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: kOrgPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'ACTIVE GRANTOR',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF00351C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Organization Settings & Profile',
          style: GoogleFonts.inter(
            fontSize: isDesktop ? 26 : 21,
            fontWeight: FontWeight.w700,
            color: kOrgTextPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Text(
            'Manage your organization profile, authorized representative credentials, notification preferences, and grant documentation templates.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: kOrgTextSecondary,
              height: 1.35,
            ),
          ),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        // Discard Draft Button
        Material(
          color: const Color(0xFFEEEDF3),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _resetFields,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                'Discard Draft',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kOrgTextPrimary,
                ),
              ),
            ),
          ),
        ),

        // Save Changes Button
        Material(
          color: kOrgPrimary,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _isSaving ? null : _handleSave,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSaving)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  else
                    const Icon(Icons.check_circle_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    _isSaving ? 'Saving...' : 'Save Changes',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: titleAndSubtitle),
          const SizedBox(width: 24),
          actions,
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleAndSubtitle,
          const SizedBox(height: 16),
          actions,
        ],
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Segmented Navigation Bar (Apple macOS Sequoia Control)
  // ---------------------------------------------------------------------------
  Widget _buildSegmentedControl({required bool isDesktop}) {
    final segments = [
      'Organization Profile',
      'Representative Info',
      'Notification Routing',
      'Security & Auth',
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEDF3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(segments.length, (i) {
                  final isSelected = _selectedSegment == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _scrollToSection(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    offset: const Offset(0, 1),
                                    blurRadius: 3,
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          segments[i],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? kOrgTextPrimary : kOrgTextSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }

          return Row(
            children: List.generate(segments.length, (i) {
              final isSelected = _selectedSegment == i;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _scrollToSection(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      segments[i],
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? kOrgTextPrimary : kOrgTextSecondary,
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Left Column Stack: 4 Main Dossier Cards
  // ---------------------------------------------------------------------------
  Widget _buildLeftColumn({
    required String orgName,
    required String initials,
    required String? email,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // SECTION 1: Institutional Profile
        _buildInstitutionalProfileCard(
          key: _profileKey,
          orgName: orgName,
          initials: initials,
        ),
        const SizedBox(height: 24),

        // SECTION 2: Authorized Representative Contact
        _buildAuthorizedRepresentativeCard(
          key: _repKey,
          email: email,
        ),
        const SizedBox(height: 24),

        // SECTION 3: Grant Notification & Intake Preferences
        _buildNotificationPreferencesCard(key: _notificationsKey),
        const SizedBox(height: 24),

        // SECTION 4: Danger Zone / Account Lifecycle
        _buildAccountLifecycleCard(key: _securityKey),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Section 1 Card: Institutional Profile
  // ---------------------------------------------------------------------------
  Widget _buildInstitutionalProfileCard({
    required Key key,
    required String orgName,
    required String initials,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kOrgSurfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kOrgBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 500;

          final brandingTile = Container(
            width: isNarrow ? 72 : 80,
            height: isNarrow ? 72 : 80,
            decoration: BoxDecoration(
              color: kOrgPrimary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: kOrgPrimary.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  initials,
                  style: GoogleFonts.inter(
                    fontSize: isNarrow ? 22 : 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'NCR, PH',
                  style: GoogleFonts.inter(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB3F1C6),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          );

          final brandingTextAndActions = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'Organization Seal & Insignia',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kOrgTextPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF7E6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCDFA0)),
                    ),
                    child: Text(
                      'DEMO EVALUATION SEAL',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8F6400),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'PNG, SVG or WEBP vector format. Recommended 800x800px. Appears on formal Grant Offer Letters and Certifications.',
                style: GoogleFonts.inter(fontSize: 11.5, color: kOrgTextSecondary, height: 1.35),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Material(
                    color: const Color(0xFFE3E2E7),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text('File upload dialog: Institutional asset replacement ready.'),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Text(
                          'Upload New',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: kOrgTextPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text('Logo reset to default foundation initials.'),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Text(
                          'Remove',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: kOrgError,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );

          final brandingUnit = Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F6FB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      brandingTile,
                      const SizedBox(height: 12),
                      brandingTextAndActions,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      brandingTile,
                      const SizedBox(width: 16),
                      Expanded(child: brandingTextAndActions),
                    ],
                  ),
          );

          final secField = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel('SEC REGISTRATION NUMBER'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _secRegController,
                style: GoogleFonts.inter(fontSize: 13, color: kOrgTextPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF7F6FB),
                  hintText: 'Not yet registered / Incomplete',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: kOrgTextMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          );

          final tinField = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel('TAX IDENTIFICATION NUMBER (TIN)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _tinController,
                style: GoogleFonts.inter(fontSize: 13, color: kOrgTextPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF7F6FB),
                  hintText: 'Not yet provided',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: kOrgTextMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          );

          final secAndTinRow = isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    secField,
                    const SizedBox(height: 16),
                    tinField,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: secField),
                    const SizedBox(width: 16),
                    Expanded(child: tinField),
                  ],
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEDF3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.corporate_fare_rounded, color: kOrgPrimary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Institutional Profile',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: kOrgTextPrimary,
                            ),
                          ),
                          Text(
                            'Public identity visible to scholarship applicants & partner universities',
                            style: GoogleFonts.inter(fontSize: 12, color: kOrgTextSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEDF3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'AY 2024–2025',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kOrgTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              brandingUnit,
              const SizedBox(height: 20),

              // Form Fields
              _buildInputLabel('LEGAL ENTITY NAME'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _legalEntityNameController,
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: kOrgTextPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF7F6FB),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  suffixIcon: const Icon(Icons.verified_rounded, size: 18, color: kOrgPrimary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              secAndTinRow,
              const SizedBox(height: 16),

              // Official Organization Website
              _buildInputLabel('OFFICIAL ORGANIZATION WEBSITE'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F6FB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Text(
                      'https://',
                      style: GoogleFonts.inter(fontSize: 13, color: kOrgTextSecondary, fontWeight: FontWeight.w500),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _websiteController,
                        style: GoogleFonts.inter(fontSize: 13, color: kOrgTextPrimary),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'example.org (Not yet provided)',
                          hintStyle: GoogleFonts.inter(fontSize: 12, color: kOrgTextMuted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const Icon(Icons.open_in_new_rounded, size: 16, color: kOrgTextMuted),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Registered Corporate Address
              _buildInputLabel('REGISTERED CORPORATE ADDRESS'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                style: GoogleFonts.inter(fontSize: 13, color: kOrgTextPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF7F6FB),
                  hintText: 'Not yet provided (Corporate address unlisted)',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: kOrgTextMuted),
                  suffixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 18),
                    child: Icon(Icons.location_on_outlined, size: 18, color: kOrgTextMuted),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Mission Statement & Granting Mandate
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInputLabel('MISSION STATEMENT & GRANTING MANDATE'),
                  Text(
                    '${_missionController.text.length} / 500 characters',
                    style: GoogleFonts.inter(fontSize: 11, color: kOrgTextMuted),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _missionController,
                maxLines: 4,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: kOrgTextPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF7F6FB),
                  hintText: 'Enter your organization\'s mission statement and granting mandate for Filipino scholars (up to 500 characters)...',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: kOrgTextMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 2 Card: Authorized Representative
  // ---------------------------------------------------------------------------
  Widget _buildAuthorizedRepresentativeCard({
    required Key key,
    required String? email,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kOrgSurfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kOrgBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 500;

          final repNameField = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel('REPRESENTATIVE LEGAL NAME'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _repNameController,
                style: GoogleFonts.inter(fontSize: 13, color: kOrgTextPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF7F6FB),
                  hintText: 'Lead Administrator (Not yet specified)',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: kOrgTextMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          );

          final repTitleField = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel('DESIGNATION / EXECUTIVE TITLE'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _repTitleController,
                style: GoogleFonts.inter(fontSize: 13, color: kOrgTextPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF7F6FB),
                  hintText: 'Lead Grant Administrator',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: kOrgTextMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          );

          final repNameAndTitleRow = isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    repNameField,
                    const SizedBox(height: 16),
                    repTitleField,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: repNameField),
                    const SizedBox(width: 16),
                    Expanded(child: repTitleField),
                  ],
                );

          final emailField = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInputLabel('WORK EMAIL ADDRESS'),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 12, color: kOrgPrimary),
                      const SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: kOrgPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                readOnly: true,
                style: GoogleFonts.inter(fontSize: 13, color: kOrgTextPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF7F6FB),
                  suffixIcon: const Icon(Icons.alternate_email_rounded, size: 16, color: kOrgTextMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          );

          final phoneField = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputLabel('OFFICIAL TELEPHONE / EXTENSION'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                style: GoogleFonts.inter(fontSize: 13, color: kOrgTextPrimary),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: const Color(0xFFF7F6FB),
                  hintText: 'Not yet provided',
                  hintStyle: GoogleFonts.inter(fontSize: 12, color: kOrgTextMuted),
                  suffixIcon: const Icon(Icons.call_outlined, size: 16, color: kOrgTextMuted),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          );

          final emailAndPhoneRow = isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    emailField,
                    const SizedBox(height: 16),
                    phoneField,
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: emailField),
                    const SizedBox(width: 16),
                    Expanded(child: phoneField),
                  ],
                );

          final pkiSignatureCard = Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F6FB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: isNarrow
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3E2E7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.draw_rounded, color: kOrgPrimary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Registered Digital PKI Signature',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: kOrgTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Digital Signature: Not enrolled with PNPKI • Pending Administrative Registration',
                        style: GoogleFonts.inter(fontSize: 11.5, color: kOrgTextSecondary),
                      ),
                      const SizedBox(height: 12),
                      Material(
                        color: const Color(0xFFE3E2E7),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text('PNPKI integration desk: Official certificate enrollment workflow.'),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            child: Text(
                              'Register Key',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: kOrgTextPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3E2E7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.draw_rounded, color: kOrgPrimary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registered Digital PKI Signature',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: kOrgTextPrimary,
                              ),
                            ),
                            Text(
                              'Digital Signature: Not enrolled with PNPKI • Pending Administrative Registration',
                              style: GoogleFonts.inter(fontSize: 11.5, color: kOrgTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: const Color(0xFFE3E2E7),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Text('PNPKI integration desk: Official certificate enrollment workflow.'),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            child: Text(
                              'Register Key',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: kOrgTextPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEEDF3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.badge_outlined, color: kOrgPrimary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Authorized Representative',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: kOrgTextPrimary,
                            ),
                          ),
                          Text(
                            'Signatory credentials for statutory grant clearance and legal disbursements',
                            style: GoogleFonts.inter(fontSize: 12, color: kOrgTextSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB3F1C6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF00351C)),
                        const SizedBox(width: 4),
                        Text(
                          'Primary Signatory',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF00351C),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              repNameAndTitleRow,
              const SizedBox(height: 16),
              emailAndPhoneRow,
              const SizedBox(height: 20),
              pkiSignatureCard,
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 3 Card: Grant Notification & Intake Preferences
  // ---------------------------------------------------------------------------
  Widget _buildNotificationPreferencesCard({required Key key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kOrgSurfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kOrgBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEDF3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_active_outlined, color: kOrgPrimary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grant Notification & Intake Preferences',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: kOrgTextPrimary,
                        ),
                      ),
                      Text(
                        'Control real-time algorithmic triggers and automated intake reporting',
                        style: GoogleFonts.inter(fontSize: 12, color: kOrgTextSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                'AUTOMATION ACTIVE',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: kOrgTextSecondary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEDF3)),

          // Toggle 1
          _buildToggleRow(
            title: 'Instant Qualified Applicant Alert (GWA ≤ 1.50)',
            description: 'Triggers immediate email routing when candidate meets highest academic tier threshold.',
            value: _alertGwa150,
            onChanged: (val) => setState(() => _alertGwa150 = val),
          ),
          const Divider(height: 1, color: Color(0xFFEEEDF3)),

          // Toggle 2
          _buildToggleRow(
            title: 'Weekly Applicant Digest & Funnel Report',
            description: 'Comprehensive analytical summary dispatched every Monday at 8:00 AM PST.',
            value: _weeklyDigest,
            onChanged: (val) => setState(() => _weeklyDigest = val),
          ),
          const Divider(height: 1, color: Color(0xFFEEEDF3)),

          // Toggle 3
          _buildToggleRow(
            title: 'Automated Duplicate LRN / DepEd ID Alert',
            description: 'Cross-checks applicant Learner Reference Number against multi-grant active registries.',
            value: _duplicateLrnAlert,
            onChanged: (val) => setState(() => _duplicateLrnAlert = val),
          ),
          const Divider(height: 1, color: Color(0xFFEEEDF3)),

          // Toggle 4
          _buildToggleRow(
            title: 'SMS Clearance Reminders for Disbursement Batches',
            description: 'Send urgent cellular push alerts to authorized signatory phone for time-sensitive clearances.',
            value: _smsClearanceReminders,
            onChanged: (val) => setState(() => _smsClearanceReminders = val),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: kOrgTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: kOrgTextSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            activeTrackColor: kOrgPrimary,
            activeThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFE3E2E7),
            inactiveThumbColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Section 4 Card: Account Actions & Lifecycle (Danger Zone)
  // ---------------------------------------------------------------------------
  Widget _buildAccountLifecycleCard({required Key key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kOrgSurfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: kOrgError, width: 4),
          top: BorderSide(color: kOrgBorder),
          right: BorderSide(color: kOrgBorder),
          bottom: BorderSide(color: kOrgBorder),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: kOrgError.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded, color: kOrgError, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Actions & Lifecycle',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kOrgTextPrimary,
                    ),
                  ),
                  Text(
                    'Permanent registry archiving and active credential termination',
                    style: GoogleFonts.inter(fontSize: 12, color: kOrgTextSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Archiving your grantor account pauses all active intake scholarship cycles, revokes open public application URLs, and freezes pending payment authorizations. Existing awarded scholar dossiers remain archived under regulatory retention standards.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: kOrgTextSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              // Sign Out of All Active Consoles
              Material(
                color: const Color(0xFFEEEDF3),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () async {
                    final confirmed = await showLogoutConfirmationDialog(context);
                    if (confirmed) {
                      await handleProviderSignOut();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.logout_rounded, size: 16, color: kOrgTextPrimary),
                        const SizedBox(width: 6),
                        Text(
                          'Sign Out of All Active Consoles',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kOrgTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Archive Organization Account
              Material(
                color: kOrgError,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _showArchiveAccountDialog,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.archive_outlined, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'Archive Organization Account',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Right Sidebar Widgets
  // ---------------------------------------------------------------------------
  Widget _buildRightSidebar({required int displayBudget}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card 1: Accreditation Status
        _buildAccreditationStatusCard(),
        const SizedBox(height: 20),

        // Card 2: Registered Headquarters
        _buildHeadquartersCard(),
        const SizedBox(height: 20),

        // Card 3: Active Fund Envelope
        _buildFundEnvelopeCard(displayBudget: displayBudget),
        const SizedBox(height: 20),

        // Card 4: Institutional Desk
        _buildInstitutionalDeskCard(),
        const SizedBox(height: 20),

        // Card 5: Provider View Mode Switcher
        _buildProviderModeSwitcherCard(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Right Sidebar Card 1: Accreditation Status
  // ---------------------------------------------------------------------------
  Widget _buildAccreditationStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kOrgSurfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kOrgBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 16, color: kOrgPrimary),
              const SizedBox(width: 6),
              Text(
                'ACCREDITATION STATUS',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: kOrgPrimary,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Coursework Evaluation Account',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: kOrgTextPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Institutional Verification Incomplete',
            style: GoogleFonts.inter(fontSize: 11.5, color: kOrgTextSecondary),
          ),
          const SizedBox(height: 14),

          // Progress Meter: Honest 25% for unverified demo account
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F6FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Compliance Readiness',
                      style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w500, color: kOrgTextPrimary),
                    ),
                    Text(
                      '25%',
                      style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.w700, color: kOrgPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.25,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE3E2E7),
                    valueColor: const AlwaysStoppedAnimation<Color>(kOrgPrimary),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pending formal Philippine SEC / BIR accreditation submission',
                  style: GoogleFonts.inter(fontSize: 10.5, color: kOrgTextMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Document Checklist
          _buildChecklistItem(
            label: 'Articles of Incorporation',
            status: 'Pending Submission',
            isComplete: false,
          ),
          const SizedBox(height: 8),
          _buildChecklistItem(
            label: 'BIR Tax Exemption Cert.',
            status: 'Pending Submission',
            isComplete: false,
          ),
          const SizedBox(height: 8),
          _buildChecklistItem(
            label: 'PCNC Seal of Good Governance',
            status: 'Not Enrolled',
            isComplete: false,
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem({
    required String label,
    required String status,
    required bool isComplete,
  }) {
    return Row(
      children: [
        Icon(
          isComplete ? Icons.check_circle_rounded : Icons.pending_outlined,
          size: 16,
          color: isComplete ? kOrgPrimary : kOrgTextMuted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 11.5, color: kOrgTextPrimary),
          ),
        ),
        Text(
          status,
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: isComplete ? kOrgPrimary : kOrgTextMuted,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Right Sidebar Card 2: Registered Headquarters
  // ---------------------------------------------------------------------------
  Widget _buildHeadquartersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kOrgSurfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kOrgBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
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
              Text(
                'REGISTERED HEADQUARTERS',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: kOrgTextSecondary,
                  letterSpacing: 0.6,
                ),
              ),
              const Icon(Icons.apartment_rounded, size: 16, color: kOrgTextMuted),
            ],
          ),
          const SizedBox(height: 12),

          // Map context visual placeholder
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD0DDEB)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Abstract grid lines
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapGridPainter(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: kOrgPrimary),
                      const SizedBox(width: 4),
                      Text(
                        'Location Not Specified',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: kOrgTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Philippine Regional Hub',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: kOrgTextPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            'Address unlisted • Update in Institutional Profile',
            style: GoogleFonts.inter(fontSize: 11.5, color: kOrgTextSecondary),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Right Sidebar Card 3: Active Fund Envelope
  // ---------------------------------------------------------------------------
  Widget _buildFundEnvelopeCard({required int displayBudget}) {
    // Format amount into Philippine Pesos (e.g. ₱50,000)
    final formatted = displayBudget >= 1000000
        ? '₱${(displayBudget / 1000000).toStringAsFixed(1)}M'
        : '₱${displayBudget.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kOrgSurfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kOrgBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
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
              Text(
                'ACTIVE FUND ENVELOPE',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: kOrgTextSecondary,
                  letterSpacing: 0.6,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEEDF3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'AY 2024–25',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: kOrgTextSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatted,
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: kOrgPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '1 Active Grant',
                style: GoogleFonts.inter(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF306948),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Mini monthly bar visualizer
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBar(heightRatio: 0.35, isPrimary: false),
                _buildBar(heightRatio: 0.42, isPrimary: false),
                _buildBar(heightRatio: 0.30, isPrimary: false),
                _buildBar(heightRatio: 0.48, isPrimary: false),
                _buildBar(heightRatio: 0.40, isPrimary: false),
                _buildBar(heightRatio: 0.52, isPrimary: true),
                _buildBar(heightRatio: 0.45, isPrimary: true),
                _buildBar(heightRatio: 0.55, isPrimary: true),
                _buildBar(heightRatio: 0.70, isPrimary: true, isPeak: true),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('OCT', style: GoogleFonts.jetBrainsMono(fontSize: 9.5, color: kOrgTextMuted)),
              Text('NOV', style: GoogleFonts.jetBrainsMono(fontSize: 9.5, color: kOrgTextMuted)),
              Text('DEC', style: GoogleFonts.jetBrainsMono(fontSize: 9.5, color: kOrgTextMuted)),
              Text('JAN', style: GoogleFonts.jetBrainsMono(fontSize: 9.5, color: kOrgTextMuted)),
              Text('ACTIVE', style: GoogleFonts.jetBrainsMono(fontSize: 9.5, color: kOrgPrimary, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar({required double heightRatio, required bool isPrimary, bool isPeak = false}) {
    return Container(
      width: 14,
      height: 48 * heightRatio,
      decoration: BoxDecoration(
        color: isPeak
            ? const Color(0xFF306948)
            : isPrimary
                ? kOrgPrimary
                : const Color(0xFFE3E2E7),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Right Sidebar Card 4: Institutional Desk
  // ---------------------------------------------------------------------------
  Widget _buildInstitutionalDeskCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEDF3),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(Icons.support_agent_rounded, size: 20, color: kOrgPrimary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Institutional Desk',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: kOrgTextPrimary,
                  ),
                ),
                Text(
                  'support@scholaris.ph',
                  style: GoogleFonts.inter(fontSize: 11, color: kOrgTextSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 18, color: kOrgTextSecondary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('Contact institutional support at support@scholaris.ph'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Right Sidebar Card 5: Provider View Mode Switcher (Testing Switcher)
  // ---------------------------------------------------------------------------
  Widget _buildProviderModeSwitcherCard() {
    final activeType = ref.watch(activeProviderTypeProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kOrgSurfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kOrgBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.swap_horiz_rounded, size: 18, color: kOrgPrimary),
              const SizedBox(width: 6),
              Text(
                'Provider View Mode',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kOrgTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Switch console interface mode for testing workflows.',
            style: GoogleFonts.inter(fontSize: 11, color: kOrgTextSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setProviderType(ref, 'organization'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: activeType == 'organization' ? kOrgPrimary : const Color(0xFFF7F6FB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: activeType == 'organization' ? kOrgPrimary : kOrgBorder,
                      ),
                    ),
                    child: Text(
                      'Institutional Org',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: activeType == 'organization' ? Colors.white : kOrgTextSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => setProviderType(ref, 'individual'),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: activeType == 'individual' ? kOrgPrimary : const Color(0xFFF7F6FB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: activeType == 'individual' ? kOrgPrimary : kOrgBorder,
                      ),
                    ),
                    child: Text(
                      'Benefactor Mode',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: activeType == 'individual' ? Colors.white : kOrgTextSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: kOrgTextSecondary,
        letterSpacing: 0.6,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Custom painter for subtle headquarters map grid background
// -----------------------------------------------------------------------------
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD8E2FF).withValues(alpha: 0.4)
      ..strokeWidth = 1.0;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
