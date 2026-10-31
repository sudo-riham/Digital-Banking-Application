// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/category_budgets_card.dart
//
// Monthly Budgets Widget:
// - Allows the user to set a monthly spending limit for each PFM category
//   (persisted locally via shared_preferences AND synced with backend /api/pfm/budgets).
// - Renders LinearProgressIndicator bars comparing actual CategorySpend from
//   Yapily against the user's target limit.
// - Color-codes progress bars:
//   * Green (<75%)
//   * Amber/Orange (75%–99% warning)
//   * Red (>=100% over budget)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pfm_models.dart';
import '../screens/pfm_dashboard_screen.dart';
import '../services/yapily_service.dart';

class CategoryBudgetsCard extends StatefulWidget {
  final List<CategorySpend> categoryBreakdown;
  final Map<String, double> initialBackendBudgets;
  final String currency;
  final YapilyService service;

  const CategoryBudgetsCard({
    super.key,
    required this.categoryBreakdown,
    required this.initialBackendBudgets,
    required this.currency,
    required this.service,
  });

  @override
  State<CategoryBudgetsCard> createState() => _CategoryBudgetsCardState();
}

class _CategoryBudgetsCardState extends State<CategoryBudgetsCard> {
  static const String _prefsKey = 'pfm_category_budgets_v1';

  static const Map<String, double> _defaultLimits = {
    'Housing & Utilities': 15000.0,
    'Groceries': 3200.0,
    'Dining': 1500.0,
    'Subscriptions': 250.0,
    'Transport': 1200.0,
    'Shopping': 500.0,
    'Uncategorized': 50000.0,
  };

  late Map<String, double> _limits;

  @override
  void initState() {
    super.initState();
    _limits = {
      ..._defaultLimits,
      ...widget.initialBackendBudgets,
    };
    _loadLocalPreferences();
  }

  Future<void> _loadLocalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_prefsKey);
      if (savedJson != null && savedJson.isNotEmpty) {
        final decoded = jsonDecode(savedJson) as Map<String, dynamic>;
        final loaded = <String, double>{};
        decoded.forEach((key, val) {
          if (val is num) {
            loaded[key] = val.toDouble();
          }
        });
        if (mounted && loaded.isNotEmpty) {
          setState(() {
            _limits = {..._limits, ...loaded};
          });
        }
      }
    } catch (_) {
      // Fallback to backend/default limits
    }
  }

  Future<void> _saveBudgetLimit(String category, double newLimit) async {
    final updated = {..._limits, category: newLimit};
    setState(() {
      _limits = updated;
    });

    // 1. Persist locally in SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(updated));
    } catch (_) {}

    // 2. Sync with backend /api/pfm/budgets
    try {
      await widget.service.updatePfmBudgets(updated);
    } catch (_) {}
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

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      symbol: _currencySymbol(widget.currency),
      decimalDigits: 2,
    ).format(amount);
  }

  /// Progress bar color rule:
  /// - Green (<75%)
  /// - Amber/Orange (75%–99% warning)
  /// - Red (>=100% over budget)
  Color _budgetStatusColor(double ratioPercent) {
    if (ratioPercent >= 100.0) {
      return const Color(0xFFF85149); // Red: Over Budget
    } else if (ratioPercent >= 75.0) {
      return const Color(0xFFF0883E); // Amber/Orange: 75%–99% Warning
    }
    return const Color(0xFF3FB950); // Green: <75% On Track
  }

  String _budgetStatusLabel(double ratioPercent) {
    if (ratioPercent >= 100.0) {
      return 'Over Budget';
    } else if (ratioPercent >= 75.0) {
      return 'Near Limit';
    }
    return 'On Track';
  }

  void _showEditBudgetDialog(String category, double currentLimit) {
    final controller = TextEditingController(
      text: currentLimit.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF30363D)),
        ),
        title: Row(
          children: [
            Icon(
              PfmDashboardScreen.categoryIcon(category),
              color: PfmDashboardScreen.categoryColor(category),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Set $category Budget',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your monthly spending target (${widget.currency}):',
              style: const TextStyle(color: Color(0xFF8B949E), fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: InputDecoration(
                prefixText: _currencySymbol(widget.currency),
                prefixStyle: const TextStyle(
                  color: Color(0xFF58A6FF),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: const Color(0xFF0D1117),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF30363D)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              if (parsed != null && parsed > 0) {
                _saveBudgetLimit(category, parsed);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save Target'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Budgets',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tap any category to customize your monthly spending limit',
                    style: TextStyle(color: Color(0xFF8B949E), fontSize: 11),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLegendDot(const Color(0xFF3FB950), '<75%'),
                  const SizedBox(width: 8),
                  _buildLegendDot(const Color(0xFFF0883E), '75-99%'),
                  const SizedBox(width: 8),
                  _buildLegendDot(const Color(0xFFF85149), '≥100%'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.categoryBreakdown.map((item) {
            final targetLimit = _limits[item.category] ?? 1000.0;
            final ratioPercent =
                targetLimit > 0 ? (item.totalSpent / targetLimit) * 100.0 : 0.0;
            final clampedProgress = (ratioPercent / 100.0).clamp(0.0, 1.0);
            final statusColor = _budgetStatusColor(ratioPercent);
            final statusLabel = _budgetStatusLabel(ratioPercent);

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showEditBudgetDialog(item.category, targetLimit),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PfmDashboardScreen.categoryIcon(item.category),
                          color: PfmDashboardScreen.categoryColor(item.category),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.45),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${ratioPercent.toStringAsFixed(0)}% • $statusLabel',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF8B949E),
                          size: 15,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: clampedProgress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFF21262D),
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Spent: ${_formatCurrency(item.totalSpent)}',
                          style: const TextStyle(
                            color: Color(0xFFC9D1D9),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Limit: ${_formatCurrency(targetLimit)}',
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
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8B949E), fontSize: 10),
        ),
      ],
    );
  }
}
