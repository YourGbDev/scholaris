import 'package:flutter/material.dart';

/// Deliberately isolated from the production student routes and repositories.
Future<void> showStudentReportPreview(
  BuildContext context, {
  required ValueChanged<Map<String, dynamic>> onAdd,
}) async {
  final form = GlobalKey<FormState>();
  var category = 'unsafe_request',
      relationship = 'experienced',
      description = '';
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        scrollable: true,
        title: const Text('Report this scholarship · Preview'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fictional demonstration only. Nothing is submitted to Scholaris. Friends can describe a concern without naming the affected student. Reports are private to the reporter and platform admins, not the provider.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: relationship,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'How do you know about this?',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'experienced',
                      child: Text('It happened to me'),
                    ),
                    DropdownMenuItem(
                      value: 'witnessed',
                      child: Text('I witnessed it'),
                    ),
                    DropdownMenuItem(
                      value: 'told',
                      child: Text('Someone told me'),
                    ),
                  ],
                  onChanged: (v) => setState(() => relationship = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Concern'),
                  items: const [
                    DropdownMenuItem(
                      value: 'unsafe_request',
                      child: Text('Unsafe or private meetup request'),
                    ),
                    DropdownMenuItem(
                      value: 'harassment',
                      child: Text('Harassment'),
                    ),
                    DropdownMenuItem(
                      value: 'threat',
                      child: Text('Threat or coercion'),
                    ),
                    DropdownMenuItem(
                      value: 'fraud',
                      child: Text('Suspected fraud'),
                    ),
                    DropdownMenuItem(
                      value: 'release_fee',
                      child: Text('Asked to pay a release fee'),
                    ),
                    DropdownMenuItem(
                      value: 'payment_not_received',
                      child: Text('Payment problem'),
                    ),
                    DropdownMenuItem(
                      value: 'other',
                      child: Text('Other concern'),
                    ),
                  ],
                  onChanged: (v) => setState(() => category = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  minLines: 3,
                  maxLines: 6,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'What happened?',
                    helperText: 'Do not include passwords, PINs or unnecessary personal details.',
                    helperMaxLines: 3,
                  ),
                  onChanged: (v) => description = v,
                  validator: (v) => (v?.trim().length ?? 0) < 10
                      ? 'Include at least 10 characters'
                      : null,
                ),
                const SizedBox(height: 12),
                const OutlinedButton(
                  onPressed: null,
                  child: Text('Attach evidence — backend required'),
                ),
                const Text(
                  'This is not a live emergency service. One serious report can need urgent review; multiple reports are not proof of wrongdoing.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                onAdd({
                  'category': category,
                  'relationship': relationship,
                  'description': description.trim(),
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add fictional report'),
          ),
        ],
      ),
    ),
  );
}
