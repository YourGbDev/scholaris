// lib/features/provider/presentation/org/widgets/assign_reviewer_dialog.dart
//
// Modal dialog allowing Organization Admins to assign or unassign active
// academic evaluators/reviewers to a specific scholarship grant program.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scholaris/features/scholarships/models/scholarship.dart';
import 'package:scholaris/shared/theme/app_motion.dart';
import '../../../models/organization_team_member.dart';
import '../../../providers/organization_team_provider.dart';
import '../org_provider_theme.dart';

class AssignReviewerDialog extends ConsumerStatefulWidget {
  const AssignReviewerDialog({
    super.key,
    required this.scholarship,
  });

  final Scholarship scholarship;

  static Future<void> show(BuildContext context, Scholarship scholarship) {
    return showDialog<void>(
      context: context,
      barrierColor: const Color(0x33000000),
      builder: (ctx) => AssignReviewerDialog(scholarship: scholarship),
    );
  }

  @override
  ConsumerState<AssignReviewerDialog> createState() =>
      _AssignReviewerDialogState();
}

class _AssignReviewerDialogState extends ConsumerState<AssignReviewerDialog> {
  final Set<String> _pendingToggles = <String>{};

  Future<void> _toggleAssignment({
    required OrganizationTeamMember member,
    required bool isCurrentlyAssigned,
  }) async {
    if (_pendingToggles.contains(member.userId)) return;

    setState(() {
      _pendingToggles.add(member.userId);
    });

    final repo = ref.read(organizationTeamRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (isCurrentlyAssigned) {
        await repo.unassignReviewer(widget.scholarship.id, member.userId);
      } else {
        await repo.assignReviewer(widget.scholarship.id, member.userId);
      }

      ref.invalidate(scholarshipReviewerAssignmentsProvider(widget.scholarship.id));
      ref.invalidate(organizationRosterProvider);

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: kOrgPrimary,
          duration: const Duration(seconds: 2),
          content: Text(
            isCurrentlyAssigned
                ? 'Unassigned ${member.fullName} from "${widget.scholarship.title}".'
                : 'Assigned ${member.fullName} to "${widget.scholarship.title}".',
            style: orgBody(color: Colors.white, fontSize: 13),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: kOrgError,
          content: Text(
            'Failed to update assignment: $e',
            style: orgBody(color: Colors.white, fontSize: 13),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _pendingToggles.remove(member.userId);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rosterAsync = ref.watch(organizationRosterProvider);
    final assignmentsAsync =
        ref.watch(scholarshipReviewerAssignmentsProvider(widget.scholarship.id));

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Center(
        child: Container(
          width: 480,
          constraints: const BoxConstraints(maxHeight: 560),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kOrgHairline),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: kOrgPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.assignment_ind_rounded,
                          color: kOrgPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Assign Reviewers',
                            style: orgHeadline(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: kOrgTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.scholarship.title,
                            style: orgLabel(
                              fontSize: 12,
                              color: kOrgTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          size: 20, color: kOrgTextSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: kOrgHairline),

              // Sub-header guidance
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: const Color(0xFFF9F9FB),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 15, color: kOrgTextSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Assigned evaluators can filter incoming dossiers using "Assigned to Me" and record rubric scores.',
                        style: orgBody(fontSize: 11.5, color: kOrgTextSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: kOrgHairline),

              // Reviewer Roster List
              Flexible(
                child: rosterAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Could not load organization roster: $err',
                        style: orgBody(color: kOrgError, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  data: (roster) {
                    final reviewers = roster
                        .where((m) => m.isReviewer && m.active)
                        .toList();

                    if (reviewers.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.group_off_rounded,
                                  size: 36, color: kOrgTextSecondary),
                              const SizedBox(height: 10),
                              Text(
                                'No Active Reviewers Found',
                                style: orgHeadline(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add reviewers to your organization in the Team & Reviewers tab.',
                                style: orgBody(
                                  fontSize: 12,
                                  color: kOrgTextSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final assignedReviewerIds = assignmentsAsync.valueOrNull
                            ?.map((a) => a.reviewerId)
                            .toSet() ??
                        <String>{};

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      physics: const AppleBouncingScrollPhysics(),
                      itemCount: reviewers.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, indent: 64, color: kOrgHairline),
                      itemBuilder: (ctx, index) {
                        final member = reviewers[index];
                        final isAssigned =
                            assignedReviewerIds.contains(member.userId);
                        final isPending =
                            _pendingToggles.contains(member.userId);

                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: isAssigned
                                ? kOrgPrimary
                                : const Color(0xFFE3E2E7),
                            child: Text(
                              member.fullName.isNotEmpty
                                  ? member.fullName[0].toUpperCase()
                                  : 'R',
                              style: orgLabel(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isAssigned ? Colors.white : kOrgTextPrimary,
                              ),
                            ),
                          ),
                          title: Text(
                            member.fullName,
                            style: orgHeadline(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: kOrgTextPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Academic Evaluator • ${member.assignedScholarshipCount} current assignments',
                            style: orgBody(
                              fontSize: 11.5,
                              color: kOrgTextSecondary,
                            ),
                          ),
                          trailing: isPending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Switch.adaptive(
                                  value: isAssigned,
                                  activeTrackColor: kOrgPrimary,
                                  onChanged: (val) {
                                    _toggleAssignment(
                                      member: member,
                                      isCurrentlyAssigned: isAssigned,
                                    );
                                  },
                                ),
                        );
                      },
                    );
                  },
                ),
              ),

              const Divider(height: 1, color: kOrgHairline),

              // Bottom Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kOrgPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                      ),
                      child: Text(
                        'Done',
                        style: orgLabel(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
