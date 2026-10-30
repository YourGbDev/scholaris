import 'inactivity_storage_native.dart'
    if (dart.library.js_interop) 'inactivity_storage_web.dart'
    as platform;

class InactivityStorage {
  Future<int?> read(String key) => platform.readDeadline(key);
  Future<void> write(String key, int value) =>
      platform.writeDeadline(key, value);
  Future<void> remove(String key) => platform.removeDeadline(key);
}
