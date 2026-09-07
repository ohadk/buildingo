import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/l10n.dart';

/// Destination for WhatsApp / Universal Link `/open/payments`.
/// In-app payment is not live yet — this page proves the link opens Buildingo.
class PaymentsComingSoonScreen extends StatelessWidget {
  const PaymentsComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: DiraColors.cream,
      appBar: AppBar(
        title: Text(l10n.payments),
        automaticallyImplyLeading: canPop,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
          child: Column(
            children: [
              const Spacer(flex: 1),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: DiraColors.brick.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  size: 42,
                  color: DiraColors.brickDark,
                ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: DiraColors.goldLight,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: DiraColors.gold.withValues(alpha: 0.55),
                  ),
                ),
                child: Text(
                  l10n.paymentsComingSoonBadge,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: DiraColors.goldDark,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.paymentsComingSoonTitle,
                textAlign: TextAlign.center,
                style: heading(fontSize: 24),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.paymentsComingSoonBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: DiraColors.inkSoft,
                ),
              ),
              const Spacer(flex: 2),
              if (canPop)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.gotIt),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
