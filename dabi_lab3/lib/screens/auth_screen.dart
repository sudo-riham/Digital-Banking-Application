// ─────────────────────────────────────────────────────────────────────────────
// lib/screens/auth_screen.dart
//
// Steps 2, 3, and 4 of User Journey:
// 2. Starts AIS consent: POST /account-auth-requests with callback = dabi-lab3://callback
// 3. Opens authorisationUrl so the user completes SCA at the bank (Modelo: mits / mits)
// 4. Handles the deep-link redirect back into the app, reads the query parameters
//    (one-time-token / consent / consentToken), exchanges the one-time token if needed,
//    and navigates to AccountsScreen.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/institution.dart';
import '../services/yapily_service.dart';
import 'accounts_screen.dart';

class AuthScreen extends StatefulWidget {
  final Institution institution;
  final YapilyService service;

  const AuthScreen({
    super.key,
    required this.institution,
    required this.service,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSub;
  Timer? _relayPollTimer;

  bool _creatingRequest = true;
  bool _exchangingToken = false;
  String? _authorisationUrl;
  String? _pendingConsentId;
  String? _error;
  bool _handledCallback = false;

  @override
  void initState() {
    super.initState();
    _listenForDeepLink();
    _initiateAuthRequest();
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    _relayPollTimer?.cancel();
    super.dispose();
  }

  void _listenForDeepLink() {
    _linkSub = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _onDeepLinkReceived(uri);
      },
      onError: (Object err) {
        // Ignore stream errors on web/desktop where relay polling is active
      },
    );

    _relayPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_handledCallback || !mounted) return;
      final relayedUri = await widget.service.checkPendingCallback();
      if (relayedUri != null && mounted && !_handledCallback) {
        _onDeepLinkReceived(relayedUri);
        return;
      }

      // Also check if the bank redirect to Yapily completed the consent
      final cid = _pendingConsentId;
      if (cid != null && cid.isNotEmpty) {
        try {
          final info = await widget.service.getConsent(cid);
          if (info.status.toUpperCase() == 'AUTHORIZED' &&
              info.consentToken != null &&
              info.consentToken!.isNotEmpty &&
              mounted &&
              !_handledCallback) {
            _handledCallback = true;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => AccountsScreen(
                  institution: widget.institution,
                  service: widget.service,
                  consentToken: info.consentToken!,
                  consentId: info.id.isNotEmpty ? info.id : cid,
                ),
              ),
            );
          }
        } catch (_) {
          // Still awaiting authorization at the bank
        }
      }
    });
  }

  Future<void> _initiateAuthRequest() async {
    setState(() {
      _creatingRequest = true;
      _error = null;
    });

    try {
      final result = await widget.service.startAccountAuthRequest(
        institutionId: widget.institution.id,
        useOneTimeToken: true,
      );

      final authUrl = result['authorisationUrl']!;
      final consentId = result['consentId'] ?? '';

      if (!mounted) return;
      setState(() {
        _authorisationUrl = authUrl;
        _pendingConsentId = consentId;
        _creatingRequest = false;
      });

      await _openBankSca(authUrl);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _creatingRequest = false;
      });
    }
  }

  Future<void> _openBankSca(String urlString) async {
    final uri = Uri.parse(urlString);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      setState(() {
        _error = 'Could not launch browser for URL: $urlString';
      });
    }
  }

  Future<void> _onDeepLinkReceived(Uri uri) async {
    if (_handledCallback) return;
    if (uri.scheme != 'dabi-lab3') return;

    _handledCallback = true;

    final params = uri.queryParameters;
    final errorParam = params['error'] ?? params['errorMessage'];
    if (errorParam != null && errorParam.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _error = 'Bank authorization failed or was cancelled: $errorParam';
        _handledCallback = false;
      });
      return;
    }

    // Check for one-time-token OR direct consent token in callback query
    final oneTimeToken = params['one-time-token'] ?? params['oneTimeToken'];
    final directConsentToken = params['consent'] ?? params['consentToken'];
    final callbackConsentId =
        params['consent-id'] ?? params['consentId'] ?? _pendingConsentId ?? '';

    if (oneTimeToken != null && oneTimeToken.isNotEmpty) {
      setState(() {
        _exchangingToken = true;
        _error = null;
      });

      try {
        final exchanged = await widget.service.exchangeOneTimeToken(oneTimeToken);
        if (!mounted) return;

        final resolvedConsentId = exchanged.consentId.isNotEmpty
            ? exchanged.consentId
            : callbackConsentId;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AccountsScreen(
              institution: widget.institution,
              service: widget.service,
              consentToken: exchanged.consentToken,
              consentId: resolvedConsentId,
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _error = 'Failed to exchange one-time token: $e';
          _exchangingToken = false;
          _handledCallback = false;
        });
      }
    } else if (directConsentToken != null && directConsentToken.isNotEmpty) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AccountsScreen(
            institution: widget.institution,
            service: widget.service,
            consentToken: directConsentToken,
            consentId: callbackConsentId,
          ),
        ),
      );
    } else {
      if (!mounted) return;
      setState(() {
        _error = 'Callback received (${uri.toString()}), '
            'but no consent or one-time-token query parameter was found.';
        _handledCallback = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.institution.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Step 2 of 3 • Bank SCA & Consent Redirect',
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 11),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: _buildStatusCard(),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_creatingRequest) {
      return _statusContainer(
        icon: const CircularProgressIndicator(color: Color(0xFF58A6FF)),
        title: 'Creating Account Auth Request…',
        subtitle:
            'Calling POST /account-auth-requests with callback:\n${YapilyService.callbackUrl}',
      );
    }

    if (_exchangingToken) {
      return _statusContainer(
        icon: const CircularProgressIndicator(color: Color(0xFF3FB950)),
        title: 'Redirect Received! Exchanging Token…',
        subtitle:
            'Exchanging one-time-token via POST /consent-one-time-token on local proxy…',
      );
    }

    if (_error != null) {
      return _statusContainer(
        icon: const Icon(Icons.error_outline_rounded, color: Color(0xFFF85149), size: 48),
        title: 'Authorization Error',
        subtitle: _error!,
        actions: [
          FilledButton.icon(
            onPressed: _initiateAuthRequest,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      );
    }

    return _statusContainer(
      icon: const Icon(Icons.open_in_browser_rounded, color: Color(0xFF58A6FF), size: 52),
      title: 'Complete SCA in Your Browser',
      subtitle:
          '1. Authenticate with ${widget.institution.name} (Modelo Sandbox: mits / mits).\n'
          '2. Approve the AISP account access request.\n'
          '3. The browser will redirect back to ${YapilyService.callbackUrl} automatically.',
      actions: [
        if (_authorisationUrl != null)
          FilledButton.icon(
            onPressed: () => _openBankSca(_authorisationUrl!),
            icon: const Icon(Icons.launch_rounded),
            label: const Text('Re-open Bank Login Page'),
          ),
      ],
    );
  }

  Widget _statusContainer({
    required Widget icon,
    required String title,
    required String subtitle,
    List<Widget> actions = const [],
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF8B949E),
              fontSize: 13,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 20),
            ...actions,
          ],
        ],
      ),
    );
  }
}
