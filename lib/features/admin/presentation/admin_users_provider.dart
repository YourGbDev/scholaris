import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';

final adminUsersProvider = FutureProvider<List<StudentProfile>>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.fetchAllProfiles();
});

final adminUserSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

final adminUserRoleFilterProvider =
    StateProvider.autoDispose<String>((ref) => 'all'); // 'all', 'student', 'provider', 'admin'
