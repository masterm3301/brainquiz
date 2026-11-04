import 'package:brainquiz/game/study_clock.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a study clock cannot jump when the app returns from background', () {
    final c = StudyClock(6);
    c.step(120);
    expect(c.done, isFalse);
    expect(c.fractionLeft, closeTo(1 - .05 / 6, 1e-9));
  });

  test('it counts down whole seconds, rounding up, and finishes', () {
    final c = StudyClock(2);
    expect(c.secondsLeft, 2);
    expect(c.fractionLeft, 1);
    for (var i = 0; i < 21; i++) {
      c.step(.05);
    }
    expect(c.secondsLeft, 1);
    expect(c.done, isFalse);
    for (var i = 0; i < 20; i++) {
      c.step(.05);
    }
    expect(c.secondsLeft, 0);
    expect(c.fractionLeft, 0);
    expect(c.done, isTrue);
  });
}
