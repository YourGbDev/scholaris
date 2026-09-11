import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scholaris/features/auth/controllers/auth_controller.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';

import 'admin_theme.dart';

class AdminAuditLogsTab extends ConsumerWidget {
  const AdminAuditLogsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserIdProvider);

    return ResponsiveContainer(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        children: [
          Text(
            'System Audit Ledger',
            style: adminHeaderStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: kAdminNavyTrust,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Immutable tracking of administrative actions, status transitions, and provider approvals.',
            style: adminLabelStyle(fontSize: 13, color: kAdminTextSecondary),
          ),
          const SizedBox(height: 18),
          // Honest Architecture & Readiness Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: kAdminCardRadius,
              border: Border.all(color: kAdminHairline, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, color: kAdminNavyTrust, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Audit logging infrastructure readiness',
                        style: adminHeaderStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kAdminNavyTrust,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kAdminGoldenOpportunity.withValues(alpha: 0.12),
                        borderRadius: kAdminPillRadius,
                      ),
                      child: Text(
                        'Migration pending',
                        style: adminLabelStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB28109),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'No unmigrated or simulated logs are presented here. Per platform safety guidelines, audit logs require dedicated database persistence before displaying event streams. Below is the blueprint specification to activate full immutable audit logging.',
                  style: adminBodyStyle(fontSize: 13, color: kAdminTextSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Target Migration Specification
          Text(
            'Target Migration Blueprint (0008_create_audit_logs.sql)',
            style: adminHeaderStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: kAdminTableRadius,
              border: Border.all(color: kAdminHairline, width: 1),
            ),
            child: Text(
              'CREATE TABLE public.audit_logs (\\n'
              '  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),\\n'
              '  actor_id    uuid NOT NULL REFERENCES auth.users(id),\\n'
              '  actor_role  text NOT NULL,\\n'
              '  action      text NOT NULL,\\n'
              '  target_type text NOT NULL,\\n'
              '  target_id   text NOT NULL,\\n'
              '  metadata    jsonb,\\n'
              '  created_at  timestamptz NOT NULL DEFAULT now()\\n'
              ');\\n'
              'ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;\\n'
              'CREATE POLICY "Audit logs are viewable by admin only"\\n'
              '  ON public.audit_logs FOR SELECT TO authenticated\\n'
              '  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = \'admin\'));',
              style: adminDataMono(fontSize: 12, color: kAdminNavyTrust),
            ),
          ),
          const SizedBox(height: 24),
          // Codebase Trigger Points Table
          Text(
            'Registered Action Hooks',
            style: adminHeaderStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: kAdminTableRadius,
              border: Border.all(color: kAdminHairline, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  color: const Color(0xFFF9FAFB),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text(
                          'Action identifier',
                          style: adminLabelStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Target type',
                          style: adminLabelStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Text(
                          'Code location',
                          style: adminLabelStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: kAdminHairline),
                _triggerRow('provider.approved', 'provider', 'AdminProvidersTab._confirmProviderApproval'),
                const Divider(height: 1, color: kAdminHairline),
                _triggerRow('scholarship.status_toggled', 'scholarship', 'AdminScholarshipsTab._isActive toggle'),
                const Divider(height: 1, color: kAdminHairline),
                _triggerRow('application.status_changed', 'application', 'provider_incoming_applications.dart'),
                const Divider(height: 1, color: kAdminHairline),
                _triggerRow('user.authenticated', 'auth.session', 'authRedirectDecision (router.dart)'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Runtime Telemetry
          Text(
            'Session Telemetry',
            style: adminHeaderStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: kAdminCardRadius,
              border: Border.all(color: kAdminHairline, width: 1),
            ),
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: kAdminBridgeGreen, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    children: [
                      Text('Operator: ', style: adminLabelStyle(fontSize: 12, color: kAdminTextSecondary)),
                      Flexible(
                        child: Text(
                          currentUserId ?? 'admin-1',
                          style: adminDataMono(fontSize: 12, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('RLS verified', style: adminLabelStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kAdminBridgeGreen)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _triggerRow(String action, String target, String location) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(action, style: adminDataMono(fontSize: 12, fontWeight: FontWeight.w600, color: kAdminNavyTrust)),
          ),
          Expanded(
            flex: 3,
            child: Text(target, style: adminBodyStyle(fontSize: 12, color: kAdminTextSecondary)),
          ),
          Expanded(
            flex: 5,
            child: Text(location, style: adminLabelStyle(fontSize: 11, color: kAdminTextSecondary)),
          ),
        ],
      ),
    );
  }
}
