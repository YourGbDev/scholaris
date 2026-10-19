// lib/features/schools/providers/school_provider.dart
//
// Riverpod providers for the School catalog domain.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/school_repository.dart';
import '../models/school.dart';

final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  return SchoolRepository();
});

final schoolsProvider = FutureProvider<List<School>>((ref) async {
  return ref.watch(schoolRepositoryProvider).fetchSchools();
});

final schoolSearchQueryProvider = StateProvider<String>((ref) => '');

final filteredSchoolsProvider = Provider<AsyncValue<List<School>>>((ref) {
  final query = ref.watch(schoolSearchQueryProvider);
  final schoolsAsync = ref.watch(schoolsProvider);
  return schoolsAsync.whenData((schools) {
    if (query.trim().isEmpty) return schools;
    final q = query.trim().toLowerCase();
    return schools.where((s) {
      if (s.name.toLowerCase().contains(q)) return true;
      if (s.normalizedName.contains(q)) return true;
      return s.aliases.any((a) => a.toLowerCase().contains(q));
    }).toList();
  });
});
