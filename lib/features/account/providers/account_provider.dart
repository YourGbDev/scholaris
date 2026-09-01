// lib/features/account/providers/account_provider.dart
//
// Riverpod wiring for the account settings surface. Only the repository is
// provided here: the account screen keeps form input (including passwords)
// strictly local to its State, matching the other auth surfaces (login, reset
// password), so no password ever enters provider state.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(),
);
