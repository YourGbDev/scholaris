// lib/admin/screens/admin_settings_screen.dart
//
// Admin Console: Admin Settings Placeholder (Screen 8)
// Visual tokens: scholaris_sequoia/DESIGN.md
// Honest placeholder: non-interactive controls clearly marked "Coming in v2".
// Zero fake values, zero hardcoded active toggles, zero fabricated compliance stamps.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scholaris/features/admin/presentation/admin_theme.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSeqSurface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header (No Live data tag per instructions) ---
            Text(
              'Admin Settings',
              style: GoogleFonts.newsreader(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: kSeqOnSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Platform configuration',
              style: seqBodyMd(color: kSeqOnSurfaceVariant),
            ),
            const SizedBox(height: 24),

            // --- Group 1: Platform ---
            _buildGroupCard(
              context,
              title: 'PLATFORM',
              icon: Icons.dns_outlined,
              children: [
                _buildToggleRow(
                  title: 'Registration Open / Closed',
                  subtitle: 'Coming in v2',
                ),
                _buildDivider(),
                _buildToggleRow(
                  title: 'Maintenance Mode',
                  subtitle: 'Coming in v2',
                ),
                _buildDivider(),
                _buildControlRow(
                  title: 'Maximum Applications per Student',
                  subtitle: 'Coming in v2',
                  controlText: '—',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Group 2: Applications ---
            _buildGroupCard(
              context,
              title: 'APPLICATIONS',
              icon: Icons.assignment_outlined,
              children: [
                _buildControlRow(
                  title: 'Application Review Period (days)',
                  subtitle: 'Coming in v2',
                  controlText: '—',
                ),
                _buildDivider(),
                _buildToggleRow(
                  title: 'Auto-close Expired Applications',
                  subtitle: 'Coming in v2',
                ),
                _buildDivider(),
                _buildToggleRow(
                  title: 'Require GPA Verification',
                  subtitle: 'Coming in v2',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Group 3: Notifications ---
            _buildGroupCard(
              context,
              title: 'NOTIFICATIONS',
              icon: Icons.notifications_none_rounded,
              children: [
                _buildToggleRow(
                  title: 'Email Notifications',
                  subtitle: 'Coming in v2',
                ),
                _buildDivider(),
                _buildToggleRow(
                  title: 'SMS Alerts',
                  subtitle: 'Coming in v2',
                ),
                _buildDivider(),
                _buildControlRow(
                  title: 'Digest Frequency',
                  subtitle: 'Coming in v2',
                  controlText: '—',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Group 4: Security ---
            _buildGroupCard(
              context,
              title: 'SECURITY',
              icon: Icons.security_outlined,
              children: [
                _buildControlRow(
                  title: 'Session Timeout',
                  subtitle: 'Coming in v2',
                  controlText: '—',
                ),
                _buildDivider(),
                _buildToggleRow(
                  title: 'Two-Factor Authentication',
                  subtitle: 'Coming in v2',
                ),
                _buildDivider(),
                _buildControlRow(
                  title: 'Audit Log Retention (days)',
                  subtitle: 'Coming in v2',
                  controlText: '—',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Footer Note (Muted) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSeqSurfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: kSeqOutlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: kSeqOutline,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Settings configuration will be available once the platform_settings table is provisioned. These controls are planned for v2.',
                      style: seqBodySm(color: kSeqOutline),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Card Container Helper ---
  Widget _buildGroupCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kSeqSurfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kSeqOutlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 16, color: kSeqOutline),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: seqLabelSm(
                    color: kSeqOutline,
                    fontWeight: FontWeight.w700,
                  ).copyWith(letterSpacing: 0.5),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: kSeqOutlineVariant.withValues(alpha: 0.2),
          ),
          ...children,
        ],
      ),
    );
  }

  // --- Toggle Row (Disabled) ---
  Widget _buildToggleRow({
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: seqBodyMd(
                    fontWeight: FontWeight.w600,
                    color: kSeqOnSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: seqLabelSm(color: kSeqOutline),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Disabled Switch (Visually present, non-interactive)
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: false,
              onChanged: null,
              activeThumbColor: kSeqOutline,
              inactiveThumbColor: kSeqOutlineVariant,
              inactiveTrackColor: kSeqSurfaceContainerLow,
            ),
          ),
        ],
      ),
    );
  }

  // --- Control Row (Disabled control pill) ---
  Widget _buildControlRow({
    required String title,
    required String subtitle,
    required String controlText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: seqBodyMd(
                    fontWeight: FontWeight.w600,
                    color: kSeqOnSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: seqLabelSm(color: kSeqOutline),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Greyed-out control badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: kSeqSurfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: kSeqOutlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              controlText,
              style: seqLabelSm(
                color: kSeqOutline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 16,
      endIndent: 16,
      color: kSeqOutlineVariant.withValues(alpha: 0.15),
    );
  }
}
