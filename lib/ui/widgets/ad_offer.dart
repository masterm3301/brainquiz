import 'package:flutter/material.dart';

import '../theme/text.dart';
import '../theme/tokens.dart';
import 'neon_button.dart';

/// Says what a rewarded ad gives before it plays. Completes true when the
/// player chooses to watch, false for "Not now" or a dismissed sheet.
Future<bool> showAdOffer(
  BuildContext context, {
  required String title,
  required String body,
}) async {
  final watch = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.panel,
    shape: const RoundedRectangleBorder(
      side: BorderSide(color: AppColors.rule),
    ),
    isScrollControlled: true,
    builder: (context) => _AdOfferSheet(title: title, body: body),
  );
  return watch ?? false;
}

class _AdOfferSheet extends StatelessWidget {
  const _AdOfferSheet({required this.title, required this.body});

  final String title, body;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const AdBadge(),
              const SizedBox(width: 8),
              Text('Optional help'.toUpperCase(), style: label(size: 11)),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: nunito(24, weight: 900)),
          const SizedBox(height: 8),
          Text(
            body,
            style: nunito(
              15,
              weight: 700,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          NeonButton.primary(
            'Watch ad',
            key: const ValueKey('ad-offer-watch'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
          GestureDetector(
            key: const ValueKey('ad-offer-cancel'),
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(false),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Not now',
                textAlign: TextAlign.center,
                style: nunito(15, weight: 800, color: AppColors.textTertiary),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A small "AD" tag for buttons that play a rewarded ad.
class AdBadge extends StatelessWidget {
  const AdBadge({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.yellow, width: 1.5),
      ),
      child: Text('AD', style: label(size: 10, color: AppColors.yellow)),
    ),
  );
}
