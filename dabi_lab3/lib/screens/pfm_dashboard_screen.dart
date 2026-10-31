// ─────────────────────────────────────────────────────────────────────────────
// lib/screens/pfm_dashboard_screen.dart
//
// Personal Financial Management (PFM) Dashboard Screen:
// 1. Net Worth & Cash Flow Header Card (+ Link Bank button, Inflow/Outflow pills)
// 2. Spending by Category Donut Chart (fl_chart PieChart + interactive touch + legend)
// 3. Cash Flow Bar Chart (fl_chart BarChart comparing Monthly Inflow vs. Outflow)
// 4. Enriched Transaction Feed (category icons, merchant, pfmCategory badge, date, amount)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/pfm_models.dart';
import '../services/yapily_service.dart';
import '../widgets/category_budgets_card.dart';
import '../widgets/recurring_subscriptions_card.dart';
import 'institutions_screen.dart';

class PfmDashboardScreen extends StatefulWidget {
  final YapilyService service;
  final String? consentToken;

  const PfmDashboardScreen({
    super.key,
    required this.service,
    this.consentToken,
  });

  static Color categoryColor(String category) {
    switch (category) {
      case 'Income':
        return const Color(0xFF3FB950);
      case 'Housing & Utilities':
        return const Color(0xFF58A6FF);
      case 'Groceries':
        return const Color(0xFF2EA043);
      case 'Dining':
        return const Color(0xFFF0883E);
      case 'Subscriptions':
        return const Color(0xFFBC8CFF);
      case 'Transport':
        return const Color(0xFF2DD4BF);
      case 'Shopping':
        return const Color(0xFFF778BA);
      case 'Uncategorized':
      default:
        return const Color(0xFF8B949E);
    }
  }

  static IconData categoryIcon(String category) {
    switch (category) {
      case 'Income':
        return Icons.trending_up_rounded;
      case 'Housing & Utilities':
        return Icons.home_work_rounded;
      case 'Groceries':
        return Icons.local_grocery_store_rounded;
      case 'Dining':
        return Icons.restaurant_rounded;
      case 'Subscriptions':
        return Icons.autorenew_rounded;
      case 'Transport':
        return Icons.directions_transit_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Uncategorized':
      default:
        return Icons.receipt_long_rounded;
    }
  }

  @override
  State<PfmDashboardScreen> createState() => _PfmDashboardScreenState();
}

class _PfmDashboardScreenState extends State<PfmDashboardScreen> {
  bool _loading = true;
  String? _error;
  PfmSummary? _summary;

