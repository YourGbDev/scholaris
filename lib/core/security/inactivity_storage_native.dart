import 'package:shared_preferences/shared_preferences.dart';

Future<int?> readDeadline(String key) async =>
    (await SharedPreferences.getInstance()).getInt(key);
Future<void> writeDeadline(String key, int value) async {
  if (!await (await SharedPreferences.getInstance()).setInt(key, value)) {
    throw StateError('Could not save inactivity deadline');
  }
}

Future<void> removeDeadline(String key) async {
  if (!await (await SharedPreferences.getInstance()).remove(key)) {
    throw StateError('Could not remove inactivity deadline');
  }
}
