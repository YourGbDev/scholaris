import '../../features/applications/models/application.dart';
import '../../features/scholarships/models/scholarship.dart';

bool isOpenSafetyReport(Map<String, dynamic> row) =>
    !['resolved', 'dismissed'].contains(row['status']);
bool isUrgentSafetyReport(Map<String, dynamic> row) =>
    isOpenSafetyReport(row) &&
    [
      'unsafe_request',
      'unsafe_meetup',
      'harassment',
      'threat',
    ].contains(row['category']);
DateTime? safetyReportDate(Map<String, dynamic> row) =>
    DateTime.tryParse(row['created_at']?.toString() ?? '');

class SafetyReportGroup {
  SafetyReportGroup({
    required this.key,
    required this.scholarshipId,
    required this.providerId,
    required this.scholarshipTitle,
    required this.providerName,
    required this.reports,
    required DateTime now,
  }) {
    final open = reports.where(isOpenSafetyReport).toList();
    totalReports = reports.length;
    distinctReporters = _people(reports);
    openReports = open.length;
    recentDistinctReporters = _people(
      reports.where((r) {
        final date = safetyReportDate(r);
        return date != null &&
            !date.isAfter(now) &&
            !date.isBefore(now.subtract(const Duration(hours: 24)));
      }),
    );
    urgent = open.any(isUrgentSafetyReport);
    final dates = open.map(safetyReportDate).whereType<DateTime>().toList()
      ..sort();
    oldestOpenAt = dates.firstOrNull;
  }
  final String key;
  final String? scholarshipId, providerId;
  final String scholarshipTitle, providerName;
  final List<Map<String, dynamic>> reports;
  late final int totalReports,
      distinctReporters,
      openReports,
      recentDistinctReporters;
  late final bool urgent;
  late final DateTime? oldestOpenAt;
  static int _people(Iterable<Map<String, dynamic>> rows) => rows
      .map((r) => r['reporter_id'])
      .whereType<String>()
      .where((id) => id.trim().isNotEmpty)
      .toSet()
      .length;
}

List<SafetyReportGroup> groupSafetyReports(
  List<Map<String, dynamic>> concerns,
  List<Application> applications,
  List<Scholarship> scholarships, {
  DateTime? now,
}) {
  final apps = {for (final a in applications) a.id: a};
  final programs = {for (final s in scholarships) s.id: s};
  final grouped = <String, List<Map<String, dynamic>>>{};
  final contexts = <String, Scholarship?>{};
  final scholarshipIds = <String, String?>{};
  final fallbackTitles = <String, String?>{};
  final fallbackProviders = <String, String?>{};

  for (var i = 0; i < concerns.length; i++) {
    final row = concerns[i];
    if (row['category'] == 'payment_record_correction') continue;
    final appId = row['application_id']?.toString();
    final app = apps[appId];
    final sId = row['scholarship_id']?.toString() ?? app?.scholarshipId;
    final program = programs[sId];

    final key = program != null
        ? 'scholarship:${program.id}'
        : sId != null && sId.isNotEmpty
            ? 'scholarship:$sId'
            : appId != null && appId.isNotEmpty
                ? 'application:$appId'
                : 'report:${row['id'] ?? i}:$i';

    grouped.putIfAbsent(key, () => []).add(row);
    contexts[key] = program;
    scholarshipIds[key] = sId;

    if (row['scholarship_title'] != null) {
      fallbackTitles[key] = row['scholarship_title'] as String;
    }
    if (row['provider_name'] != null) {
      fallbackProviders[key] = row['provider_name'] as String;
    }
  }

  final groups = grouped.entries.map((e) {
    final s = contexts[e.key];
    final fTitle = fallbackTitles[e.key];
    final fProvider = fallbackProviders[e.key];
    final firstRow = e.value.isNotEmpty ? e.value.first : <String, dynamic>{};

    return SafetyReportGroup(
      key: e.key,
      scholarshipId: scholarshipIds[e.key],
      providerId: s?.createdBy ?? firstRow['provider_id']?.toString(),
      scholarshipTitle: s?.title ?? fTitle ?? 'Scholarship context unavailable',
      providerName: s?.provider ?? fProvider ?? 'Provider context unavailable',
      reports: List.unmodifiable(e.value),
      now: now ?? DateTime.now(),
    );
  }).toList();

  groups.sort((a, b) {
    final priority = (b.urgent ? 1 : 0).compareTo(a.urgent ? 1 : 0);
    if (priority != 0) return priority;
    return (a.oldestOpenAt ?? DateTime(9999)).compareTo(
      b.oldestOpenAt ?? DateTime(9999),
    );
  });
  return groups;
}
