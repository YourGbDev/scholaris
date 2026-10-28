import 'package:scholaris/features/provider/repositories/support_concern_repository.dart';

class PreviewSupportConcerns implements SupportConcernRepository {
  final rows = <Map<String, dynamic>>[];
  @override
  Future<List<Map<String, dynamic>>> load(String? application) async => [
    for (final r in rows)
      if (application == null || r['application_id'] == application)
        Map<String, dynamic>.from(r),
  ];
  @override
  Future<void> report(
    String application,
    String category,
    String description,
  ) async {
    rows.add({
      'id': 'concern-${rows.length}',
      'application_id': application,
      'reporter_id': 'stud-1',
      'category': category,
      'description': description,
      'status': 'open',
    });
  }

  @override
  Future<void> review(String id, String status, String note) async {
    final row = rows.firstWhere((r) => r['id'] == id);
    row['status'] = status;
    row['resolution_note'] = note;
  }
}
