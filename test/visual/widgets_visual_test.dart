import 'package:brainquiz/game/block.dart';
import 'package:brainquiz/game/stability.dart';
import 'package:brainquiz/ui/theme/tokens.dart';
import 'package:brainquiz/ui/theme/text.dart';
import 'package:brainquiz/ui/widgets/arena.dart';
import 'package:brainquiz/ui/widgets/tower_view.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/load_font.dart';

Block _b(BlockColor c, BlockShape s, double w, double h) =>
    Block(color: c, shape: s, width: w, height: h);

void main() {
  testWidgets('widgets golden', (t) async {
    await loadNunito();
    t.view.physicalSize = const Size(380, 600);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: AppColors.background,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Stack(children: [Arena(
            showCentreLine: true,
            child: TowerView(
              leanDegrees: 4,
              placed: [
                PlacedBlock(_b(BlockColor.cyan, BlockShape.rectangle, 0.74, 26), 0),
                PlacedBlock(_b(BlockColor.green, BlockShape.triangle, 0.82, 40), 0),
                PlacedBlock(_b(BlockColor.yellow, BlockShape.rectangle, 0.7, 44), 0),
                PlacedBlock(_b(BlockColor.cyan, BlockShape.square, 0.3, 30), 0),
                PlacedBlock(_b(BlockColor.green, BlockShape.invertedTriangle, 0.4, 36), 0),
              ],
            ),
          ),
          Positioned(
            left: 16,
            top: 14,
            child: Text('Memorise the tower',
                style: nunito(22, weight: 900)),
          ),
          ]),
        ),
      ),
    ));
    await expectLater(find.byType(Directionality),
        matchesGoldenFile('goldens/widgets.png'));
  });
}
