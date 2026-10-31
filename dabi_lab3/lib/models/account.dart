// ─────────────────────────────────────────────────────────────────────────────
// lib/models/account.dart
// ─────────────────────────────────────────────────────────────────────────────

class AccountIdentification {
  final String type;
  final String identification;

  const AccountIdentification({required this.type, required this.identification});

  factory AccountIdentification.fromJson(Map<String, dynamic> json) =>
      AccountIdentification(
        type:           json['type']           as String? ?? '',
        identification: json['identification'] as String? ?? '',
      );
}

class AccountBalance {
  final String type;
  final double amount;
  final String currency;

  const AccountBalance({
    required this.type,
    required this.amount,
    required this.currency,
  });

  factory AccountBalance.fromJson(Map<String, dynamic> json) {
    final balanceAmount = json['balanceAmount'] as Map<String, dynamic>? ?? {};
    return AccountBalance(
      type:     json['type']     as String? ?? '',
      amount:   (balanceAmount['amount'] as num?)?.toDouble() ?? 0.0,
      currency: balanceAmount['currency'] as String? ?? '',
    );
  }
}

class Account {
  final String id;
  final String type;
  final double balance;
  final String currency;
  final String usageType;
  final String accountType;
  final String nickname;
  final List<String> accountNames;
  final List<AccountIdentification> accountIdentifications;
  final List<AccountBalance> accountBalances;

  const Account({
    required this.id,
    required this.type,
    required this.balance,
    required this.currency,
    required this.usageType,
    required this.accountType,
    required this.nickname,
    required this.accountNames,
    required this.accountIdentifications,
    required this.accountBalances,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id:          json['id']          as String? ?? '',
      type:        json['type']        as String? ?? '',
      balance:     (json['balance']    as num?)?.toDouble() ?? 0.0,
      currency:    json['currency']    as String? ?? '',
      usageType:   json['usageType']   as String? ?? '',
      accountType: json['accountType'] as String? ?? '',
      nickname:    json['nickname']    as String? ?? '',
      accountNames: (json['accountNames'] as List<dynamic>? ?? [])
          .map((e) => (e as Map<String, dynamic>)['name'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList(),
      accountIdentifications: (json['accountIdentifications'] as List<dynamic>? ?? [])
          .map((e) => AccountIdentification.fromJson(e as Map<String, dynamic>))
          .toList(),
      accountBalances: (json['accountBalances'] as List<dynamic>? ?? [])
          .map((e) => AccountBalance.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String? get iban {
    try {
      return accountIdentifications.firstWhere((i) => i.type == 'IBAN').identification;
    } catch (_) {
      return null;
    }
  }

  String get holderName => accountNames.isNotEmpty ? accountNames.first : 'Unknown';

  bool get isPositive => balance >= 0;
}
