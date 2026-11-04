// Local presentation fixture only. No Supabase initialization or real auth session.
// ?screen=onboarding&step=0&scale=1&keyboard=0
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scholaris/features/auth/presentation/login_screen.dart';
import 'package:scholaris/features/auth/presentation/signup_screen.dart';
import 'package:scholaris/features/auth/presentation/forgot_password_screen.dart';
import 'package:scholaris/features/intro/presentation/intro_screen.dart';
import 'package:scholaris/features/onboarding/presentation/onboarding_screen.dart';
import 'package:scholaris/shared/theme/app_theme.dart';
import 'package:scholaris/features/provider/presentation/provider_login_screen.dart';
import 'package:scholaris/features/provider/presentation/provider_signup_screen.dart';

void main() {
  final params = Uri.base.queryParameters;
  final screen = params['screen'] ?? 'onboarding';
  final router = GoRouter(
    initialLocation: screen == 'onboarding'
        ? '/onboarding?step=${params['step'] ?? '0'}'
        : '/$screen',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, state) => OnboardingScreen(
          initialPage:
              int.tryParse(state.uri.queryParameters['step'] ?? '') ?? 0,
        ),
      ),
      GoRoute(path: '/intro', builder: (_, _) => const IntroScreen()),
      GoRoute(
        path: '/login',
        builder: (_, _) => const LoginScreen(showProviderCta: true),
      ),
      GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
      GoRoute(path: '/provider-login', builder: (_, _) => const ProviderLoginScreen()),
      GoRoute(path: '/provider-signup', builder: (_, _) => const ProviderSignupScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordScreen(),
      ),
    ],
  );
  runApp(
    ProviderScope(
      child: MaterialApp.router(
        title: 'Scholaris entry presentation preview',
        debugShowCheckedModeBanner: false,
        theme: scholarisTheme(),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              double.tryParse(params['scale'] ?? '') ?? 1,
            ),
            disableAnimations: params['motion'] != 'on',
            viewInsets: EdgeInsets.only(
              bottom: double.tryParse(params['keyboard'] ?? '') ?? 0,
            ),
          ),
          child: child!,
        ),
      ),
    ),
  );
}
