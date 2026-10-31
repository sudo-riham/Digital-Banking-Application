// ─────────────────────────────────────────────────────────────────────────────
// lib/services/yapily_service.dart
//
// Calls the local Node.js proxy server.
// NO Yapily Application ID or Secret exists anywhere in this client!
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/institution.dart';
import '../models/account.dart';
import '../models/consent_info.dart';
import '../models/transaction.dart';
import '../models/pfm_models.dart';

class TokenExchangeResult {
  final String consentId;
  final String consentToken;
  final String status;
  final String institutionId;
  final String? authorizedAt;
  final String? expiresAt;
  final String? reconfirmBy;

  const TokenExchangeResult({
    required this.consentId,
    required this.consentToken,
    required this.status,
    required this.institutionId,
    this.authorizedAt,
    this.expiresAt,
    this.reconfirmBy,
  });
}

class YapilyService {
  /// Default user ID from the DABI Lab 3 Yapily sandbox environment
  static const String applicationUserId = 'dabi-lab3';

  /// Deep-link callback registered in Yapily Console
  static const String callbackUrl = 'dabi-lab3://callback';

  /// Automatically resolves 10.0.2.2 for Android emulator or localhost for iOS/desktop.
  /// Can also be overridden in the UI if testing on a physical device over Wi-Fi.
  String? customBaseUrl;

  String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.trim().isNotEmpty) {
      return customBaseUrl!.trim();
    }
    if (kIsWeb) {
      final origin = Uri.base.origin;
      // When served from the Express server (localhost:4000, LAN IP, tunnel, or cloud host),
      // use the current browser origin so iPhones/remote devices reach the backend automatically.
      if (origin.startsWith('http') &&
          !(Uri.base.host == 'localhost' && Uri.base.port != 4000)) {
        return '$origin/proxy';
      }
      return 'http://localhost:4000/proxy';
    }
    if (Platform.isAndroid) {
      return 'http://192.168.0.117:4000/proxy';
    }
    return 'http://localhost:4000/proxy';
  }

  /// 1. GET /proxy/institutions -> GET https://api.yapily.com/institutions
  Future<List<Institution>> getInstitutions() async {
    final uri = Uri.parse('$baseUrl/institutions');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load institutions (${response.statusCode}): ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => Institution.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 2. POST /proxy/auth-request -> POST https://api.yapily.com/account-auth-requests
  /// Returns a map with `authorisationUrl` and `consentId`.
  Future<Map<String, String>> startAccountAuthRequest({
    required String institutionId,
    bool useOneTimeToken = true,
  }) async {
    final uri = Uri.parse('$baseUrl/auth-request');
    final payload = {
      'applicationUserId': applicationUserId,
      'institutionId': institutionId,
      'callback': callbackUrl,
      'oneTimeToken': useOneTimeToken,
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to create auth request (${response.statusCode}): ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body['data'] is Map<String, dynamic>)
        ? body['data'] as Map<String, dynamic>
        : body;

    final authUrl = data['authorisationUrl'] as String? ?? '';
    final consentId = data['id'] as String? ?? '';

    if (authUrl.isEmpty) {
      throw Exception('No authorisationUrl returned from Yapily.');
    }

    return {
      'authorisationUrl': authUrl,
      'consentId': consentId,
    };
  }

  /// 3. POST /proxy/exchange-token -> POST https://api.yapily.com/consent-one-time-token
  Future<TokenExchangeResult> exchangeOneTimeToken(String oneTimeToken) async {
    final uri = Uri.parse('$baseUrl/exchange-token');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'oneTimeToken': oneTimeToken}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to exchange one-time token (${response.statusCode}): ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (body['data'] is Map<String, dynamic>)
        ? body['data'] as Map<String, dynamic>
        : body;

    return TokenExchangeResult(
      consentId: data['id'] as String? ?? '',
      consentToken: data['consentToken'] as String? ?? '',
      status: data['status'] as String? ?? 'AUTHORIZED',
      institutionId: data['institutionId'] as String? ?? '',
      authorizedAt: data['authorizedAt'] as String?,
      expiresAt: data['expiresAt'] as String?,
      reconfirmBy: data['reconfirmBy'] as String?,
    );
  }

  /// 4. GET /proxy/accounts -> GET https://api.yapily.com/accounts
  Future<List<Account>> getAccounts(String consentToken) async {
    final uri = Uri.parse('$baseUrl/accounts');
    final response = await http.get(
      uri,
      headers: {'x-consent-token': consentToken},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch accounts (${response.statusCode}): ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => Account.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 5. GET /proxy/accounts/:accountId/transactions -> GET https://api.yapily.com/accounts/:id/transactions
  Future<List<Transaction>> getTransactions(
    String accountId,
    String consentToken,
  ) async {
    final uri = Uri.parse('$baseUrl/accounts/$accountId/transactions');
    final response = await http.get(
      uri,
      headers: {'x-consent-token': consentToken},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch transactions (${response.statusCode}): ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 6. GET /proxy/consent/:consentId -> GET https://api.yapily.com/consents/:consentId
  Future<ConsentInfo> getConsent(String consentId) async {
    final uri = Uri.parse('$baseUrl/consent/$consentId');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch consent details (${response.statusCode}): ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return ConsentInfo.fromJson(body);
  }

  /// 7. GET /api/pfm/summary (or /proxy/pfm/summary)
  /// Fetches the aggregated PFM Enrichment & Analytics summary across accounts.
  Future<PfmSummary> getPfmSummary({String? consentToken}) async {
    // Derive the /api/pfm/summary URL from the configured host
    final rootUrl = baseUrl.endsWith('/proxy')
        ? baseUrl.substring(0, baseUrl.length - '/proxy'.length)
        : baseUrl;
    final uri = Uri.parse('$rootUrl/api/pfm/summary');

    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (consentToken != null && consentToken.trim().isNotEmpty) {
      headers['x-consent-token'] = consentToken.trim();
    }

    final response = await http.get(uri, headers: headers);
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch PFM summary (${response.statusCode}): ${response.body}',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return PfmSummary.fromJson(body);
  }

  /// 8. PUT /api/pfm/budgets
  /// Persists updated category monthly limits to the backend.
  Future<Map<String, double>> updatePfmBudgets(
    Map<String, double> budgets,
  ) async {
    final rootUrl = baseUrl.endsWith('/proxy')
        ? baseUrl.substring(0, baseUrl.length - '/proxy'.length)
        : baseUrl;
    final uri = Uri.parse('$rootUrl/api/pfm/budgets');

    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'budgets': budgets}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to save budgets (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = body['budgets'] as Map<String, dynamic>? ?? const {};
    return raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  /// Checks if the local proxy caught a dabi-lab3://callback deep link on desktop
  Future<Uri?> checkPendingCallback() async {
    try {
      final uri = Uri.parse('$baseUrl/pending-callback');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final raw = body['uri'] as String?;
        if (raw != null && raw.isNotEmpty) {
          return Uri.tryParse(raw);
        }
      }
    } catch (_) {
      // Ignore transient polling errors
    }
    return null;
  }
}
