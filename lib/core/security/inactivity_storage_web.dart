import 'package:web/web.dart';
import 'inactivity_storage.dart';

Future<int?> readDeadline(String key) async {
  final raw = window.sessionStorage.getItem(key);
  return parseInactivityDeadline(raw);
}

Future<void> writeDeadline(String key, int value) async =>
    window.sessionStorage.setItem(key, value.toString());

Future<void> removeDeadline(String key) async =>
    window.sessionStorage.removeItem(key);
