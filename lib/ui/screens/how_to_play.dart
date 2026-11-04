import 'package:flutter/material.dart';

import '../theme/text.dart';
import '../theme/tokens.dart';

const _rules = [
  'Study the tower before the countdown ends.',
  'Rebuild it from the bottom up. Placed blocks stay put, so drop them straight.',
  'Lock it and hold through the wind. Wrong blocks and crooked drops can bring it down.',
];

Future<void> showHowToPlay(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
          side: BorderSide(color: AppColors.rule)),
      isScrollControlled: true,
      builder: (_) => const HowToPlaySheet(),
    );

class HowToPlaySheet extends StatelessWidget {
  const HowToPlaySheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HOW TO PLAY', style: label(size: 11)),
            const SizedBox(height: 14),
            for (var i = 0; i < _rules.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('${i + 1}',
                          style: nunito(18, weight: 900, color: AppColors.green)
                              .copyWith(shadows: [
                            Shadow(
                                color: AppColors.green.withValues(alpha: 0.7),
                                blurRadius: 12)
                          ])),
                    ),
                    Expanded(
                      child: Text(_rules[i],
                          style: nunito(15,
                              weight: 700,
                              color: AppColors.textSecondary,
                              height: 1.4)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
