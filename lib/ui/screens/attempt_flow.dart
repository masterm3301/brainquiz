import 'package:flutter/material.dart';

import '../theme/text.dart';
import '../theme/tokens.dart';
import 'levels_screen.dart';

/// Placeholder until the level loop lands: shows the level and goes back.
class AttemptFlow extends StatefulWidget {
  const AttemptFlow({super.key, required this.levelNumber});

  final int levelNumber;

  @override
  State<AttemptFlow> createState() => _AttemptFlowState();
}

class _AttemptFlowState extends State<AttemptFlow> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackLabel(),
              const SizedBox(height: 16),
              Text('Level ${widget.levelNumber}',
                  style: nunito(28, weight: 900)),
            ],
          ),
        ),
      ),
    );
  }
}
