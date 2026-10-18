// lib/features/provider/providers/provider_sub_role_provider.dart
//
// Role-Based Access Control (RBAC) Sub-Role Provider for DOST Organization:
// - Evaluator: Dr. Renato U. Solidum Jr. (Academic Evaluator) -> Port 5001 / provider.dost@scholaris.gov.ph
// - Finance: Engr. Maria Santos, CPA (Disbursing Officer) -> Port 5002 / finance.dost@scholaris.gov.ph

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/providers/profile_setup_provider.dart';

enum ProviderSubRole {
  evaluator,
  finance,
}

class ProviderIdentityInfo {
  final ProviderSubRole role;
  final String name;
  final String initials;
  final String roleSubtitle;
  final String topEyebrow;

  const ProviderIdentityInfo({
    required this.role,
    required this.name,
    required this.initials,
    required this.roleSubtitle,
    required this.topEyebrow,
  });

  bool get isFinance => role == ProviderSubRole.finance;
  bool get isEvaluator => role == ProviderSubRole.evaluator;
}

final providerSubRoleProvider = Provider<ProviderIdentityInfo>((ref) {
  final profile = ref.watch(currentProfileProvider).valueOrNull;
  final currentUser = Supabase.instance.client.auth.currentUser;
  final email = currentUser?.email?.toLowerCase().trim() ?? '';
  final fullName = profile?.fullName.trim() ?? '';

  bool isFinance = false;

  // 1. Port-based isolation for local testing / demo rehearsal
  if (kIsWeb) {
    final port = Uri.base.port;
    if (port == 5002) {
      isFinance = true;
    } else if (port == 5001) {
      isFinance = false;
    }
  }

  // 2. Email-based binding (authoritative)
  if (email == 'finance.dost@scholaris.gov.ph' || email.startsWith('finance.')) {
    isFinance = true;
  } else if (email == 'provider.dost@scholaris.gov.ph' || email.startsWith('provider.')) {
    isFinance = false;
  }

  // 3. Name fallback
  if (!isFinance &&
      (fullName.contains('Maria Santos') ||
          fullName.contains('Disbursing') ||
          fullName.contains('Comptroller') ||
          fullName.contains('Finance'))) {
    isFinance = true;
  }

  if (isFinance) {
    return const ProviderIdentityInfo(
      role: ProviderSubRole.finance,
      name: 'Engr. Maria Santos, CPA',
      initials: 'MS',
      roleSubtitle: 'Disbursing Officer',
      topEyebrow: 'ENGR. MARIA SANTOS, CPA • TREASURY & DISBURSEMENTS',
    );
  }

  return const ProviderIdentityInfo(
    role: ProviderSubRole.evaluator,
    name: 'Dr. Renato U. Solidum Jr.',
    initials: 'RS',
    roleSubtitle: 'Academic Evaluator',
    topEyebrow: 'DR. RENATO U. SOLIDUM JR. • ACADEMIC EVALUATION DESK',
  );
});
