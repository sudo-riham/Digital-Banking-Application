// ─────────────────────────────────────────────────────────────────────────────
// lib/models/pfm_models.dart
//
// Strongly-typed Dart models for the PFM Enrichment & Analytics API:
//   - PfmSummary
//   - MonthlyCashFlow
//   - CategorySpend
//   - RecurringTransaction
//   - EnrichedTransaction
// ─────────────────────────────────────────────────────────────────────────────

class MonthlyCashFlow {
  final double totalInflow;
  final double totalOutflow;
  final double netSavings;

  const MonthlyCashFlow({
    required this.totalInflow,
    required this.totalOutflow,
    required this.netSavings,
  });

  factory MonthlyCashFlow.fromJson(Map<String, dynamic> json) {
    return MonthlyCashFlow(
      totalInflow: (json['totalInflow'] as num?)?.toDouble() ?? 0.0,
      totalOutflow: (json['totalOutflow'] as num?)?.toDouble() ?? 0.0,
      netSavings: (json['netSavings'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'totalInflow': totalInflow,
        'totalOutflow': totalOutflow,
        'netSavings': netSavings,
      };
}

class CategorySpend {
  final String category;
  final double totalSpent;
  final double percentage;
  final int transactionCount;

  const CategorySpend({
    required this.category,
    required this.totalSpent,
    required this.percentage,
    required this.transactionCount,
  });

  factory CategorySpend.fromJson(Map<String, dynamic> json) {
    return CategorySpend(
      category: json['category'] as String? ?? 'Uncategorized',
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      transactionCount: (json['transactionCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'totalSpent': totalSpent,
        'percentage': percentage,
        'transactionCount': transactionCount,
      };
}

class RecurringTransaction {
  final String merchantName;
  final String category;
  final double averageAmount;
  final double lastAmount;
  final String currency;
  final int occurrenceCount;
  final String frequency;
  final String lastDate;

  const RecurringTransaction({
    required this.merchantName,
    required this.category,
    required this.averageAmount,
    required this.lastAmount,
    required this.currency,
    required this.occurrenceCount,
    required this.frequency,
    required this.lastDate,
  });

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      merchantName: json['merchantName'] as String? ?? 'Subscription',
      category: json['category'] as String? ?? 'Subscriptions',
      averageAmount: (json['averageAmount'] as num?)?.toDouble() ?? 0.0,
      lastAmount: (json['lastAmount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'GBP',
      occurrenceCount: (json['occurrenceCount'] as num?)?.toInt() ?? 1,
      frequency: json['frequency'] as String? ?? 'Recurring',
      lastDate: json['lastDate'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'merchantName': merchantName,
        'category': category,
        'averageAmount': averageAmount,
        'lastAmount': lastAmount,
        'currency': currency,
        'occurrenceCount': occurrenceCount,
        'frequency': frequency,
        'lastDate': lastDate,
      };
}

class EnrichedTransaction {
  final String id;
  final String accountId;
  final String accountName;
  final String date;
  final String description;
  final String merchantName;
  final double amount;
  final String currency;
  final bool isCredit;
  final String status;
  final String pfmCategory;

  const EnrichedTransaction({
    required this.id,
    required this.accountId,
    required this.accountName,
    required this.date,
    required this.description,
    required this.merchantName,
    required this.amount,
    required this.currency,
    required this.isCredit,
    required this.status,
    required this.pfmCategory,
  });

  factory EnrichedTransaction.fromJson(Map<String, dynamic> json) {
    final amountVal = (json['amount'] as num?)?.toDouble() ?? 0.0;
    return EnrichedTransaction(
      id: json['id'] as String? ?? '',
      accountId: json['accountId'] as String? ?? '',
      accountName: json['accountName'] as String? ?? 'Account',
      date: json['date'] as String? ?? '',
      description: json['description'] as String? ?? 'Transaction',
      merchantName: json['merchantName'] as String? ??
          (json['description'] as String? ?? 'Transaction'),
      amount: amountVal,
      currency: json['currency'] as String? ?? 'GBP',
      isCredit: json['isCredit'] as bool? ?? (amountVal > 0),
      status: json['status'] as String? ?? 'BOOKED',
      pfmCategory: json['pfmCategory'] as String? ?? 'Uncategorized',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'accountName': accountName,
        'date': date,
        'description': description,
        'merchantName': merchantName,
        'amount': amount,
        'currency': currency,
        'isCredit': isCredit,
        'status': status,
        'pfmCategory': pfmCategory,
      };
}

class PfmSummary {
  final String currency;
  final double totalNetWorth;
  final int accountsCount;
  final MonthlyCashFlow monthlyCashFlow;
  final List<CategorySpend> categoryBreakdown;
  final Map<String, double> categoryBudgets;
  final List<RecurringTransaction> recurringTransactions;
  final List<EnrichedTransaction> enrichedTransactions;

  const PfmSummary({
    required this.currency,
    required this.totalNetWorth,
    required this.accountsCount,
    required this.monthlyCashFlow,
    required this.categoryBreakdown,
    this.categoryBudgets = const {},
    required this.recurringTransactions,
    required this.enrichedTransactions,
  });

  factory PfmSummary.fromJson(Map<String, dynamic> json) {
    final cashFlowJson =
        json['monthlyCashFlow'] as Map<String, dynamic>? ?? const {};
    final breakdownList = json['categoryBreakdown'] as List<dynamic>? ?? const [];
    final rawBudgets =
        json['categoryBudgets'] as Map<String, dynamic>? ?? const {};
    final recurringList =
        json['recurringTransactions'] as List<dynamic>? ?? const [];
    final txList = json['enrichedTransactions'] as List<dynamic>? ?? const [];

    final parsedBudgets = <String, double>{};
    rawBudgets.forEach((key, value) {
      if (value is num) {
        parsedBudgets[key] = value.toDouble();
      }
    });

    return PfmSummary(
      currency: json['currency'] as String? ?? 'GBP',
      totalNetWorth: (json['totalNetWorth'] as num?)?.toDouble() ?? 0.0,
      accountsCount: (json['accountsCount'] as num?)?.toInt() ?? 0,
      monthlyCashFlow: MonthlyCashFlow.fromJson(cashFlowJson),
      categoryBreakdown: breakdownList
          .map((e) => CategorySpend.fromJson(e as Map<String, dynamic>))
          .toList(),
      categoryBudgets: parsedBudgets,
      recurringTransactions: recurringList
          .map((e) => RecurringTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      enrichedTransactions: txList
          .map((e) => EnrichedTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'currency': currency,
        'totalNetWorth': totalNetWorth,
        'accountsCount': accountsCount,
        'monthlyCashFlow': monthlyCashFlow.toJson(),
        'categoryBreakdown': categoryBreakdown.map((e) => e.toJson()).toList(),
        'categoryBudgets': categoryBudgets,
        'recurringTransactions':
            recurringTransactions.map((e) => e.toJson()).toList(),
        'enrichedTransactions':
            enrichedTransactions.map((e) => e.toJson()).toList(),
      };
}
