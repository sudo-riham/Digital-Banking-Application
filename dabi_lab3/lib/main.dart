// ─────────────────────────────────────────────────────────────────────────────
// lib/main.dart
//
// Entry point for DABI504 Lab 3 (Yapily Open Banking AISP Mobile App).
// Starts on InstitutionsScreen (Step 1 of User Journey) and also handles
// cold-start deep links if the OS relaunches the app on dabi-lab3://callback.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import 'models/institution.dart';
import 'screens/accounts_screen.dart';
import 'screens/institutions_screen.dart';
import 'services/yapily_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DabiLab3App());
}

class DabiLab3App extends StatefulWidget {
  const DabiLab3App({super.key});

  @override
  State<DabiLab3App> createState() => _DabiLab3AppState();
}

class _DabiLab3AppState extends State<DabiLab3App> {
  final YapilyService _service = YapilyService();
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _checkInitialDeepLink();
  }

  /// Handles cold-start deep link if the OS killed the app while in browser SCA
  Future<void> _checkInitialDeepLink() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null && initialUri.scheme == 'dabi-lab3') {
        final params = initialUri.queryParameters;
        final oneTimeToken = params['one-time-token'] ?? params['oneTimeToken'];
        final directConsent = params['consent'] ?? params['consentToken'];
        final consentId = params['consent-id'] ?? params['consentId'] ?? '';

        const fallbackInst = Institution(
          id: 'modelo-sandbox',
          name: 'Connected Bank',
          fullName: 'Connected Bank',
          environmentType: 'SANDBOX',
          features: ['ACCOUNTS', 'ACCOUNT_TRANSACTIONS'],
          media: [],
          countryCodes: [],
        );

        if (oneTimeToken != null && oneTimeToken.isNotEmpty) {
          final exchanged = await _service.exchangeOneTimeToken(oneTimeToken);
          _navKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => AccountsScreen(
                institution: fallbackInst,
                service: _service,
                consentToken: exchanged.consentToken,
                consentId: exchanged.consentId.isNotEmpty
                    ? exchanged.consentId
                    : consentId,
              ),
            ),
          );
        } else if (directConsent != null && directConsent.isNotEmpty) {
          _navKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => AccountsScreen(
                institution: fallbackInst,
                service: _service,
                consentToken: directConsent,
                consentId: consentId,
              ),
            ),
          );
        }
      }
    } catch (_) {
      // Ignore cold-start link errors; AuthScreen handles active stream links
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DABI504 Lab 3 – Yapily AISP',
      navigatorKey: _navKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D1117),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF58A6FF),
          secondary: Color(0xFF3FB950),
          surface: Color(0xFF161B22),
        ),
        useMaterial3: true,
      ),
      home: InstitutionsScreen(service: _service),
    );
  }
}
