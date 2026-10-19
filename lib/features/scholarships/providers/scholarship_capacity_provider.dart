// lib/features/scholarships/providers/scholarship_capacity_provider.dart
//
// Riverpod providers for scholarship capacity accounting.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/scholarship_capacity_repository.dart';
import '../models/scholarship_capacity.dart';

final scholarshipCapacityRepositoryProvider =
    Provider<ScholarshipCapacityRepository>((ref) {
  return ScholarshipCapacityRepository();
});

final scholarshipCapacityProvider =
    FutureProvider.family<ScholarshipCapacity?, String>(
        (ref, scholarshipId) async {
  return ref
      .watch(scholarshipCapacityRepositoryProvider)
      .fetchCapacity(scholarshipId);
});

final allScholarshipCapacitiesProvider =
    FutureProvider<Map<String, ScholarshipCapacity>>((ref) async {
  return ref.watch(scholarshipCapacityRepositoryProvider).fetchAllCapacities();
});
