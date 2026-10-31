// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/institution_card.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/institution.dart';

class InstitutionCard extends StatelessWidget {
  final Institution institution;
  final VoidCallback onTap;

  const InstitutionCard({
    super.key,
    required this.institution,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final countries = institution.countryCodes.join(', ');

    return Card(
      color: const Color(0xFF161B22),
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: institution.isSandbox
              ? const Color(0xFF238636).withValues(alpha: 0.5)
              : const Color(0xFF30363D),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Bank Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF21262D),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: institution.iconUrl.isNotEmpty
                    ? Image.network(
                        institution.iconUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.account_balance_rounded,
                          color: Color(0xFF58A6FF),
                        ),
                      )
                    : const Icon(
                        Icons.account_balance_rounded,
                        color: Color(0xFF58A6FF),
                      ),
              ),
              const SizedBox(width: 14),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            institution.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (institution.isSandbox) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF238636).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF2EA043),
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              'SANDBOX',
                              style: TextStyle(
                                color: Color(0xFF3FB950),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${institution.id}${countries.isNotEmpty ? ' • $countries' : ''}',
                      style: const TextStyle(
                        color: Color(0xFF8B949E),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFF8B949E),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
