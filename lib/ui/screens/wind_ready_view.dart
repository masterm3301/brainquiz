import 'package:flutter/material.dart';

import '../../game/attempt.dart';
import '../app_scope.dart';
import '../theme/text.dart';
import '../theme/tokens.dart';
import '../widgets/arena.dart';
import '../widgets/neon_button.dart';
import '../widgets/panel.dart';
import '../widgets/tower_view.dart';
import '../widgets/screen_body.dart';

/// Between the lock and the wind: the only place the extra-brace ad is
/// offered. Shown only when an ad is ready.
class WindReadyView extends StatefulWidget {
  const WindReadyView({super.key, required this.attempt, required this.onStart});

  final Attempt attempt;
  final VoidCallback onStart;

  @override
  State<WindReadyView> createState() => _WindReadyViewState();
}

class _WindReadyViewState extends State<WindReadyView> {
  bool _adShowing = false;

  Future<void> _watch() async {
    if (_adShowing || widget.attempt.adBraceEarned) return;
    setState(() => _adShowing = true);
    final earned = await AppScope.of(context).ads.show();
    if (!mounted) return;
    setState(() => _adShowing = false);
    if (earned) widget.attempt.earnAdBrace();
  }

  @override
  Widget build(BuildContext context) {
    final ads = AppScope.of(context).ads;
    return ScreenBody(
      children: [
        Text('Tower locked'.toUpperCase(), style: label(color: AppColors.green)),
        const SizedBox(height: 6),
        Text(
          'Ready for the wind',
          style: nunito(28, weight: 900, letterSpacing: -0.4),
        ),
        const SizedBox(height: 18),
        ArenaSlot(
          child: Arena(
            child: TowerView(placed: widget.attempt.placed),
          ),
        ),
        const SizedBox(height: 20),
        ListenableBuilder(
          listenable: Listenable.merge([widget.attempt, ads.isReady]),
          builder: (context, _) {
            final earned = widget.attempt.adBraceEarned;
            final offer = !earned && (ads.isReady.value || _adShowing);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Before the wind'.toUpperCase(), style: label(size: 11)),
                      const SizedBox(height: 6),
                      Text(
                        earned
                            ? 'Extra brace earned. You have two braces, and '
                                  'the first one is free.'
                            : 'Once the wind starts you cannot add anything. '
                                  'An extra brace is a free way to steady a '
                                  'leaning tower.',
                        style: nunito(
                          15,
                          weight: 700,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (offer) ...[
                  Stack(
                    children: [
                      NeonButton.outline(
                        'Watch ad for an extra brace',
                        onPressed: _adShowing ? null : _watch,
                      ),
                      Positioned(
                        top: 4,
                        right: 6,
                        child: IgnorePointer(
                          child: Text('Ad'.toUpperCase(), style: label(size: 10)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                NeonButton.primary(
                  'Start the wind',
                  onPressed: _adShowing ? null : widget.onStart,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
