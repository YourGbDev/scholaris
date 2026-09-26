// lib/features/provider/models/provider_verification.dart
//
// Data model for Provider Verification and Accreditation submissions.
// Adheres strictly to Philippine regulatory compliance (RA 10173, SEC, BIR).

class ProviderVerification {
  const ProviderVerification({
    this.id,
    required this.userId,
    required this.providerType, // 'individual' | 'organization'
    this.status = 'pending', // 'pending' | 'approved' | 'rejected'
    this.submittedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNote,
    // Individual fields
    this.fullName,
    this.email,
    this.phone,
    this.govIdType,
    this.govIdNumber,
    this.govIdFrontPath,
    this.selfieIdPath,
    this.sourceOfFunds,
    this.monthlyGivingBudget,
    this.tin,
    this.dataConsent = false,
    // Organization fields
    this.orgName,
    this.orgType,
    this.regNumber,
    this.repName,
    this.repPosition,
    this.repEmail,
    this.repPhone,
    this.secCertPath,
    this.bir2303Path,
    this.boardResolutionPath,
  });

  final String? id;
  final String userId;
  final String providerType;
  final String status;
  final DateTime? submittedAt;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNote;

  // Individual fields
  final String? fullName;
  final String? email;
  final String? phone;
  final String? govIdType;
  final String? govIdNumber;
  final String? govIdFrontPath;
  final String? selfieIdPath;
  final String? sourceOfFunds;
  final String? monthlyGivingBudget;
  final String? tin;
  final bool dataConsent;

  // Organization fields
  final String? orgName;
  final String? orgType;
  final String? regNumber;
  final String? repName;
  final String? repPosition;
  final String? repEmail;
  final String? repPhone;
  final String? secCertPath;
  final String? bir2303Path;
  final String? boardResolutionPath;

  /// Display name across Individual vs Organization
  String get displayName {
    if (providerType == 'individual') {
      return fullName?.trim().isNotEmpty == true
          ? fullName!.trim()
          : 'Individual Provider';
    }
    return orgName?.trim().isNotEmpty == true
        ? orgName!.trim()
        : 'Organization Provider';
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  /// Masked ID number showing only the last 4 characters for security & privacy.
  /// Never reveals the full ID number or TIN in logs/UI.
  String get maskedIdNumber {
    final raw = (govIdNumber?.trim() ?? regNumber?.trim() ?? '').replaceAll(RegExp(r'[\s\-]'), '');
    if (raw.isEmpty) return '—';
    if (raw.length <= 4) return '•••• $raw';
    final last4 = raw.substring(raw.length - 4);
    return '•••• •••• $last4';
  }

  /// Masked TIN (last 4)
  String get maskedTin {
    final clean = (tin?.trim() ?? '').replaceAll(RegExp(r'[\s\-]'), '');
    if (clean.isEmpty) return '—';
    if (clean.length <= 4) return '•••• $clean';
    return '•••-•••-${clean.substring(clean.length - 4)}';
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'provider_type': providerType,
      'status': status,
      'submitted_at': (submittedAt ?? DateTime.now()).toIso8601String(),
      if (reviewedBy != null) 'reviewed_by': reviewedBy,
      if (reviewedAt != null) 'reviewed_at': reviewedAt!.toIso8601String(),
      if (reviewNote != null) 'review_note': reviewNote,
      // Individual fields
      if (fullName != null) 'full_name': fullName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (govIdType != null) 'gov_id_type': govIdType,
      if (govIdNumber != null) 'gov_id_number': govIdNumber,
      if (govIdFrontPath != null) 'gov_id_front_path': govIdFrontPath,
      if (selfieIdPath != null) 'selfie_id_path': selfieIdPath,
      if (sourceOfFunds != null) 'source_of_funds': sourceOfFunds,
      if (monthlyGivingBudget != null)
        'monthly_giving_budget': monthlyGivingBudget,
      if (tin != null) 'tin': tin,
      'data_consent': dataConsent,
      // Organization fields
      if (orgName != null) 'org_name': orgName,
      if (orgType != null) 'org_type': orgType,
      if (regNumber != null) 'reg_number': regNumber,
      if (repName != null) 'rep_name': repName,
      if (repPosition != null) 'rep_position': repPosition,
      if (repEmail != null) 'rep_email': repEmail,
      if (repPhone != null) 'rep_phone': repPhone,
      if (secCertPath != null) 'sec_cert_path': secCertPath,
      if (bir2303Path != null) 'bir_2303_path': bir2303Path,
      if (boardResolutionPath != null)
        'board_resolution_path': boardResolutionPath,
    };
  }

