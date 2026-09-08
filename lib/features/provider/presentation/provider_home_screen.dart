// lib/features/provider/presentation/provider_home_screen.dart
//
// Persistent landing surface for signed-in users whose profiles.role is
// 'provider'. The router sends role='provider' here instead of /home
// (see authRedirectDecision).
//
// PLACEHOLDER: renders the same "Application Under Review" copy as
// /provider-review for now. Step 3 replaces this content with the real
// provider console; the route itself stays.
//
// Deliberately has no "Back to login" action: unlike /provider-review (the
// end of the signup flow), this is a signed-in landing — bouncing to /login
// would just be redirected straight back here by the auth gate.

import 'package:flutter/material.dart';

import 'package:scholaris/shared/theme/app_theme.dart';

class ProviderHomeScreen extends StatelessWidget {
  const ProviderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 80),
                  Icon(
                    Icons.hourglass_empty_rounded,
                    size: 80,
                    color: kPrimary,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Application Under Review',
                    textAlign: TextAlign.center,
                    style: poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: kPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Thanks for your interest in becoming a scholarship '
                    'provider. Our team will review your application and '
                    'get back to you within 3–5 business days.',
                    textAlign: TextAlign.center,
                    style: openSans(
                      fontSize: 15,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
