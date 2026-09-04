// lib/features/provider/presentation/provider_review_screen.dart
//
// Static confirmation page shown after a provider account is created.
// Tells the user their application is under review and provides a back-to-login
// action. No approval workflow yet — this is the end of the provider signup
// flow for now.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:scholaris/shared/theme/app_theme.dart';

class ProviderReviewScreen extends StatelessWidget {
  const ProviderReviewScreen({super.key});

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
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Back to login',
                      style: poppins(fontWeight: FontWeight.w600),
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
