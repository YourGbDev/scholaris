import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';

final adminApplicantsProvider = FutureProvider<List<StudentProfile>>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  final all = await repository.fetchAllProfiles();
  return all.where((p) => p.role == 'student').toList();
});

final adminApplicantSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

final adminApplicantRegionFilterProvider =
    StateProvider.autoDispose<String>((ref) => 'all');
