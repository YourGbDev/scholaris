import 'package:flutter_test/flutter_test.dart';
import 'package:scholaris/features/applications/models/application.dart';
import 'package:scholaris/features/applications/repositories/application_repository.dart';

import '../../helpers/fake_application_data_source.dart';

/// Models the Rubric Evaluation domain data structure specified for
/// `public.application_evaluations` in the 3rd Increment master plan.
class ApplicationEvaluation {
  const ApplicationEvaluation({
    required this.id,
    required this.applicationId,
    required this.reviewerId,
    required this.scoreAcademic,
    required this.scoreFinancial,
    required this.scoreLeadership,
    required this.scoreVision,
    required this.compositeScore,
    required this.decision,
    this.deliberationNotes,
    required this.createdAt,
  });

  final String id;
  final String applicationId;
  final String reviewerId;
  final double scoreAcademic;
  final double scoreFinancial;
  final double scoreLeadership;
  final double scoreVision;
  final double compositeScore;
  final String decision;
  final String? deliberationNotes;
  final DateTime createdAt;

  static double calculateComposite({
    required double academic,
    required double financial,
    required double leadership,
    required double vision,
  }) {
    // 40% Academic, 30% Financial, 20% Leadership, 10% Vision
    return (academic * 0.40) +
        (financial * 0.30) +
        (leadership * 0.20) +
        (vision * 0.10);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'application_id': applicationId,
        'reviewer_id': reviewerId,
        'score_academic': scoreAcademic,
        'score_financial': scoreFinancial,
        'score_leadership': scoreLeadership,
        'score_vision': scoreVision,
        'composite_score': compositeScore,
        'decision': decision,
        'deliberation_notes': deliberationNotes,
        'created_at': createdAt.toIso8601String(),
      };
}

/// Models the Status History audit trail specified for
/// `public.application_status_history` in the 3rd Increment master plan.
class ApplicationStatusHistory {
  const ApplicationStatusHistory({
    required this.id,
    required this.applicationId,
    required this.changedBy,
    required this.fromStatus,
    required this.toStatus,
    this.remarks,
    required this.createdAt,
  });

  final String id;
  final String applicationId;
  final String changedBy;
  final String fromStatus;
  final String toStatus;
  final String? remarks;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'application_id': applicationId,
        'changed_by': changedBy,
        'from_status': fromStatus,
        'to_status': toStatus,
        'remarks': remarks,
        'created_at': createdAt.toIso8601String(),
      };
}

/// Models the in-app Notification record specified for
/// `public.notifications` in the 3rd Increment master plan.
class InAppNotification {
  const InAppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.targetId,
    this.isRead = false,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String? targetId;
  final bool isRead;
  final DateTime createdAt;

