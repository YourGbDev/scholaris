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
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scholaris/shared/theme/app_theme.dart';

import 'provider_incoming_applications.dart';

class ProviderHomeScreen extends StatelessWidget {
  const ProviderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: Text(
          'Provider Console',
          style: poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: kPrimary,
          ),
        ),
        centerTitle: false,
        backgroundColor: kBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: kError),
            tooltip: 'Sign out',
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ProviderIncomingApplications(),
      ),
    );
  }
}
