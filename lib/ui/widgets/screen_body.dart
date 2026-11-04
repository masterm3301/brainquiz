import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../theme/tokens.dart';

/// Shared frame for the wind and result screens: the sheet's padding, with
/// an [ArenaSlot] that takes whatever height is left. Content scrolls only
/// when it cannot fit even with the arena at its minimum height.
class ScreenBody extends StatelessWidget {
  const ScreenBody({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, c) {
          final compact = c.maxHeight < 700;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: c.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    compact ? 12 : 24,
                    24,
                    compact ? 12 : 28,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

/// The flexible arena of a [ScreenBody]: fills the leftover height, and
/// never gets smaller than [minHeight].
class ArenaSlot extends StatelessWidget {
  const ArenaSlot({super.key, required this.child, this.minHeight = 90});

  final Widget child;
  final double minHeight;

  @override
  Widget build(BuildContext context) =>
      Expanded(child: _MinHeight(minHeight: minHeight, child: child));
}

/// Reports a fixed intrinsic height, because the arena's layout builders
/// cannot answer intrinsic queries.
class _MinHeight extends SingleChildRenderObjectWidget {
  const _MinHeight({required this.minHeight, required super.child});

  final double minHeight;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMinHeight(minHeight);

  @override
  void updateRenderObject(BuildContext context, _RenderMinHeight r) =>
      r.minHeight = minHeight;
}

class _RenderMinHeight extends RenderProxyBox {
  _RenderMinHeight(this._minHeight);

  double _minHeight;
  set minHeight(double v) {
    if (v == _minHeight) return;
    _minHeight = v;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicHeight(double width) => _minHeight;
  @override
  double computeMaxIntrinsicHeight(double width) => _minHeight;
  @override
  double computeMinIntrinsicWidth(double height) => 0;
  @override
  double computeMaxIntrinsicWidth(double height) => 0;
}
