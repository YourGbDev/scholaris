import 'package:flutter/material.dart';
import 'package:scholaris/shared/widgets/responsive_container.dart';

import 'admin_theme.dart';

class AdminAuditLogsTab extends StatelessWidget {
  const AdminAuditLogsTab({super.key});

  @override
  Widget build(BuildContext context) {

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
            'Target migration blueprint (0008_create_audit_logs.sql)',
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
              'CREATE TABLE public.audit_logs (\n'
              '  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),\n'
              '  actor_id    uuid NOT NULL REFERENCES auth.users(id),\n'
              '  actor_role  text NOT NULL,\n'
              '  action      text NOT NULL,\n'
              '  target_type text NOT NULL,\n'
              '  target_id   text NOT NULL,\n'
              '  metadata    jsonb,\n'
              '  created_at  timestamptz NOT NULL DEFAULT now()\n'
              ');\n'
              'ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;\n'
              'CREATE POLICY "Audit logs are viewable by admin only"\n'
              '  ON public.audit_logs FOR SELECT TO authenticated\n'
              '  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = \'admin\'));',
              style: adminDataMono(fontSize: 12, color: kAdminNavyTrust),
            ),
          ),
          const SizedBox(height: 24),
          // Inactive Event Stream Notice
          Text(
            'Audit event stream',
            style: adminHeaderStyle(fontSize: 15, fontWeight: FontWeight.w600, color: kAdminNavyTrust),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: kAdminTableRadius,
              border: Border.all(color: kAdminHairline, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.inbox_outlined, color: kAdminTextSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Event streaming inactive',
                        style: adminHeaderStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kAdminNavyTrust,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Audit event recording and live streaming will activate automatically once migration 0008 is executed against the database. No simulated or mock entries are generated.',
                        style: adminBodyStyle(fontSize: 13, color: kAdminTextSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
