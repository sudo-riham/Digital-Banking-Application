// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/account_card.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/account.dart';

class AccountCard extends StatelessWidget {
  final Account account;
  final bool isSelected;
  final VoidCallback onTap;

  const AccountCard({
    super.key,
    required this.account,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iban = account.iban;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isSelected
                ? [const Color(0xFF1F6FEB), const Color(0xFF0D419D)]
                : [const Color(0xFF161B22), const Color(0xFF161B22)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF58A6FF)
                : const Color(0xFF30363D),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    account.type.isNotEmpty ? account.type : account.accountType,
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : const Color(0xFF8B949E),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    account.usageType.isNotEmpty ? account.usageType : 'ACCOUNT',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${account.currency} ${account.balance.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Holder: ${account.holderName}',
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFFC9D1D9),
                fontSize: 13,
              ),
            ),
            if (iban != null && iban.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'IBAN: $iban',
                style: TextStyle(
                  color: isSelected ? Colors.white70 : const Color(0xFF8B949E),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ] else if (account.accountIdentifications.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                account.accountIdentifications
                    .map((i) => '${i.type}: ${i.identification}')
                    .join(' • '),
                style: TextStyle(
                  color: isSelected ? Colors.white70 : const Color(0xFF8B949E),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
