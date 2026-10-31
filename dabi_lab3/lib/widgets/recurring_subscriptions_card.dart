// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/recurring_subscriptions_card.dart
//
// Recurring Bills & Subscriptions Card:
// Horizontal scrollable carousel displaying `recurringTransactions` detected
// by the backend so the user can see their active monthly subscriptions and
// upcoming fixed bills.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/pfm_models.dart';
import '../screens/pfm_dashboard_screen.dart';

class RecurringSubscriptionsCard extends StatelessWidget {
  final List<RecurringTransaction> recurringTransactions;
  final String currency;

  const RecurringSubscriptionsCard({
    super.key,
    required this.recurringTransactions,
    required this.currency,
  });

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

  String _formatCurrency(double amount, String code) {
    return NumberFormat.currency(
      symbol: _currencySymbol(code),
      decimalDigits: 2,
    ).format(amount);
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

  @override
  Widget build(BuildContext context) {
    final totalEstimatedMonthly = recurringTransactions.fold<double>(
      0.0,
      (sum, item) => sum + item.averageAmount,
    );

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recurring Bills & Subscriptions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Auto-detected fixed bills & repeated merchant charges',
                      style: TextStyle(color: Color(0xFF8B949E), fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFBC8CFF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFBC8CFF).withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'Avg: ${_formatCurrency(totalEstimatedMonthly, currency)}',
                  style: const TextStyle(
                    color: Color(0xFFBC8CFF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recurringTransactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'No recurring subscriptions or fixed bills detected yet.',
                  style: TextStyle(color: Color(0xFF8B949E), fontSize: 13),
                ),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recurringTransactions.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = recurringTransactions[index];
                  final catColor = PfmDashboardScreen.categoryColor(item.category);
                  final catIcon = PfmDashboardScreen.categoryIcon(item.category);

                  return Container(
                    width: 220,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D1117),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: catColor.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(catIcon, color: catColor, size: 18),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.merchantName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF21262D),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item.occurrenceCount}x',
                                style: const TextStyle(
                                  color: Color(0xFF8B949E),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatCurrency(item.averageAmount, item.currency),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Last: ${_formatCurrency(item.lastAmount, item.currency)} • ${_formatDate(item.lastDate)}',
                              style: const TextStyle(
                                color: Color(0xFF8B949E),
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.category,
                                  style: TextStyle(
                                    color: catColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              item.frequency,
                              style: const TextStyle(
                                color: Color(0xFF8B949E),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
