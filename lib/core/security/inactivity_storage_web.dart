import 'package:web/web.dart';

Future<int?> readDeadline(String key) async =>
    int.tryParse(window.sessionStorage.getItem(key) ?? '');
Future<void> writeDeadline(String key, int value) async =>
    window.sessionStorage.setItem(key, value.toString());
Future<void> removeDeadline(String key) async =>
    window.sessionStorage.removeItem(key);
