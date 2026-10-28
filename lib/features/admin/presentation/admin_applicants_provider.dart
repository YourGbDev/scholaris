import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';

final FutureProvider<List<StudentProfile>> adminApplicantsProvider =
    FutureProvider<List<StudentProfile>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];

  final repository = ref.watch(profileRepositoryProvider);
  final all = await repository.fetchAllProfiles();

  // Guard against in-flight stale completion (e.g. sign-out or account switch while fetching)
  if (ref.read(currentUserIdProvider) != userId) {
    return const [];
  }

  return all.where((p) => p.role == 'student').toList();
});

final adminApplicantSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

final adminApplicantRegionFilterProvider =
    StateProvider.autoDispose<String>((ref) => 'all');
