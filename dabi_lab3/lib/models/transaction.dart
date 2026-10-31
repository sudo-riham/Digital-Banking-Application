// ─────────────────────────────────────────────────────────────────────────────
// lib/models/transaction.dart
// ─────────────────────────────────────────────────────────────────────────────

class Transaction {
  final String id;
  final String? description;
  final String? transactionInformation;
  final double amount;
  final String currency;
  final String? transactionReference;
  final String status;
  final String? date;
  final String? bookingDateTime;
  final String? valueDateTime;
  final bool isCredit;
  final String? merchantName;
  final String? category;
  final String pfmCategory;

  const Transaction({
    required this.id,
    this.description,
    this.transactionInformation,
    required this.amount,
    required this.currency,
    required this.status,
    this.transactionReference,
    this.date,
    this.bookingDateTime,
    this.valueDateTime,
    required this.isCredit,
    this.merchantName,
    this.category,
    this.pfmCategory = 'Uncategorized',
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Yapily returns `amount` as a number AND `transactionAmount` as `{ amount, currency }`
    double parsedAmount = 0.0;
    String parsedCurrency = (json['currency'] as String?) ?? 'GBP';

    if (json['amount'] is num) {
      parsedAmount = (json['amount'] as num).toDouble();
    } else if (json['amount'] is Map<String, dynamic>) {
      final amountMap = json['amount'] as Map<String, dynamic>;
      parsedAmount = (amountMap['amount'] as num?)?.toDouble() ?? 0.0;
      parsedCurrency = (amountMap['currency'] as String?) ?? parsedCurrency;
    } else if (json['transactionAmount'] is Map<String, dynamic>) {
      final txAmountMap = json['transactionAmount'] as Map<String, dynamic>;
      parsedAmount = (txAmountMap['amount'] as num?)?.toDouble() ?? 0.0;
      parsedCurrency = (txAmountMap['currency'] as String?) ?? parsedCurrency;
    }

    final proprietaryBankTransactionCode =
        json['proprietaryBankTransactionCode'] as Map<String, dynamic>? ?? {};
    final propCode =
        (proprietaryBankTransactionCode['code'] as String? ?? '').toUpperCase();
    final indicator =
        (json['creditDebitIndicator'] as String? ?? '').toUpperCase();

    final isCredit =
        parsedAmount > 0 || indicator == 'CREDIT' || propCode == 'CREDIT';

    String? txInfo;
    if (json['transactionInformation'] is List) {
      final list = json['transactionInformation'] as List<dynamic>;
      if (list.isNotEmpty) {
        txInfo = list.map((e) => e.toString()).join(' ');
      }
    } else if (json['transactionInformation'] is String) {
      txInfo = json['transactionInformation'] as String;
    }

    final merchantMap = json['merchant'] as Map<String, dynamic>?;
    final rawMerchant =
        (merchantMap?['merchantName'] ?? merchantMap?['name']) as String?;

    return Transaction(
      id: json['id'] as String? ?? '',
      description: json['description'] as String?,
      transactionInformation: txInfo,
      amount: parsedAmount,
      currency: parsedCurrency,
      status: json['status'] as String? ?? 'BOOKED',
      transactionReference: json['transactionReference'] as String?,
      date: json['date'] as String?,
      bookingDateTime: json['bookingDateTime'] as String?,
      valueDateTime: json['valueDateTime'] as String?,
      isCredit: isCredit,
      merchantName:
          (rawMerchant != null && rawMerchant.toLowerCase() != 'slacker')
              ? rawMerchant
              : null,
      category: proprietaryBankTransactionCode['code'] as String?,
      pfmCategory: json['pfmCategory'] as String? ?? 'Uncategorized',
    );
  }

  String get displayName =>
      merchantName ??
      description ??
      transactionInformation ??
      transactionReference ??
      'Transaction';

  String get displayDate => bookingDateTime ?? date ?? valueDateTime ?? '';
}
