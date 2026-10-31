// ─────────────────────────────────────────────────────────────────────────────
// lib/screens/accounts_screen.dart
//
// Step 5 of User Journey:
// Displays:
// - Consent lease details from GET /consents/{consentId}
//   (authorizedAt, expiresAt, reconfirmBy)
// - Account details from GET /accounts (with header consent: <consentToken>)
// - Transactions for the selected account from GET /accounts/{id}/transactions
//
// Strictly AISP only — no payment endpoints or Pay buttons.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/consent_info.dart';
import '../models/institution.dart';
import '../models/transaction.dart';
import '../services/yapily_service.dart';
import '../widgets/account_card.dart';
import '../widgets/consent_badge.dart';
import 'pfm_dashboard_screen.dart';

class AccountsScreen extends StatefulWidget {
  final Institution institution;
  final YapilyService service;
  final String consentToken;
  final String consentId;

  const AccountsScreen({
    super.key,
    required this.institution,
    required this.service,
    required this.consentToken,
    required this.consentId,
  });

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  bool _loading = true;
  String? _error;

  ConsentInfo? _consentInfo;
  List<Account> _accounts = [];
  Account? _selectedAccount;

  bool _loadingTransactions = false;
  List<Transaction> _transactions = [];
  String? _transactionsError;

  @override
  void initState() {
    super.initState();
    _loadAccountAndConsentData();
  }

  Future<void> _loadAccountAndConsentData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final accountsFuture = widget.service.getAccounts(widget.consentToken);
      Future<ConsentInfo>? consentFuture;
      if (widget.consentId.isNotEmpty) {
        consentFuture = widget.service.getConsent(widget.consentId);
      }

      final accounts = await accountsFuture;
      ConsentInfo? consent;
      if (consentFuture != null) {
        try {
          consent = await consentFuture;
        } catch (_) {
          // Fallback if consentId lookup fails
          consent = ConsentInfo(
            id: widget.consentId,
            status: 'AUTHORIZED',
            institutionId: widget.institution.id,
            featureScope: const ['ACCOUNTS', 'ACCOUNT_TRANSACTIONS'],
          );
        }
      } else {
        consent = ConsentInfo(
          id: 'From Callback Token',
          status: 'AUTHORIZED',
          institutionId: widget.institution.id,
          featureScope: const ['ACCOUNTS', 'ACCOUNT_TRANSACTIONS'],
        );
      }

      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _consentInfo = consent;
        _selectedAccount = accounts.isNotEmpty ? accounts.first : null;
        _loading = false;
      });

      if (_selectedAccount != null) {
        _loadTransactions(_selectedAccount!.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadTransactions(String accountId) async {
    setState(() {
      _loadingTransactions = true;
      _transactionsError = null;
    });

    try {
      final txns = await widget.service.getTransactions(
        accountId,
        widget.consentToken,
      );
      if (!mounted) return;
      setState(() {
        _transactions = txns;
        _loadingTransactions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _transactionsError = e.toString();
        _loadingTransactions = false;
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
              '${widget.institution.name} • Accounts',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Step 3 of 3 • GET /accounts & GET /consents/{id}',
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PfmDashboardScreen(
                    service: widget.service,
                    consentToken: widget.consentToken,
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.pie_chart_rounded,
              color: Color(0xFF3FB950),
              size: 18,
            ),
            label: const Text(
              'PFM Dashboard',
              style: TextStyle(
                color: Color(0xFF3FB950),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Refresh Data',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF58A6FF)),
            onPressed: _loadAccountAndConsentData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF58A6FF)),
            SizedBox(height: 14),
            Text(
              'Loading accounts & consent lease from Yapily…',
              style: TextStyle(color: Color(0xFF8B949E)),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFF85149), size: 48),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadAccountAndConsentData,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Prominent CTA Banner to open the PFM Analytics Dashboard
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D213B), Color(0xFF161B22)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF58A6FF).withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.insights_rounded, color: Color(0xFF58A6FF), size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PFM Financial Analytics Ready',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'View Net Worth, Category Donut Chart, Cash Flow Bar Chart & Enriched Feed.',
                      style: TextStyle(color: Color(0xFF8B949E), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PfmDashboardScreen(
                        service: widget.service,
                        consentToken: widget.consentToken,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.pie_chart_rounded, size: 16),
                label: const Text('Open PFM'),
              ),
            ],
          ),
        ),
        if (_consentInfo != null) ...[
          ConsentBadge(consent: _consentInfo!),
          const SizedBox(height: 20),
        ],
        const Text(
          'Authorized Accounts',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        if (_accounts.isEmpty)
          const Text(
            'No accounts returned for this consent.',
            style: TextStyle(color: Color(0xFF8B949E)),
          )
        else
          ..._accounts.map(
            (acc) => AccountCard(
              account: acc,
              isSelected: _selectedAccount?.id == acc.id,
              onTap: () {
                setState(() => _selectedAccount = acc);
                _loadTransactions(acc.id);
              },
            ),
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions (AISP Read-Only)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_selectedAccount != null)
              Text(
                _selectedAccount!.nickname.isNotEmpty
                    ? _selectedAccount!.nickname
                    : _selectedAccount!.id,
                style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _buildTransactionsSection(),
      ],
    );
  }

  Widget _buildTransactionsSection() {
    if (_loadingTransactions) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF58A6FF)),
        ),
      );
    }

    if (_transactionsError != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Could not load transactions: $_transactionsError',
          style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF161B22),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF30363D)),
        ),
        child: const Text(
          'No transactions found for this account.',
          style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: _transactions.map((tx) {
        final sign = tx.isCredit ? '+' : '';
        final amountColor =
            tx.isCredit ? const Color(0xFF3FB950) : const Color(0xFFC9D1D9);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF161B22),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF30363D)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (tx.isCredit
                          ? const Color(0xFF238636)
                          : const Color(0xFF30363D))
                      .withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  tx.isCredit
                      ? Icons.south_west_rounded
                      : Icons.north_east_rounded,
                  size: 18,
                  color: amountColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (tx.displayDate.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        tx.displayDate.split('T').first,
                        style: const TextStyle(
                          color: Color(0xFF8B949E),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$sign${tx.currency} ${tx.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: amountColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
