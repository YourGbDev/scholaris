import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../repositories/support_repository.dart';

class SupportPaymentCorrection extends ConsumerStatefulWidget {
  const SupportPaymentCorrection({
    super.key,
    required this.payment,
    this.admin = false,
  });
  final Map<String, dynamic> payment;
  final bool admin;
  @override
  ConsumerState<SupportPaymentCorrection> createState() =>
      _SupportPaymentCorrectionState();
}

class _SupportPaymentCorrectionState
    extends ConsumerState<SupportPaymentCorrection> {
  bool _busy = false;
  Future<void> _correct({bool request = false}) async {
    var reason = '';
    final form = GlobalKey<FormState>();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          request ? 'Request platform review' : 'Correct this payment record?',
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request
                        ? 'Ask platform admins to review this specific confirmed payment. The record and totals stay unchanged until reviewed. This request does not reveal private student reports.'
                        : 'The original entry stays in history and will no longer count as sent. The student is notified. This does not reverse a transfer or issue a refund.',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    onChanged: (v) => reason = v,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: 'Reason for correction',
                      helperText: request
                          ? 'Shared with platform admins. Do not include credentials.'
                          : 'Visible to the student. Do not include private credentials.',
                      helperMaxLines: 2,
                    ),
                    validator: (v) =>
                        (v?.trim().length ?? 0) < (request ? 10 : 5)
                        ? (request
                              ? 'Explain the request in at least 10 characters'
                              : 'Explain the correction in at least 5 characters')
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep record'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(ctx, reason.trim());
              }
            },
            child: Text(
              request ? 'Submit review request' : 'Mark entered in error',
            ),
          ),
        ],
      ),
    );

    if (value == null || !mounted) return;
    setState(() => _busy = true);
    try {
      if (request) {
        await ref
            .read(supportRepositoryProvider)
            .requestReview(widget.payment['id'] as String, value);
      } else {
        await ref
            .read(supportRepositoryProvider)
            .voidPayment(widget.payment['id'] as String, value);
      }
      ref.invalidate(supportLedgerProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              request
                  ? 'Review request submitted. Your payment record is unchanged.'
                  : 'Record corrected. No money was moved.',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              request
                  ? 'Could not submit the review request. An open request may already exist for this application; contact the platform admin if needed.'
                  : 'Could not correct this record. Refresh first; student-confirmed records require admin review.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.payment['voided_at'] != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          'Entered in error: ${widget.payment['void_reason']}\nKept in history; excluded from sent totals.',
        ),
      );
    }
    if (widget.payment['received_at'] != null && !widget.admin) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Student-confirmed record. Corrections require platform review.',
          ),
          TextButton(
            onPressed: _busy ? null : () => _correct(request: true),
            child: Text(_busy ? 'Submitting…' : 'Request platform review'),
          ),
        ],
      );
    }
    return TextButton.icon(
      onPressed: _busy ? null : _correct,
      icon: const Icon(Icons.edit_note_outlined, size: 18),
      label: Text(_busy ? 'Correcting…' : 'Correct record'),
    );
  }
}
