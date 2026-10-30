import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/controllers/auth_controller.dart';
import 'inactivity_storage.dart';

final inactivityStorageProvider = Provider<InactivityStorage>(
  (ref) => InactivityStorage(),
);

final inactivitySignOutProvider = Provider<Future<void> Function()>((ref) {
  return () => Supabase.instance.client.auth.signOut(scope: SignOutScope.local);
});

class InactivityGuard extends ConsumerStatefulWidget {
  const InactivityGuard({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<InactivityGuard> createState() => _InactivityGuardState();
}

class _InactivityGuardState extends ConsumerState<InactivityGuard>
    with WidgetsBindingObserver {
  static const _timeout = Duration(minutes: 15);
  static const _warningBefore = Duration(minutes: 1);
  Timer? _warningTimer;
  Timer? _timeoutTimer;
  DateTime? _deadline;
  String? _userId;
  bool _warning = false;
  bool _expired = false;
  bool _signingOut = false;
  bool _signOutFailed = false;
  bool _loading = false;
  bool _storageFailed = false;
  int _generation = 0;
  Future<void> _storageQueue = Future.value();

  String _key(String userId) => 'inactivity_deadline_$userId';

  Future<void> _queue(Future<void> Function() operation) {
    final next = _storageQueue.then((_) => operation());
    _storageQueue = next.catchError((Object _) {});
    return next;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_onKey);
    _cancelTimers();
    super.dispose();
  }

  void _cancelTimers() {
    _warningTimer?.cancel();
    _timeoutTimer?.cancel();
  }

  void _startSession(String? userId) {
    _cancelTimers();
    final storage = ref.read(inactivityStorageProvider);
    final previous = _userId;
    final generation = ++_generation;
    _userId = userId;
    _deadline = null;
    _warning = false;
    _expired = false;
    _signingOut = false;
    _signOutFailed = false;
    _storageFailed = false;
    _loading = userId != null;
    if (previous != null && previous != userId) {
      _queue(() => storage.remove(_key(previous))).catchError((Object _) {
        if (mounted && generation == _generation && _userId != null) {
          setState(() {
            _cancelTimers();
            _loading = false;
            _storageFailed = true;
          });
        }
      });
    }
    if (userId != null) _restore(userId, generation);
  }

  Future<void> _restore(String userId, int generation) async {
    final storage = ref.read(inactivityStorageProvider);
    try {
      int? saved;
      await _queue(() async {
        if (generation != _generation) return;
        saved = await storage.read(_key(userId));
      });
      if (!mounted || generation != _generation) return;

      if (saved == null) {
        final deadline = DateTime.now().add(_timeout);
        await _queue(() async {
          if (generation != _generation) return;
          await storage.write(_key(userId), deadline.millisecondsSinceEpoch);
        });
        if (!mounted || generation != _generation) return;
        setState(() {
          _loading = false;
          _deadline = deadline;
        });
        _scheduleDeadline();
      } else {
        final now = DateTime.now();
        final isInvalid = saved! <= 0;
        final savedDeadline = isInvalid
            ? null
            : DateTime.fromMillisecondsSinceEpoch(saved!);
        final isExpired = isInvalid ||
            savedDeadline == null ||
            savedDeadline.difference(now) > const Duration(hours: 24) ||
            !savedDeadline.isAfter(now);

        if (!mounted || generation != _generation) return;
        if (isExpired) {
          _expire();
          return;
        }

        setState(() {
          _loading = false;
          _deadline = savedDeadline;
        });
        _scheduleDeadline();
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() {
          _loading = false;
          _storageFailed = true;
        });
      }
    }
  }

  void _scheduleDeadline() {
    _cancelTimers();
    final remaining = _deadline!.difference(DateTime.now());
    if (remaining <= Duration.zero || remaining > const Duration(hours: 24)) {
      _expire();
      return;
    }
    if (remaining <= _warningBefore) {
      setState(() => _warning = true);
    } else {
      _warningTimer = Timer(remaining - _warningBefore, () {
        if (mounted) setState(() => _warning = true);
      });
    }
    _timeoutTimer = Timer(remaining, _expire);
  }

