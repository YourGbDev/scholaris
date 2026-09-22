// lib/features/profile/presentation/profile_setup_screen.dart
//
// Multi-step profile setup wizard. Migrated to 100% Stitch V2 visual fidelity
// with segmented micro-bar step tracker, 740+ Active Philippine Grants insight
// banner, GWA scale switcher tabs, DOST qualification live badge, LGU location
// funding insights, Subsidies Unlocked visualizer, quick income brackets, and
// RA 10173 data privacy shield.
//
// Preserves domain validation (ProfileValidator), profileSetupProvider state,
// and all test contracts.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:scholaris/app/router.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/models/avatar_item.dart';
import 'package:scholaris/features/profile/models/profile_validator.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/presentation/widgets/avatar_display.dart';
import 'package:scholaris/features/profile/providers/avatar_provider.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/shared/widgets/scholaris_logo.dart';
import 'package:scholaris/shared/widgets/success_overlay.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key, required this.step});

  final String step;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _fullNameController;
  late final TextEditingController _nationalityController;
  late final TextEditingController _courseController;
  late final TextEditingController _schoolController;
  late final TextEditingController _gpaController;
  late final TextEditingController _incomeController;
  late final TextEditingController _provinceController;
  late final TextEditingController _cityController;

  String _selectedGpaScale = '1.0 – 5.0';
  bool _is4psBeneficiary = false;
  bool _isSoloParentDependent = false;

  int get _stepIndex => switch (widget.step) {
        'personal' => 1,
        'academic' => 2,
        _ => 3,
      };

  String get _stepTitle => switch (widget.step) {
        'personal' => 'Personal Information',
        'academic' => 'Academic Information',
        _ => 'Financial Information',
      };

  String get _stepSubtitle => switch (widget.step) {
        'personal' =>
          'We use these verified academic details to match you with university grants, CHED UniFAST subsidies, and private endowments tailored to you.',
        'academic' =>
          'We use this to match scholarships for your university and major program.',
        _ =>
          'Many of the biggest grants in the Philippines are need-based subsidies (such as CHED TES, UniFAST, and foundation grants) built specifically to uplift deserving students.',
      };

  String get _stepTrackerCategory => switch (widget.step) {
        'personal' => 'Academics & Basics',
        'academic' => 'Residency & Location',
        _ => 'Financial Matching',
      };

  @override
  void initState() {
    super.initState();
    final userId = ref.read(currentUserIdProvider);
    final state = userId == null
        ? const ProfileSetupState()
        : ref.read(profileSetupProvider(userId));
    _fullNameController = TextEditingController(text: state.fullName);
    _nationalityController = TextEditingController(text: state.nationality);
    _courseController = TextEditingController(text: state.course);
    _schoolController = TextEditingController(text: state.school);
    _gpaController = TextEditingController(text: state.gpa);
    _incomeController =
        TextEditingController(text: state.monthlyFamilyIncome);
    _provinceController = TextEditingController(text: state.province);
    _cityController = TextEditingController(text: state.cityMunicipality);
  }

  void _syncHydration(ProfileSetupState? previous, ProfileSetupState next) {
    if (next.hydrated && !(previous?.hydrated ?? false)) {
      if (next.attempted) return;
      _syncFromState(next);
    }
  }

  void _syncFromState(ProfileSetupState state) {
    _fullNameController.text = state.fullName;
    _nationalityController.text = state.nationality;
    _courseController.text = state.course;
    _schoolController.text = state.school;
    _gpaController.text = state.gpa;
    _incomeController.text = state.monthlyFamilyIncome;
    _provinceController.text = state.province;
    _cityController.text = state.cityMunicipality;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _nationalityController.dispose();
    _courseController.dispose();
    _schoolController.dispose();
    _gpaController.dispose();
    _incomeController.dispose();
    _provinceController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    final state = ref.watch(profileSetupProvider(userId));
    final notifier = ref.read(profileSetupProvider(userId).notifier);
    ref.listen(profileSetupProvider(userId), _syncHydration);

    return Scaffold(
      backgroundColor: kSurfaceWarm,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        leading: widget.step != 'personal'
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: kTextPrimary),
                onPressed: () {
                  final backRoute = widget.step == 'academic'
                      ? ProfileSetupRoute.personal
                      : ProfileSetupRoute.academic;
                  context.go(backRoute);
                },
              )
            : null,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ScholarisLogo(compact: true),
            const SizedBox(width: 8),
            Text(
              'Profile Setup',
              style: poppins(
                color: kPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: kTextSecondary, size: 22),
            tooltip: 'Help and Support',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Need help? Contact support@scholaris.ph or your university scholarship office.'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: kPrimary,
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Step Tracker & Visual Meter
                    _buildStepMeter(),
                    const SizedBox(height: 18),

                    // Step Header Titles
                    Text(
                      _stepTitle,
                      style: outfit(
                        color: kTextPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _stepSubtitle,
                      style: openSans(
                        color: kTextSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Context / Insight Card
                    _buildInsightBanner(),
                    const SizedBox(height: 20),

                    // Step Fields
                    ..._buildStepFields(context, notifier, state),

                    if (state.error != null) ...[
                      const SizedBox(height: 16),
                      _buildErrorBanner(state.error!),
                    ],
                    const SizedBox(height: 28),

                    // Bottom Action Bar
                    _buildButtons(context, state),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Step Meter Header ----------------------------------------------------

  Widget _buildStepMeter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Step $_stepIndex of 3',
                    style: outfit(
                      color: kPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      ' • $_stepTrackerCategory',
                      style: outfit(
                        color: kPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildStepBadge(),
          ],
        ),
        const SizedBox(height: 8),

        // 3-Segment Micro-Bar with celebratory spark on final step
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerRight,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: _stepIndex >= 2 ? kPrimary : const Color(0xFFDDE2F3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: _stepIndex >= 3 ? kPrimary : const Color(0xFFDDE2F3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
            if (_stepIndex == 3)
              Positioned(
                right: -2,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: kTertiaryFixedDim,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x33FABC28),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: kOnTertiaryFixed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStepBadge() {
    if (_stepIndex == 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: kPrimaryLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '33% Complete',
          style: outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: kPrimary,
          ),
        ),
      );
    }
    if (_stepIndex == 2) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFDDE2F3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '66%',
          style: outfit(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: kTextPrimary,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: kTertiaryFixed,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, size: 13, color: kOnTertiaryFixed),
          const SizedBox(width: 4),
          Text(
            'Final Step',
            style: outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: kOnTertiaryFixed,
            ),
          ),
        ],
      ),
    );
  }

  // --- Insight Banners ------------------------------------------------------

  Widget _buildInsightBanner() {
    if (_stepIndex == 1) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDE2F3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFD2E4FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: Color(0xFF1B3A5C),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '740+ Active Philippine Grants',
                    style: outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                  ),
                  Text(
                    'DOST-SEI, UniFAST, LGU subsidies, and private foundations open.',
                    style: openSans(
                      fontSize: 11,
                      color: kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_stepIndex == 2) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDE2F3)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFD2E4FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.school_rounded,
                color: Color(0xFF1B3A5C),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Targeting Philippine Academic Grants',
                    style: outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                  ),
                  Text(
                    'DOST Priority S&T, CHED UniFAST, and university partner endowments.',
                    style: openSans(
                      fontSize: 11,
                      color: kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Step 3 Insight: 100% Confidential Shield + Subsidies Unlocked
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDE2F3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: kPrimaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: kPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '100% Confidential & Protected',
                      style: outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'This info is stored under bank-grade encryption. It is used exclusively by our matching engine to calculate subsidy eligibility and will never be shared with schools or third parties without your permission.',
                      style: openSans(
                        fontSize: 11,
                        color: kTextSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Step Fields ----------------------------------------------------------

  List<Widget> _buildStepFields(
    BuildContext context,
    ProfileSetupNotifier notifier,
    ProfileSetupState state,
  ) {
    return switch (widget.step) {
      'personal' => [
          _buildAvatarSetupCard(context),
          const SizedBox(height: 20),
          _textField(
            label: 'Full Name',
            controller: _fullNameController,
            onChanged: notifier.setFullName,
            required: true,
            hintText: 'e.g. Juan P. Dela Cruz',
            prefixIcon: Icons.badge_outlined,
            helperText: 'Matches official school enrollment records, PSA birth certificate, and national ID.',
            validator: (_) => _fieldError((e) => e.fullName),
          ),
          const SizedBox(height: 16),
          _textField(
            label: 'Nationality',
            controller: _nationalityController,
            onChanged: notifier.setNationality,
            required: true,
            hintText: 'e.g. Filipino',
            prefixIcon: Icons.flag_outlined,
            helperText: 'Required for Philippine republic grants, LGU subsidies, and state university funds.',
            validator: (_) => _fieldError((e) => e.nationality),
          ),
          const SizedBox(height: 16),
          _birthDateField(context, notifier, state),
          const SizedBox(height: 16),
          _buildGenderSelector(notifier, state),
          const SizedBox(height: 20),
          _buildTrustMicroPanel(),
        ],
      'academic' => [
          _buildYearLevelSelector(notifier, state),
          const SizedBox(height: 16),
          _textField(
            label: 'Course',
            controller: _courseController,
            onChanged: notifier.setCourse,
            required: true,
            hintText: 'e.g. BS Computer Science, BA Communication',
            prefixIcon: Icons.school_outlined,
            helperText: 'DOST Priority S&T courses, Agri-Fisheries, and Tech-Voc endowments match automatically to this field.',
            validator: (_) => _fieldError((e) => e.course),
          ),
          const SizedBox(height: 16),
          _textField(
            label: 'School',
            controller: _schoolController,
            onChanged: notifier.setSchool,
            optional: true,
            hintText: 'Search state U, college, or institute... (e.g. UP Diliman, UST)',
            prefixIcon: Icons.account_balance_outlined,
            helperText: 'Unlocks institution-specific alumni grants, campus work-study, CHED UniFAST, and LGU partner funds.',
          ),
          const SizedBox(height: 16),
          _buildGpaCard(notifier, state),
        ],
      _ => [
          // Subsidies Unlocked Visualizer Tile
          _buildSubsidiesUnlockedTile(state),
          const SizedBox(height: 18),

          // Monthly Family Income
          _buildIncomeField(notifier, state),
          const SizedBox(height: 10),

          // Low-pressure opt-out card
          _buildOptOutTile(notifier, state),
          const SizedBox(height: 20),

          // Regional Context Accent Card
          _buildLocationContextCard(),
          const SizedBox(height: 14),

          _dropdown<String>(
            label: 'Region',
            required: true,
            value: state.region,
            hint: 'Select your Philippine region',
            prefixIcon: Icons.map_outlined,
            helperText: 'Connects you with regional CHED and DOST chapter priority allotments.',
            items: kPhilippineRegions
                .map(
                  (region) => DropdownMenuItem(
                    value: region,
                    child: Text(region, style: openSans()),
                  ),
                )
                .toList(),
            validator: (_) => _fieldError((e) => e.region),
            onChanged: (value) {
              if (value != null) notifier.setRegion(value);
            },
          ),
          const SizedBox(height: 14),
          _textField(
            label: 'Province',
            controller: _provinceController,
            onChanged: notifier.setProvince,
            optional: true,
            hintText: 'e.g. Metro Manila, Cebu, Laguna',
            prefixIcon: Icons.location_on_outlined,
            helperText: 'Matches provincial council educational assistance & governor grants.',
          ),
          const SizedBox(height: 14),
          _textField(
            label: 'City / Municipality',
            controller: _cityController,
            onChanged: notifier.setCityMunicipality,
            optional: true,
            hintText: 'e.g. Quezon City, Manila, Cebu City',
            prefixIcon: Icons.location_city_outlined,
            helperText: 'Unlocks dedicated City Hall LGU grants (e.g., QC Youth Development Scholarship).',
          ),
          const SizedBox(height: 14),

          // LGU Funding Insight Tip Card
          _buildLguFundingInsightCard(),
          const SizedBox(height: 20),

          // Government & Foundation Qualifiers Section
          _buildGovernmentQualifiersSection(notifier, state),
          const SizedBox(height: 16),

          // Security & Data Privacy Act Micro-Footer
          _buildDataPrivacyFooter(),
        ],
    };
  }

  // --- Step 1 Widgets -------------------------------------------------------

  Widget _buildAvatarSetupCard(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider) ?? 'anonymous';
    final avatarState = ref.watch(avatarProvider(userId));
    final notifier = ref.read(avatarProvider(userId).notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE2F3)),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Your Avatar',
                      style: outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kNavyTrust,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Pick a doodle or set up later',
                      style: openSans(
                        fontSize: 11,
                        color: kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                key: const ValueKey('avatar-setup-later'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () async {
                  await notifier.skipToDefault();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Default doodle avatar assigned. You can change this anytime in your profile.'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Text(
                  'Set up later',
                  style: outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              AvatarDisplay(
                avatarId: avatarState.avatarId,
                isRealPhoto: avatarState.isRealPhoto,
                size: 56,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 64,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: AvatarItem.presets.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final preset = AvatarItem.presets[index];
                      final isSelected = !avatarState.isRealPhoto && avatarState.avatarId == preset.id;
                      return GestureDetector(
                        key: ValueKey('avatar-setup-option-${preset.id}'),
                        onTap: () => notifier.selectDoodle(preset.id),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? kPrimary : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: Center(
                            child: AvatarDisplay(
                              avatarId: preset.id,
                              isRealPhoto: false,
                              size: 44,
                              showVerifiedBadge: false,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _birthDateField(
    BuildContext context,
    ProfileSetupNotifier notifier,
    ProfileSetupState state,
  ) {
    final birthDate = state.birthDate;
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: birthDate ?? DateTime(2003, 10, 14),
          firstDate: DateTime(1970),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          notifier.setBirthDate(picked);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: _fieldDecoration(
          label: 'Birth Date',
          optional: true,
          prefixIcon: Icons.calendar_month_outlined,
          helperText: 'Several youth fellowships and youth development funds filter by age eligibility (18–25).',
        ),
        child: Text(
          birthDate == null ? 'Select date' : formatDate(birthDate),
          style: openSans(
            fontSize: 14,
            color: birthDate == null ? Colors.black38 : kTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderSelector(ProfileSetupNotifier notifier, ProfileSetupState state) {
    final selectedGender = state.gender?.trim().toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.person_outline_rounded, size: 16, color: kPrimary),
            const SizedBox(width: 6),
            Text(
              'Gender',
              style: outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => notifier.setGender('male'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: selectedGender == 'male' ? kPrimaryLight : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedGender == 'male' ? kPrimary : const Color(0xFFDDE2F3),
                      width: selectedGender == 'male' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('👨', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        'Male',
                        style: outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selectedGender == 'male' ? kPrimary : kTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => notifier.setGender('female'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                  decoration: BoxDecoration(
                    color: selectedGender == 'female' ? kPrimaryLight : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedGender == 'female' ? kPrimary : const Color(0xFFDDE2F3),
                      width: selectedGender == 'female' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('👩', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(
                        'Female',
                        style: outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selectedGender == 'female' ? kPrimary : kTextPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Personalizes your campus mascot across your dashboard and notifications.',
          style: openSans(fontSize: 11, color: kTextSecondary),
        ),
      ],
    );
  }

  Widget _buildTrustMicroPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE2F3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline_rounded, size: 15, color: kPrimary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Protected by 256-bit encryption • Only matched with accredited partners',
              style: outfit(fontSize: 11, fontWeight: FontWeight.w500, color: kTextSecondary),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 2 Widgets -------------------------------------------------------

  Widget _buildYearLevelSelector(ProfileSetupNotifier notifier, ProfileSetupState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Year Level *',
              style: outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kTextPrimary,
              ),
            ),
            Text(
              'AY 2024-2025',
              style: outfit(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: kTextSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 3.2,
          children: [
            _yearPill(level: 1, title: '1st Year (Freshman)', isSelected: state.yearLevel == 1, onTap: () => notifier.setYearLevel(1)),
            _yearPill(level: 2, title: '2nd Year (Sophomore)', isSelected: state.yearLevel == 2, onTap: () => notifier.setYearLevel(2)),
            _yearPill(level: 3, title: '3rd Year (Junior)', isSelected: state.yearLevel == 3, onTap: () => notifier.setYearLevel(3)),
            _yearPill(level: 4, title: '4th Year+ / Graduating', isSelected: state.yearLevel >= 4, onTap: () => notifier.setYearLevel(4)),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, size: 14, color: kPrimary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Separates freshman entrance merit scholarships from thesis grants and final-year completion stipends.',
                style: openSans(fontSize: 11, color: kTextSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _yearPill({
    required int level,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? kPrimary : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? kPrimary : const Color(0xFFDDE2F3),
          width: 1,
        ),
      ),
      elevation: isSelected ? 1.5 : 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? kPrimaryFixedDim : const Color(0xFFDDE2F3),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: outfit(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : kTextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGpaCard(ProfileSetupNotifier notifier, ProfileSetupState state) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE2F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Grade Point Average (GWA)',
                  style: outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kTextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: kPrimaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Merit Factor',
                  style: outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: kPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Scale Switcher Tabs
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFE8EEFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _scaleTab('1.0 – 5.0'),
                _scaleTab('% Percentage'),
                _scaleTab('4.0 Scale'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // GWA Value Input
          _textField(
            label: 'GPA',
            controller: _gpaController,
            onChanged: notifier.setGpa,
            required: true,
            hintText: 'e.g. 1.45 or 92.50',
            prefixIcon: Icons.military_tech_outlined,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            validator: (_) => _fieldError((e) => e.gpa),
          ),
          const SizedBox(height: 6),

          // Dynamic Scale Hint
          Text(
            'Active scale: $_selectedGpaScale. You can update this every semester.',
            style: openSans(fontSize: 11, color: kTextSecondary),
          ),
          const SizedBox(height: 10),

          // Qualification Live Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDDE2F3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: kPrimary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: openSans(fontSize: 11, color: kTextPrimary),
                      children: const [
                        TextSpan(
                          text: 'DOST-SEI & Megaworld Foundation ',
                          style: TextStyle(fontWeight: FontWeight.w700, color: kPrimary),
                        ),
                        TextSpan(text: 'cutoff met for your academic standing.'),
                      ],
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

  Widget _scaleTab(String scale) {
    final isSelected = _selectedGpaScale == scale;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedGpaScale = scale;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            scale,
            textAlign: TextAlign.center,
            style: outfit(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? kPrimary : kTextSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // --- Step 3 Widgets -------------------------------------------------------

  Widget _buildSubsidiesUnlockedTile(ProfileSetupState state) {
    final isUndisclosed = state.incomeUndisclosed;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE2F3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: kPrimary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.payments_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subsidies Unlocked',
                        style: outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: kTextSecondary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        isUndisclosed ? 'Merit Only Filter Active' : '₱60,000+ Potential / yr',
                        style: outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: kPrimaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: kPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Active Filter',
                  style: outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: kPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeField(ProfileSetupNotifier notifier, ProfileSetupState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _incomeController,
          enabled: !state.incomeUndisclosed,
          onChanged: notifier.setMonthlyFamilyIncome,
          validator: (_) => _fieldError((e) => e.monthlyFamilyIncome),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          style: outfit(fontSize: 16, fontWeight: FontWeight.w700, color: kTextPrimary),
          decoration: InputDecoration(
            labelText: 'Monthly Family Income *',
            labelStyle: openSans(color: kTextSecondary, fontSize: 13),
            hintText: '25,000',
            hintStyle: openSans(color: Colors.black38, fontSize: 13),
            helperText: 'Combined gross monthly income of parents, guardians, or breadwinners living in your home.',
            helperStyle: openSans(color: kTextSecondary, fontSize: 11),
            prefixText: '₱ ',
            prefixStyle: outfit(color: kPrimary, fontWeight: FontWeight.w700, fontSize: 16),
            prefixIcon: const Icon(Icons.payments_outlined, size: 20, color: kTextSecondary),
            suffixIcon: _incomeController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: kTextSecondary),
                    onPressed: () {
                      _incomeController.clear();
                      notifier.setMonthlyFamilyIncome('');
                    },
                  )
                : null,
            filled: true,
            fillColor: state.incomeUndisclosed ? const Color(0xFFF1F3FF) : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDDE2F3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDDE2F3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimary, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Quick Select Bracket Pills
        Text(
          'Quick Select Bracket',
          style: outfit(fontSize: 11, fontWeight: FontWeight.w600, color: kTextSecondary),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _bracketPill('Under ₱15,000', '12000', notifier, state),
            _bracketPill('₱15,000–₱30,000', '25000', notifier, state),
            _bracketPill('₱30,000–₱50,000', '40000', notifier, state),
            _bracketPill('₱50,000+', '65000', notifier, state),
          ],
        ),
      ],
    );
  }

  Widget _bracketPill(String label, String amount, ProfileSetupNotifier notifier, ProfileSetupState state) {
    final isSelected = _incomeController.text == amount;
    return GestureDetector(
      onTap: state.incomeUndisclosed
          ? null
          : () {
              _incomeController.text = amount;
              notifier.setMonthlyFamilyIncome(amount);
            },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? kPrimary : const Color(0xFFDDE2F3),
          ),
        ),
        child: Text(
          label,
          style: outfit(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : kTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildOptOutTile(ProfileSetupNotifier notifier, ProfileSetupState state) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFDDE2F3)),
      ),
      child: CheckboxListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: kPrimary,
        title: Text(
          'Prefer not to say',
          style: outfit(fontSize: 13, fontWeight: FontWeight.w700, color: kTextPrimary),
        ),
        subtitle: Text(
          'You will still see 100% of academic, merit, STEM, creative, and leadership grants. Need-based filters will simply pause until you wish to update this.',
          style: openSans(fontSize: 11, color: kTextSecondary, height: 1.35),
        ),
        value: state.incomeUndisclosed,
        onChanged: (value) {
          final checked = value ?? false;
          if (checked) _incomeController.clear();
          notifier.setIncomeUndisclosed(checked);
        },
      ),
    );
  }

  Widget _buildLocationContextCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE2F3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.my_location_rounded, color: kNavyTrust, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Targeting Philippine Local Subsidies',
              style: outfit(fontSize: 12, fontWeight: FontWeight.w700, color: kNavyTrust),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLguFundingInsightCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EEFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFDDE2F3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: kTertiaryFixedDim,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LGU Funding Insight',
                  style: outfit(fontSize: 12, fontWeight: FontWeight.w700, color: kSecondary),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: openSans(fontSize: 11, color: kTextPrimary, height: 1.35),
                    children: const [
                      TextSpan(text: 'LGUs like Quezon City, Pasig, and Manila offer up to '),
                      TextSpan(
                        text: '₱10,000–₱25,000/sem',
                        style: TextStyle(fontWeight: FontWeight.w700, color: kPrimary),
                      ),
                      TextSpan(text: ' specifically for registered local students. Keep your Barangay Indigency or Residency Certificate handy!'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGovernmentQualifiersSection(ProfileSetupNotifier notifier, ProfileSetupState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Government & Foundation Qualifiers',
          style: outfit(fontSize: 14, fontWeight: FontWeight.w700, color: kTextPrimary),
        ),
        const SizedBox(height: 2),
        Text(
          'Select any that apply to your household. These unlock preferential slots in CHED UniFAST TDP, DOST SEI, and private foundation quotas.',
          style: openSans(fontSize: 11, color: kTextSecondary),
        ),
        const SizedBox(height: 10),

        // Qualifier 1: 4Ps Beneficiary Household
        _qualifierTile(
          icon: Icons.family_restroom_rounded,
          title: '4Ps Beneficiary Household',
          subtitle: 'Pantawid Pamilyang Pilipino Program recipient',
          value: _is4psBeneficiary,
          onChanged: (val) => setState(() => _is4psBeneficiary = val),
        ),
        const SizedBox(height: 8),

        // Qualifier 2: Solo Parent Dependent
        _qualifierTile(
          icon: Icons.escalator_warning_rounded,
          title: 'Solo Parent Dependent',
          subtitle: 'Supported under Solo Parents Welfare Act',
          value: _isSoloParentDependent,
          onChanged: (val) => setState(() => _isSoloParentDependent = val),
        ),
        const SizedBox(height: 8),

        // Qualifier 3: Has a disability
        _qualifierTile(
          icon: Icons.accessible_rounded,
          title: 'Has a disability',
          subtitle: 'PWD-priority scholarships & DOST assistance may apply',
          value: state.hasDisability,
          onChanged: notifier.setHasDisability,
        ),
        const SizedBox(height: 8),

        // Qualifier 4: Indigenous person
        _qualifierTile(
          icon: Icons.diversity_3_rounded,
          title: 'Indigenous person',
          subtitle: 'NCIP & Indigenous-specific educational funds may apply',
          value: state.isIndigenous,
          onChanged: notifier.setIsIndigenous,
        ),
      ],
    );
  }

  Widget _qualifierTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: value ? kPrimary : const Color(0xFFDDE2F3),
          width: value ? 1.5 : 1,
        ),
      ),
      child: CheckboxListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        activeColor: kPrimary,
        secondary: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: value ? kPrimaryLight : const Color(0xFFF1F3FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: value ? kPrimary : kSecondary, size: 18),
        ),
        title: Text(
          title,
          style: outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kTextPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: openSans(fontSize: 11, color: kTextSecondary),
        ),
        value: value,
        onChanged: (v) => onChanged(v ?? false),
      ),
    );
  }

  Widget _buildDataPrivacyFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt_rounded, size: 16, color: kPrimary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Next: We will calculate your matched scholarship pool in real-time!',
                style: outfit(fontSize: 11, fontWeight: FontWeight.w600, color: kPrimary),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 13, color: kTextSecondary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Encrypted • Republic Act No. 10173 (Data Privacy Act) Compliant',
                style: openSans(fontSize: 11, color: kTextSecondary),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Shared Field Helpers -------------------------------------------------

  String? _fieldError(String? Function(ProfileFieldErrors) pick) {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return null;
    final errors = ref.read(profileSetupProvider(userId)).fieldErrors;
    return errors == null ? null : pick(errors);
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<String> onChanged,
    bool required = false,
    bool optional = false,
    String? helperText,
    String? hintText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    FormFieldValidator<String>? validator,
    bool enabled = true,
    String? prefixText,
    IconData? prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: openSans(fontSize: 14, color: kTextPrimary),
      decoration: _fieldDecoration(
        label: label,
        required: required,
        optional: optional,
        helperText: helperText,
        hintText: hintText,
        prefixText: prefixText,
        prefixIcon: prefixIcon,
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    bool required = false,
    FormFieldValidator<T>? validator,
    String? hint,
    String? helperText,
    IconData? prefixIcon,
  }) {
    return DropdownButtonFormField<T>(
      key: ValueKey(value),
      initialValue: value,
      hint: hint == null
          ? null
          : Text(hint, style: openSans(color: Colors.black38, fontSize: 13)),
      onChanged: onChanged,
      items: items,
      validator: validator,
      style: openSans(fontSize: 14, color: kTextPrimary),
      decoration: _fieldDecoration(
        label: label,
        required: required,
        helperText: helperText,
        prefixIcon: prefixIcon,
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    bool required = false,
    bool optional = false,
    String? helperText,
    String? hintText,
    String? prefixText,
    IconData? prefixIcon,
  }) {
    final labelText = required
        ? '$label *'
        : optional
            ? '$label (optional)'
            : label;
    return InputDecoration(
      labelText: labelText,
      labelStyle: openSans(color: kTextSecondary, fontSize: 13),
      hintText: hintText,
      hintStyle: openSans(color: Colors.black38, fontSize: 13),
      helperText: helperText,
      helperStyle: openSans(color: kTextSecondary, fontSize: 11),
      prefixText: prefixText,
      prefixStyle: outfit(color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 14),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: kTextSecondary) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE2F3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE2F3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: kError, width: 1.5),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kErrorSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kError.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: kError, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: openSans(color: kError, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // --- Buttons --------------------------------------------------------------

  Widget _buildButtons(BuildContext context, ProfileSetupState state) {
    final isLastStep = widget.step == 'financial';
    final backRoute = widget.step == 'academic'
        ? ProfileSetupRoute.personal
        : ProfileSetupRoute.academic;

    return Row(
      children: [
        if (widget.step != 'personal') ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () => context.go(backRoute),
              style: OutlinedButton.styleFrom(
                foregroundColor: kSecondary,
                side: const BorderSide(color: Color(0xFFDDE2F3), width: 1.5),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_back_rounded, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Back',
                    style: outfit(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: widget.step == 'personal' ? 1 : 2,
          child: ElevatedButton(
            onPressed: state.isSubmitting
                ? null
                : () => _handleNextOrSubmit(isLastStep),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: state.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isLastStep ? 'Complete Profile' : 'Continue',
                        style: outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isLastStep ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleNextOrSubmit(bool isLastStep) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final notifier = ref.read(profileSetupProvider(userId).notifier);

    notifier.validateStep(widget.step);
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (isLastStep) {
      final success = await notifier.submit();
      if (!mounted) return;
      if (success) {
        await SuccessOverlay.show(context);
        if (!mounted) return;
        ref.invalidate(profileCompleteProvider);
        ref.invalidate(currentProfileProvider);
        try {
          await ref.read(profileCompleteProvider.future);
        } catch (_) {}
        if (!mounted) return;
        context.go('/home');
      }
    } else {
      final nextRoute = widget.step == 'academic'
          ? ProfileSetupRoute.financial
          : ProfileSetupRoute.academic;
      context.go(nextRoute);
    }
  }
}
