import 'stability.dart';

class ResultText {
  const ResultText({required this.headline, required this.detail});

  final String headline;
  final String detail;
}

const _ordinals = [
  'first',
  'second',
  'third',
  'fourth',
  'fifth',
  'sixth',
  'seventh',
  'eighth',
  'ninth',
  'tenth',
];

String _ordinal(int row) =>
    row >= 1 && row <= _ordinals.length ? _ordinals[row - 1] : '${row}th';

String _side(Side side) => side == Side.left ? 'left' : 'right';

String _count(int n) => switch (n) {
  1 => 'One',
  2 => 'Two',
  _ => '$n',
};

String _wrongHeadline(int n) => '${_count(n)} wrong block${n == 1 ? '' : 's'}';

String _rows(List<int> rows) {
  if (rows.length == 1) return 'Row ${rows.single} did';
  final head = rows.sublist(0, rows.length - 1).join(', ');
  return 'Rows $head and ${rows.last} did';
}

/// Blames the drop that missed by the most; on a tie, the lowest of them.
String _crookedDetail(List<CrookedDrop> crooked) {
  final worst = crooked.reduce(
    (a, b) => b.offset.abs() > a.offset.abs() ? b : a,
  );
  return 'The ${_ordinal(worst.row)} block was dropped off to the '
      '${_side(worst.side)}, which pulled the stack off the pillar.';
}

ResultText explainFall(StabilityReport report, {required int total}) {
  final wrong = report.wrongCount;
  final crooked = report.crooked;
  if (wrong == 0 && crooked.isEmpty) {
    return const ResultText(
      headline: "It couldn't hold",
      detail:
          'Every block matched and the stack was straight, '
          'but the wind was too strong this time.',
    );
  }
  if (wrong == 0) {
    return ResultText(
      headline: 'Right blocks, crooked stack',
      detail: _crookedDetail(crooked),
    );
  }
  final wrongDetail =
      '${_rows(report.wrongRows)} not match the tower you studied. '
      '${total - wrong} of $total blocks matched.';
  if (crooked.isEmpty) {
    return ResultText(headline: _wrongHeadline(wrong), detail: wrongDetail);
  }
  return ResultText(
    headline: '${_wrongHeadline(wrong)}, crooked stack',
    detail: '$wrongDetail ${_crookedDetail(crooked)}',
  );
}

String explainHold(StabilityReport report) {
  final wrong = report.wrongCount;
  final crooked = report.crooked.isNotEmpty;
  if (wrong == 0) {
    return crooked
        ? 'Every block matched and the stack held, even though it leaned.'
        : 'Every block matched and the stack stayed over the pillar.';
  }
  final what =
      '${_count(wrong).toLowerCase()} wrong block'
      '${wrong == 1 ? '' : 's'}';
  return crooked
      ? 'Despite $what, the stack held in the wind.'
      : 'Despite $what, the stack stayed balanced over the pillar.';
}