  void _resetTimer() {
    if (_userId == null || _expired || _loading || _storageFailed) return;
    _cancelTimers();
    _deadline = DateTime.now().add(_timeout);
    final userId = _userId!;
    final generation = _generation;
    final deadline = _deadline!;
    final storage = ref.read(inactivityStorageProvider);
    _queue(() async {
      if (generation != _generation) return;
      await storage.write(_key(userId), deadline.millisecondsSinceEpoch);
    }).catchError((Object _) {
      if (mounted && generation == _generation) {
        setState(() {
          _cancelTimers();
          _storageFailed = true;
        });
      }
    });
    _warningTimer = Timer(_timeout - _warningBefore, () {
      if (mounted) setState(() => _warning = true);
    });
    _timeoutTimer = Timer(_timeout, _expire);
  }

  void _activity() {
    if (_warning || _expired || _loading || _storageFailed || _userId == null) {
      return;
    }
    if (_deadline != null) {
      final now = DateTime.now();
      if (!now.isBefore(_deadline!) ||
          _deadline!.difference(now) > const Duration(hours: 24)) {
        _expire();
        return;
      }
    }
    _resetTimer();
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent) _activity();
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _deadline == null || _expired) {
      return;
    }
    final remaining = _deadline!.difference(DateTime.now());
    if (remaining <= Duration.zero || remaining > const Duration(hours: 24)) {
      _expire();
    } else if (remaining <= _warningBefore && !_warning) {
      setState(() => _warning = true);
    }
  }

  Future<void> _expire() async {
    if (!mounted || _userId == null || _signingOut) return;
    _cancelTimers();
    final expiredUserId = _userId;
    setState(() {
      _loading = false;
      _expired = true;
      _warning = false;
      _signingOut = true;
      _signOutFailed = false;
    });
    try {
      await ref.read(inactivitySignOutProvider)();
    } catch (_) {
      if (mounted && _userId == expiredUserId) {
        setState(() => _signOutFailed = true);
      }
    } finally {
      if (mounted && _userId == expiredUserId) {
        setState(() => _signingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    if (userId != _userId) _startSession(userId);

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _activity(),
      onPointerHover: (_) => _activity(),
      onPointerSignal: (_) => _activity(),
      child: Stack(
        children: [
          ExcludeFocus(
            excluding: _warning || _expired || _loading || _storageFailed,
            child: ExcludeSemantics(
              excluding: _warning || _expired || _loading || _storageFailed,
              child: widget.child,
            ),
          ),
          if (_loading || _storageFailed) ...[
            const ModalBarrier(dismissible: false, color: Colors.black54),
            Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : AlertDialog(
                      title: const Text('Security check unavailable'),
                      content: const Text(
                        'Could not save your session timer. Please sign out and try again.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: _expire,
                          child: const Text('Sign out'),
                        ),
                      ],
                    ),
            ),
          ],
          if (_warning || _expired) ...[
            const ModalBarrier(dismissible: false, color: Colors.black54),
            Center(
              child: AlertDialog(
                title: Text(
                  _expired
                      ? 'Your session has expired'
                      : 'Your session is about to expire',
                ),
                content: Text(
                  _expired
                      ? (_signOutFailed
                            ? 'We could not sign you out. Please try again.'
                            : 'Signing you out after 15 minutes of inactivity.')
                      : 'You will be signed out in one minute due to inactivity.',
                ),
                actions: [
                  if (_warning)
                    TextButton(
                      onPressed: () {
                        setState(() => _warning = false);
                        _resetTimer();
                      },
                      child: const Text('Stay signed in'),
                    ),
                  if (_expired && _signOutFailed && !_signingOut) ...[
                    TextButton(
                      onPressed: _expire,
                      child: const Text('Try again'),
                    ),
                    TextButton(
                      onPressed: _expire,
                      child: const Text('Sign out'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
