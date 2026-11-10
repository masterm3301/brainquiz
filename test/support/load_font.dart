import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the bundled fonts so widget and golden tests render real glyphs.
Future<void> loadNunito() async {
  for (final (family, file) in const [
    ('Nunito', 'Nunito-Variable.ttf'),
    ('Manrope', 'Manrope-Variable.ttf'),
    ('Unbounded', 'Unbounded-Variable.ttf'),
  ]) {
    final bytes = File('assets/fonts/$file').readAsBytesSync();
    final loader = FontLoader(family)
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
  }
}
