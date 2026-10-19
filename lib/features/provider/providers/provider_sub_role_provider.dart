// lib/features/provider/providers/provider_sub_role_provider.dart
//
// Organization membership is provisioned by a trusted database operator.
// UI state fails closed while loading; database authorization remains decisive.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../profile/providers/profile_setup_provider.dart';

enum ProviderSubRole {
  unavailable,
  orgAdmin,
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
  bool get isOrgAdmin => role == ProviderSubRole.orgAdmin;
}

final organizationMembershipProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return Supabase.instance.client.from('organization_memberships')
      .select('user_id, organization_id, role')
      .eq('user_id', userId).eq('active', true).maybeSingle();
});

final currentOrganizationIdProvider = Provider<String?>((ref) {
  final membership = ref.watch(organizationMembershipProvider).valueOrNull;
  return membership?['organization_id'] as String?;
});

final providerSubRoleProvider = Provider<ProviderIdentityInfo>((ref) {
  final profile = ref.watch(currentProfileProvider).valueOrNull;
  final membership = ref.watch(organizationMembershipProvider).valueOrNull;
  final role = switch (membership?['role']) {
    'org_admin' => ProviderSubRole.orgAdmin,
    'reviewer' => ProviderSubRole.evaluator,
    'finance' => ProviderSubRole.finance,
    _ => ProviderSubRole.unavailable,
  };
  final name = profile?.fullName.trim() ?? '';
  final subtitle = switch (role) {
    ProviderSubRole.orgAdmin => 'Organization Admin',
    ProviderSubRole.evaluator => 'Reviewer',
    ProviderSubRole.finance => 'Finance',
    ProviderSubRole.unavailable => 'Membership unavailable',
  };
  return ProviderIdentityInfo(
    role: role,
    name: name.isEmpty ? 'Organization member' : name,
    initials: name.isEmpty ? '?' : name.split(RegExp(r'\s+')).take(2).map((s) => s[0]).join(),
    roleSubtitle: subtitle,
    topEyebrow: subtitle.toUpperCase(),
  );
});