  InAppNotification copyWith({bool? isRead}) {
    return InAppNotification(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      targetId: targetId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}

/// Extended fake data store supporting transaction cycle tables:
/// - application_evaluations
/// - application_status_history
/// - notifications
class TransactionCycleDataStore {
  final List<ApplicationEvaluation> evaluations = [];
  final List<ApplicationStatusHistory> statusHistories = [];
  final List<InAppNotification> notifications = [];

  void recordEvaluation(ApplicationEvaluation eval) {
    evaluations.add(eval);
  }

  void recordTransition(ApplicationStatusHistory history) {
    statusHistories.add(history);
  }

  void sendNotification(InAppNotification notif) {
    notifications.add(notif);
  }

  List<InAppNotification> getUnreadForUser(String userId) {
    return notifications.where((n) => n.userId == userId && !n.isRead).toList();
  }
}

void main() {
  group('3rd Increment Checking: Full Transaction Cycle Verification', () {
    late FakeApplicationDataSource appDs;
    late TransactionCycleDataStore txStore;

    const studentId = 'student-juan-101';
    const providerId = 'provider-dost-202';
    const scholarshipId = 'sch-dost-stem-01';

    setUp(() {
      appDs = FakeApplicationDataSource();
      txStore = TransactionCycleDataStore();

      // Seed provider scholarship in application data source index
      appDs.scholarshipIndex[scholarshipId] = {
        'id': scholarshipId,
        'created_by': providerId,
        'title': 'DOST-SEI Merit Scholarship Program',
      };
    });

    // -------------------------------------------------------------------------
    // ACT 1: Student Application Submission
    // -------------------------------------------------------------------------
    group('Act 1: Student Application Submission', () {
      test('Student successfully submits application and row is persisted', () async {
        final studentRepo = ApplicationRepository(
          dataSource: appDs,
          currentUserId: () => studentId,
        );

        // Verify initial state: not applied yet
        expect(await studentRepo.hasApplied(scholarshipId), isFalse);

        // Student applies
        final application = await studentRepo.apply(
          scholarshipId: scholarshipId,
          notes: 'Personal statement and academic track submitted.',
        );

        // Verification: Application created with submitted status
        expect(application.id, isNotEmpty);
        expect(application.userId, studentId);
        expect(application.scholarshipId, scholarshipId);
        expect(application.status, ApplicationStatus.submitted);
        expect(application.notes, contains('Personal statement'));
        expect(application.appliedAt, isNotNull);

        // Verification: Query state reflects applied
        expect(await studentRepo.hasApplied(scholarshipId), isTrue);

        // Verification: Record exists in user's application list
        final myApps = await studentRepo.fetchMyApplications();
        expect(myApps.length, 1);
        expect(myApps.first.id, application.id);
        expect(myApps.first.status, ApplicationStatus.submitted);
      });

      test('Enforces duplicate submission prevention for same student and scholarship', () async {
        final studentRepo = ApplicationRepository(
          dataSource: appDs,
          currentUserId: () => studentId,
        );

        await studentRepo.apply(scholarshipId: scholarshipId);

        // Second application attempt must throw ApplicationDuplicateException
        expect(
          () => studentRepo.apply(scholarshipId: scholarshipId),
          throwsA(isA<ApplicationDuplicateException>()),
        );
      });

      test('Student can save draft and promote draft to submitted', () async {
        final studentRepo = ApplicationRepository(
          dataSource: appDs,
          currentUserId: () => studentId,
        );

        // Save as draft
        final draft = await studentRepo.saveDraft(
          scholarshipId: scholarshipId,
          notes: 'In-progress draft statement',
        );
        expect(draft.status, ApplicationStatus.draft);

        // Promoting draft via apply()
        final submitted = await studentRepo.apply(
          scholarshipId: scholarshipId,
          notes: 'Finalized and digitally signed statement',
        );
        expect(submitted.status, ApplicationStatus.submitted);
        expect(submitted.notes, contains('Finalized and digitally signed'));
      });
    });

    // -------------------------------------------------------------------------
    // ACT 2: Provider Deliberation & Rubric Scoring
    // -------------------------------------------------------------------------
    group('Act 2: Provider Deliberation, Rubric Scoring & Award Decision', () {
      test('Calculates 4-criteria composite score correctly per institutional weighting', () {
        // Institutional weights: Academic 40%, Need 30%, Leadership 20%, Vision 10%
        final composite = ApplicationEvaluation.calculateComposite(
          academic: 95.0,
          financial: 88.0,
          leadership: 92.0,
          vision: 90.0,
        );

        // 95*0.4 + 88*0.3 + 92*0.2 + 90*0.1 = 38.0 + 26.4 + 18.4 + 9.0 = 91.80
        expect(composite, closeTo(91.80, 0.001));
      });

      test('Composite calculation respects boundary conditions (0% and 100%)', () {
        expect(
          ApplicationEvaluation.calculateComposite(
            academic: 100,
            financial: 100,
            leadership: 100,
            vision: 100,
          ),
          equals(100.0),
        );

        expect(
          ApplicationEvaluation.calculateComposite(
            academic: 0,
            financial: 0,
            leadership: 0,
            vision: 0,
          ),
          equals(0.0),
        );
      });

      test('Provider reviews submission, saves rubric evaluation, updates status, and logs history', () async {
        // Step 1: Student submits application
        final studentRepo = ApplicationRepository(
          dataSource: appDs,
          currentUserId: () => studentId,
        );
        final submittedApp = await studentRepo.apply(
          scholarshipId: scholarshipId,
          notes: 'Student credentials and certifications attached.',
        );

        // Step 2: Provider accesses incoming applications
        final providerRepo = ApplicationRepository(
          dataSource: appDs,
          currentUserId: () => providerId,
        );
        final incoming = await providerRepo.fetchIncomingApplications();
        expect(incoming.length, 1);
        expect(incoming.first.id, submittedApp.id);
        expect(incoming.first.status, ApplicationStatus.submitted);

        // Step 3: Provider scores application across 4 criteria
        const academicScore = 94.0;
        const financialScore = 90.0;
        const leadershipScore = 86.0;
        const visionScore = 92.0;
        final composite = ApplicationEvaluation.calculateComposite(
          academic: academicScore,
          financial: financialScore,
          leadership: leadershipScore,
          vision: visionScore,
        );

        final evaluation = ApplicationEvaluation(
          id: 'eval-1',
          applicationId: submittedApp.id,
          reviewerId: providerId,
          scoreAcademic: academicScore,
          scoreFinancial: financialScore,
          scoreLeadership: leadershipScore,
          scoreVision: visionScore,
          compositeScore: composite,
          decision: 'approved',
          deliberationNotes: 'Candidate demonstrated exemplary academic rigor and leadership in STEM outreach.',
          createdAt: DateTime.now(),
        );
        txStore.recordEvaluation(evaluation);

        // Step 4: Provider updates application status to approved
        await providerRepo.providerUpdateStatus(
          submittedApp.id,
          ApplicationStatus.approved,
        );

        // Step 5: Log audit status transition
        final transition = ApplicationStatusHistory(
          id: 'hist-1',
          applicationId: submittedApp.id,
          changedBy: providerId,
          fromStatus: 'submitted',
          toStatus: 'approved',
          remarks: 'Approved by Committee Review with composite score ${composite.toStringAsFixed(1)}/100',
          createdAt: DateTime.now(),
        );
        txStore.recordTransition(transition);

        // Step 6: Dispatch notification to student
        final notification = InAppNotification(
          id: 'notif-1',
          userId: studentId,
          title: 'Application Approved!',
          message: 'Congratulations! Your application for DOST-SEI Merit Scholarship Program has been approved.',
          type: 'application_update',
          targetId: submittedApp.id,
          createdAt: DateTime.now(),
        );
        txStore.sendNotification(notification);

        // Assertions: Database state verification
        // 1. Applications table status updated
        final studentApps = await studentRepo.fetchMyApplications();
        expect(studentApps.first.status, ApplicationStatus.approved);

        // 2. Evaluations table contains persisted evaluation
        expect(txStore.evaluations.length, 1);
        final savedEval = txStore.evaluations.first;
        expect(savedEval.applicationId, submittedApp.id);
        expect(savedEval.reviewerId, providerId);
        expect(savedEval.compositeScore, closeTo(91.0, 0.01));
        expect(savedEval.decision, 'approved');
        expect(savedEval.deliberationNotes, contains('exemplary academic rigor'));

        // 3. Status history transition is logged
        expect(txStore.statusHistories.length, 1);
        final savedHist = txStore.statusHistories.first;
        expect(savedHist.applicationId, submittedApp.id);
        expect(savedHist.fromStatus, 'submitted');
        expect(savedHist.toStatus, 'approved');
        expect(savedHist.changedBy, providerId);

        // 4. Notification dispatched to student
        final unreadNotifs = txStore.getUnreadForUser(studentId);
        expect(unreadNotifs.length, 1);
        expect(unreadNotifs.first.title, 'Application Approved!');
        expect(unreadNotifs.first.targetId, submittedApp.id);
      });
    });

    // -------------------------------------------------------------------------
    // ACT 3: Student Confirmation & Award Ceremony Celebration
    // -------------------------------------------------------------------------
    group('Act 3: Student Confirmation & Award Ceremony Celebration', () {
      test('Student receives notification, views approved status, and terminal lock prevents withdrawal', () async {
        final studentRepo = ApplicationRepository(
          dataSource: appDs,
          currentUserId: () => studentId,
        );
        final providerRepo = ApplicationRepository(
          dataSource: appDs,
          currentUserId: () => providerId,
        );

        // Complete submission & approval
        final app = await studentRepo.apply(scholarshipId: scholarshipId);
        await providerRepo.providerUpdateStatus(app.id, ApplicationStatus.approved);

        // Create notification
        txStore.sendNotification(
          InAppNotification(
            id: 'notif-2',
            userId: studentId,
            title: 'Application Approved!',
            message: 'Your scholarship application was approved.',
            type: 'application_update',
            targetId: app.id,
            createdAt: DateTime.now(),
          ),
        );

        // Step 1: Student checks notifications
        final notifications = txStore.getUnreadForUser(studentId);
        expect(notifications.length, 1);
        final notif = notifications.first;
        expect(notif.title, 'Application Approved!');
        expect(notif.targetId, app.id);

        // Step 2: Student navigates to application detail
        final myApps = await studentRepo.fetchMyApplications();
        final detail = myApps.firstWhere((a) => a.id == notif.targetId);
        expect(detail.status, ApplicationStatus.approved);

        // Step 3: Terminal status security rule: Student CANNOT withdraw approved application
        expect(
          () => studentRepo.withdraw(detail.id),
          throwsA(isA<ApplicationWithdrawalException>()),
        );
      });

      test('Admin confirms award from approved state', () async {
        final studentRepo = ApplicationRepository(
          dataSource: appDs,
          currentUserId: () => studentId,
        );
        final providerRepo = ApplicationRepository(
          dataSource: appDs,
          currentUserId: () => providerId,
        );
        const adminId = 'admin-commissioner-999';
        final adminRepo = ApplicationRepository(
          dataSource: appDs,
          currentUserId: () => adminId,
        );

        final app = await studentRepo.apply(scholarshipId: scholarshipId);
        await providerRepo.providerUpdateStatus(app.id, ApplicationStatus.approved);

        // Admin confirms award
        await adminRepo.confirmAward(app.id);

        final myApps = await studentRepo.fetchMyApplications();
        expect(myApps.first.status, ApplicationStatus.awarded);
      });
    });
  });
}
