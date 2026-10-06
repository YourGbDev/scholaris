// lib/features/applications/providers/application_draft_provider.dart
//
// In-memory draft persistence provider keyed by scholarshipId.
// Prevents essay drafts and added recommender lists from being wiped out
// when students open QR dialogs, switch tabs, or background the app.

import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApplicationDraftState {
  const ApplicationDraftState({
    this.essay = '',
    this.recommenders = const <String>[],
  });

  final String essay;
  final List<String> recommenders;

  ApplicationDraftState copyWith({
    String? essay,
    List<String>? recommenders,
  }) {
    return ApplicationDraftState(
      essay: essay ?? this.essay,
      recommenders: recommenders ?? this.recommenders,
    );
  }
}

class ApplicationDraftNotifier
    extends FamilyNotifier<ApplicationDraftState, String> {
  @override
  ApplicationDraftState build(String arg) {
    return const ApplicationDraftState();
  }

  void setEssay(String essay) {
    state = state.copyWith(essay: essay);
  }

  void addRecommender(String recommender) {
    if (!state.recommenders.contains(recommender)) {
      state = state.copyWith(
        recommenders: [...state.recommenders, recommender],
      );
    }
  }

  void removeRecommender(String recommender) {
    state = state.copyWith(
      recommenders: state.recommenders.where((r) => r != recommender).toList(),
    );
  }

  void clear() {
    state = const ApplicationDraftState();
  }
}

final applicationDraftProvider = NotifierProvider.family<
    ApplicationDraftNotifier, ApplicationDraftState, String>(
  ApplicationDraftNotifier.new,
);
