import 'package:flutter/material.dart';

import '../theme/text.dart';
import '../theme/tokens.dart';

const _memoryRules = [
  'Study the cubes before the countdown ends. Tap I\'m ready to start early for bonus points.',
  'Tap a colour to stack the next cube, bottom to top. Big levels split into towers: fill the left one first. Tap any cube to change it.',
  'Get 70% right to clear the level, 80% for two stars, every cube right for three.',
  'Stuck? When an ad is ready, Peek shows the tower again and Same tower retries it after a miss. Ad help caps the round at two stars.',
];

const _rules = [
  'Study the tower before the countdown ends.',
  'Rebuild it from the bottom up. Placed blocks stay put, so drop them straight.',
  'Lock it and hold through the wind. Wrong blocks and crooked drops can bring it down.',
];

/// The rules of both games, as a section of the About page.
class HowToPlay extends StatelessWidget {
  const HowToPlay({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Memory Towers', style: nunito(20, weight: 900)),
      const SizedBox(height: 10),
      ..._steps(_memoryRules),
      const SizedBox(height: 8),
      Text('Wind Levels', style: nunito(20, weight: 900)),
      const SizedBox(height: 10),
      ..._steps(_rules),
    ],
  );
}

List<Widget> _steps(List<String> rules) => [
  for (var i = 0; i < rules.length; i++)
    Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${i + 1}',
              style: nunito(18, weight: 900, color: AppColors.green).copyWith(
                shadows: [
                  Shadow(
                    color: AppColors.green.withValues(alpha: 0.7),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Text(
              rules[i],
              style: nunito(
                15,
                weight: 700,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ),
];
