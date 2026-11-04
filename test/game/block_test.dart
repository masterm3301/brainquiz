import 'package:brainquiz/game/block.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('block equality and triangle mass', () {
    const a = Block(
      color: BlockColor.green,
      shape: BlockShape.rectangle,
      width: .5,
      height: 40,
    );
    const b = Block(
      color: BlockColor.green,
      shape: BlockShape.rectangle,
      width: .5,
      height: 40,
    );
    const t = Block(
      color: BlockColor.green,
      shape: BlockShape.triangle,
      width: .5,
      height: 40,
    );
    const it = Block(
      color: BlockColor.green,
      shape: BlockShape.invertedTriangle,
      width: .5,
      height: 40,
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(t.mass, a.mass / 2);
    expect(it.mass, a.mass / 2);
    expect(a, isNot(t));
  });

  test('pillar is a red rectangle', () {
    expect(pillar.color, BlockColor.red);
    expect(pillar.shape, BlockShape.rectangle);
    expect(pillar.width, 0.18);
    expect(pillar.height, 70);
  });
}
