import 'dart:io';
import 'dart:ui' as ui;

import 'package:brainquiz/ui/theme/tokens.dart';
import 'package:flutter_test/flutter_test.dart';

/// Not a check: paints the launcher icon to assets/icon/icon.png.
/// Run `flutter test test/visual/render_icon_test.dart`, then
/// `dart run flutter_launcher_icons`.
void main() {
  test('render the launcher icon', () async {
    const size = 1024.0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, size, size),
      ui.Paint()..color = AppColors.background,
    );

    // Floor line and the red pillar standing on it.
    const floorY = 820.0;
    canvas.drawRect(
      const ui.Rect.fromLTWH(140, floorY, 744, 14),
      ui.Paint()..color = AppColors.dashed,
    );
    // Three glowing blocks, each centred on the pillar.
    final blocks = {
      const ui.Rect.fromLTWH(222, 610, 580, 170): AppColors.cyan,
      const ui.Rect.fromLTWH(302, 410, 420, 170): AppColors.green,
      const ui.Rect.fromLTWH(382, 210, 260, 170): AppColors.yellow,
    };
    blocks.forEach((rect, color) {
      canvas.drawRect(
        rect.inflate(10),
        ui.Paint()
          ..color = color.withValues(alpha: 0.6)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 40),
      );
    });
    canvas.drawRect(
      const ui.Rect.fromLTWH(472, 190, 80, floorY - 190),
      ui.Paint()..color = AppColors.red,
    );

    blocks.forEach((rect, color) {
      canvas.drawRect(rect, ui.Paint()..color = color);
    });

    final picture = recorder.endRecording();
    final bytes = await () async {
      final image = await picture.toImage(size.toInt(), size.toInt());
      return image.toByteData(format: ui.ImageByteFormat.png);
    }();
    File('assets/icon/icon.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