  factory ProviderVerification.fromJson(Map<String, dynamic> json) {
    return ProviderVerification(
      id: json['id'] as String?,
      userId: json['user_id'] as String? ?? '',
      providerType: json['provider_type'] as String? ?? 'individual',
      status: json['status'] as String? ?? 'pending',
      submittedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'] as String)
          : null,
      reviewNote: json['review_note'] as String?,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      govIdType: json['gov_id_type'] as String?,
      govIdNumber: json['gov_id_number'] as String?,
      govIdFrontPath: json['gov_id_front_path'] as String?,
      selfieIdPath: json['selfie_id_path'] as String?,
      sourceOfFunds: json['source_of_funds'] as String?,
      monthlyGivingBudget: json['monthly_giving_budget'] as String?,
      tin: json['tin'] as String?,
      dataConsent: json['data_consent'] as bool? ?? false,
      orgName: json['org_name'] as String?,
      orgType: json['org_type'] as String?,
      regNumber: json['reg_number'] as String?,
      repName: json['rep_name'] as String?,
      repPosition: json['rep_position'] as String?,
      repEmail: json['rep_email'] as String?,
      repPhone: json['rep_phone'] as String?,
      secCertPath: json['sec_cert_path'] as String?,
      bir2303Path: json['bir_2303_path'] as String?,
      boardResolutionPath: json['board_resolution_path'] as String?,
    );
  }

  ProviderVerification copyWith({
    String? id,
    String? userId,
    String? providerType,
    String? status,
    DateTime? submittedAt,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? reviewNote,
    String? fullName,
    String? email,
    String? phone,
    String? govIdType,
    String? govIdNumber,
    String? govIdFrontPath,
    String? selfieIdPath,
    String? sourceOfFunds,
    String? monthlyGivingBudget,
    String? tin,
    bool? dataConsent,
    String? orgName,
    String? orgType,
    String? regNumber,
    String? repName,
    String? repPosition,
    String? repEmail,
    String? repPhone,
    String? secCertPath,
    String? bir2303Path,
    String? boardResolutionPath,
  }) {
    return ProviderVerification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      providerType: providerType ?? this.providerType,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNote: reviewNote ?? this.reviewNote,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      govIdType: govIdType ?? this.govIdType,
      govIdNumber: govIdNumber ?? this.govIdNumber,
      govIdFrontPath: govIdFrontPath ?? this.govIdFrontPath,
      selfieIdPath: selfieIdPath ?? this.selfieIdPath,
      sourceOfFunds: sourceOfFunds ?? this.sourceOfFunds,
      monthlyGivingBudget: monthlyGivingBudget ?? this.monthlyGivingBudget,
      tin: tin ?? this.tin,
      dataConsent: dataConsent ?? this.dataConsent,
      orgName: orgName ?? this.orgName,
      orgType: orgType ?? this.orgType,
      regNumber: regNumber ?? this.regNumber,
      repName: repName ?? this.repName,
      repPosition: repPosition ?? this.repPosition,
      repEmail: repEmail ?? this.repEmail,
      repPhone: repPhone ?? this.repPhone,
      secCertPath: secCertPath ?? this.secCertPath,
      bir2303Path: bir2303Path ?? this.bir2303Path,
      boardResolutionPath: boardResolutionPath ?? this.boardResolutionPath,
    );
  }
}
