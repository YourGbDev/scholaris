// lib/features/scholarships/models/scholarship_capacity.dart
//
// Model representing aggregate capacity accounting for a scholarship,
// derived dynamically from public.scholarship_capacities view.

class ScholarshipCapacity {
  const ScholarshipCapacity({
    required this.scholarshipId,
    this.totalSlots,
    required this.occupiedSlots,
    this.remainingSlots,
    required this.isUncapped,
  });

  final String scholarshipId;
  final int? totalSlots;
  final int occupiedSlots;
  final int? remainingSlots;
  final bool isUncapped;

  factory ScholarshipCapacity.fromJson(Map<String, dynamic> json) {
    return ScholarshipCapacity(
      scholarshipId: json['scholarship_id'] as String,
      totalSlots: json['total_slots'] != null
          ? (json['total_slots'] as num).toInt()
          : null,
      occupiedSlots: json['occupied_slots'] != null
          ? (json['occupied_slots'] as num).toInt()
          : 0,
      remainingSlots: json['remaining_slots'] != null
          ? (json['remaining_slots'] as num).toInt()
          : null,
      isUncapped: json['is_uncapped'] as bool? ?? (json['total_slots'] == null),
    );
  }

  Map<String, dynamic> toJson() => {
        'scholarship_id': scholarshipId,
        if (totalSlots != null) 'total_slots': totalSlots,
        'occupied_slots': occupiedSlots,
        if (remainingSlots != null) 'remaining_slots': remainingSlots,
        'is_uncapped': isUncapped,
      };

  /// UI presentation helper: e.g. "5 remaining" or "Uncapped" or "Fully Booked"
  String get remainingLabel {
    if (isUncapped || totalSlots == null) return 'Uncapped';
    final rem = remainingSlots ?? 0;
    if (rem <= 0) return 'Fully Booked';
    return '$rem seat${rem == 1 ? '' : 's'} remaining';
  }

  /// UI seat ratio helper: e.g. "3/10 awarded" or "3 awarded (Uncapped)"
  String get occupancyRatioLabel {
    if (isUncapped || totalSlots == null) {
      return '$occupiedSlots awarded (Uncapped)';
    }
    return '$occupiedSlots/${totalSlots!} seats filled';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScholarshipCapacity &&
          runtimeType == other.runtimeType &&
          scholarshipId == other.scholarshipId &&
          totalSlots == other.totalSlots &&
          occupiedSlots == other.occupiedSlots &&
          remainingSlots == other.remainingSlots &&
          isUncapped == other.isUncapped;

  @override
  int get hashCode => Object.hash(
        scholarshipId,
        totalSlots,
        occupiedSlots,
        remainingSlots,
        isUncapped,
      );

  @override
  String toString() =>
      'ScholarshipCapacity(id: $scholarshipId, total: $totalSlots, occupied: $occupiedSlots, remaining: $remainingSlots, uncapped: $isUncapped)';
}
