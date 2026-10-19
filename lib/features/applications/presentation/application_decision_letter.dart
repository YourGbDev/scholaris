import 'package:flutter/material.dart';
import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/shared/theme/app_theme.dart';

/// A view of the saved decision, without invented signatures or payment claims.
class ApplicationDecisionLetter extends StatelessWidget {
  const ApplicationDecisionLetter({
    super.key,
    required this.application,
    required this.scholarshipTitle,
    this.providerName,
    this.studentName,
  });

  final Application application;
  final String scholarshipTitle;
  final String? providerName;
  final String? studentName;

  @override
  Widget build(BuildContext context) {
    final awarded = application.status == ApplicationStatus.awarded;
    final eligible =
        awarded || application.status == ApplicationStatus.approved;
    final title = awarded
        ? 'Scholarship Award Certificate'
        : 'Scholarship Approval Letter';
    return Scaffold(
      appBar: AppBar(
        title: Text(awarded ? 'Award certificate' : 'Approval letter'),
      ),
      backgroundColor: const Color(0xFFF5F4EE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFFB38A35),
                    width: awarded ? 2.0 : 1.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x120F4D2E),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: eligible
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Icon(
                            Icons.workspace_premium_outlined,
                            color: awarded
                                ? const Color(0xFFB38A35)
                                : const Color(0xFF0F4D2E),
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'SCHOLARIS',
                            textAlign: TextAlign.center,
                            style: outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F4D2E),
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: outfit(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F4D2E),
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (studentName?.trim().isNotEmpty == true) ...[
                            Text(
                              studentName!.trim(),
                              textAlign: TextAlign.center,
                              style: outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            awarded
                                ? 'Your scholarship has been awarded for'
                                : 'Your application has been approved for',
                            textAlign: TextAlign.center,
                            style: openSans(
                              fontSize: 14,
                              color: const Color(0xFF404942),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            scholarshipTitle,
                            textAlign: TextAlign.center,
                            style: outfit(
                              fontSize: 21,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (providerName?.trim().isNotEmpty == true) ...[
                            const SizedBox(height: 12),
                            Text(
                              providerName!.trim(),
                              textAlign: TextAlign.center,
                              style: openSans(
                                fontSize: 14,
                                color: const Color(0xFF707971),
                              ),
                            ),
                          ],
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Divider(),
                          ),
                          if (application.decidedAt != null)
                            Text(
                              'Application approved on ${_date(application.decidedAt!.toLocal())}',
                              textAlign: TextAlign.center,
                              style: openSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF404942),
                              ),
                            ),
                          const SizedBox(height: 12),
                          SelectableText(
                            'Application reference\n${application.id}',
                            textAlign: TextAlign.center,
                            style: openSans(
                              fontSize: 13,
                              color: const Color(0xFF707971),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            awarded
                                ? 'This record reflects your saved scholarship status in Scholaris. Contact your provider for the next steps and release schedule.'
                                : 'This letter records your application approval in Scholaris. Contact your provider for the next steps. Approval does not confirm that funds have been released.',
                            textAlign: TextAlign.center,
                            style: openSans(
                              fontSize: 13,
                              color: const Color(0xFF404942),
                              height: 1.5,
                            ),
                          ),
                        ],
                      )
                    : const Text(
                        'A letter is available only for an approved or awarded application.',
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _date(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
