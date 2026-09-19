// lib/core/security/login_lockout_service.dart
//
// IAS Account Lockout & Audit Trail Service:
// - Tracks failed login attempts per email.
// - Enforces progressive lockout backoff:
//     * 3 failed attempts  -> 5 minutes
//     * 4 failed attempts  -> 15 minutes
//     * 5+ failed attempts -> 60 minutes
// - Clears failed attempts upon successful login.
// - Persists attempts and audit events to Supabase when available.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LockoutStatus {
  const LockoutStatus({
    required this.isLocked,
    required this.failedAttempts,
    this.remainingTime = Duration.zero,
    this.lockedUntil,
  });

  final bool isLocked;
  final int failedAttempts;
  final Duration remainingTime;
  final DateTime? lockedUntil;

  String get lockoutMessage {
    if (!isLocked) return '';
    final mins = remainingTime.inMinutes;
    final secs = remainingTime.inSeconds % 60;
    final displaySecs =
        (mins == 0 && secs == 0 && remainingTime.inMilliseconds > 0) ? 1 : secs;
    if (mins > 0) {
      return 'Account temporarily locked due to $failedAttempts failed attempts. '
          'Please try again in ${mins}m ${displaySecs}s.';
    }
    return 'Account temporarily locked. Please try again in ${displaySecs}s.';
  }
}

class LoginLockoutService {
  LoginLockoutService._() {
    initPrefs();
  }
  static final LoginLockoutService instance = LoginLockoutService._();

  // In-memory registry of failed attempts and lockouts per email (normalized lowercase).
  final Map<String, int> _failedAttempts = {};
  final Map<String, DateTime> _lockedUntil = {};

  // For audit trail fallback/in-memory ledger
  final List<Map<String, dynamic>> _inMemoryAuditLogs = [];

  SharedPreferences? _prefs;

  List<Map<String, dynamic>> get inMemoryAuditLogs =>
      List.unmodifiable(_inMemoryAuditLogs);