  int _touchedPieIndex = -1;
  String _selectedCategoryFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadPfmSummary();
  }

  Future<void> _loadPfmSummary() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await widget.service.getPfmSummary(
        consentToken: widget.consentToken,
      );
      if (!mounted) return;
      setState(() {
        _summary = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openLinkBankFlow() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InstitutionsScreen(service: widget.service),
      ),
    );
  }

  String _currencySymbol(String code) {
    switch (code.toUpperCase()) {
      case 'GBP':
        return '£';
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      default:
        return '$code ';
    }
  }

  String _formatCurrency(double amount, String currencyCode) {
    final fmt = NumberFormat.currency(
      symbol: _currencySymbol(currencyCode),
      decimalDigits: 2,
    );
    return fmt.format(amount);
  }

  String _formatDate(String rawDate) {
    if (rawDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return rawDate.split('T').first;
    }
  }

  static Color categoryColor(String category) {
    switch (category) {
      case 'Income':
        return const Color(0xFF3FB950);
      case 'Housing & Utilities':
        return const Color(0xFF58A6FF);
      case 'Groceries':
        return const Color(0xFF2EA043);
      case 'Dining':
        return const Color(0xFFF0883E);
      case 'Subscriptions':
        return const Color(0xFFBC8CFF);
      case 'Transport':
        return const Color(0xFF2DD4BF);
      case 'Shopping':
        return const Color(0xFFF778BA);
      case 'Uncategorized':
      default:
        return const Color(0xFF8B949E);
    }
  }

  static IconData categoryIcon(String category) {
    switch (category) {
      case 'Income':
        return Icons.trending_up_rounded;
      case 'Housing & Utilities':
        return Icons.home_work_rounded;
      case 'Groceries':
        return Icons.local_grocery_store_rounded;
      case 'Dining':
        return Icons.restaurant_rounded;
      case 'Subscriptions':
        return Icons.autorenew_rounded;
      case 'Transport':
        return Icons.directions_transit_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Uncategorized':
      default:
        return Icons.receipt_long_rounded;
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PFM Financial Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Open Banking Enrichment & Analytics • GET /api/pfm/summary',
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Link Bank Account',
            icon: const Icon(Icons.add_card_rounded, color: Color(0xFF3FB950)),
            onPressed: _openLinkBankFlow,
          ),
          IconButton(
            tooltip: 'Refresh PFM Summary',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF58A6FF)),
            onPressed: _loadPfmSummary,
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
            SizedBox(height: 16),
            Text(
              'Aggregating accounts & enriching transactions…',
              style: TextStyle(color: Color(0xFF8B949E), fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF161B22),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF30363D)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  color: Color(0xFFF85149),
                  size: 48,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Unable to Load PFM Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.icon(
                      onPressed: _loadPfmSummary,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _openLinkBankFlow,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('+ Link Bank'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final summary = _summary;
    if (summary == null ||
        (summary.accountsCount == 0 && summary.enrichedTransactions.isEmpty)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Color(0xFF58A6FF),
                size: 56,
              ),
              const SizedBox(height: 14),
              const Text(
                'No Connected Bank Data Yet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Link a bank via Yapily Open Banking to view your net worth, spending breakdown, and enriched transactions.',
                style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _openLinkBankFlow,
                icon: const Icon(Icons.add_rounded),
                label: const Text('+ Link Bank'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredTransactions = _selectedCategoryFilter == 'All'
        ? summary.enrichedTransactions
        : summary.enrichedTransactions
            .where((t) => t.pfmCategory == _selectedCategoryFilter)
            .toList();

    return RefreshIndicator(
      color: const Color(0xFF58A6FF),
      backgroundColor: const Color(0xFF161B22),
      onRefresh: _loadPfmSummary,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. Net Worth & Cash Flow Header Card
                _buildNetWorthHeaderCard(summary),
                const SizedBox(height: 20),

                // 2. Spending by Category Donut Chart
                _buildCategoryDonutCard(summary),
                const SizedBox(height: 20),

                // 3. Monthly Category Budgets (Interactive Progress Bars)
                CategoryBudgetsCard(
                  categoryBreakdown: summary.categoryBreakdown,
                  initialBackendBudgets: summary.categoryBudgets,
                  currency: summary.currency,
                  service: widget.service,
                ),
                const SizedBox(height: 20),

                // 4. Cash Flow Bar Chart
                _buildCashFlowBarCard(summary),
                const SizedBox(height: 20),

                // 5. Recurring Bills & Subscriptions Carousel
                RecurringSubscriptionsCard(
                  recurringTransactions: summary.recurringTransactions,
                  currency: summary.currency,
                ),
                const SizedBox(height: 20),

                // 6. Enriched Transaction Feed Header + Filter Chips
                _buildTransactionsHeader(summary, filteredTransactions.length),
                const SizedBox(height: 12),

                // 5. Enriched Transaction Items
                if (filteredTransactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF161B22),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF30363D)),
                    ),
                    child: const Text(
                      'No transactions in this category.',
                      style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...filteredTransactions
                      .take(40)
                      .map((tx) => _buildEnrichedTransactionTile(tx)),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 1. Net Worth & Cash Flow Header Card ──────────────────────────────────
  Widget _buildNetWorthHeaderCard(PfmSummary summary) {
    final netSavings = summary.monthlyCashFlow.netSavings;
    final isPositiveSavings = netSavings >= 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF161B22), Color(0xFF0D213B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF30363D), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'TOTAL NET WORTH',
                        style: TextStyle(
                          color: Color(0xFF8B949E),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF58A6FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${summary.accountsCount} ${summary.accountsCount == 1 ? "Account" : "Accounts"}',
                          style: const TextStyle(
                            color: Color(0xFF58A6FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(summary.totalNetWorth, summary.currency),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _openLinkBankFlow,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF238636),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  '+ Link Bank',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Net savings badge
          Row(
            children: [
              Icon(
                isPositiveSavings
                    ? Icons.check_circle_outline_rounded
                    : Icons.info_outline_rounded,
                size: 15,
                color: isPositiveSavings
                    ? const Color(0xFF3FB950)
                    : const Color(0xFFD29922),
              ),
              const SizedBox(width: 6),
              Text(
                'Net Cash Flow: ${_formatCurrency(netSavings, summary.currency)}',
                style: TextStyle(
                  color: isPositiveSavings
                      ? const Color(0xFF3FB950)
                      : const Color(0xFFD29922),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Monthly Inflow (green) vs Monthly Outflow (red) Summary Pills
          Row(
            children: [
              Expanded(
                child: _buildCashFlowPill(
                  label: 'Monthly Inflow',
                  amount: _formatCurrency(
                    summary.monthlyCashFlow.totalInflow,
                    summary.currency,
                  ),
                  color: const Color(0xFF3FB950),
                  icon: Icons.south_west_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCashFlowPill(
                  label: 'Monthly Outflow',
                  amount: _formatCurrency(
                    summary.monthlyCashFlow.totalOutflow,
                    summary.currency,
                  ),
                  color: const Color(0xFFF85149),
                  icon: Icons.north_east_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowPill({
    required String label,
    required String amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF8B949E),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  amount,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. Spending by Category Donut Chart (fl_chart PieChart) ───────────────
  Widget _buildCategoryDonutCard(PfmSummary summary) {
    final activeCategories = summary.categoryBreakdown
        .where((c) => c.totalSpent > 0)
        .toList();

    final touchedCategory = (_touchedPieIndex >= 0 &&
            _touchedPieIndex < activeCategories.length)
        ? activeCategories[_touchedPieIndex]
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending by Category',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Tap slice to inspect',
                style: TextStyle(color: Color(0xFF8B949E), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (activeCategories.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No spending transactions recorded.',
                  style: TextStyle(color: Color(0xFF8B949E)),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 210,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedPieIndex = -1;
                              return;
                            }
                            _touchedPieIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 3,
                      centerSpaceRadius: 56,
                      sections: List.generate(activeCategories.length, (i) {
                        final item = activeCategories[i];
                        final isTouched = i == _touchedPieIndex;
                        final color = categoryColor(item.category);

                        return PieChartSectionData(
                          color: color,
                          value: item.totalSpent,
                          title: item.percentage >= 5.0
                              ? '${item.percentage.toStringAsFixed(1)}%'
                              : '',
                          radius: isTouched ? 52.0 : 42.0,
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          badgeWidget: isTouched
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D1117),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: color, width: 1.5),
                                  ),
                                  child: Text(
                                    '${item.category}: ${_formatCurrency(item.totalSpent, summary.currency)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                          badgePositionPercentageOffset: 1.35,
                        );
                      }),
                    ),
                  ),
                  // Center label inside Donut
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        touchedCategory != null
                            ? touchedCategory.category
                            : 'Total Outflow',
                        style: const TextStyle(
                          color: Color(0xFF8B949E),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        touchedCategory != null
                            ? _formatCurrency(
                                touchedCategory.totalSpent,
                                summary.currency,
                              )
                            : _formatCurrency(
                                summary.monthlyCashFlow.totalOutflow,
                                summary.currency,
                              ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (touchedCategory != null)
                        Text(
                          '${touchedCategory.percentage.toStringAsFixed(1)}% (${touchedCategory.transactionCount} txns)',
                          style: TextStyle(
                            color: categoryColor(touchedCategory.category),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF30363D), height: 1),
            const SizedBox(height: 12),
            // Legend showing each category's color, name, count, percentage, and amount
            ...summary.categoryBreakdown.map((item) {
              final color = categoryColor(item.category);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${item.category} (${item.transactionCount})',
                        style: const TextStyle(
                          color: Color(0xFFC9D1D9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${item.percentage.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 95,
                      child: Text(
                        _formatCurrency(item.totalSpent, summary.currency),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ─── 3. Cash Flow Bar Chart (fl_chart BarChart) ────────────────────────────
  Widget _buildCashFlowBarCard(PfmSummary summary) {
    final inflow = summary.monthlyCashFlow.totalInflow;
    final outflow = summary.monthlyCashFlow.totalOutflow;
    final maxY = math.max(inflow, outflow) * 1.25;
    final safeMaxY = maxY <= 0 ? 100.0 : maxY;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Cash Flow (Inflow vs. Outflow)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Compares total incoming credits against outgoing debits across connected accounts.',
            style: TextStyle(color: Color(0xFF8B949E), fontSize: 12),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceEvenly,
                maxY: safeMaxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF21262D),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label =
                          group.x == 0 ? 'Monthly Inflow' : 'Monthly Outflow';
                      return BarTooltipItem(
                        '$label\n${_formatCurrency(rod.toY, summary.currency)}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 56,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        final compact = NumberFormat.compactCurrency(
                          symbol: _currencySymbol(summary.currency),
                          decimalDigits: 0,
                        ).format(value);
                        return Text(
                          compact,
                          style: const TextStyle(
                            color: Color(0xFF8B949E),
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final isInflow = value.toInt() == 0;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            isInflow ? 'Monthly Inflow' : 'Monthly Outflow',
                            style: TextStyle(
                              color: isInflow
                                  ? const Color(0xFF3FB950)
                                  : const Color(0xFFF85149),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFF30363D),
                    strokeWidth: 0.8,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: inflow,
                        color: const Color(0xFF3FB950),
                        width: 44,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: outflow,
                        color: const Color(0xFFF85149),
                        width: 44,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 4. Enriched Transaction Feed ──────────────────────────────────────────
  Widget _buildTransactionsHeader(PfmSummary summary, int count) {
    final categories = <String>[
      'All',
      'Income',
      'Housing & Utilities',
      'Groceries',
      'Dining',
      'Subscriptions',
      'Transport',
      'Shopping',
      'Uncategorized',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Enriched Transaction Feed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$count transactions',
              style: const TextStyle(color: Color(0xFF8B949E), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final isSelected = _selectedCategoryFilter == cat;
              final chipColor =
                  cat == 'All' ? const Color(0xFF58A6FF) : categoryColor(cat);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedCategoryFilter = cat);
                  },
                  selectedColor: chipColor.withValues(alpha: 0.25),
                  backgroundColor: const Color(0xFF161B22),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF8B949E),
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(
                    color: isSelected ? chipColor : const Color(0xFF30363D),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEnrichedTransactionTile(EnrichedTransaction tx) {
    final catColor = categoryColor(tx.pfmCategory);
    final catIcon = categoryIcon(tx.pfmCategory);
    final amountColor =
        tx.isCredit ? const Color(0xFF3FB950) : Colors.white;
    final formattedAbs = _formatCurrency(tx.amount.abs(), tx.currency);
    final signedAmountText = tx.isCredit ? '+$formattedAbs' : '-$formattedAbs';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          // Category Icon Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(catIcon, color: catColor, size: 20),
          ),
          const SizedBox(width: 12),
          // Merchant, Category Chip Badge & Date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.merchantName.isNotEmpty ? tx.merchantName : tx.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Assigned pfmCategory Chip Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: catColor.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        tx.pfmCategory,
                        style: TextStyle(
                          color: catColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(tx.date),
                      style: const TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Formatted Amount
          Text(
            signedAmountText,
            style: TextStyle(
              color: amountColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
