/// 30 per correct block, 10 per 3 seconds held, minus 40 per paid brace.
int pointsFor({
  required int correct,
  required int heldSeconds,
  required int paidBraces,
}) {
  final points =
      30 * correct + (heldSeconds * 10 / 3).round() - 40 * paidBraces;
  return points < 0 ? 0 : points;
}

/// Three stars for a clean perfect stand, two if help was used,
/// one for a stand with any wrong block. A fall earns none (see Attempt).
int starsFor({
  required int correct,
  required int total,
  required bool usedBrace,
  required bool usedSecondLook,
}) {
  if (correct < total) return 1;
  return usedBrace || usedSecondLook ? 2 : 3;
}
