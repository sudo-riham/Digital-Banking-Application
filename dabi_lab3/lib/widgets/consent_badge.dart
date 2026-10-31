// ─────────────────────────────────────────────────────────────────────────────
// lib/widgets/consent_badge.dart
//
// Displays the Open Banking AIS consent lease details:
// - authorizedAt
// - expiresAt
// - reconfirmBy
// Emphasises that AIS consent is a temporary lease, not forever.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../models/consent_info.dart';

class ConsentBadge extends StatelessWidget {
  final ConsentInfo consent;

  const ConsentBadge({super.key, required this.consent});

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) {
      return 'Not specified by ASPSP (90-day default window)';
    }
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthorized = consent.status.toUpperCase() == 'AUTHORIZED';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isAuthorized ? const Color(0xFF238636) : const Color(0xFFD29922),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isAuthorized ? Icons.verified_user_rounded : Icons.schedule_rounded,
                color: isAuthorized ? const Color(0xFF3FB950) : const Color(0xFFD29922),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'AISP Consent Lease (Read-Only)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isAuthorized
                          ? const Color(0xFF238636)
                          : const Color(0xFFD29922))
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  consent.status,
                  style: TextStyle(
                    color: isAuthorized
                        ? const Color(0xFF3FB950)
                        : const Color(0xFFD29922),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Consent is a time-bounded lease under Open Banking rules, not permanent access.',
            style: TextStyle(color: Color(0xFF8B949E), fontSize: 12),
          ),
          const Divider(color: Color(0xFF30363D), height: 22),
          _buildRow('Consent ID', consent.id.isNotEmpty ? consent.id : 'N/A'),
          const SizedBox(height: 8),
          _buildRow(
            'authorizedAt',
            _formatDate(consent.authorizedAt ?? consent.createdAt),
          ),
          const SizedBox(height: 8),
          _buildRow('expiresAt', _formatDate(consent.expiresAt)),
          const SizedBox(height: 8),
          _buildRow('reconfirmBy', _formatDate(consent.reconfirmBy)),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8B949E),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFFC9D1D9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
