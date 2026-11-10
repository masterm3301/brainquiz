import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_scope.dart';
import '../theme/text.dart';
import '../theme/tokens.dart';
import '../widgets/neon_button.dart';
import 'how_to_play.dart';
import 'levels_screen.dart' show BackLabel;

/// A few lines about the developer, shown under "Made by".
const developerBio =
    'Memory Towers is made by one independent developer who loves small '
    'games that train the mind.';

/// The developer's GitHub profile, linked under "Made by".
final developerGithub = Uri.parse('https://github.com/masterm3301');

/// Opens [url] outside the app. Tests swap it for a fake.
typedef LinkOpener = Future<bool> Function(Uri url);

Future<bool> _openExternally(Uri url) =>
    launchUrl(url, mode: LaunchMode.externalApplication);

/// About: how to play, the coming ranking, the developer, and a full reset.
class AboutScreen extends StatelessWidget {
  const AboutScreen({
    super.key,
    this.openLink = _openExternally,
    this.rulesOpen = false,
  });

  final LinkOpener openLink;

  /// Opens with How to play unfolded, for the home screen's help button.
  final bool rulesOpen;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Align(alignment: Alignment.centerLeft, child: BackLabel()),
          const SizedBox(height: 4),
          Text('About', style: nunito(28, weight: 900)),
          const SizedBox(height: 22),
          _HowToPlayDropdown(initiallyOpen: rulesOpen),
          const _Section('Top memory recallers', child: _RankingSoon()),
          _Section('Made by', child: _Developer(openLink)),
          const _Section('Progress', child: _ResetProgress()),
          const _PrivacyOptions(),
        ],
      ),
    ),
  );
}

/// A small caps heading over a panel.
class _Section extends StatelessWidget {
  const _Section(this.title, {required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title.toUpperCase(), style: label(size: 12)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.panel,
            border: Border.all(color: AppColors.rule),
          ),
          child: child,
        ),
      ],
    ),
  );
}

TextStyle _body([Color color = AppColors.textSecondary]) =>
    nunito(15, weight: 700, color: color, height: 1.45);

class _RankingSoon extends StatelessWidget {
  const _RankingSoon();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.yellow, width: 1.5),
        ),
        child: Text('Coming soon'.toUpperCase(),
            style: label(size: 10, color: AppColors.yellow)),
      ),
      const SizedBox(height: 10),
      Text(
        'A ranking of the players with the sharpest memory is on its way. '
        'Keep clearing levels and collecting stars.',
        style: _body(),
      ),
    ],
  );
}

class _Developer extends StatelessWidget {
  const _Developer(this.openLink);

  final LinkOpener openLink;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(developerBio, style: _body()),
      const SizedBox(height: 14),
      Semantics(
        link: true,
        label: 'GitHub, ${developerGithub.host}${developerGithub.path}',
        excludeSemantics: true,
        child: GestureDetector(
          key: const ValueKey('about-github'),
          behavior: HitTestBehavior.opaque,
          onTap: () => _open(context),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.green, width: 2),
            ),
            child: Row(
              children: [
                Text('GitHub', style: nunito(16, weight: 900)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${developerGithub.host}${developerGithub.path}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: nunito(14, weight: 800, color: AppColors.green),
                  ),
                ),
                const _Chevron(),
              ],
            ),
          ),
        ),
      ),
    ],
  );

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    var opened = false;
    try {
      opened = await openLink(developerGithub);
    } catch (_) {}
    if (!opened) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.panel,
          content: Text(
            'Could not open the link. Visit $developerGithub',
            style: nunito(14, weight: 700, color: AppColors.textSecondary),
          ),
        ),
      );
    }
  }
}

/// How to play, folded away until the player taps its heading.
class _HowToPlayDropdown extends StatefulWidget {
  const _HowToPlayDropdown({required this.initiallyOpen});

  final bool initiallyOpen;

  @override
  State<_HowToPlayDropdown> createState() => _HowToPlayDropdownState();
}

class _HowToPlayDropdownState extends State<_HowToPlayDropdown> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        border: Border.all(
          color: _open
              ? AppColors.green.withValues(alpha: 0.35)
              : AppColors.rule,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: _open,
            label: 'How to play',
            excludeSemantics: true,
            child: GestureDetector(
              key: const ValueKey('about-how-to-play'),
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _open = !_open),
              child: Container(
                constraints: const BoxConstraints(minHeight: 56),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('How to play', style: nunito(18, weight: 900)),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const _Chevron(down: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _open
                ? const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: HowToPlay(),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    ),
  );
}

/// The ad consent form, when the player's region requires one.
class _PrivacyOptions extends StatelessWidget {
  const _PrivacyOptions();

  @override
  Widget build(BuildContext context) {
    final ads = AppScope.of(context).ads;
    return ValueListenableBuilder<bool>(
      valueListenable: ads.privacyOptionsRequired,
      builder: (context, required, _) => !required
          ? const SizedBox.shrink()
          : _Section(
              'Privacy',
              child: NeonButton.outline(
                'Privacy options',
                key: const ValueKey('about-privacy'),
                color: AppColors.textSecondary,
                onPressed: ads.showPrivacyOptions,
              ),
            ),
    );
  }
}

class _ResetProgress extends StatelessWidget {
  const _ResetProgress();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Start over from level 1. This clears every star and point in '
        'Memory Towers and Wind Levels.',
        style: _body(),
      ),
      const SizedBox(height: 14),
      NeonButton.outline(
        'Reset game',
        key: const ValueKey('about-reset'),
        color: AppColors.red,
        onPressed: () => _confirmReset(context),
      ),
    ],
  );
}

Future<void> _confirmReset(BuildContext context) async {
  final scope = AppScope.of(context);
  final navigator = Navigator.of(context);
  final sure = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.panel,
    shape: const RoundedRectangleBorder(
      side: BorderSide(color: AppColors.rule),
    ),
    isScrollControlled: true,
    builder: (context) => const _ResetSheet(),
  );
  if (sure != true) return;
  await Future.wait([scope.memoryProgress.reset(), scope.progress.reset()]);
  navigator.popUntil((route) => route.isFirst);
}

class _ResetSheet extends StatelessWidget {
  const _ResetSheet();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Reset game?', style: nunito(24, weight: 900)),
          const SizedBox(height: 8),
          Text(
            'All your stars, points and unlocked levels in both games will '
            'be gone. This cannot be undone.',
            style: _body(),
          ),
          const SizedBox(height: 20),
          NeonButton.primary(
            'Reset everything',
            key: const ValueKey('about-reset-confirm'),
            color: AppColors.red,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          GestureDetector(
            key: const ValueKey('about-reset-cancel'),
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).pop(false),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Keep my progress',
                textAlign: TextAlign.center,
                style: nunito(15, weight: 800, color: AppColors.textTertiary),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// A small green arrow: right for a link, down for a closed dropdown.
class _Chevron extends StatelessWidget {
  const _Chevron({this.down = false});

  final bool down;

  @override
  Widget build(BuildContext context) => RotatedBox(
    quarterTurns: down ? 1 : 0,
    child: const CustomPaint(size: Size(16, 16), painter: _ChevronPainter()),
  );
}

class _ChevronPainter extends CustomPainter {
  const _ChevronPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.35, h * 0.2)
        ..lineTo(w * 0.7, h * 0.5)
        ..lineTo(w * 0.35, h * 0.8),
      Paint()
        ..color = AppColors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => false;
}
