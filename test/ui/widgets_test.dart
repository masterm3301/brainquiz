import 'package:brainquiz/game/block.dart';
import 'package:brainquiz/game/stability.dart';
import 'package:brainquiz/ui/theme/tokens.dart';
import 'package:brainquiz/ui/widgets/block_view.dart';
import 'package:brainquiz/ui/widgets/collapse_view.dart';
import 'package:brainquiz/ui/widgets/meter.dart';
import 'package:brainquiz/ui/widgets/neon_button.dart';
import 'package:brainquiz/ui/widgets/tower_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _wide = Block(
  color: BlockColor.yellow,
  shape: BlockShape.rectangle,
  width: 0.6,
  height: 40,
);

void main() {
  final tallTower10 = List.filled(10, _wide);
  final smallTower3 = List.filled(3, _wide);

  test('meter colours use the spec bands', () {
    expect(meterColor(70), AppColors.green);
    expect(meterColor(69), AppColors.yellow);
    expect(meterColor(40), AppColors.yellow);
    expect(meterColor(39), AppColors.red);
  });

  test('block colours map to tokens', () {
    expect(blockColor(BlockColor.green), AppColors.green);
    expect(blockColor(BlockColor.cyan), AppColors.cyan);
    expect(blockColor(BlockColor.yellow), AppColors.yellow);
    expect(blockColor(BlockColor.red), AppColors.red);
  });

  test('ten blocks scale to fit, and small towers are not enlarged', () {
    expect(TowerLayout.scaleFor(tallTower10, 240), lessThan(1));
    expect(TowerLayout.scaleFor(smallTower3, 600), 1);
  });

  testWidgets('a disabled NeonButton does not fire', (t) async {
    var taps = 0;
    await t.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Column(children: [
        const NeonButton.primary('Off'),
        NeonButton.outline('On', onPressed: () => taps++),
      ]),
    ));
    await t.tap(find.text('Off'));
    expect(taps, 0);
    await t.tap(find.text('On'));
    expect(taps, 1);
  });

  testWidgets('every shape paints without error', (t) async {
    await t.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Column(children: [
        for (final s in BlockShape.values)
          for (final held in [false, true])
            BlockView(
              block: Block(
                  color: BlockColor.green, shape: s, width: 0.3, height: 30),
              width: 80,
              height: 30,
              heldWhite: held,
            ),
      ]),
    ));
    expect(t.takeException(), isNull);
  });

  testWidgets('replay restarts the collapse', (t) async {
    final key = GlobalKey<CollapseViewState>();
    await t.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: 300,
        height: 400,
        child: CollapseView(
          key: key,
          placed: const [PlacedBlock(_wide, 0), PlacedBlock(_wide, 0.05)],
          seed: 7,
          direction: 1,
        ),
      ),
    ));
    await t.pump(const Duration(milliseconds: 1500));
    expect(key.currentState!.controller.value, 1);
    key.currentState!.replay();
    await t.pump(const Duration(milliseconds: 100));
    expect(key.currentState!.controller.value, lessThan(0.3));
  });
}
