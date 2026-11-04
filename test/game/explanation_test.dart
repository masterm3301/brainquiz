import 'package:brainquiz/game/explanation.dart';
import 'package:brainquiz/game/levels.dart';
import 'package:brainquiz/game/stability.dart';
import 'package:brainquiz/game/tower_generator.dart';
import 'package:flutter_test/flutter_test.dart';

StabilityReport _report({
  List<int> wrong = const [],
  List<CrookedDrop> crooked = const [],
}) => StabilityReport(
  score: 50,
  mustFall: wrong.length >= 2,
  wrongRows: wrong,
  crooked: crooked,
  topHeavy: false,
  meterLine: '',
);

void main() {
  test('fall: crooked only', () {
    final t = explainFall(
      _report(crooked: [const CrookedDrop(3, -0.2)]),
      total: 5,
    );
    expect(t.headline, 'Right blocks, crooked stack');
    expect(t.detail, contains('third'));
    expect(t.detail, contains('left'));
    expect(t.detail, isNot(contains('wrong')));
  });

  test('fall: two wrong, straight', () {
    final t = explainFall(_report(wrong: [2, 4]), total: 6);
    expect(t.headline, 'Two wrong blocks');
    expect(t.detail, contains('2'));
    expect(t.detail, contains('4'));
    expect(t.detail, isNot(contains('crooked')));
    expect(t.headline, isNot(contains('crooked')));
  });

  test('fall: one wrong and crooked', () {
    final t = explainFall(
      _report(wrong: [2], crooked: [const CrookedDrop(4, 0.2)]),
      total: 6,
    );
    expect(t.headline, 'One wrong block, crooked stack');
    expect(t.detail, contains('fourth'));
    expect(t.detail, contains('right'));
  });

  test('fall: names the largest miss, not the first, with its side', () {
    final tower = generateTower(levels[3], 1);
    final blocks = tower.blocks;
    final report = assessStability(
      target: blocks,
      placed: [
        for (var i = 0; i < blocks.length; i++)
          PlacedBlock(blocks[i], i < 3 ? 0.04 : -0.33),
      ],
      level: levels[3],
    );
    expect(report.crooked.first.row, 1);

    final text = explainFall(report, total: blocks.length);
    expect(text.headline, 'Right blocks, crooked stack');
    expect(text.detail, contains('fourth'));
    expect(text.detail, contains('left'));
    expect(text.detail, isNot(contains('first')));
    expect(text.detail, isNot(contains('right')));
  });

  test('fall: with wrong blocks too, still names the largest miss', () {
    final text = explainFall(
      _report(
        wrong: [2],
        crooked: const [CrookedDrop(1, 0.05), CrookedDrop(5, 0.3)],
      ),
      total: 6,
    );
    expect(text.detail, contains('fifth'));
    expect(text.detail, contains('right'));
    expect(text.detail, isNot(contains('first')));
  });

  test('fall: a tie for the largest miss names the lower block', () {
    final text = explainFall(
      _report(
        crooked: const [CrookedDrop(2, -0.2), CrookedDrop(4, 0.2)],
      ),
      total: 5,
    );
    expect(text.detail, contains('second'));
    expect(text.detail, contains('left'));
  });

  test('fall: nothing wrong is wind luck, never blames a block', () {
    final t = explainFall(_report(), total: 4);
    expect(t.headline, "It couldn't hold");
    expect(t.detail, isNot(contains('wrong')));
    expect(t.detail, isNot(contains('crooked')));
  });

  test('hold: perfect', () {
    expect(
      explainHold(_report()),
      'Every block matched and the stack stayed over the pillar.',
    );
  });

  test('hold: one wrong', () {
    final text = explainHold(_report(wrong: [2]));
    expect(text, contains('one wrong block'));
    expect(text, contains('balanced'));
  });
}
