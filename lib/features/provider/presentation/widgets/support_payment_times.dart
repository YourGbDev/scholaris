import 'package:flutter/material.dart';

String supportRecordedTime(BuildContext context, dynamic value) {
  final time = value is String ? DateTime.tryParse(value)?.toLocal() : null;
  if (time == null) return 'Not recorded';
  final local = MaterialLocalizations.of(context);
  return '${local.formatMediumDate(time)} ${local.formatTimeOfDay(TimeOfDay.fromDateTime(time))}';
}

class SupportPaymentTimes extends StatelessWidget {
  const SupportPaymentTimes({super.key, required this.payment});
  final Map<String, dynamic> payment;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      'Recorded sent: ${supportRecordedTime(context, payment['sent_at'])}${payment['received_at'] == null ? '' : '\nReceipt confirmed: ${supportRecordedTime(context, payment['received_at'])}'}',
    ),
  );
}
