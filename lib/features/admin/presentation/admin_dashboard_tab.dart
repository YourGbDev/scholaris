// lib/features/admin/presentation/admin_dashboard_tab.dart
import 'package:flutter/material.dart';
import 'package:scholaris/admin/screens/platform_overview_screen.dart';

class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({super.key, this.onProviders, this.onReports});
  final VoidCallback? onProviders;
  final VoidCallback? onReports;

  @override
  Widget build(BuildContext context) {
    return PlatformOverviewScreen(
      onProviders: onProviders,
      onReports: onReports,
    );
  }
}
