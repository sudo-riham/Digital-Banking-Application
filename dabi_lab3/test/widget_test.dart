import 'package:flutter_test/flutter_test.dart';
import 'package:dabi_lab3/main.dart';
import 'package:dabi_lab3/models/pfm_models.dart';

void main() {
  testWidgets('App starts on Select Your Bank screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DabiLab3App());
    expect(find.text('Select Your Bank (AISP)'), findsOneWidget);
  });

  test('PfmSummary.fromJson parses backend /api/pfm/summary payload', () {
    final sampleJson = {
      'currency': 'GBP',
      'totalNetWorth': 12500.50,
      'accountsCount': 2,
      'monthlyCashFlow': {
        'totalInflow': 4447.74,
        'totalOutflow': 1250.24,
        'netSavings': 3197.50,
      },
      'categoryBreakdown': [
        {
          'category': 'Housing & Utilities',
          'totalSpent': 479.83,
          'percentage': 38.4,
          'transactionCount': 3,
        },
        {
          'category': 'Groceries',
          'totalSpent': 73.16,
          'percentage': 5.9,
          'transactionCount': 4,
        },
      ],
      'recurringTransactions': [
        {
          'merchantName': 'OVO ENERGY',
          'category': 'Housing & Utilities',
          'averageAmount': 479.83,
          'lastAmount': 564.50,
          'currency': 'GBP',
          'occurrenceCount': 3,
          'frequency': 'Recurring',
          'lastDate': '2026-09-13T00:00:00.000Z',
        },
      ],
      'enrichedTransactions': [
        {
          'id': 'tx-1',
          'accountId': 'acc-1',
          'accountName': 'Main Account',
          'date': '2026-10-01T00:00:00.000Z',
          'description': 'TESCO',
          'merchantName': 'TESCO',
          'amount': -29.34,
          'currency': 'GBP',
          'isCredit': false,
          'status': 'BOOKED',
          'pfmCategory': 'Groceries',
        },
      ],
      'categoryBudgets': {
        'Housing & Utilities': 600.0,
        'Groceries': 350.0,
      },
    };

    final summary = PfmSummary.fromJson(sampleJson);
    expect(summary.totalNetWorth, 12500.50);
    expect(summary.monthlyCashFlow.totalInflow, 4447.74);
    expect(summary.monthlyCashFlow.totalOutflow, 1250.24);
    expect(summary.monthlyCashFlow.netSavings, 3197.50);
    expect(summary.categoryBreakdown.first.category, 'Housing & Utilities');
    expect(summary.recurringTransactions.first.merchantName, 'OVO ENERGY');
    expect(summary.enrichedTransactions.first.pfmCategory, 'Groceries');
    expect(summary.categoryBudgets['Housing & Utilities'], 600.0);
    expect(summary.categoryBudgets['Groceries'], 350.0);
  });
}
