import 'package:flutter/widgets.dart';

import '../theme/text.dart';
import '../theme/tokens.dart';

class NeonButton extends StatelessWidget {
  const NeonButton.primary(this.label,
      {super.key, this.onPressed, Color? color})
      : _outline = false,
        color = color ?? AppColors.green;
  const NeonButton.outline(this.label,
      {super.key, this.onPressed, Color? color})
      : _outline = true,
        color = color ?? AppColors.green;

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool _outline;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Opacity(
          opacity: enabled ? 1 : 0.4,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _outline ? null : color,
              border: _outline ? Border.all(color: color, width: 2) : null,
              boxShadow: _outline
                  ? null
                  : [
                      BoxShadow(
                          color: color.withValues(alpha: 0.45), blurRadius: 30),
                    ],
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: nunito(18,
                  weight: 900, color: _outline ? color : AppColors.onGreen),
            ),
          ),
        ),
      ),
    );
  }
}
