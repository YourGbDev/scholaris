import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/controllers/auth_controller.dart';

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
    _userId = userId;
    _deadline = null;
    _warning = false;
    _expired = false;
    _signingOut = false;
    _signOutFailed = false;
    if (userId != null) _resetTimer();
  }

  void _resetTimer() {
    if (_userId == null || _expired) return;
    _cancelTimers();
    _deadline = DateTime.now().add(_timeout);
    _warningTimer = Timer(_timeout - _warningBefore, () {
      if (mounted) setState(() => _warning = true);
    });
    _timeoutTimer = Timer(_timeout, _expire);
  }

  void _activity() {
    if (_warning || _expired || _userId == null) return;
    if (_deadline != null && !DateTime.now().isBefore(_deadline!)) {
      _expire();
      return;
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
    if (remaining <= Duration.zero) {
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
      child: Stack(children: [
        ExcludeFocus(
          excluding: _warning || _expired,
          child: ExcludeSemantics(
            excluding: _warning || _expired,
            child: widget.child,
          ),
        ),
        if (_warning || _expired) ...[
          const ModalBarrier(dismissible: false, color: Colors.black54),
          Center(
            child: AlertDialog(
              title: Text(_expired
                  ? 'Your session has expired'
                  : 'Your session is about to expire'),
              content: Text(_expired
                  ? (_signOutFailed
                      ? 'We could not sign you out. Please try again.'
                      : 'Signing you out after 15 minutes of inactivity.')
                  : 'You will be signed out in one minute due to inactivity.'),
              actions: [
                if (_warning)
                  TextButton(
                    onPressed: () {
                      setState(() => _warning = false);
                      _resetTimer();
                    },
                    child: const Text('Stay signed in'),
                  ),
                if (_expired && _signOutFailed && !_signingOut)
                  TextButton(
                    onPressed: _expire,
                    child: const Text('Try again'),
                  ),
              ],
            ),
          ),
        ],
      ]),
    );
  }
}
