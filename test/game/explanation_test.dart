import 'package:brainquiz/game/explanation.dart';
import 'package:brainquiz/game/stability.dart';
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
      _report(crooked: [const CrookedDrop(3, Side.left)]),
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
      _report(wrong: [2], crooked: [const CrookedDrop(4, Side.right)]),
      total: 6,
    );
    expect(t.headline, 'One wrong block, crooked stack');
    expect(t.detail, contains('fourth'));
    expect(t.detail, contains('right'));
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
