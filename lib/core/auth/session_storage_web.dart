import 'package:web/web.dart';

final _sessionStorage = window.sessionStorage;

bool hasAccessToken(String persistSessionKey) =>
    _sessionStorage.getItem(persistSessionKey) != null;

String? accessToken(String persistSessionKey) =>
    _sessionStorage.getItem(persistSessionKey);

void removePersistedSession(String persistSessionKey) =>
    _sessionStorage.removeItem(persistSessionKey);

void persistSession(String persistSessionKey, String persistSessionString) =>
    _sessionStorage.setItem(persistSessionKey, persistSessionString);
