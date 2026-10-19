// lib/features/schools/models/school.dart
//
// Domain model representing a higher education institution in the master
// public.schools catalog.

class School {
  const School({
    required this.id,
    required this.name,
    required this.normalizedName,
    this.aliases = const [],
    this.isCurated = true,
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String name;
  final String normalizedName;
  final List<String> aliases;
  final bool isCurated;
  final String? createdBy;
  final DateTime? createdAt;

  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      id: json['id'] as String,
      name: json['name'] as String,
      normalizedName: json['normalized_name'] as String? ?? '',
      aliases: (json['aliases'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      isCurated: json['is_curated'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'normalized_name': normalizedName,
        'aliases': aliases,
        'is_curated': isCurated,
        if (createdBy != null) 'created_by': createdBy,
        if (createdAt != null) 'created_at': createdAt?.toUtc().toIso8601String(),
      };

  School copyWith({
    String? id,
    String? name,
    String? normalizedName,
    List<String>? aliases,
    bool? isCurated,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return School(
      id: id ?? this.id,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      aliases: aliases ?? this.aliases,
      isCurated: isCurated ?? this.isCurated,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is School && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'School(id: $id, name: $name, isCurated: $isCurated)';
}
