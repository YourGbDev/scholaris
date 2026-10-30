import 'inactivity_storage_native.dart'
    if (dart.library.js_interop) 'inactivity_storage_web.dart'
    as platform;

/// Parses a stored inactivity deadline string (e.g. from web sessionStorage).
///
/// Returns `null` if [raw] is `null` (key is absent from storage, indicating
/// a brand-new authenticated session).
/// Throws [FormatException] if [raw] is present but cannot be parsed as a valid integer
/// (e.g. empty string, non-numeric string, 'NaN').
int? parseInactivityDeadline(String? raw) {
  if (raw == null) return null;
  final value = int.tryParse(raw);
  if (value == null) {
    throw FormatException('Malformed inactivity deadline in storage: "$raw"');
  }
  return value;
}

/// Abstract storage contract for inactivity deadlines.
///
/// Implementations must:
/// - Return `null` if and only if the key is absent.
/// - Throw [FormatException] or error if the key is present but malformed/corrupted.
class InactivityStorage {
  Future<int?> read(String key) => platform.readDeadline(key);
  Future<void> write(String key, int value) =>
      platform.writeDeadline(key, value);
  Future<void> remove(String key) => platform.removeDeadline(key);
}

/// Storage implementation for web sessionStorage with injectable getter/setter for testing.
class InactivityWebStorage implements InactivityStorage {
  InactivityWebStorage({
    this.getItem,
    this.setItem,
    this.removeItem,
  });

  final String? Function(String key)? getItem;
  final void Function(String key, String value)? setItem;
  final void Function(String key)? removeItem;

  @override
  Future<int?> read(String key) async {
    final reader = getItem;
    if (reader != null) {
      final raw = reader(key);
      return parseInactivityDeadline(raw);
    }
    return platform.readDeadline(key);
  }

  @override
  Future<void> write(String key, int value) async {
    final writer = setItem;
    if (writer != null) {
      writer(key, value.toString());
      return;
    }
    await platform.writeDeadline(key, value);
  }

  @override
  Future<void> remove(String key) async {
    final remover = removeItem;
    if (remover != null) {
      remover(key);
      return;
    }
    await platform.removeDeadline(key);
  }
}