  /// Initializes SharedPreferences and loads persisted attempts.
  Future<void> initPrefs() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final prefs = _prefs;
      if (prefs != null) {
        for (final key in prefs.getKeys()) {
          if (key.startsWith('lockout_attempts_')) {
            final email = key.substring('lockout_attempts_'.length);
            _failedAttempts[email] = prefs.getInt(key) ?? 0;
          } else if (key.startsWith('lockout_until_')) {
            final email = key.substring('lockout_until_'.length);
            final ms = prefs.getInt(key);
            if (ms != null) {
              final until = DateTime.fromMillisecondsSinceEpoch(ms);
              if (DateTime.now().isBefore(until)) {
                _lockedUntil[email] = until;
              } else {
                prefs.remove(key);
              }
            }
          }
        }
      }
    } catch (_) {
      // In headless test environments where plugins are unmocked, non-fatal.
    }
  }

  void _saveToPrefs(String key, int attempts, DateTime? until) {
    final prefs = _prefs;
    if (prefs != null) {
      prefs.setInt('lockout_attempts_$key', attempts);
      if (until != null) {
        prefs.setInt('lockout_until_$key', until.millisecondsSinceEpoch);
      } else {
        prefs.remove('lockout_until_$key');
      }
    }
  }

  void _clearFromPrefs(String key) {
    final prefs = _prefs;
    if (prefs != null) {
      prefs.remove('lockout_attempts_$key');
      prefs.remove('lockout_until_$key');
    }
  }

  void _clearAllPrefs() {
    final prefs = _prefs;
    if (prefs != null) {
      for (final key in prefs.getKeys().toList()) {
        if (key.startsWith('lockout_attempts_') || key.startsWith('lockout_until_')) {
          prefs.remove(key);
        }
      }
    }
  }

  /// Checks if an email is currently locked out.
  LockoutStatus checkLockout(String email) {
    final key = email.trim().toLowerCase();
    DateTime? until = _lockedUntil[key];
    int attempts = _failedAttempts[key] ?? 0;

    if (until == null && _prefs != null) {
      final ms = _prefs?.getInt('lockout_until_$key');
      if (ms != null) {
        until = DateTime.fromMillisecondsSinceEpoch(ms);
        _lockedUntil[key] = until;
      }
      attempts = _prefs?.getInt('lockout_attempts_$key') ?? attempts;
      _failedAttempts[key] = attempts;
    }

    if (until != null) {
      final now = DateTime.now();
      if (now.isBefore(until)) {
        final remaining = until.difference(now);
        return LockoutStatus(
          isLocked: true,
          failedAttempts: attempts,
          remainingTime: remaining,
          lockedUntil: until,
        );
      } else {
        // Lockout expired
        _lockedUntil.remove(key);
        _clearFromPrefs(key);
      }
    }

    return LockoutStatus(
      isLocked: false,
      failedAttempts: attempts,
    );
  }

  /// Checks lockout status with remote Supabase fallback if online.
  Future<LockoutStatus> checkLockoutRemote(String email) async {
    final localStatus = checkLockout(email);
    try {
      final client = Supabase.instance.client;
      final res = await client.rpc(
        'get_login_lockout_status',
        params: {'p_email': email.trim().toLowerCase()},
      );
      if (res != null && res is Map) {
        final isLocked = res['is_locked'] == true;
        final failedAttempts =
            (res['failed_attempts'] as num?)?.toInt() ?? localStatus.failedAttempts;
        final lockedUntilStr = res['locked_until'] as String?;
        DateTime? lockedUntil;
        Duration remaining = Duration.zero;
        if (lockedUntilStr != null) {
          lockedUntil = DateTime.tryParse(lockedUntilStr);
          if (lockedUntil != null && DateTime.now().isBefore(lockedUntil)) {
            remaining = lockedUntil.difference(DateTime.now());
          }
        }
        if (isLocked && lockedUntil != null) {
          final key = email.trim().toLowerCase();
          _failedAttempts[key] = failedAttempts;
          _lockedUntil[key] = lockedUntil;
          _saveToPrefs(key, failedAttempts, lockedUntil);
          return LockoutStatus(
            isLocked: true,
            failedAttempts: failedAttempts,
            remainingTime: remaining,
            lockedUntil: lockedUntil,
          );
        }
      }
    } catch (_) {}
    return localStatus;
  }

  /// Records a failed login attempt and calculates escalating lockout duration.
  LockoutStatus recordFailedAttempt(String email) {
    final key = email.trim().toLowerCase();
    final currentAttempts = (_failedAttempts[key] ?? 0) + 1;
    _failedAttempts[key] = currentAttempts;

    Duration? lockoutDuration;
    if (currentAttempts == 3) {
      lockoutDuration = const Duration(minutes: 5);
    } else if (currentAttempts == 4) {
      lockoutDuration = const Duration(minutes: 15);
    } else if (currentAttempts >= 5) {
      lockoutDuration = const Duration(minutes: 60);
    }

    DateTime? until;
    if (lockoutDuration != null) {
      until = DateTime.now().add(lockoutDuration);
      _lockedUntil[key] = until;
    }

    _saveToPrefs(key, currentAttempts, until);

    // Record attempt asynchronously in Supabase if client is ready
    _persistAttempt(email: key, success: false);

    return LockoutStatus(
      isLocked: until != null,
      failedAttempts: currentAttempts,
      remainingTime: lockoutDuration ?? Duration.zero,
      lockedUntil: until,
    );
  }

  /// Clears failed attempts after a successful login.
  void recordSuccessfulLogin(String email) {
    final key = email.trim().toLowerCase();
    _failedAttempts.remove(key);
    _lockedUntil.remove(key);
    _clearFromPrefs(key);
    _persistAttempt(email: key, success: true);
  }

  /// Resets all local state (useful for tests).
  @visibleForTesting
  void resetState() {
    _failedAttempts.clear();
    _lockedUntil.clear();
    _inMemoryAuditLogs.clear();
    _clearAllPrefs();
  }

  Future<void> _persistAttempt({
    required String email,
    required bool success,
  }) async {
    try {
      final client = Supabase.instance.client;
      await client.from('login_attempts').insert({
        'email': email,
        'success': success,
        'attempt_time': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Non-fatal if offline or table not migrated yet
    }
  }

  /// Records an audit log event.
  Future<void> logAuditEvent({
    required String action,
    required String targetType,
    String? targetId,
    Map<String, dynamic>? details,
    String? actorEmail,
    String? actorRole,
  }) async {
    final now = DateTime.now();
    final logEntry = {
      'id': 'log-${now.millisecondsSinceEpoch}',
      'action': action,
      'target_type': targetType,
      'target_id': targetId,
      'details': details ?? {},
      'actor_email': actorEmail ?? 'system@scholaris.ph',
      'actor_role': actorRole ?? 'system',
      'created_at': now.toIso8601String(),
    };

    _inMemoryAuditLogs.insert(0, logEntry);

    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      final email = client.auth.currentUser?.email ?? actorEmail;

      await client.from('audit_logs').insert({
        'actor_id': userId,
        'actor_email': email,
        'actor_role': actorRole ?? 'authenticated',
        'action': action,
        'target_type': targetType,
        'target_id': targetId,
        'details': details ?? {},
        'created_at': now.toIso8601String(),
      });
    } catch (_) {
      // Non-fatal if offline
    }
  }
}
