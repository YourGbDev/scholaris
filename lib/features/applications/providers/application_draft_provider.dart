// lib/features/applications/providers/application_draft_provider.dart
//
// In-memory draft persistence provider keyed by userId + scholarshipId.
// Prevents essay drafts and added recommender lists from being wiped out
// when students open QR dialogs, switch tabs, or background the app.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_controller.dart';

typedef ApplicationDraftKey = ({String? userId, String scholarshipId});

class ApplicationDraftState {
  const ApplicationDraftState({
    this.essay = '',
    this.recommenders = const <String>[],
  });

  final String essay;
  final List<String> recommenders;

  ApplicationDraftState copyWith({String? essay, List<String>? recommenders}) {
    return ApplicationDraftState(
      essay: essay ?? this.essay,
      recommenders: recommenders ?? this.recommenders,
    );
  }
}

class ApplicationDraftNotifier
    extends FamilyNotifier<ApplicationDraftState, ApplicationDraftKey> {
  @override
  ApplicationDraftState build(ApplicationDraftKey arg) {
    _owner = arg;
    ref.watch(currentUserIdProvider);
    return const ApplicationDraftState();
  }

  late ApplicationDraftKey _owner;
  bool get _current => ref.read(currentUserIdProvider) == _owner.userId;

  void setEssay(String essay) {
    if (!_current) return;
    state = state.copyWith(essay: essay);
  }

  void addRecommender(String recommender) {
    if (!_current) return;
    if (!state.recommenders.contains(recommender)) {
      state = state.copyWith(
        recommenders: [...state.recommenders, recommender],
      );
    }
  }

  void removeRecommender(String recommender) {
    if (!_current) return;
    state = state.copyWith(
      recommenders: state.recommenders.where((r) => r != recommender).toList(),
    );
  }

  void clear() {
    state = const ApplicationDraftState();
  }
}

final applicationDraftProvider =
    NotifierProvider.family<
      ApplicationDraftNotifier,
      ApplicationDraftState,
      ApplicationDraftKey
    >(ApplicationDraftNotifier.new);
