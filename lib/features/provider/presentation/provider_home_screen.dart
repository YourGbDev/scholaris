// lib/features/provider/presentation/provider_home_screen.dart
//
// Persistent landing surface for signed-in users whose profiles.role is
// 'provider'. The router sends role='provider' here instead of /home
// (see authRedirectDecision).
//
// The placeholder "Application Under Review" copy (shown during signup review)
// has been replaced by the real provider console content:
// [ProviderIncomingApplications] — a read-only list of applications submitted
// to scholarships the provider owns, with applicant name, scholarship title,
// applied date and status resolved client-side.

import 'package:flutter/material.dart';

import 'package:scholaris/shared/theme/app_theme.dart';

import 'provider_incoming_applications.dart';

class ProviderHomeScreen extends StatelessWidget {
  const ProviderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: ProviderIncomingApplications(),
      ),
    );
  }
}
