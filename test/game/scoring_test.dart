import 'package:brainquiz/game/scoring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a perfect level 4 is worth 240, a paid brace costs 40', () {
    expect(pointsFor(correct: 6, heldSeconds: 18, paidBraces: 0), 240);
    expect(pointsFor(correct: 6, heldSeconds: 18, paidBraces: 1), 200);
    expect(pointsFor(correct: 0, heldSeconds: 0, paidBraces: 2), 0);
  });

  test('stars', () {
    expect(
      starsFor(correct: 6, total: 6, usedBrace: false, usedSecondLook: false),
      3,
    );
    expect(
      starsFor(correct: 6, total: 6, usedBrace: true, usedSecondLook: false),
      2,
    );
    expect(
      starsFor(correct: 6, total: 6, usedBrace: false, usedSecondLook: true),
      2,
    );
    expect(
      starsFor(correct: 5, total: 6, usedBrace: false, usedSecondLook: false),
      1,
    );
  });
}
