import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/app/router.dart';
import 'package:scholaris/features/profile/models/student_profile.dart';
import 'package:scholaris/features/profile/providers/profile_setup_provider.dart';
import 'package:scholaris/features/profile/repositories/profile_repository.dart';

import 'helpers/fake_profile_data_source.dart';

class _FailingCheckpointSource extends FakeProfileDataSource {
  @override
  Future<void> upsertProfile(String userId, Map<String, dynamic> row) async {
    throw StateError('offline');
  }
}

void main() {
  test(
    '90 percent and its scale persist and hydrate without conversion',
    () async {
      final source = FakeProfileDataSource();
      final repo = ProfileRepository(
        dataSource: source,
        currentUserId: () => 'student-a',
      );
      final n = ProfileSetupNotifier(repo);
      await n.hydrationComplete;
      n.setFullName('Test student');
      n.setNationality('Filipino');
      n.setCourse('BSIT');
      n.setGpaScale('% Percentage');
      n.setGpa('90.0');
      n.setRegion('Region VIII');
      n.setIncomeUndisclosed(true);
      expect(await n.submit(), isTrue);
      expect(source.rows['student-a']!['gpa'], 90.0);
      expect(source.rows['student-a']!['gpa_scale'], 'percentage');
      final restored = ProfileSetupNotifier(repo);
      await restored.hydrationComplete;
      expect(restored.state.gpa, '90.00');
      expect(restored.state.gpaScale, '% Percentage');
      n.dispose();
      restored.dispose();
    },
  );

  test('saved personal step survives restart and remains incomplete', () async {
    final source = FakeProfileDataSource();
    final repo = ProfileRepository(
      dataSource: source,
      currentUserId: () => 'student-a',
    );
    final n = ProfileSetupNotifier(repo);
    await n.hydrationComplete;
    n.setFullName('Test student');
    expect(await n.saveCheckpoint('personal'), isTrue);
    expect(source.rows['student-a']!['setup_complete'], isFalse);
    expect(source.rows['student-a']!['profile_setup_step'], 2);
    final restored = ProfileSetupNotifier(repo);
    await restored.hydrationComplete;
    expect(restored.state.fullName, 'Test student');
    expect((await repo.fetchCurrent())!.profileSetupStep, 2);
    n.dispose();
    restored.dispose();
  });

  test('resume routing uses the saved step without bypassing setup', () {
    expect(
      authRedirectDecision(
        location: '/login',
        isLoggedIn: true,
        recoveryActive: false,
        onAuthRoute: true,
        onSetupRoute: false,
        profileLoading: false,
        profileComplete: false,
        profileSetupStep: 3,
      ),
      ProfileSetupRoute.financial,
    );
  });

  test(
    'legacy profile keeps unknown grading scale rather than inventing one',
    () {
      final profile = StudentProfile.fromJson({'id': 'legacy', 'gpa': 2.0});
      expect(profile.gpaScale, isNull);
    },
  );

  test(
    'failed checkpoint retains input and never marks setup complete',
    () async {
      final source = _FailingCheckpointSource();
      final n = ProfileSetupNotifier(
        ProfileRepository(dataSource: source, currentUserId: () => 'student-a'),
      );
      await n.hydrationComplete;
      n.setFullName('Test student');
      expect(await n.saveCheckpoint('personal'), isFalse);
      expect(n.state.fullName, 'Test student');
      expect(n.state.isSubmitting, isFalse);
      expect(n.state.error, contains('Your entries are still here'));
      expect(source.rows, isEmpty);
      n.dispose();
    },
  );

  test('saved checkpoint is scoped to the authenticated student', () async {
    final source = FakeProfileDataSource();
    final a = ProfileSetupNotifier(
      ProfileRepository(dataSource: source, currentUserId: () => 'student-a'),
    );
    await a.hydrationComplete;
    a.setFullName('Student A');
    expect(await a.saveCheckpoint('personal'), isTrue);
    final b = ProfileSetupNotifier(
      ProfileRepository(dataSource: source, currentUserId: () => 'student-b'),
    );
    await b.hydrationComplete;
    expect(b.state.fullName, isEmpty);
    expect(source.rows.containsKey('student-b'), isFalse);
    a.dispose();
    b.dispose();
  });
}
