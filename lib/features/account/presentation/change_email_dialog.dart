import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:scholaris/core/security/captcha_challenge.dart';

import '../providers/account_provider.dart';

class ChangeEmailDialog extends ConsumerStatefulWidget {
  const ChangeEmailDialog({required this.currentEmail, super.key});

  final String currentEmail;

  @override
  ConsumerState<ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends ConsumerState<ChangeEmailDialog> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  bool _waiting = false;
  bool _requested = false;
  bool _confirmed = false;
  bool _useNewEmail = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    final email = _email.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'Enter a valid new email address.');
      return;
    }
    if (email.toLowerCase() == widget.currentEmail.toLowerCase()) {
      setState(() => _error = 'Enter a different email address.');
      return;
    }
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter your current password.');
      return;
    }
    setState(() { _waiting = true; _error = null; });
    try {
      final captcha = await acquireCaptcha(context);
      if (!mounted || !captcha.allowed) return;
      await ref.read(accountRepositoryProvider).requestEmailChange(
        currentPassword: _password.text,
        newEmail: email,
        captchaToken: captcha.token,
      );
      if (!mounted) return;
      _password.clear();
      setState(() => _requested = true);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not request the change. Check your password and try again.');
    } finally {
      if (mounted) setState(() => _waiting = false);
    }
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (!RegExp(r'^\d{8}$').hasMatch(code)) {
      setState(() => _error = 'Enter the 8-digit code.');
      return;
    }
    final target = _useNewEmail ? _email.text.trim() : widget.currentEmail;
    setState(() { _waiting = true; _error = null; _notice = null; });
    try {
      final captcha = await acquireCaptcha(context);
      if (!mounted || !captcha.allowed) return;
      final actualEmail = await ref.read(accountRepositoryProvider).verifyEmailChangeCode(
        email: target,
        code: code,
        captchaToken: captcha.token,
      );
      if (!mounted) return;
      _code.clear();
      setState(() {
        if (actualEmail?.toLowerCase() == _email.text.trim().toLowerCase()) {
          _confirmed = true;
        } else {
          _notice = 'Code accepted. Check the other inbox for a confirmation code.';
          _useNewEmail = !_useNewEmail;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not verify that code. Check it and try again.');
    } finally {
      if (mounted) setState(() => _waiting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change email'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 380,
          child: _confirmed
              ? const Text('Your new email address has been confirmed.')
              : Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (!_requested) ...[
                    const Text('Confirm your password. We will send confirmation codes to your email addresses.'),
                    TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'New email address')),
                    TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')),
                  ] else ...[
                    const Text('Check your current and new inboxes. Choose the address that received each code.'),
                    DropdownButton<bool>(
                      value: _useNewEmail,
                      isExpanded: true,
                      items: [
                        DropdownMenuItem(value: false, child: Text('Current: ${widget.currentEmail}', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: true, child: Text('New: ${_email.text.trim()}', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: _waiting ? null : (value) => setState(() => _useNewEmail = value ?? false),
                    ),
                    TextField(controller: _code, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)], decoration: const InputDecoration(labelText: '8-digit confirmation code')),
                  ],
                  if (_notice != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_notice!)),
                  if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                ]),
        ),
      ),
      actions: [
        TextButton(onPressed: _waiting ? null : () => Navigator.pop(context), child: Text(_confirmed ? 'Done' : 'Cancel')),
        if (!_confirmed) FilledButton(onPressed: _waiting ? null : (_requested ? _verify : _request), child: Text(_waiting ? 'Please wait…' : (_requested ? 'Verify code' : 'Send codes'))),
      ],
    );
  }
}
