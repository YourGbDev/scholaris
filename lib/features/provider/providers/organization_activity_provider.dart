// lib/features/provider/providers/organization_activity_provider.dart
//
// Riverpod providers for organization activity logs.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/organization_activity_repository.dart';
import '../models/organization_activity_log.dart';
import 'provider_sub_role_provider.dart';

final organizationActivityRepositoryProvider =
    Provider<OrganizationActivityRepository>((ref) {
  return OrganizationActivityRepository();
});

final organizationActivityActionFilterProvider =
    StateProvider<String?>((ref) => null);

final organizationActivityLogsProvider =
    FutureProvider<List<OrganizationActivityLog>>((ref) async {
  final orgId = ref.watch(currentOrganizationIdProvider);
  if (orgId == null) return const [];
  final filter = ref.watch(organizationActivityActionFilterProvider);
  return ref.watch(organizationActivityRepositoryProvider).fetchActivityLogs(
        orgId,
        actionFilter: filter,
      );
});
