// ─────────────────────────────────────────────────────────────────────────────
// lib/models/institution.dart
// ─────────────────────────────────────────────────────────────────────────────

class InstitutionMedia {
  final String source;
  final String type;

  const InstitutionMedia({required this.source, required this.type});

  factory InstitutionMedia.fromJson(Map<String, dynamic> json) =>
      InstitutionMedia(
        source: json['source'] as String? ?? '',
        type:   json['type']   as String? ?? '',
      );
}

class Institution {
  final String id;
  final String name;
  final String fullName;
  final String environmentType;
  final List<String> features;
  final List<InstitutionMedia> media;
  final List<String> countryCodes;

  const Institution({
    required this.id,
    required this.name,
    required this.fullName,
    required this.environmentType,
    required this.features,
    required this.media,
    required this.countryCodes,
  });

  factory Institution.fromJson(Map<String, dynamic> json) {
    final rawMedia = (json['media'] as List<dynamic>? ?? []);
    final rawCountries = (json['countries'] as List<dynamic>? ?? []);

    return Institution(
      id:              json['id']              as String? ?? '',
      name:            json['name']            as String? ?? '',
      fullName:        json['fullName']        as String? ?? '',
      environmentType: json['environmentType'] as String? ?? '',
      features: (json['features'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      media: rawMedia
          .map((e) => InstitutionMedia.fromJson(e as Map<String, dynamic>))
          .toList(),
      countryCodes: rawCountries
          .map((e) => (e as Map<String, dynamic>)['countryCode2'] as String? ?? '')
          .where((c) => c.isNotEmpty)
          .toList(),
    );
  }

  /// Returns the icon URL from media list, or empty string.
  String get iconUrl {
    try {
      return media.firstWhere((m) => m.type == 'icon').source;
    } catch (_) {
      return media.isNotEmpty ? media.first.source : '';
    }
  }

  bool get isSandbox => environmentType.toUpperCase().contains('SANDBOX');

  bool supportsAccounts() =>
      features.contains('ACCOUNTS') || features.contains('ACCOUNT_BALANCES');
}
