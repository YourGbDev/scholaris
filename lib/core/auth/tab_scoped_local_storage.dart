import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'session_storage_stub.dart'
    if (dart.library.js_interop) 'session_storage_web.dart' as web;

/// A [LocalStorage] implementation for Flutter Web that scopes the Supabase auth
/// session to the active browser tab via `window.sessionStorage`.
///
/// Standard web `window.localStorage` shares auth tokens across all tabs of the
/// same origin, causing conflicting sessions when demonstrating provider,
/// student, and admin flows in parallel browser tabs.
///
/// With `window.sessionStorage`, each tab maintains its own isolated session
/// sandbox. Mobile and desktop builds retain standard persistence.
class TabScopedLocalStorage extends LocalStorage {
  final String persistSessionKey;

  const TabScopedLocalStorage({required this.persistSessionKey});

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    if (kIsWeb) {
      return web.hasAccessToken(persistSessionKey);
    }
    return false;
  }

  @override
  Future<String?> accessToken() async {
    if (kIsWeb) {
      return web.accessToken(persistSessionKey);
    }
    return null;
  }

  @override
  Future<void> removePersistedSession() async {
    if (kIsWeb) {
      web.removePersistedSession(persistSessionKey);
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    if (kIsWeb) {
      web.persistSession(persistSessionKey, persistSessionString);
    }
  }
}
