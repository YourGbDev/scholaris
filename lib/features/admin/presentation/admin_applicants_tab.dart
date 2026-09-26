// lib/features/admin/presentation/admin_applicants_tab.dart
import 'package:flutter/material.dart';
import 'package:scholaris/admin/screens/applications_oversight_screen.dart';

class AdminApplicantsTab extends StatelessWidget {
  const AdminApplicantsTab({super.key, this.initialInspectApproved = false});

  final bool initialInspectApproved;

  @override
  Widget build(BuildContext context) {
    return ApplicationsOversightScreen(
      initialInspectApproved: initialInspectApproved,
    );
  }
}
