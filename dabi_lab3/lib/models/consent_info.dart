// ─────────────────────────────────────────────────────────────────────────────
// lib/models/consent_info.dart
// ─────────────────────────────────────────────────────────────────────────────

class ConsentInfo {
  final String id;
  final String status;
  final String institutionId;
  final String? consentToken;
  final String? createdAt;
  final String? authorizedAt;
  final String? expiresAt;
  final String? reconfirmBy;
  final List<String> featureScope;

  const ConsentInfo({
    required this.id,
    required this.status,
    required this.institutionId,
    this.consentToken,
    this.createdAt,
    this.authorizedAt,
    this.expiresAt,
    this.reconfirmBy,
    required this.featureScope,
  });

  factory ConsentInfo.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    return ConsentInfo(
      id: data['id'] as String? ?? '',
      status: data['status'] as String? ?? 'UNKNOWN',
      institutionId: data['institutionId'] as String? ?? '',
      consentToken: data['consentToken'] as String?,
      createdAt: data['createdAt'] as String?,
      authorizedAt: data['authorizedAt'] as String?,
      expiresAt: data['expiresAt'] as String?,
      reconfirmBy: data['reconfirmBy'] as String?,
      featureScope: (data['featureScope'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
